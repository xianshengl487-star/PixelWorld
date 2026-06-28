extends Node2D
class_name NPC
## NPC.gd — NPC 控制脚本
## 管理 NPC 数据、显示、交互

const AssetResolverClass = preload("res://scripts/assets/AssetResolver.gd")

# NPC 数据
var npc_data: Dictionary = {}
var _ai_client = null

# 显示节点
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label
@onready var _interact_indicator: ColorRect = $InteractIndicator
@onready var _area: Area2D = $Area2D

# 瓦片坐标到像素坐标的转换
var _tile_size: int = 32


func _ready() -> void:
	# 创建交互碰撞形状（代码中创建）
	var shape_node = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape_node.shape = circle
	_area.add_child(shape_node)
	
	add_to_group("npc")
	_setup_display()
	_setup_interact_indicator()


## 初始化 NPC 数据
func setup(data: Dictionary, ai_client, tile_size: int = 32) -> void:
	npc_data = data
	_ai_client = ai_client
	_tile_size = tile_size
	
	# 设置瓦片坐标到像素坐标
	var x = float(data.get("x", 0))
	var y = float(data.get("y", 0))
	position = Vector2(
		x * tile_size + tile_size / 2,
		y * tile_size + tile_size / 2
	)
	
	_setup_display()


## 设置显示
func _setup_display() -> void:
	if _label:
		var name_text = npc_data.get("name", "NPC")
		var importance = npc_data.get("importance", "minor")
		
		if importance == "major":
			name_text = "★ " + name_text
		
		_label.text = name_text
		_label.position = Vector2(0, -24)
	
	if _sprite:
		var role = npc_data.get("role", "villager")
		var texture = AssetResolverClass.new().get_npc_texture(str(role))
		if texture != null:
			_sprite.texture = texture
			_sprite.region_enabled = texture.get_width() > 32 or texture.get_height() > 32
			if _sprite.region_enabled:
				_sprite.region_rect = Rect2(0, 0, min(32, texture.get_width()), min(32, texture.get_height()))
			_sprite.modulate = Color.WHITE
			return
		# 根据角色类型改变颜色
		match role:
			"quest_giver":
				_sprite.modulate = Color(1, 0.85, 0.3)  # 金色
			"elder":
				_sprite.modulate = Color(0.7, 0.7, 1)  # 淡蓝
			"merchant":
				_sprite.modulate = Color(1, 0.8, 0.4)  # 橙色
			"guard":
				_sprite.modulate = Color(0.5, 0.7, 0.5)  # 绿色
			"enemy":
				_sprite.modulate = Color(1, 0.3, 0.3)  # 红色
			_:
				_sprite.modulate = Color(0.8, 0.8, 0.8)  # 灰色


## 设置交互指示器
func _setup_interact_indicator() -> void:
	if _interact_indicator:
		_interact_indicator.visible = false


## 玩家靠近时显示交互提示
func _on_area_body_entered(body: Node2D) -> void:
	if body.has_method("_try_interact"):
		_show_interact_hint(true)


func _on_area_body_exited(body: Node2D) -> void:
	if body.has_method("_try_interact"):
		_show_interact_hint(false)


func _show_interact_hint(visible: bool) -> void:
	if _interact_indicator:
		_interact_indicator.visible = visible


## 与 NPC 交互
func interact(ai_client) -> void:
	var importance = npc_data.get("importance", "minor")
	
	# 构建上下文
	var context = _build_context()
	
	var result: Dictionary
	
	if importance == "major":
		result = await ai_client.generate_major_npc_reply(context)
	else:
		result = await ai_client.generate_minor_npc_reply(context)
	
	# 处理结果
	_handle_interact_result(result)


## 构建 NPC 交互上下文
func _build_context() -> Dictionary:
	return {
		"npc_id": npc_data.get("id", ""),
		"npc_name": npc_data.get("name", ""),
		"npc_role": npc_data.get("role", "villager"),
		"npc_personality": npc_data.get("personality", []),
		"npc_goal": npc_data.get("goal", ""),
		"npc_memory": WorldState.get_npc_memory(npc_data.get("id", "")),
		"dialogue_profile": npc_data.get("dialogue_profile", ""),
		"initial_dialogue": npc_data.get("initial_dialogue", ""),
		"player_reputation": WorldState.player_reputation,
		"player_action_history": WorldState.action_history.slice(-5),
		"current_location": _get_current_region(),
		"world_type": WorldState.world_type,
		"current_events": WorldState.get_active_events()
	}


## 处理交互结果
func _handle_interact_result(result: Dictionary) -> void:
	var dialogue = result.get("dialogue", "...")
	var attitude_change = result.get("attitude_change", 0)
	var memory_to_add = result.get("memory_to_add")
	var event_trigger = result.get("event_trigger")
	var world_changes = result.get("world_changes", [])
	
	# 记录 NPC 记忆
	if memory_to_add != null:
		WorldState.set_npc_memory(
			npc_data.get("id", ""),
			str(Time.get_unix_time_from_system()),
			memory_to_add
		)
	
	# 触发事件
	if event_trigger != null and event_trigger != "":
		WorldState.set_event_progress(event_trigger, 1)
		GameLog.add_entry("[事件触发] %s" % event_trigger)
	
	# 应用世界变化
	for change in world_changes:
		var change_type = change.get("type", "")
		match change_type:
			"reputation":
				WorldState.player_reputation += change.get("delta", 0)
			"faction":
				WorldState.modify_faction_attitude(change.get("target", ""), change.get("delta", 0))
			"event":
				WorldState.set_event_progress(change.get("target", ""), change.get("delta", 0))
	
	# 记录行动
	var npc_name = npc_data.get("name", "NPC")
	WorldState.log_action("与 %s 对话" % npc_name, {"dialogue": dialogue})
	
	# 显示对话
	_show_dialogue(dialogue, npc_data.get("importance", "minor"))


## 显示对话
func _show_dialogue(dialogue: String, importance: String) -> void:
	var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box and dialogue_box.has_method("show_dialogue"):
		dialogue_box.show_dialogue(npc_data.get("name", "NPC"), dialogue)


## 获取当前位置所在区域
func _get_current_region() -> String:
	var tile_x = int(position.x / _tile_size)
	var tile_y = int(position.y / _tile_size)
	
	for region in WorldState.world_blueprint.get("regions", []):
		# 简单检测：根据 NPC 坐标和区域中心距离
		var region_id = region.get("id", "")
		# 暂时返回 start_region
		return WorldState.world_blueprint.get("start_region", "unknown")
	
	return "unknown"


## 获取瓦片位置
func _get_tile_position() -> Vector2:
	return Vector2(
		int(position.x / _tile_size),
		int(position.y / _tile_size)
	)


## 获取 NPC 数据（供 Player 使用）
func get_npc_data() -> Dictionary:
	return npc_data


func get_interaction_prompt() -> String:
	return "[E] Talk: %s" % str(npc_data.get("name", "NPC"))
