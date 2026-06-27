extends RefCounted
class_name MapTransition
## MapTransition.gd - a door, edge exit, cave mouth, portal, or locked route.

var transition_id: String = ""
var from_map_id: String = ""
var to_map_id: String = ""
var from_rect: Rect2i = Rect2i(0, 0, 1, 1)
var target_spawn_id: String = "default"
var transition_type: String = "edge_exit"
var required_flags: Array = []
var required_items: Array = []
var required_realm_order: int = 0
var required_faction: String = ""
var required_faction_relation: int = 0
var locked_message: String = ""
var enabled: bool = true


func setup(data: Dictionary) -> void:
	transition_id = str(data.get("transition_id", data.get("connection_id", transition_id)))
	from_map_id = str(data.get("from_map_id", from_map_id))
	to_map_id = str(data.get("to_map_id", data.get("target_map_id", to_map_id)))
	target_spawn_id = str(data.get("target_spawn_id", data.get("to_spawn_id", target_spawn_id)))
	transition_type = str(data.get("transition_type", data.get("connection_type", transition_type)))
	required_flags = data.get("required_flags", []).duplicate(true)
	required_items = data.get("required_items", []).duplicate(true)
	required_realm_order = int(data.get("required_realm_order", required_realm_order))
	required_faction = str(data.get("required_faction", required_faction))
	required_faction_relation = int(data.get("required_faction_relation", required_faction_relation))
	locked_message = str(data.get("locked_message", locked_message))
	enabled = bool(data.get("enabled", enabled))
	from_rect = _parse_rect(data.get("from_rect", data.get("rect", from_rect)))


func can_use(world_state) -> Dictionary:
	if not enabled:
		return {"ok": false, "reason": get_locked_reason(world_state)}
	for flag in required_flags:
		if not _has_flag(world_state, str(flag)):
			return {"ok": false, "reason": get_locked_reason(world_state)}
	if required_realm_order > 0:
		var current_order = int(world_state.progression_data.get("current_realm_order", 0)) if world_state != null else 0
		if current_order < required_realm_order:
			return {"ok": false, "reason": get_locked_reason(world_state)}
	return {"ok": true, "reason": ""}


func get_locked_reason(world_state) -> String:
	if locked_message != "":
		return locked_message
	if required_realm_order > 0:
		return "你的当前境界还不足以通过这里。"
	if required_flags.size() > 0:
		return "这里暂时还没有开启。"
	return "这条路暂时不可用。"


func to_save_data() -> Dictionary:
	return {
		"transition_id": transition_id,
		"from_map_id": from_map_id,
		"to_map_id": to_map_id,
		"from_rect": {"x": from_rect.position.x, "y": from_rect.position.y, "w": from_rect.size.x, "h": from_rect.size.y},
		"target_spawn_id": target_spawn_id,
		"transition_type": transition_type,
		"required_flags": required_flags,
		"required_items": required_items,
		"required_realm_order": required_realm_order,
		"required_faction": required_faction,
		"required_faction_relation": required_faction_relation,
		"locked_message": locked_message,
		"enabled": enabled
	}


func _has_flag(world_state, flag: String) -> bool:
	if world_state == null or flag == "":
		return false
	if world_state.get("global_flags") != null and world_state.global_flags.get(flag, false):
		return true
	if world_state.progression_data.get("special_flags", {}).get(flag, false):
		return true
	if world_state.event_states.has(flag):
		return bool(world_state.event_states[flag].get("active", false)) or int(world_state.event_states[flag].get("progress", 0)) > 0
	return false


func _parse_rect(value) -> Rect2i:
	if value is Rect2i:
		return value
	if value is Dictionary:
		return Rect2i(
			int(value.get("x", 0)),
			int(value.get("y", 0)),
			int(value.get("w", value.get("width", 1))),
			int(value.get("h", value.get("height", 1)))
		)
	if value is Array and value.size() >= 4:
		return Rect2i(int(value[0]), int(value[1]), int(value[2]), int(value[3]))
	return Rect2i(0, 0, 1, 1)
