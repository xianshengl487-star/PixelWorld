extends RefCounted
class_name MapStateSerializer
## MapStateSerializer.gd - converts MapState objects and dictionaries for saves.

const MapStateClass = preload("res://scripts/map/MapState.gd")


func serialize_map_state(map_state) -> Dictionary:
	if map_state == null:
		return {}
	if map_state is Dictionary:
		return map_state.duplicate(true)
	if map_state.has_method("to_save_data"):
		return map_state.to_save_data()
	return {}


func deserialize_map_state(data: Dictionary):
	var state = MapStateClass.new()
	state.load_save_data(data)
	return state


func serialize_all_map_states(map_states: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for map_id in map_states.keys():
		result[map_id] = serialize_map_state(map_states[map_id])
	return result


func deserialize_all_map_states(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for map_id in data.keys():
		result[map_id] = deserialize_map_state(data[map_id]).to_save_data() if data[map_id] is Dictionary else {}
	return result
