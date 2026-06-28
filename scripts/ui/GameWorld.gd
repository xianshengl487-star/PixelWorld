extends Node2D
## GameWorld.gd - runtime map loader and transition controller.

const TILE_SIZE: int = 32

const AIClientClass = preload("res://scripts/ai/AIClient.gd")
const MapGeneratorClass = preload("res://scripts/map/MapGenerator.gd")
const MapValidatorClass = preload("res://scripts/map/MapValidator.gd")
const MapRepairerClass = preload("res://scripts/map/MapRepairer.gd")
const MapCollisionBuilderClass = preload("res://scripts/map/MapCollisionBuilder.gd")
const MapInstanceGeneratorClass = preload("res://scripts/map/MapInstanceGenerator.gd")
const MapStateClass = preload("res://scripts/map/MapState.gd")
const MapTransitionClass = preload("res://scripts/map/MapTransition.gd")
const TransitionAreaClass = preload("res://scripts/map/TransitionArea.gd")
const WorldGraphClass = preload("res://scripts/world/WorldGraph.gd")
const EnemyScene = preload("res://scenes/Enemy.tscn")
const InteractableClass = preload("res://scripts/interactions/Interactable.gd")
const ExplorationSystemClass = preload("res://scripts/world/ExplorationSystem.gd")

var current_world_graph = null
var current_map_instance = null
var current_map_id: String = ""
var map_states: Dictionary = {}
var visited_maps: Dictionary = {}
var last_transition_message: String = ""

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
	var player = get_player_node()
	if _is_initialized and _exploration_system != null and player != null:
		_exploration_system.update_player_tile(WorldState.player_position)


func setup_from_world_state() -> bool:
	_ai_client = AIClientClass.new()
	if WorldState.world_blueprint.is_empty():
		push_warning("[GameWorld] WorldState has no world_blueprint.")
		return false
	ensure_runtime_layers()
	if WorldState.world_blueprint.has("maps") and WorldState.world_blueprint.has("connections"):
		if not setup_world_graph_from_blueprint(WorldState.world_blueprint):
			return false
		var start_id = WorldState.current_map_id if WorldState.current_map_id != "" else current_world_graph.get_start_map_id()
		var ok = load_map(start_id, WorldState.last_spawn_id if WorldState.last_spawn_id != "" else "default")
		_is_initialized = ok and get_player_node() != null
		return _is_initialized
	_generate_legacy_map()
	_render_map()
	_build_collisions()
	ensure_player(Vector2i(int(WorldState.player_position.x), int(WorldState.player_position.y)))
	_spawn_npcs()
	_spawn_enemies()
	_spawn_interactables()
	_setup_ui()
	try_log("Entered world: %s" % WorldState.world_name)
	_is_initialized = get_player_node() != null
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
	ensure_runtime_layers()
	if current_world_graph == null:
		if not setup_world_graph_from_blueprint(WorldState.world_blueprint):
			return false
	if not current_world_graph.has_map(map_id):
		_log_error("GameWorld", "target map not found: %s" % map_id)
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
	_map_data = {
		"tiles": current_map_instance.tiles,
		"walkable": current_map_instance.walkable,
		"width": current_map_instance.size.x,
		"height": current_map_instance.size.y
	}
	visited_maps[map_id] = true
	WorldState.mark_map_visited(map_id)
	WorldState.current_region = current_map_instance.display_name
	_render_map()
	_build_collisions()
	_spawn_buildings()
	create_transition_areas_for_map(current_map_instance)
	place_player_at_spawn(spawn_id)
	_spawn_npcs()
	_spawn_enemies()
	_spawn_interactables()
	restore_map_state(map_id)
	_setup_ui()
	_log_map_arrival()
	_is_initialized = get_player_node() != null
	return _is_initialized


func unload_current_map() -> void:
	save_current_map_state()
	for layer_name in ["GroundLayer", "DecorationLayer", "BuildingLayer", "InteractionLayer", "TransitionLayer", "CollisionLayer", "NPCLayer", "EnemyLayer", "InteractableLayer", "TileMap"]:
		var layer = get_node_or_null(layer_name)
		if layer == null:
			continue
		for child in layer.get_children():
			child.queue_free()
	var entity_layer = get_node_or_null("EntityLayer")
	if entity_layer != null:
		for child in entity_layer.get_children():
			if child.name == "Player":
				continue
			child.queue_free()
	_collision_count = 0


func save_current_map_state() -> void:
	if current_map_id == "":
		return
	var state = MapStateClass.new()
	state.load_save_data(WorldState.get_map_state(current_map_id))
	state.map_id = current_map_id
	state.mark_visited()
	var player = get_player_node()
	if player != null:
		var tile_pos = Vector2i(int(player.position.x / TILE_SIZE), int(player.position.y / TILE_SIZE))
		state.last_player_position = tile_pos
		WorldState.player_position_by_map[current_map_id] = {"x": tile_pos.x, "y": tile_pos.y}
	for enemy_id in WorldState.defeated_enemies:
		state.mark_enemy_defeated(str(enemy_id))
	for item_id in WorldState.collected_items:
		state.mark_resource_collected(str(item_id))
	if current_map_instance != null:
		for building in current_map_instance.buildings:
			var building_id = str(building.get("building_id", ""))
			if building_id == "":
				continue
			var existing = state.get_building_state(building_id)
			if existing.is_empty():
				existing = {"visited": bool(WorldState.building_states.get(building_id, {}).get("visited", false)), "open": true}
			state.set_building_state(building_id, existing)
			WorldState.building_states[building_id] = existing.duplicate(true)
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
	for building_id in state_data.get("building_states", {}).keys():
		WorldState.building_states[str(building_id)] = state_data["building_states"][building_id]


func switch_map(target_map_id: String, target_spawn_id: String = "default") -> bool:
	if current_world_graph == null or not current_world_graph.has_map(target_map_id):
		last_transition_message = "target map not found: %s" % target_map_id
		_log_error("GameWorld", last_transition_message)
		return false
	var from_display = get_loaded_map_display_name()
	save_current_map_state()
	var ok = load_map(target_map_id, target_spawn_id)
	if ok:
		var to_display = get_loaded_map_display_name()
		if _is_interior_map(target_map_id):
			try_log("Entered building: %s" % to_display)
		elif from_display != "" and _is_interior_display(from_display):
			try_log("Left building and returned to %s." % to_display)
		last_transition_message = "Arrived at %s" % to_display
		if _hud != null and _hud.has_method("show_transition_message"):
			_hud.show_transition_message(last_transition_message)
	return ok


func request_map_transition(transition_id: String) -> bool:
	var transition_data = _find_transition(transition_id)
	if transition_data.is_empty():
		last_transition_message = "transition not found: %s" % transition_id
		_log_error("GameWorld", last_transition_message)
		return false
	var transition = MapTransitionClass.new()
	transition.setup(transition_data)
	var result = transition.can_use(WorldState)
	if not result.get("ok", false):
		last_transition_message = str(result.get("reason", transition.get_locked_reason(WorldState)))
		try_log(last_transition_message)
		if _hud != null and _hud.has_method("show_transition_message"):
			_hud.show_transition_message(last_transition_message)
		return false
	return switch_map(transition.to_map_id, transition.target_spawn_id)


func place_player_at_spawn(spawn_id: String) -> bool:
	var spawn = current_map_instance.get_spawn_point(spawn_id) if current_map_instance != null else Vector2i(int(WorldState.player_position.x), int(WorldState.player_position.y))
	return ensure_player(spawn) != null


func ensure_runtime_layers() -> void:
	var names = ["MapRoot", "GroundLayer", "DecorationLayer", "BuildingLayer", "EntityLayer", "InteractionLayer", "TransitionLayer", "CollisionLayer", "NPCLayer", "EnemyLayer", "InteractableLayer"]
	for layer_name in names:
		if get_node_or_null(layer_name) == null:
			var layer = Node2D.new()
			layer.name = layer_name
			add_child(layer)


func ensure_player(spawn_pos: Vector2i) -> Node:
	ensure_runtime_layers()
	var entity_layer = get_node_or_null("EntityLayer")
	var player = get_player_node()
	if player == null:
		player = create_player_at(spawn_pos)
	else:
		if entity_layer != null and player.get_parent() != entity_layer:
			player.reparent(entity_layer)
		_move_player_to_tile(player, spawn_pos)
	_setup_player(player)
	_player = player
	return _player


func create_player_at(spawn_pos: Vector2i) -> Node:
	var entity_layer = get_node_or_null("EntityLayer")
	var player_scene = load("res://scenes/Player.tscn")
	var player = player_scene.instantiate() if player_scene != null else null
	if player == null:
		player = CharacterBody2D.new()
		var shape_node = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		shape_node.shape = shape
		player.add_child(shape_node)
	player.name = "Player"
	if player.has_method("add_to_group"):
		player.add_to_group("player")
	if entity_layer != null:
		entity_layer.add_child(player)
	else:
		add_child(player)
	_move_player_to_tile(player, spawn_pos)
	_setup_player(player)
	return player


func create_transition_areas_for_map(map_instance) -> void:
	var layer = get_node_or_null("TransitionLayer")
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()
	if map_instance == null:
		return
	for transition in map_instance.transitions:
		var area = TransitionAreaClass.new()
		area.name = str(transition.get("transition_id", transition.get("connection_id", "Transition")))
		area.setup(transition, TILE_SIZE)
		layer.add_child(area)
		var rect_data = transition.get("from_rect", {"w": 2, "h": 2})
		var w = int(rect_data.get("w", rect_data.get("width", 2))) if rect_data is Dictionary else 2
		var h = int(rect_data.get("h", rect_data.get("height", 2))) if rect_data is Dictionary else 2
		var marker = ColorRect.new()
		marker.name = "Marker"
		marker.size = Vector2(w * TILE_SIZE, h * TILE_SIZE)
		marker.position = -marker.size / 2.0
		marker.color = Color(0.25, 0.75, 1.0, 0.35)
		area.add_child(marker)


func debug_print_node_tree() -> void:
	print(_node_tree_string(self))


func get_current_map_id() -> String:
	return current_map_id


func get_loaded_map_display_name() -> String:
	return current_map_instance.display_name if current_map_instance != null else ""


func get_current_map_type() -> String:
	return current_map_instance.map_type if current_map_instance != null else ""


func get_current_building_name() -> String:
	if current_map_instance == null:
		return ""
	if current_map_instance.parent_building_id == "":
		return ""
	return current_map_instance.display_name


func get_map_count() -> int:
	return current_world_graph.maps.size() if current_world_graph != null else 0


func get_transition_count() -> int:
	var layer = get_node_or_null("TransitionLayer")
	if layer != null and layer.get_child_count() > 0:
		return layer.get_child_count()
	return current_map_instance.transitions.size() if current_map_instance != null else 0


func get_building_count() -> int:
	return current_map_instance.buildings.size() if current_map_instance != null else 0


func apply_loaded_state() -> void:
	if WorldState.current_map_id != "" and WorldState.current_map_id != current_map_id:
		load_map(WorldState.current_map_id, WorldState.last_spawn_id)
	else:
		var player = get_player_node()
		if player != null:
			_move_player_to_tile(player, Vector2i(int(WorldState.player_position.x), int(WorldState.player_position.y)))
	_spawn_enemies()
	_spawn_interactables()
	_setup_ui()


func try_log(text: String) -> void:
	var loop = Engine.get_main_loop()
	var gl = loop.root.get_node_or_null("GameLog") if loop is SceneTree else null
	if gl != null and gl.has_method("add_entry"):
		gl.add_entry(text)
	else:
		print(text)


func _generate_legacy_map() -> void:
	var generator = MapGeneratorClass.new()
	_map_data = generator.generate(WorldState.world_blueprint)
	var validator = MapValidatorClass.new()
	var validation_result = validator.validate(_map_data, WorldState.world_blueprint)
	if not validation_result.valid:
		var repairer = MapRepairerClass.new()
		var repair_result = repairer.repair(_map_data, WorldState.world_blueprint, validation_result.errors)
		_map_data = repair_result.map_data


func _render_map() -> void:
	ensure_runtime_layers()
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
	place_player_at_spawn(spawn_id)


func _spawn_npcs() -> void:
	var npc_layer = get_node_or_null("NPCLayer")
	if npc_layer == null:
		return
	for child in npc_layer.get_children():
		child.queue_free()
	var npc_scene = load("res://scenes/NPC.tscn")
	if npc_scene == null:
		return
	var npcs = current_map_instance.npcs if current_map_instance != null and current_map_instance.npcs.size() > 0 else WorldState.get_all_npcs()
	for npc_data in npcs:
		var npc_instance = npc_scene.instantiate()
		var safe = find_nearest_walkable_tile(int(npc_data.get("x", 0)), int(npc_data.get("y", 0)))
		npc_data["x"] = safe.x
		npc_data["y"] = safe.y
		npc_instance.setup(npc_data, _ai_client, TILE_SIZE)
		npc_layer.add_child(npc_instance)


func _spawn_enemies() -> void:
	var enemy_layer = get_node_or_null("EnemyLayer")
	if enemy_layer == null:
		return
	for child in enemy_layer.get_children():
		child.queue_free()
	var enemies = current_map_instance.enemies if current_map_instance != null else []
	if enemies.is_empty() and (current_map_instance == null or current_map_instance.map_type == "village"):
		enemies = [
			{"id": "enemy_slime_01", "display_name": "Slime", "enemy_type": "slime", "x": 34, "y": 15},
			{"id": "enemy_slime_02", "display_name": "Slime", "enemy_type": "slime", "x": 38, "y": 13},
			{"id": "enemy_wolf_01", "display_name": "Wolf", "enemy_type": "wolf", "x": 15, "y": 14}
		]
	var state = WorldState.get_map_state(current_map_id)
	for data in enemies:
		var enemy_id = str(data.get("id", ""))
		if WorldState.defeated_enemies.has(enemy_id) or state.get("defeated_enemies", {}).has(enemy_id):
			continue
		var safe = find_nearest_walkable_tile(int(data.get("x", 0)), int(data.get("y", 0)))
		data["x"] = safe.x
		data["y"] = safe.y
		var enemy = EnemyScene.instantiate()
		enemy.setup(data, TILE_SIZE)
		enemy_layer.add_child(enemy)


func _spawn_interactables() -> void:
	var layer = get_node_or_null("InteractableLayer")
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()
	var items: Array = []
	if current_map_instance != null:
		items.append_array(current_map_instance.resources)
		items.append_array(current_map_instance.pois)
	if items.is_empty() and (current_map_instance == null or current_map_instance.map_type == "village"):
		items = [
			{"id": "herb_01", "display_name": "Herb", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 34, "y": 16},
			{"id": "herb_02", "display_name": "Herb", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 36, "y": 18},
			{"id": "herb_03", "display_name": "Herb", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 30, "y": 15},
			{"id": "chest_01", "display_name": "Old Chest", "interaction_type": "chest", "x": 29, "y": 31},
			{"id": "village_sign", "display_name": "Notice Board", "interaction_type": "sign", "interaction_text": "The east road leads to the forest.", "x": 31, "y": 28}
		]
	var state = WorldState.get_map_state(current_map_id)
	for data in items:
		var item_id = str(data.get("id", ""))
		var interaction_type = str(data.get("interaction_type", ""))
		if WorldState.collected_items.has(item_id) or state.get("collected_resources", {}).has(item_id):
			continue
		if interaction_type == "chest" and state.get("opened_chests", {}).has(item_id):
			continue
		var safe = find_nearest_walkable_tile(int(data.get("x", 0)), int(data.get("y", 0)))
		data["x"] = safe.x
		data["y"] = safe.y
		var interactable = InteractableClass.new()
		interactable.setup(data, TILE_SIZE)
		layer.add_child(interactable)


func _spawn_buildings() -> void:
	var layer = get_node_or_null("BuildingLayer")
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()
	if current_map_instance == null:
		return
	for building in current_map_instance.buildings:
		var pos = _vec(building.get("position", {"x": 0, "y": 0}))
		var size = _vec(building.get("size", [5, 5]))
		var rect = ColorRect.new()
		rect.name = str(building.get("building_id", "Building"))
		rect.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
		rect.size = Vector2(size.x * TILE_SIZE, size.y * TILE_SIZE)
		rect.color = _building_color(str(building.get("building_type", "")))
		layer.add_child(rect)
		var door_pos = _vec(building.get("door_position", {"x": pos.x, "y": pos.y}))
		var door = ColorRect.new()
		door.name = "%s_Door" % rect.name
		door.position = Vector2(door_pos.x * TILE_SIZE, door_pos.y * TILE_SIZE)
		door.size = Vector2(TILE_SIZE, TILE_SIZE)
		door.color = Color(0.95, 0.78, 0.25, 0.95)
		layer.add_child(door)
		if not WorldState.building_states.has(str(building.get("building_id", ""))):
			WorldState.building_states[str(building.get("building_id", ""))] = {"visited": false, "open": true}


func _setup_ui() -> void:
	_hud = get_node_or_null("GameHUD")
	if _hud != null and _hud.has_method("setup"):
		_hud.setup(_ai_client, get_player_node())
	if _hud != null and _hud.has_method("update_map_info") and current_map_instance != null:
		_hud.update_map_info(current_map_id, current_map_instance.display_name, current_map_instance.map_type)
	if _hud != null and _hud.has_method("update_building_info"):
		_hud.update_building_info(get_current_building_name())
	_dialogue_box = get_node_or_null("DialogueBox")


func _attach_graph_transitions(map_instance) -> void:
	var existing: Dictionary = {}
	for transition in map_instance.transitions:
		existing[str(transition.get("transition_id", transition.get("connection_id", "")))] = true
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


func _setup_player(player: Node) -> void:
	if player != null and player.has_method("setup"):
		player.setup(_map_data.get("walkable", []), _ai_client, TILE_SIZE)


func _move_player_to_tile(player: Node, tile: Vector2i) -> void:
	if player == null:
		return
	player.position = Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2, tile.y * TILE_SIZE + TILE_SIZE / 2)
	WorldState.player_position = Vector2(tile.x, tile.y)


func _log_map_arrival() -> void:
	if current_map_instance == null:
		return
	try_log("Arrived at %s." % current_map_instance.display_name)
	if _is_interior_map(current_map_id) and current_map_instance.parent_building_id != "":
		WorldState.building_states[current_map_instance.parent_building_id] = {"visited": true, "open": true}


func _is_interior_map(map_id: String) -> bool:
	return current_map_instance != null and (current_map_instance.map_type == "interior" or map_id.ends_with("_interior"))


func _is_interior_display(display: String) -> bool:
	return display.ends_with("Interior")


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
	var entity_player = get_node_or_null("EntityLayer/Player")
	if entity_player != null:
		_player = entity_player
		return _player
	var root_player = get_node_or_null("Player")
	if root_player != null:
		_player = root_player
		return _player
	_player = _find_node_by_name(self, "Player")
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


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _node_tree_string(node: Node, depth: int = 0) -> String:
	var text = "%s%s(%s)\n" % ["  ".repeat(depth), node.name, node.get_class()]
	for child in node.get_children():
		text += _node_tree_string(child, depth + 1)
	return text


func _get_tile_color(tile_type: int) -> Color:
	match tile_type:
		0: return Color(0.20, 0.50, 0.15)
		1: return Color(0.55, 0.45, 0.30)
		2: return Color(0.10, 0.35, 0.10)
		3: return Color(0.15, 0.30, 0.70, 0.80)
		4: return Color(0.55, 0.35, 0.20)
		5: return Color(0.35, 0.35, 0.35)
		6: return Color(0.15, 0.10, 0.05)
		7: return Color(0.70, 0.65, 0.50)
		_: return Color(0.20, 0.50, 0.15)


func _building_color(building_type: String) -> Color:
	match building_type:
		"apothecary": return Color(0.35, 0.62, 0.38, 0.95)
		"blacksmith": return Color(0.38, 0.38, 0.42, 0.95)
		"inn": return Color(0.68, 0.45, 0.28, 0.95)
		"general_store": return Color(0.55, 0.46, 0.70, 0.95)
		"sect_gate", "task_hall", "training_hall": return Color(0.65, 0.62, 0.52, 0.95)
		_: return Color(0.58, 0.36, 0.18, 0.95)


func _vec(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO
