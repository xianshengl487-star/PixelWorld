extends Node
## SaveManager.gd — JSON 存档/读档 Autoload

const MapStateSerializerClass = preload("res://scripts/map/MapStateSerializer.gd")
const SAVE_DIR := "user://saves"
const SAVE_VERSION := "0.4.2"


func save_game(slot_id: String = "save_001") -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var path = _slot_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		GameLog.add_error("存档失败: 无法写入 %s" % path)
		return false
	var data = _collect_save_data()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	GameLog.add_entry("游戏已保存。")
	return true


func load_game(slot_id: String = "save_001") -> Dictionary:
	var path = _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "save_not_found"}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "open_failed"}
	var text = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or not (data is Dictionary):
		return {"ok": false, "error": "parse_failed"}
	var migrated = migrate_save_data(data)
	_apply_save_data(migrated)
	GameLog.add_entry("游戏已读取。")
	return {"ok": true, "data": migrated}


func has_save(slot_id: String = "save_001") -> bool:
	return FileAccess.file_exists(_slot_path(slot_id))


func delete_save(slot_id: String = "save_001") -> bool:
	var path = _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK


func _slot_path(slot_id: String) -> String:
	return SAVE_DIR + "/" + slot_id + ".json"


func _collect_save_data() -> Dictionary:
	var serializer = MapStateSerializerClass.new()
	return {
		"save_version": SAVE_VERSION,
		"world_name": WorldState.world_name,
		"world_type": WorldState.world_type,
		"world_blueprint": WorldState.world_blueprint,
		"player_position": {"x": WorldState.player_position.x, "y": WorldState.player_position.y},
		"player_health": WorldState.player_health,
		"action_history": WorldState.action_history,
		"npc_memory": WorldState.npc_memory,
		"inventory": WorldState.get_inventory_items(),
		"discovered_locations": WorldState.discovered_locations,
		"collected_items": WorldState.collected_items,
		"defeated_enemies": WorldState.defeated_enemies,
		"current_region": WorldState.current_region,
		"current_day": WorldState.current_day,
		"current_hour": WorldState.current_hour,
		"progression_data": WorldState.progression_data,
		"player_stats": WorldState.player_stats,
		"unlocked_features": WorldState.unlocked_features,
		"world_rule_modifiers": WorldState.world_rule_modifiers,
		"realm_history": WorldState.realm_history,
		"breakthrough_history": WorldState.breakthrough_history,
		"tribulation_record": WorldState.tribulation_record,
		"progression_template_id": WorldState.progression_data.get("system_id", ""),
		"progression_world_type": WorldState.progression_data.get("world_type", WorldState.world_type),
		"current_map_id": WorldState.current_map_id,
		"visited_maps": WorldState.visited_maps,
		"map_states": serializer.serialize_all_map_states(WorldState.map_states),
		"building_states": WorldState.building_states,
		"quest_state": WorldState.quest_state,
		"equipment_state": WorldState.equipment_state,
		"training_used_today": WorldState.training_used_today,
		"world_graph": WorldState.world_graph_data if not WorldState.world_graph_data.is_empty() else (WorldState.current_world_graph.to_save_data() if WorldState.current_world_graph != null and WorldState.current_world_graph.has_method("to_save_data") else {}),
		"player_position_by_map": WorldState.player_position_by_map,
		"last_spawn_id": WorldState.last_spawn_id
	}


func migrate_save_data(data: Dictionary) -> Dictionary:
	var migrated = data.duplicate(true)
	migrated["save_version"] = str(migrated.get("save_version", SAVE_VERSION))
	if not migrated.has("world_blueprint") or not (migrated.get("world_blueprint", {}) is Dictionary):
		migrated["world_blueprint"] = {}
	if str(migrated.get("current_map_id", "")) == "":
		migrated["current_map_id"] = str(migrated.get("world_blueprint", {}).get("start_map_id", "village_001"))
	var visited = migrated.get("visited_maps", {})
	if not (visited is Dictionary):
		visited = {}
	var current_map = str(migrated.get("current_map_id", ""))
	if current_map != "":
		visited[current_map] = true
	migrated["visited_maps"] = visited
	if not migrated.has("map_states") or not (migrated.get("map_states", {}) is Dictionary):
		migrated["map_states"] = {}
	if not migrated.has("building_states") or not (migrated.get("building_states", {}) is Dictionary):
		migrated["building_states"] = {}
	if not migrated.has("quest_state") or not (migrated.get("quest_state", {}) is Dictionary):
		migrated["quest_state"] = {}
	if not migrated.has("equipment_state") or not (migrated.get("equipment_state", {}) is Dictionary):
		migrated["equipment_state"] = {}
	if not migrated.has("training_used_today") or not (migrated.get("training_used_today", {}) is Dictionary):
		migrated["training_used_today"] = {}
	if not migrated.has("player_position_by_map") or not (migrated.get("player_position_by_map", {}) is Dictionary):
		migrated["player_position_by_map"] = {}
	if not migrated.has("progression_data") or not (migrated.get("progression_data", {}) is Dictionary):
		migrated["progression_data"] = WorldState._default_progression_data()
	if not migrated.has("inventory") or not (migrated.get("inventory", {}) is Dictionary):
		migrated["inventory"] = {}
	if not migrated.has("player_position") or not (migrated.get("player_position", {}) is Dictionary):
		migrated["player_position"] = {"x": 0, "y": 0}
	if not migrated.has("world_graph") or not (migrated.get("world_graph", {}) is Dictionary):
		migrated["world_graph"] = {}
	return migrated


func _apply_save_data(data: Dictionary) -> void:
	data = migrate_save_data(data)
	WorldState.world_name = data.get("world_name", "")
	WorldState.world_type = data.get("world_type", "")
	WorldState.world_blueprint = data.get("world_blueprint", {})
	var pos = data.get("player_position", {"x": 0, "y": 0})
	WorldState.player_position = Vector2(float(pos.get("x", 0)), float(pos.get("y", 0)))
	WorldState.player_health = int(data.get("player_health", WorldState.player_health))
	WorldState.action_history = data.get("action_history", [])
	WorldState.npc_memory = data.get("npc_memory", {})
	WorldState.set_inventory_items(data.get("inventory", {}))
	WorldState.discovered_locations = data.get("discovered_locations", {})
	WorldState.collected_items = data.get("collected_items", [])
	WorldState.defeated_enemies = data.get("defeated_enemies", [])
	WorldState.current_region = data.get("current_region", WorldState.current_region)
	WorldState.current_day = int(data.get("current_day", WorldState.current_day))
	WorldState.current_hour = int(data.get("current_hour", WorldState.current_hour))
	WorldState.progression_data = data.get("progression_data", WorldState._default_progression_data())
	WorldState.player_stats = data.get("player_stats", {})
	var features_data = data.get("unlocked_features", {})
	if features_data is Array:
		var feature_dict: Dictionary = {}
		for feature in features_data:
			feature_dict[str(feature)] = true
		features_data = feature_dict
	WorldState.unlocked_features = features_data if features_data is Dictionary else {}
	WorldState.world_rule_modifiers = data.get("world_rule_modifiers", WorldState.progression_data.get("world_modifiers", {}))
	WorldState.realm_history = data.get("realm_history", WorldState.progression_data.get("realm_history", []))
	WorldState.breakthrough_history = data.get("breakthrough_history", WorldState.progression_data.get("breakthrough_history", []))
	WorldState.tribulation_record = data.get("tribulation_record", WorldState.progression_data.get("tribulation_record", []))
	WorldState.progression_data["unlocked_features"] = WorldState.unlocked_features.keys()
	WorldState.progression_data["world_modifiers"] = WorldState.world_rule_modifiers
	WorldState.progression_data["realm_history"] = WorldState.realm_history
	WorldState.progression_data["breakthrough_history"] = WorldState.breakthrough_history
	WorldState.progression_data["tribulation_record"] = WorldState.tribulation_record
	WorldState.current_map_id = str(data.get("current_map_id", WorldState.world_blueprint.get("start_map_id", "")))
	var visited_data = data.get("visited_maps", {})
	WorldState.visited_maps = visited_data if visited_data is Dictionary else {}
	var map_state_data = data.get("map_states", {})
	WorldState.map_states = MapStateSerializerClass.new().deserialize_all_map_states(map_state_data if map_state_data is Dictionary else {})
	var building_data = data.get("building_states", {})
	WorldState.building_states = building_data if building_data is Dictionary else {}
	var quest_data = data.get("quest_state", {})
	WorldState.quest_state = quest_data if quest_data is Dictionary else {}
	var equipment_data = data.get("equipment_state", {})
	WorldState.equipment_state = equipment_data if equipment_data is Dictionary else {}
	var training_data = data.get("training_used_today", {})
	WorldState.training_used_today = training_data if training_data is Dictionary else {}
	var graph_data = data.get("world_graph", {})
	WorldState.world_graph_data = graph_data if graph_data is Dictionary else {}
	if WorldState.world_graph_data.is_empty() and not WorldState.world_blueprint.is_empty() and WorldState.world_blueprint.has("maps"):
		var graph = preload("res://scripts/world/WorldGraph.gd").new()
		graph.setup(WorldState.world_blueprint)
		WorldState.set_world_graph(graph)
	WorldState.player_position_by_map = data.get("player_position_by_map", {})
	WorldState.last_spawn_id = str(data.get("last_spawn_id", "default"))
	if WorldState.current_map_id == "" and not WorldState.world_blueprint.is_empty():
		WorldState.current_map_id = str(WorldState.world_blueprint.get("start_map_id", ""))
	if WorldState.current_map_id != "":
		WorldState.mark_map_visited(WorldState.current_map_id)
