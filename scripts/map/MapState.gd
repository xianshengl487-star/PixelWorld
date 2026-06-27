extends RefCounted
class_name MapState
## MapState.gd - persistent runtime deltas for one map.

var map_id: String = ""
var visited: bool = false
var opened_chests: Dictionary = {}
var collected_resources: Dictionary = {}
var defeated_enemies: Dictionary = {}
var triggered_events: Dictionary = {}
var solved_puzzles: Dictionary = {}
var npc_states: Dictionary = {}
var building_states: Dictionary = {}
var dynamic_objects: Dictionary = {}
var last_player_position: Vector2i = Vector2i.ZERO


func setup(data: Dictionary) -> void:
	load_save_data(data)


func mark_visited() -> void:
	visited = true


func mark_chest_opened(chest_id: String) -> void:
	if chest_id != "":
		opened_chests[chest_id] = true


func is_chest_opened(chest_id: String) -> bool:
	return bool(opened_chests.get(chest_id, false))


func mark_resource_collected(resource_id: String) -> void:
	if resource_id != "":
		collected_resources[resource_id] = true


func is_resource_collected(resource_id: String) -> bool:
	return bool(collected_resources.get(resource_id, false))


func mark_enemy_defeated(enemy_id: String) -> void:
	if enemy_id != "":
		defeated_enemies[enemy_id] = true


func is_enemy_defeated(enemy_id: String) -> bool:
	return bool(defeated_enemies.get(enemy_id, false))


func mark_event_triggered(event_id: String) -> void:
	if event_id != "":
		triggered_events[event_id] = true


func is_event_triggered(event_id: String) -> bool:
	return bool(triggered_events.get(event_id, false))


func set_npc_state(npc_id: String, data: Dictionary) -> void:
	if npc_id != "":
		npc_states[npc_id] = data.duplicate(true)


func get_npc_state(npc_id: String) -> Dictionary:
	return npc_states.get(npc_id, {}).duplicate(true)


func set_building_state(building_id: String, data: Dictionary) -> void:
	if building_id != "":
		building_states[building_id] = data.duplicate(true)


func get_building_state(building_id: String) -> Dictionary:
	return building_states.get(building_id, {}).duplicate(true)


func to_save_data() -> Dictionary:
	return {
		"map_id": map_id,
		"visited": visited,
		"opened_chests": opened_chests,
		"collected_resources": collected_resources,
		"defeated_enemies": defeated_enemies,
		"triggered_events": triggered_events,
		"solved_puzzles": solved_puzzles,
		"npc_states": npc_states,
		"building_states": building_states,
		"dynamic_objects": dynamic_objects,
		"last_player_position": {"x": last_player_position.x, "y": last_player_position.y}
	}


func load_save_data(data: Dictionary) -> void:
	map_id = str(data.get("map_id", map_id))
	visited = bool(data.get("visited", visited))
	opened_chests = data.get("opened_chests", {}).duplicate(true)
	collected_resources = data.get("collected_resources", {}).duplicate(true)
	defeated_enemies = data.get("defeated_enemies", {}).duplicate(true)
	triggered_events = data.get("triggered_events", {}).duplicate(true)
	solved_puzzles = data.get("solved_puzzles", {}).duplicate(true)
	npc_states = data.get("npc_states", {}).duplicate(true)
	building_states = data.get("building_states", {}).duplicate(true)
	dynamic_objects = data.get("dynamic_objects", {}).duplicate(true)
	var pos = data.get("last_player_position", {"x": 0, "y": 0})
	if pos is Array and pos.size() >= 2:
		last_player_position = Vector2i(int(pos[0]), int(pos[1]))
	elif pos is Dictionary:
		last_player_position = Vector2i(int(pos.get("x", 0)), int(pos.get("y", 0)))
