extends Node2D
## GameWorld.gd — 游戏世界脚本
## 生成地图、放置玩家和 NPC、管理游戏循环

const TILE_SIZE: int = 32

# 预加载依赖类
const AIClientClass = preload("res://scripts/ai/AIClient.gd")
const MapGeneratorClass = preload("res://scripts/map/MapGenerator.gd")
const MapValidatorClass = preload("res://scripts/map/MapValidator.gd")
const MapRepairerClass = preload("res://scripts/map/MapRepairer.gd")
const MapCollisionBuilderClass = preload("res://scripts/map/MapCollisionBuilder.gd")
const EnemyScene = preload("res://scenes/Enemy.tscn")
const InteractableClass = preload("res://scripts/interactions/Interactable.gd")
const ExplorationSystemClass = preload("res://scripts/world/ExplorationSystem.gd")

var _ai_client = null
var _map_data: Dictionary = {}
var _player = null
var _hud = null
var _dialogue_box = null
var _is_initialized: bool = false
var _collision_count: int = 0
var _exploration_system = null


func _ready() -> void:
	add_to_group("game_world")
	_exploration_system = ExplorationSystemClass.new()
	setup_from_world_state()


func _process(_delta: float) -> void:
	if _is_initialized and _exploration_system != null and _player != null and is_instance_valid(_player):
		_exploration_system.update_player_tile(WorldState.player_position)


## 从 WorldState 初始化（可被 SmokeTestRunner 直接调用）
## @return bool — 成功 true，失败 false
func setup_from_world_state() -> bool:
	_ai_client = AIClientClass.new()
	
	if WorldState.world_blueprint.is_empty():
		var err_msg = "[GameWorld] WorldState 中没有世界蓝图！"
		push_error(err_msg)
		return false
	
	_generate_map()
	_render_map()
	_build_collisions()
	_spawn_player()
	_spawn_npcs()
	_spawn_enemies()
	_spawn_interactables()
	_setup_ui()
	
	try_log("进入世界: %s" % WorldState.world_name)
	try_log("在 %s 醒来..." % _get_start_region_name())
	
	_is_initialized = _player != null
	return _is_initialized


func _world_state_ref():
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		return root.root.get_node_or_null("WorldState")
	return null


func try_log(text: String) -> void:
	var gl = null
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		gl = loop.root.get_node_or_null("GameLog")
	if gl and gl.has_method("add_entry"):
		gl.add_entry(text)
	else:
		print(text)


## 生成地图
func _generate_map() -> void:
	var generator = MapGeneratorClass.new()
	_map_data = generator.generate(WorldState.world_blueprint)
	
	var validator = MapValidatorClass.new()
	var validation_result = validator.validate(_map_data, WorldState.world_blueprint)
	
	if not validation_result.valid:
		GameLog.add_warning("地图校验发现 %d 个错误" % validation_result.errors.size())
		for err in validation_result.errors:
			GameLog.add_warning("  " + err)
		
		var repairer = MapRepairerClass.new()
		var repair_result = repairer.repair(_map_data, WorldState.world_blueprint, validation_result.errors)
		_map_data = repair_result.map_data
		
		if repair_result.repaired:
			GameLog.add_entry("地图已自动修复")
		else:
			GameLog.add_error("地图修复失败，已使用保底模板")


## 渲染地图视觉
func _render_map() -> void:
	var tile_map = get_node_or_null("TileMap")
	if tile_map == null:
		tile_map = Node2D.new()
		tile_map.name = "TileMap"
		add_child(tile_map)
	
	for child in tile_map.get_children():
		child.queue_free()
	
	var tiles = _map_data.get("tiles", [])
	
	for y in range(tiles.size()):
		for x in range(tiles[y].size()):
			var rect = ColorRect.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.color = _get_tile_color(tiles[y][x])
			tile_map.add_child(rect)
	
	if tiles.size() > 0 and tiles[0].size() > 0:
		for y in range(tiles.size() + 1):
			var line = ColorRect.new()
			line.size = Vector2(TILE_SIZE * tiles[0].size(), 1)
			line.position = Vector2(0, y * TILE_SIZE)
			line.color = Color(0, 0, 0, 0.1)
			tile_map.add_child(line)
		
		for x in range(tiles[0].size() + 1):
			var line = ColorRect.new()
			line.size = Vector2(1, TILE_SIZE * tiles.size())
			line.position = Vector2(x * TILE_SIZE, 0)
			line.color = Color(0, 0, 0, 0.1)
			tile_map.add_child(line)


## 构建障碍物碰撞体
func _build_collisions() -> void:
	var collision_layer = get_node_or_null("CollisionLayer")
	if collision_layer == null:
		collision_layer = Node2D.new()
		collision_layer.name = "CollisionLayer"
		add_child(collision_layer)
	
	# 先移除旧碰撞体的引用，创建新的
	for child in collision_layer.get_children():
		child.queue_free()
	
	var builder = MapCollisionBuilderClass.new()
	_collision_count = builder.build_collisions(_map_data, TILE_SIZE, collision_layer)


func _get_tile_color(tile_type: int) -> Color:
	match tile_type:
		0: return Color(0.2, 0.5, 0.15)   # GRASS
		1: return Color(0.55, 0.45, 0.3)   # ROAD
		2: return Color(0.1, 0.35, 0.1)    # TREE
		3: return Color(0.15, 0.3, 0.7, 0.8)  # WATER
		4: return Color(0.6, 0.3, 0.15)    # HOUSE
		5: return Color(0.35, 0.35, 0.35)  # MOUNTAIN
		6: return Color(0.15, 0.1, 0.05)   # CAVE
		7: return Color(0.7, 0.65, 0.5)    # SECT_FLOOR
		_: return Color(0.2, 0.5, 0.15)


func _spawn_player() -> void:
	_player = get_node_or_null("Player")
	if _player == null:
		# 尝试动态创建 Player
		var player_scene = load("res://scenes/Player.tscn")
		if player_scene:
			_player = player_scene.instantiate()
			_player.name = "Player"
			add_child(_player)
	
	if _player == null:
		push_warning("[GameWorld] Player 节点不存在且无法创建")
		return
	
	var walkable = _map_data.get("walkable", [])
	_player.setup(walkable, _ai_client, TILE_SIZE)


func _spawn_npcs() -> void:
	var npc_layer = get_node_or_null("NPCLayer")
	if npc_layer == null:
		npc_layer = Node2D.new()
		npc_layer.name = "NPCLayer"
		add_child(npc_layer)
	
	var npc_scene = load("res://scenes/NPC.tscn")
	if npc_scene == null:
		push_error("[GameWorld] 无法加载 NPC.tscn")
		return
	
	for npc_data in WorldState.get_major_npcs():
		var npc_instance = npc_scene.instantiate()
		npc_instance.setup(npc_data, _ai_client, TILE_SIZE)
		npc_layer.add_child(npc_instance)
	
	for npc_data in WorldState.get_minor_npcs():
		var npc_instance = npc_scene.instantiate()
		npc_instance.setup(npc_data, _ai_client, TILE_SIZE)
		npc_layer.add_child(npc_instance)
	
	var total = WorldState.get_major_npcs().size() + WorldState.get_minor_npcs().size()
	GameLog.add_entry("已生成 %d 个 NPC" % total)


func _spawn_enemies() -> void:
	var enemy_layer = get_node_or_null("EnemyLayer")
	if enemy_layer == null:
		enemy_layer = Node2D.new()
		enemy_layer.name = "EnemyLayer"
		add_child(enemy_layer)
	for child in enemy_layer.get_children():
		child.queue_free()
	
	var enemies = [
		{"id": "enemy_slime_01", "display_name": "史莱姆", "enemy_type": "slime", "x": 34, "y": 15},
		{"id": "enemy_slime_02", "display_name": "史莱姆", "enemy_type": "slime", "x": 38, "y": 13},
		{"id": "enemy_wolf_01", "display_name": "妖狼", "enemy_type": "wolf", "x": 15, "y": 14}
	]
	
	for data in enemies:
		if WorldState.defeated_enemies.has(data.get("id", "")):
			continue
		var safe = find_nearest_walkable_tile(int(data.x), int(data.y))
		data["x"] = safe.x
		data["y"] = safe.y
		var enemy = EnemyScene.instantiate()
		enemy.setup(data, TILE_SIZE)
		enemy_layer.add_child(enemy)
	
	GameLog.add_entry("已生成 %d 个敌人" % enemy_layer.get_child_count())


func _spawn_interactables() -> void:
	var layer = get_node_or_null("InteractableLayer")
	if layer == null:
		layer = Node2D.new()
		layer.name = "InteractableLayer"
		add_child(layer)
	for child in layer.get_children():
		child.queue_free()
	
	var items = [
		{"id": "herb_01", "display_name": "草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 34, "y": 16},
		{"id": "herb_02", "display_name": "草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 36, "y": 18},
		{"id": "herb_03", "display_name": "草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 30, "y": 15},
		{"id": "chest_01", "display_name": "旧木宝箱", "interaction_type": "chest", "x": 29, "y": 31},
		{"id": "cave_entrance", "display_name": "残破洞府", "interaction_type": "cave", "interaction_text": "洞府深处传来潮湿的风声。", "x": 12, "y": 14},
		{"id": "village_sign", "display_name": "告示牌", "interaction_type": "sign", "interaction_text": "告示牌写着：森林近日有妖物出没，切勿独行。", "x": 31, "y": 28}
	]
	
	for data in items:
		if WorldState.collected_items.has(data.get("id", "")):
			continue
		var safe = find_nearest_walkable_tile(int(data.x), int(data.y))
		data["x"] = safe.x
		data["y"] = safe.y
		var interactable = InteractableClass.new()
		interactable.setup(data, TILE_SIZE)
		layer.add_child(interactable)
	
	GameLog.add_entry("已生成 %d 个可交互物体" % layer.get_child_count())


func _setup_ui() -> void:
	_hud = get_node_or_null("GameHUD")
	if _hud and _hud.has_method("setup"):
		_hud.setup(_ai_client, _player)
	_dialogue_box = get_node_or_null("DialogueBox")


func apply_loaded_state() -> void:
	if _player != null and is_instance_valid(_player):
		_player.position = Vector2(
			WorldState.player_position.x * TILE_SIZE + TILE_SIZE / 2,
			WorldState.player_position.y * TILE_SIZE + TILE_SIZE / 2
		)
		if _player.has_method("get_stats"):
			var player_stats = _player.get_stats()
			player_stats.configure({
				"max_health": WorldState.player_max_health,
				"health": WorldState.player_health,
				"attack": player_stats.attack,
				"defense": player_stats.defense,
				"move_speed": player_stats.move_speed,
				"max_stamina": WorldState.player_max_stamina,
				"stamina": WorldState.player_stamina
			})
	_spawn_enemies()
	_spawn_interactables()


func _get_start_region_name() -> String:
	var regions = WorldState.world_blueprint.get("regions", [])
	var start_id = WorldState.world_blueprint.get("start_region", "")
	for region in regions:
		if region.get("id") == start_id:
			return region.get("name", start_id)
	return "未知区域"


# ═══════════════════════════════════════
# SmokeTest 可暴露方法
# ═══════════════════════════════════════

func get_player_node() -> Node:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_node_or_null("Player")
	if _player == null:
		# 递归搜索
		for child in get_children():
			if child.name == "Player" or child is CharacterBody2D:
				_player = child
				break
		if _player == null:
			# 深层搜索
			for child in get_children():
				var found = child.get_node_or_null("Player")
				if found:
					_player = found
					break
	return _player

func get_npc_count() -> int:
	var layer = get_node_or_null("NPCLayer")
	if layer == null: return 0
	return layer.get_child_count()

func get_obstacle_collision_count() -> int:
	if _collision_count > 0:
		return _collision_count
	var layer = get_node_or_null("CollisionLayer")
	if layer != null:
		var count = layer.get_child_count()
		if count > 0:
			_collision_count = count
			return count
	return 0

func get_map_visual_node_count() -> int:
	var tile_map = get_node_or_null("TileMap")
	if tile_map == null: return 0
	return tile_map.get_child_count()

func get_map_data() -> Dictionary:
	return _map_data

func is_initialized() -> bool:
	return _is_initialized

func get_enemy_count() -> int:
	var layer = get_node_or_null("EnemyLayer")
	if layer == null: return 0
	return layer.get_child_count()

func get_interactable_count() -> int:
	var layer = get_node_or_null("InteractableLayer")
	if layer == null: return 0
	return layer.get_child_count()

func find_nearest_walkable_tile(x: int, y: int) -> Vector2i:
	var walkable = _map_data.get("walkable", [])
	if walkable.size() == 0:
		return Vector2i(x, y)
	for dist in range(0, 24):
		for dy in range(-dist, dist + 1):
			for dx in range(-dist, dist + 1):
				var nx = x + dx
				var ny = y + dy
				if _is_walkable_tile(walkable, nx, ny):
					return Vector2i(nx, ny)
	return Vector2i(20, 20)


func _is_walkable_tile(walkable: Array, x: int, y: int) -> bool:
	if y < 0 or y >= walkable.size():
		return false
	if x < 0 or x >= walkable[y].size():
		return false
	return bool(walkable[y][x])
