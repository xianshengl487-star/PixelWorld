extends RefCounted
class_name WorldGraph
## WorldGraph.gd - topology of maps and transitions for a world.

const MapInstanceClass = preload("res://scripts/map/MapInstance.gd")

var world_id: String = ""
var world_name: String = ""
var world_type: String = ""
var seed: int = 0
var start_map_id: String = ""
var current_map_id: String = ""
var maps: Dictionary = {}
var connections: Array = []
var main_path: Array = []
var side_paths: Array = []
var hidden_paths: Array = []
var locked_paths: Array = []


func setup(data: Dictionary) -> void:
	world_id = str(data.get("world_id", data.get("id", world_id)))
	world_name = str(data.get("world_name", data.get("name", world_name)))
	world_type = str(data.get("world_type", world_type))
	seed = int(data.get("seed", seed))
	start_map_id = str(data.get("start_map_id", start_map_id))
	current_map_id = str(data.get("current_map_id", data.get("current_map", current_map_id)))
	connections = data.get("connections", connections).duplicate(true)
	main_path = data.get("main_path", main_path).duplicate(true)
	side_paths = data.get("side_paths", side_paths).duplicate(true)
	hidden_paths = data.get("hidden_paths", hidden_paths).duplicate(true)
	locked_paths = data.get("locked_paths", locked_paths).duplicate(true)
	maps.clear()
	for map_data in data.get("maps", []):
		var map_instance = MapInstanceClass.new()
		map_instance.setup(map_data)
		add_map(map_instance)
	if maps.is_empty() and data.get("maps", {}) is Dictionary:
		for map_id in data.get("maps", {}).keys():
			var map_instance = MapInstanceClass.new()
			var raw = data["maps"][map_id]
			map_instance.setup(raw if raw is Dictionary else {"map_id": str(map_id)})
			add_map(map_instance)
	if start_map_id == "" and maps.size() > 0:
		start_map_id = maps.keys()[0]
	if current_map_id == "":
		current_map_id = start_map_id


func add_map(map_instance) -> void:
	var id = _map_id(map_instance)
	if id != "":
		maps[id] = map_instance


func get_map(map_id: String):
	return maps.get(map_id, null)


func has_map(map_id: String) -> bool:
	return maps.has(map_id)


func add_connection(connection_data: Dictionary) -> void:
	connections.append(connection_data.duplicate(true))


func get_connections_from(map_id: String) -> Array:
	var found: Array = []
	for connection in connections:
		if str(connection.get("from_map_id", "")) == map_id:
			found.append(connection)
	return found


func get_connection(connection_id: String) -> Dictionary:
	for connection in connections:
		if str(connection.get("connection_id", "")) == connection_id:
			return connection
	return {}


func get_start_map_id() -> String:
	return start_map_id


func set_current_map(map_id: String) -> void:
	if has_map(map_id):
		current_map_id = map_id


func validate_graph() -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	if maps.is_empty():
		errors.append("world_graph has no maps")
	if start_map_id == "" or not has_map(start_map_id):
		errors.append("start_map_id missing or invalid: %s" % start_map_id)
	if current_map_id != "" and not has_map(current_map_id):
		errors.append("current_map_id invalid: %s" % current_map_id)
	for map_id in maps.keys():
		var map_instance = maps[map_id]
		var spawns = map_instance.spawn_points if map_instance != null and map_instance.get("spawn_points") != null else {}
		if not spawns.has("default"):
			errors.append("map missing default spawn: %s" % map_id)
	for connection in connections:
		var from_id = str(connection.get("from_map_id", ""))
		var to_id = str(connection.get("to_map_id", ""))
		if not has_map(from_id):
			errors.append("connection invalid from_map_id: %s" % connection.get("connection_id", ""))
		if not has_map(to_id):
			errors.append("connection invalid to_map_id: %s" % connection.get("connection_id", ""))
		if int(connection.get("required_realm_order", 0)) < 0:
			errors.append("connection has negative required_realm_order: %s" % connection.get("connection_id", ""))
		if int(connection.get("required_realm_order", 0)) > 0 and str(connection.get("locked_message", "")) == "":
			warnings.append("locked connection has no locked_message: %s" % connection.get("connection_id", ""))
	if main_path.size() > 1:
		for i in range(main_path.size() - 1):
			if not _has_path_between(str(main_path[i]), str(main_path[i + 1])):
				errors.append("main_path is not connected: %s -> %s" % [main_path[i], main_path[i + 1]])
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


func to_save_data() -> Dictionary:
	var map_list: Array = []
	for id in maps.keys():
		var item = maps[id]
		map_list.append(item.to_save_data() if item != null and item.has_method("to_save_data") else item)
	return {
		"world_id": world_id,
		"world_name": world_name,
		"world_type": world_type,
		"seed": seed,
		"start_map_id": start_map_id,
		"current_map_id": current_map_id,
		"maps": map_list,
		"connections": connections,
		"main_path": main_path,
		"side_paths": side_paths,
		"hidden_paths": hidden_paths,
		"locked_paths": locked_paths
	}


func load_save_data(data: Dictionary) -> void:
	setup(data)


func _map_id(map_instance) -> String:
	if map_instance == null:
		return ""
	if map_instance is Dictionary:
		return str(map_instance.get("map_id", ""))
	return str(map_instance.get("map_id"))


func _has_path_between(from_id: String, to_id: String) -> bool:
	for connection in connections:
		if str(connection.get("from_map_id", "")) == from_id and str(connection.get("to_map_id", "")) == to_id:
			return true
		if str(connection.get("from_map_id", "")) == to_id and str(connection.get("to_map_id", "")) == from_id:
			return true
	return false
