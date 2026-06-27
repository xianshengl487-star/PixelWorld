extends RefCounted
class_name BuildingTemplate
## BuildingTemplate.gd - reusable building definition.

var building_type: String = ""
var display_name: String = ""
var world_types: Array = []
var size: Vector2i = Vector2i(5, 5)
var door_offset: Vector2i = Vector2i(2, 4)
var required_near: Array = []
var avoid_near: Array = []
var services: Array = []
var interior_template: String = ""
var default_npcs: Array = []
var faction_role: String = ""
var access_rules: Dictionary = {}


func setup(data: Dictionary) -> void:
	building_type = str(data.get("building_type", building_type))
	display_name = str(data.get("display_name", display_name))
	world_types = data.get("world_types", world_types).duplicate(true)
	size = _parse_vec(data.get("size", [size.x, size.y]))
	door_offset = _parse_vec(data.get("door_offset", [door_offset.x, door_offset.y]))
	required_near = data.get("required_near", required_near).duplicate(true)
	avoid_near = data.get("avoid_near", avoid_near).duplicate(true)
	services = data.get("services", services).duplicate(true)
	interior_template = str(data.get("interior_template", interior_template))
	default_npcs = data.get("default_npcs", default_npcs).duplicate(true)
	faction_role = str(data.get("faction_role", faction_role))
	access_rules = data.get("access_rules", access_rules).duplicate(true)


func to_dict() -> Dictionary:
	return {
		"building_type": building_type,
		"display_name": display_name,
		"world_types": world_types,
		"size": [size.x, size.y],
		"door_offset": [door_offset.x, door_offset.y],
		"required_near": required_near,
		"avoid_near": avoid_near,
		"services": services,
		"interior_template": interior_template,
		"default_npcs": default_npcs,
		"faction_role": faction_role,
		"access_rules": access_rules
	}


func _parse_vec(value) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return value if value is Vector2i else Vector2i.ZERO
