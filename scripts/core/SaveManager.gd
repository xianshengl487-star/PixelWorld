extends Node
## SaveManager.gd — JSON 存档/读档 Autoload

const SAVE_DIR := "user://saves"


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
	_apply_save_data(data)
	GameLog.add_entry("游戏已读取。")
	return {"ok": true, "data": data}


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
	return {
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
		"progression_world_type": WorldState.progression_data.get("world_type", WorldState.world_type)
	}


func _apply_save_data(data: Dictionary) -> void:
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
