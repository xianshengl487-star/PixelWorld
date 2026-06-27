extends Node2D
## GameWorld.gd - loads one MapInstance from a WorldGraph and supports map switching.

const TILE_SIZE: int = 32

const AIClientClass = preload("res://scripts/ai/AIClient.gd")
const MapGeneratorClass = preload("res://scripts/map/MapGenerator.gd")
const MapValidatorClass = preload("res://scripts/map/MapValidator.gd")
const MapRepairerClass = preload("res://scripts/map/MapRepairer.gd")
const MapCollisionBuilderClass = preload("res://scripts/map/MapCollisionBuilder.gd")
const MapInstanceGeneratorClass = preload("res://scripts/map/MapInstanceGenerator.gd")
const MapStateClass = preload("res://scripts/map/MapState.gd")
const MapTransitionClass = preload("res://scripts/map/MapTransition.gd")
const WorldGraphClass = preload("res://scripts/world/WorldGraph.gd")
const EnemyScene = preload("res://scenes/Enemy.tscn")
const InteractableClass = preload("res://scripts/interactions/Interactable.gd")
const ExplorationSystemClass = preload("res://scripts/world/ExplorationSystem.gd")

var current_world_graph = null
var current_map_instance = null
var current_map_id: String = ""
var map_states: Dictionary = {}
var visited_maps: Dictionary = {}

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


func setup_from_world_state() -> bool:
	_ai_client = AIClientClass.new()
	if WorldState.world_blueprint.is_empty():
		push_error("[GameWorld] WorldState 中没有世界蓝图！")
		return false
	_ensure_layers()
	if WorldState.world_blueprint.has("maps") and WorldState.world_blueprint.has("connections"):
		if not setup_world_graph_from_blueprint(WorldState.world_blueprint):
			return false
		var start_id = WorldState.current_map_id if WorldState.current_map_id != "" else current_world_graph.get_start_map_id()
		return load_map(start_id, WorldState.last_spawn_id if WorldState.last_spawn_id != "" else "default")
	_generate_legacy_map()
	_render_map()
	_build_collisions()
	_spawn_player("default")
	_spawn_npcs()
	_spawn_enemies()
	_spawn_interactables()
	_setup_ui()
	try_log("进入世界: %s" % WorldState.world_name)
	try_log("在 %s 醒来..." % _get_start_region_name())
	_is_initialized = _player != null
	return _is_initialized


func setup_world_graph_from_blueprint(blueprint: Dictionary) -> bool:
	current_world_graph = WorldGraphClass.new()
	current_world_graph.setup(blueprint)
	var validation = current_world_graph.validate_graph()
	if not validation.get("ok", false):
		for err in validation.get("errors", []):
			_log_error("WorldGraph", str(err))
		return false
	WorldState.set_world_graph(current_world_graph)
	visited_maps = WorldState.visited_maps
	map_states = WorldState.map_states
	current_map_id = current_world_graph.current_map_id
	return true


func load_map(map_id: String, spawn_id: String = "default") -> bool:
	if current_world_graph == null:
		if not setup_world_graph_from_blueprint(WorldState.world_blueprint):
			return false
	if not current_world_graph.has_map(map_id):
		_log_error("GameWorld", "目标地图不存在: %s" % map_id)
		return false
	unload_current_map()
	current_map_id = map_id
	WorldState.set_current_map_id(map_id, spawn_id)
	current_world_graph.set_current_map(map_id)
	var raw_map = current_world_graph.get_map(map_id)
	var generator = MapInstanceGeneratorClass.new()
	var map_data = raw_map.to_save_data() if raw_map != null and raw_map.has_method("to_save_data") else raw_map
	map_data["world_type"] = WorldState.world_type
	current_map_instance = generator.generate_map_instance(map_data, {"world_type": WorldState.world_type, "seed": current_world_graph.seed})
	current_world_graph.maps[map_id] = current_map_instance
	_attach_graph_transitions(current_map_instance)
	_map_data = {"tiles": current_map_instance.tiles, "walkable": current_map_instance.walkable, "width": current_map_instance.size.x, "height": current_map_instance.size.y}
	visited_maps[map_id] = true
	WorldState.mark_map_visited(map_id)
	WorldState.current_region = current_map_instance.display_name
	_render_map()
	_build_collisions()
	_spawn_buildings()
	_spawn_transitions()
	_spawn_player(spawn_id)
	_spawn_npcs()
	_spawn_enemies()
	_spawn_interactables()
	restore_map_state(map_id)
	_setup_ui()
	try_log("你来到了%s。" % get_loaded_map_display_name())
	_is_initialized = _player != null
	return _is_initialized


func unload_current_map() -> void:
	for layer_name in ["GroundLayer", "DecorationLayer", "BuildingLayer", "EntityLayer", "InteractionLayer", "TransitionLayer", "CollisionLayer", "NPCLayer", "EnemyLayer", "InteractableLayer", "TileMap"]:
		var layer = get_node_or_null(layer_name)
		if layer == null:
			continue
		for child in layer.get_children():
			child.queue_free()
	_collision_count = 0


func save_current_map_state() -> void:
	if current_map_id == "":
		return
	var state = MapStateClass.new()
	state.load_save_data(WorldState.get_map_state(current_map_id))
	state.map_id = current_map_id
	state.mark_visited()
	if _player != null and is_instance_valid(_player):
		var tile_pos = Vector2i(int(_player.position.x / TILE_SIZE), int(_player.position.y / TILE_SIZE))
		state.last_player_position = tile_pos
		WorldState.player_position_by_map[current_map_id] = {"x": tile_pos.x, "y": tile_pos.y}
	for enemy_id in WorldState.defeated_enemies:
		state.mark_enemy_defeated(str(enemy_id))
	for item_id in WorldState.collected_items:
		state.mark_resource_collected(str(item_id))
	WorldState.set_map_state(current_map_id, state.to_save_data())
	map_states[current_map_id] = state.to_save_data()


func restore_map_state(map_id: String) -> void:
	var state_data = WorldState.get_map_state(map_id)
	if state_data.is_empty():
		return
	for enemy_id in state_data.get("defeated_enemies", {}).keys():
		if not WorldState.defeated_enemies.has(enemy_id):
			WorldState.defeated_enemies.append(enemy_id)
	for resource_id in state_data.get("collected_resources", {}).keys():
		if not WorldState.collected_items.has(resource_id):
			WorldState.collected_items.append(resource_id)


func switch_map(target_map_id: String, target_spawn_id: String = "default") -> bool:
	if current_world_graph == null or not current_world_graph.has_map(target_map_id):
		_log_error("GameWorld", "地图切换失败，目标不存在: %s" % target_map_id)
		return false
	save_current_map_state()
	return load_map(target_map_id, target_spawn_id)


func request_map_transition(transition_id: String) -> bool:
	var transition_data = _find_transition(transition_id)
	if transition_data.is_empty():
		_log_error("GameWorld", "找不到地图切换点: %s" % transition_id)
		return false
	var transition = MapTransitionClass.new()
	transition.setup(transition_data)
	var result = transition.can_use(WorldState)
	if not result.get("ok", false):
		GameLog.add_entry(str(result.get("reason", transition.get_locked_reason(WorldState))))
		return false
	return switch_map(transition.to_map_id, transition.target_spawn_id)


func get_current_map_id() -> String:
	return current_map_id


func get_loaded_map_display_name() -> String:
	return current_map_instance.display_name if current_map_instance != null else ""


func get_map_count() -> int:
	return current_world_graph.maps.size() if current_world_graph != null else 0


func get_transition_count() -> int:
	return current_map_instance.transitions.size() if current_map_instance != null else 0


func get_building_count() -> int:
	return current_map_instance.buildings.size() if current_map_instance != null else 0


func apply_loaded_state() -> void:
	if WorldState.current_map_id != "" and WorldState.current_map_id != current_map_id:
		load_map(WorldState.current_map_id, WorldState.last_spawn_id)
	elif _player != null and is_instance_valid(_player):
		_player.position = Vector2(WorldState.player_position.x * TILE_SIZE + TILE_SIZE / 2, WorldState.player_position.y * TILE_SIZE + TILE_SIZE / 2)
	_spawn_enemies()
	_spawn_interactables()


func try_log(text: String) -> void:
	var loop = Engine.get_main_loop()
	var gl = loop.root.get_node_or_null("GameLog") if loop is SceneTree else null
	if gl and gl.has_method("add_entry"):
		gl.add_entry(text)
	else:
		print(text)


func _ensure_layers() -> void:
	for layer_name in ["MapRoot", "GroundLayer", "DecorationLayer", "BuildingLayer", "EntityLayer", "InteractionLayer", "TransitionLayer", "CollisionLayer", "NPCLayer", "EnemyLayer", "InteractableLayer"]:
		if get_node_or_null(layer_name) == null:
			var layer = Node2D.new()
			layer.name = layer_name
			add_child(layer)


func _generate_legacy_map() -> void:
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


func _render_map() -> void:
	_ensure_layers()
	var ground_layer = get_node_or_null("GroundLayer")
	var tile_map = get_node_or_null("TileMap")
	for layer in [ground_layer, tile_map]:
		if layer == null:
			continue
		for child in layer.get_children():
			child.queue_free()
	var tiles = _map_data.get("tiles", [])
	for y in range(tiles.size()):
		for x in range(tiles[y].size()):
			var rect = ColorRect.new()
			rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.color = _get_tile_color(int(tiles[y][x]))
			ground_layer.add_child(rect)


func _build_collisions() -> void:
	var collision_layer = get_node_or_null("CollisionLayer")
	if collision_layer == null:
		collision_layer = Node2D.new()
		collision_layer.name = "CollisionLayer"
		add_child(collision_layer)
	for child in collision_layer.get_children():
		child.queue_free()
	var builder = MapCollisionBuilderClass.new()
	_collision_count = builder.build_collisions(_map_data, TILE_SIZE, collision_layer)


func _spawn_player(spawn_id: String = "default") -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_node_or_null("Player")
	if _player == null:
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
	var spawn = current_map_instance.get_spawn_point(spawn_id) if current_map_instance != null else Vector2i(WorldState.player_position.x, WorldState.player_position.y)
	_player.position = Vector2(spawn.x * TILE_SIZE + TILE_SIZE / 2, spawn.y * TILE_SIZE + TILE_SIZE / 2)
	WorldState.player_position = Vector2(spawn.x, spawn.y)


func _spawn_npcs() -> void:
	var npc_layer = get_node_or_null("NPCLayer")
	for child in npc_layer.get_children():
		child.queue_free()
	var npc_scene = load("res://scenes/NPC.tscn")
	if npc_scene == null:
		push_error("[GameWorld] 无法加载 NPC.tscn")
		return
	var npcs = current_map_instance.npcs if current_map_instance != null and current_map_instance.npcs.size() > 0 else WorldState.get_all_npcs()
	for npc_data in npcs:
		var npc_instance = npc_scene.instantiate()
		var safe = find_nearest_walkable_tile(int(npc_data.get("x", 0)), int(npc_data.get("y", 0)))
		npc_data["x"] = safe.x
		npc_data["y"] = safe.y
		npc_instance.setup(npc_data, _ai_client, TILE_SIZE)
		npc_layer.add_child(npc_instance)
	GameLog.add_entry("已生成 %d 个 NPC" % npc_layer.get_child_count())


func _spawn_enemies() -> void:
	var enemy_layer = get_node_or_null("EnemyLayer")
	for child in enemy_layer.get_children():
		child.queue_free()
	var enemies = current_map_instance.enemies if current_map_instance != null else []
	if enemies.is_empty():
		enemies = [
			{"id": "enemy_slime_01", "display_name": "史莱姆", "enemy_type": "slime", "x": 34, "y": 15},
			{"id": "enemy_slime_02", "display_name": "史莱姆", "enemy_type": "slime", "x": 38, "y": 13},
			{"id": "enemy_wolf_01", "display_name": "妖狼", "enemy_type": "wolf", "x": 15, "y": 14}
		]
	for data in enemies:
		if WorldState.defeated_enemies.has(data.get("id", "")):
			continue
		var safe = find_nearest_walkable_tile(int(data.get("x", 0)), int(data.get("y", 0)))
		data["x"] = safe.x
		data["y"] = safe.y
		var enemy = EnemyScene.instantiate()
		enemy.setup(data, TILE_SIZE)
		enemy_layer.add_child(enemy)
	GameLog.add_entry("已生成 %d 个敌人" % enemy_layer.get_child_count())


func _spawn_interactables() -> void:
	var layer = get_node_or_null("InteractableLayer")
	for child in layer.get_children():
		child.queue_free()
	var items: Array = []
	if current_map_instance != null:
		items.append_array(current_map_instance.resources)
		items.append_array(current_map_instance.pois)
	if items.is_empty():
		items = [
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
		var safe = find_nearest_walkable_tile(int(data.get("x", 0)), int(data.get("y", 0)))
		data["x"] = safe.x
		data["y"] = safe.y
		var interactable = InteractableClass.new()
		interactable.setup(data, TILE_SIZE)
		layer.add_child(interactable)
	GameLog.add_entry("已生成 %d 个可交互物体" % layer.get_child_count())


func _spawn_buildings() -> void:
	var layer = get_node_or_null("BuildingLayer")
	for child in layer.get_children():
		child.queue_free()
	if current_map_instance == null:
		return
	for building in current_map_instance.buildings:
		var rect = ColorRect.new()
		var pos = building.get("position", {"x": 0, "y": 0})
		var size = building.get("size", [5, 5])
		rect.name = str(building.get("building_id", "Building"))
		rect.position = Vector2(int(pos.get("x", 0)) * TILE_SIZE, int(pos.get("y", 0)) * TILE_SIZE)
		rect.size = Vector2(int(size[0]) * TILE_SIZE, int(size[1]) * TILE_SIZE)
		rect.color = Color(0.58, 0.36, 0.18, 0.95)
		layer.add_child(rect)
		var door = ColorRect.new()
		var door_pos = building.get("door_position", {"x": int(pos.get("x", 0)), "y": int(pos.get("y", 0))})
		door.position = Vector2(int(door_pos.get("x", 0)) * TILE_SIZE, int(door_pos.get("y", 0)) * TILE_SIZE)
		door.size = Vector2(TILE_SIZE, TILE_SIZE)
		door.color = Color(0.9, 0.72, 0.35, 0.95)
		layer.add_child(door)


func _spawn_transitions() -> void:
	var layer = get_node_or_null("TransitionLayer")
	for child in layer.get_children():
		child.queue_free()
	if current_map_instance == null:
		return
	for transition in current_map_instance.transitions:
		var rect_data = transition.get("from_rect", {"x": int(transition.get("x", 0)), "y": int(transition.get("y", 0)), "w": 2, "h": 2})
		var marker = ColorRect.new()
		marker.name = str(transition.get("transition_id", "Transition"))
		marker.position = Vector2(int(rect_data.get("x", 0)) * TILE_SIZE, int(rect_data.get("y", 0)) * TILE_SIZE)
		marker.size = Vector2(int(rect_data.get("w", 2)) * TILE_SIZE, int(rect_data.get("h", 2)) * TILE_SIZE)
		marker.color = Color(0.35, 0.75, 1.0, 0.35)
		layer.add_child(marker)


func _setup_ui() -> void:
	_hud = get_node_or_null("GameHUD")
	if _hud and _hud.has_method("setup"):
		_hud.setup(_ai_client, _player)
	_dialogue_box = get_node_or_null("DialogueBox")


func _attach_graph_transitions(map_instance) -> void:
	var existing: Dictionary = {}
	for transition in map_instance.transitions:
		existing[str(transition.get("transition_id", ""))] = true
	for connection in current_world_graph.get_connections_from(map_instance.map_id):
		var transition_id = str(connection.get("connection_id", ""))
		if existing.has(transition_id):
			continue
		var spawn = map_instance.get_spawn_point(str(connection.get("from_spawn_id", "default")))
		var data = connection.duplicate(true)
		data["transition_id"] = transition_id
		data["target_spawn_id"] = str(connection.get("to_spawn_id", connection.get("target_spawn_id", "default")))
		data["from_rect"] = {"x": max(0, spawn.x - 1), "y": max(0, spawn.y - 1), "w": 3, "h": 3}
		map_instance.add_transition(data)


func _find_transition(transition_id: String) -> Dictionary:
	if current_map_instance != null:
		for transition in current_map_instance.transitions:
			if str(transition.get("transition_id", transition.get("connection_id", ""))) == transition_id:
				return transition
	if current_world_graph != null:
		return current_world_graph.get_connection(transition_id)
	return {}


func _get_tile_color(tile_type: int) -> Color:
	match tile_type:
		0: return Color(0.2, 0.5, 0.15)
		1: return Color(0.55, 0.45, 0.3)
		2: return Color(0.1, 0.35, 0.1)
		3: return Color(0.15, 0.3, 0.7, 0.8)
		4: return Color(0.6, 0.3, 0.15)
		5: return Color(0.35, 0.35, 0.35)
		6: return Color(0.15, 0.1, 0.05)
		7: return Color(0.7, 0.65, 0.5)
		_: return Color(0.2, 0.5, 0.15)


func _get_start_region_name() -> String:
	if current_map_instance != null:
		return current_map_instance.display_name
	var regions = WorldState.world_blueprint.get("regions", [])
	var start_id = WorldState.world_blueprint.get("start_region", "")
	for region in regions:
		if region.get("id") == start_id:
			return region.get("name", start_id)
	return "未知区域"


func _log_error(context: String, message: String) -> void:
	push_warning("[%s] %s" % [context, message])
	var tree = get_tree()
	if tree != null:
		var log = tree.root.get_node_or_null("GameLog")
		if log != null and log.has_method("add_error"):
			log.add_error(message)


func get_player_node() -> Node:
	if _player != null and is_instance_valid(_player):
		return _player
	_player = get_node_or_null("Player")
	return _player


func get_npc_count() -> int:
	var layer = get_node_or_null("NPCLayer")
	return layer.get_child_count() if layer != null else 0


func get_obstacle_collision_count() -> int:
	if _collision_count > 0:
		return _collision_count
	var layer = get_node_or_null("CollisionLayer")
	return layer.get_child_count() if layer != null else 0


func get_map_visual_node_count() -> int:
	var layer = get_node_or_null("GroundLayer")
	if layer != null and layer.get_child_count() > 0:
		return layer.get_child_count()
	var tile_map = get_node_or_null("TileMap")
	return tile_map.get_child_count() if tile_map != null else 0


func get_map_data() -> Dictionary:
	return _map_data


func is_initialized() -> bool:
	return _is_initialized


func get_enemy_count() -> int:
	var layer = get_node_or_null("EnemyLayer")
	return layer.get_child_count() if layer != null else 0


func get_interactable_count() -> int:
	var layer = get_node_or_null("InteractableLayer")
	return layer.get_child_count() if layer != null else 0


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
	return Vector2i(min(max(0, x), walkable[0].size() - 1), min(max(0, y), walkable.size() - 1))


func _is_walkable_tile(walkable: Array, x: int, y: int) -> bool:
	if y < 0 or y >= walkable.size():
		return false
	if x < 0 or x >= walkable[y].size():
		return false
	return bool(walkable[y][x])
