extends RefCounted
class_name WorldInstance
## WorldInstance.gd - runtime world state around a WorldGraph.

const WorldGraphClass = preload("res://scripts/world/WorldGraph.gd")

var world_id: String = ""
var world_name: String = ""
var world_type: String = ""
var seed: int = 0
var graph = null
var global_flags: Dictionary = {}
var visited_maps: Dictionary = {}
var map_states: Dictionary = {}
var created_at: String = ""
var version: String = "0.4.0"


func setup_from_blueprint(blueprint: Dictionary) -> void:
	world_id = str(blueprint.get("world_id", blueprint.get("id", "world_%d" % Time.get_unix_time_from_system())))
	world_name = str(blueprint.get("world_name", "未知世界"))
	world_type = str(blueprint.get("world_type", "unknown"))
	seed = int(blueprint.get("seed", 0))
	created_at = Time.get_datetime_string_from_system()
	graph = WorldGraphClass.new()
	graph.setup(blueprint)
	mark_map_visited(get_current_map_id())


func get_current_map_id() -> String:
	return graph.current_map_id if graph != null else ""


func set_current_map_id(map_id: String) -> void:
	if graph != null:
		graph.set_current_map(map_id)
		mark_map_visited(map_id)


func mark_map_visited(map_id: String) -> void:
	if map_id != "":
		visited_maps[map_id] = true


func is_map_visited(map_id: String) -> bool:
	return bool(visited_maps.get(map_id, false))


func get_map_state(map_id: String) -> Dictionary:
	return map_states.get(map_id, {}).duplicate(true)


func set_map_state(map_id: String, state: Dictionary) -> void:
	if map_id != "":
		map_states[map_id] = state.duplicate(true)


func to_save_data() -> Dictionary:
	return {
		"world_id": world_id,
		"world_name": world_name,
		"world_type": world_type,
		"seed": seed,
		"graph": graph.to_save_data() if graph != null and graph.has_method("to_save_data") else {},
		"global_flags": global_flags,
		"visited_maps": visited_maps,
		"map_states": map_states,
		"created_at": created_at,
		"version": version
	}


func load_save_data(data: Dictionary) -> void:
	world_id = str(data.get("world_id", world_id))
	world_name = str(data.get("world_name", world_name))
	world_type = str(data.get("world_type", world_type))
	seed = int(data.get("seed", seed))
	global_flags = data.get("global_flags", {}).duplicate(true)
	visited_maps = data.get("visited_maps", {}).duplicate(true)
	map_states = data.get("map_states", {}).duplicate(true)
	created_at = str(data.get("created_at", created_at))
	version = str(data.get("version", version))
	graph = WorldGraphClass.new()
	graph.setup(data.get("graph", {}))
