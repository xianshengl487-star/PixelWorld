extends RefCounted
class_name BuildingInstance
## BuildingInstance.gd - one placed building on a MapInstance.

var building_id: String = ""
var building_type: String = ""
var display_name: String = ""
var position: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i(5, 5)
var door_position: Vector2i = Vector2i.ZERO
var interior_map_id: String = ""
var services: Array = []
var owner_faction: String = ""
var locked: bool = false
var access_rules: Dictionary = {}
var state: Dictionary = {}


func setup(data: Dictionary) -> void:
	building_id = str(data.get("building_id", data.get("id", building_id)))
	building_type = str(data.get("building_type", building_type))
	display_name = str(data.get("display_name", display_name))
	position = _parse_vec(data.get("position", {"x": 0, "y": 0}))
	size = _parse_vec(data.get("size", [size.x, size.y]))
	door_position = _parse_vec(data.get("door_position", {"x": position.x + size.x / 2, "y": position.y + size.y}))
	interior_map_id = str(data.get("interior_map_id", interior_map_id))
	services = data.get("services", services).duplicate(true)
	owner_faction = str(data.get("owner_faction", owner_faction))
	locked = bool(data.get("locked", locked))
	access_rules = data.get("access_rules", access_rules).duplicate(true)
	state = data.get("state", state).duplicate(true)


func to_dict() -> Dictionary:
	return {
		"building_id": building_id,
		"building_type": building_type,
		"display_name": display_name,
		"position": {"x": position.x, "y": position.y},
		"size": [size.x, size.y],
		"door_position": {"x": door_position.x, "y": door_position.y},
		"interior_map_id": interior_map_id,
		"services": services,
		"owner_faction": owner_faction,
		"locked": locked,
		"access_rules": access_rules,
		"state": state
	}


func _parse_vec(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO
