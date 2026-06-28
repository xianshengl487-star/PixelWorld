extends CanvasLayer
class_name GameHUD
## GameHUD.gd — 游戏 HUD
## 显示世界信息、日志、自由行动输入框

@onready var _world_name_label: Label = $TopBar/WorldNameLabel
@onready var _region_label: Label = $TopBar/RegionLabel
@onready var _reputation_label: Label = $TopBar/ReputationLabel
@onready var _hp_label: Label = $TopBar/HPLabel
@onready var _hp_bar: ProgressBar = $TopBar/HPBar
@onready var _stamina_label: Label = $TopBar/StaminaLabel
@onready var _stamina_bar: ProgressBar = $TopBar/StaminaBar
@onready var _log_panel: Panel = $LogPanel
@onready var _log_text: RichTextLabel = $LogPanel/LogText
@onready var _action_input: LineEdit = $BottomBar/ActionInput
@onready var _action_button: Button = $BottomBar/SubmitButton
@onready var _save_button: Button = $BottomBar/SaveButton
@onready var _load_button: Button = $BottomBar/LoadButton
@onready var _action_result: Label = $ActionResult
@onready var _status_label: Label = $StatusLabel
@onready var _inventory_label: Label = $InventoryLabel
@onready var _progression_label: Label = $ProgressionLabel
@onready var _map_info_label: Label = get_node_or_null("MapInfoLabel")
@onready var _building_info_label: Label = get_node_or_null("BuildingInfoLabel")
@onready var _transition_message_label: Label = get_node_or_null("TransitionMessageLabel")

var _ai_client = null
var _player = null


func _ready() -> void:
	_update_hud()
	
	# 连接自由行动输入信号
	if _action_input:
		_action_input.text_submitted.connect(_on_action_submitted)
		_action_input.placeholder_text = "输入自由行动..."
	
	if _action_button:
		_action_button.pressed.connect(_on_action_button_pressed)
	if _save_button:
		_save_button.pressed.connect(_on_save_button_pressed)
	if _load_button:
		_load_button.pressed.connect(_on_load_button_pressed)
	
	# 定时刷新日志显示
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(func():
		_update_log_display()
		_update_hud()
	)
	add_child(timer)


func setup(ai_client, player = null) -> void:
	_ai_client = ai_client
	_player = player
	_update_hud()


func _update_hud() -> void:
	if _world_name_label:
		_world_name_label.text = WorldState.world_name
	
	if _region_label:
		var region = WorldState.current_region
		if region == "":
			region = WorldState.world_blueprint.get("start_region", "未知")
		_region_label.text = "区域: %s" % region
	
	if _reputation_label:
		var rep = WorldState.player_reputation
		var rep_text = "声望: "
		if rep > 10:
			rep_text += str(rep) + " (友善)"
		elif rep < -10:
			rep_text += str(rep) + " (恶名)"
		else:
			rep_text += str(rep) + " (中立)"
		_reputation_label.text = rep_text
	
	var hp = WorldState.player_health
	var max_hp = WorldState.player_max_health
	var stamina = WorldState.player_stamina
	var max_stamina = WorldState.player_max_stamina
	if _player and _player.has_method("get_stats"):
		var s = _player.get_stats()
		hp = s.health
		max_hp = s.max_health
		stamina = s.stamina
		max_stamina = s.max_stamina
	
	if _hp_label:
		_hp_label.text = "HP %d / %d" % [hp, max_hp]
	if _hp_bar:
		_hp_bar.max_value = max(1, max_hp)
		_hp_bar.value = clampi(hp, 0, max_hp)
	if _stamina_label:
		_stamina_label.text = "体力 %d / %d" % [stamina, max_stamina]
	if _stamina_bar:
		_stamina_bar.max_value = max(1, max_stamina)
		_stamina_bar.value = clampi(stamina, 0, max_stamina)
	if _inventory_label:
		_inventory_label.text = _inventory_text()
	update_progression_display(WorldState.get_progression_summary())


func update_progression_display(summary: Dictionary) -> void:
	if _progression_label == null:
		return
	if summary.is_empty() or str(summary.get("system_name", "")) == "":
		_progression_label.text = "成长: 未初始化"
		return
	var progress = int(summary.get("current_progress", 0))
	var target = int(summary.get("progress_to_next", 0))
	var text = "%s | %s %s | %s %d / %d" % [
		summary.get("system_name", "成长"),
		summary.get("current_realm_name", ""),
		summary.get("current_stage_name", ""),
		summary.get("exp_label", "进度"),
		progress,
		max(1, target)
	]
	if bool(summary.get("bottleneck", false)):
		text += " | 瓶颈: %s" % summary.get("bottleneck_reason", "需要突破")
	if bool(summary.get("tribulation_pending", false)):
		text += " | 试炼: %s 待处理" % summary.get("tribulation_type", "")
	var features = summary.get("unlocked_features", [])
	if features is Array and features.size() > 0:
		text += " | 能力: %s" % ", ".join(features.slice(0, min(3, features.size())))
	var modifiers = summary.get("world_modifiers", {})
	if modifiers is Dictionary and modifiers.size() > 0:
		text += " | 世界影响: %d项" % modifiers.size()
	_progression_label.text = text


func update_map_info(map_id: String, display_name: String, map_type: String) -> void:
	var text = "Map: %s (%s)" % [display_name if display_name != "" else map_id, map_type]
	if _map_info_label != null:
		_map_info_label.text = text
	elif _region_label != null:
		_region_label.text = text


func show_transition_message(text: String) -> void:
	if _transition_message_label != null:
		_transition_message_label.text = text
	_set_action_result(text)


func update_building_info(building_name: String = "") -> void:
	var text = "Building: %s" % building_name if building_name != "" else ""
	if _building_info_label != null:
		_building_info_label.text = text


func show_breakthrough_result(result: Dictionary) -> void:
	_set_action_result(str(result.get("message", "突破结果已记录。")))
	update_progression_display(WorldState.get_progression_summary())


func show_tribulation_log(entry: Dictionary) -> void:
	var text = "试炼第%d轮: 伤害 %d" % [int(entry.get("round_index", 0)), int(entry.get("damage", 0))]
	_set_action_result(text)


func show_unlocked_features(features: Array) -> void:
	if _status_label:
		_status_label.text = "已解锁: %s" % ", ".join(features)


## 处理自由行动提交
func _on_action_submitted(text: String) -> void:
	_handle_free_action(text)


func _on_action_button_pressed() -> void:
	if _action_input:
		_handle_free_action(_action_input.text)


func _on_save_button_pressed() -> void:
	var save_manager = _get_save_manager()
	if save_manager and save_manager.save_game():
		_set_action_result("游戏已保存。")
	else:
		_set_action_result("保存失败。")


func _on_load_button_pressed() -> void:
	var save_manager = _get_save_manager()
	if save_manager == null:
		_set_action_result("读取失败。")
		return
	var result = save_manager.load_game()
	if result.get("ok", false):
		var game_world = get_tree().get_first_node_in_group("game_world")
		if game_world and game_world.has_method("apply_loaded_state"):
			game_world.apply_loaded_state()
		_set_action_result("游戏已读取。")
	else:
		_set_action_result("没有可读取的存档。")


func _handle_free_action(text: String) -> void:
	text = text.strip_edges()
	if text == "":
		return
	
	# 清空输入框
	if _action_input:
		_action_input.text = ""
		_action_input.release_focus()
	
	# 显示处理中
	if _action_result:
		_action_result.text = "正在处理..."
	
	GameLog.add_entry("[行动] %s" % text)
	
	if _ai_client == null:
		_ai_client = preload("res://scripts/ai/AIClient.gd").new()
	
	# 构建上下文
	var context = {
		"player_input": text,
		"player_reputation": WorldState.player_reputation,
		"player_position": {"x": WorldState.player_position.x, "y": WorldState.player_position.y},
		"current_region": WorldState.world_blueprint.get("start_region", ""),
		"world_type": WorldState.world_type,
		"world_name": WorldState.world_name,
		"action_history": WorldState.action_history.slice(-5),
		"active_events": WorldState.get_active_events()
	}
	
	# 调用 AI
	call_deferred("_interpret_action", context)


func _interpret_action(context: Dictionary) -> void:
	var result = await _ai_client.interpret_player_action(context)
	
	var narrative = result.get("narrative_result", result.get("interpretation", "无事发生。"))
	var world_changes = result.get("world_changes", [])
	
	# 应用世界变化
	for change in world_changes:
		var change_type = change.get("type", "")
		var target = change.get("target", "")
		var delta = change.get("delta", 0)
		
		match change_type:
			"reputation":
				WorldState.player_reputation += delta
			"faction":
				WorldState.modify_faction_attitude(target, delta)
			"event":
				WorldState.set_event_progress(target, delta)
	
	# 记录到行动历史
	WorldState.log_action(context.player_input, result)
	
	# 更新显示
	if _action_result:
		_action_result.text = narrative
	
	_update_hud()
	
	# 3 秒后清除结果
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 4.0
	timer.timeout.connect(func():
		if _action_result:
			_action_result.text = ""
		timer.queue_free()
	)
	add_child(timer)
	timer.start()


## 更新日志显示
func _update_log_display() -> void:
	if _log_text:
		_log_text.text = GameLog.get_log_text(6)


func _set_action_result(text: String) -> void:
	if _action_result:
		_action_result.text = text


func _inventory_text() -> String:
	var items = WorldState.get_inventory_items()
	if items.is_empty():
		return "背包: 空"
	var parts: Array = []
	for id in items.keys():
		var label = id.capitalize()
		match id:
			"herb":
				label = "Herb"
			"coin":
				label = "Coin"
			"potion":
				label = "Potion"
			"wood":
				label = "Wood"
			"stone":
				label = "Stone"
			"sword":
				label = "Sword"
		parts.append("%s x%d" % [label, int(items[id])])
	return "背包: " + ", ".join(parts)


func _get_save_manager():
	if get_tree() == null:
		return null
	return get_tree().root.get_node_or_null("SaveManager")
