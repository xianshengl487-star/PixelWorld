extends RefCounted
class_name BuildingRegistry
## BuildingRegistry.gd - loads building templates and creates placed building data.

const TEMPLATE_PATH := "res://data/buildings/building_templates.json"

var _templates: Dictionary = {}


func load_templates() -> Dictionary:
	if not _templates.is_empty():
		return _templates.duplicate(true)
	if not FileAccess.file_exists(TEMPLATE_PATH):
		push_warning("[BuildingRegistry] missing template file: %s" % TEMPLATE_PATH)
		return {}
	var file = FileAccess.open(TEMPLATE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		_templates = data.duplicate(true)
	return _templates.duplicate(true)


func get_template(building_type: String) -> Dictionary:
	if _templates.is_empty():
		load_templates()
	return _templates.get(building_type, {}).duplicate(true)


func create_building_instance(building_type: String, position: Vector2i, parent_map_id: String) -> Dictionary:
	var template = get_template(building_type)
	if template.is_empty():
		template = {
			"building_type": building_type,
			"display_name": building_type.capitalize(),
			"size": [5, 5],
			"door_offset": [2, 4],
			"services": [],
			"access_rules": {}
		}
	var size = _vec(template.get("size", [5, 5]))
	var door_offset = _vec(template.get("door_offset", [size.x / 2, size.y]))
	var id = "%s_%s_%03d_%03d" % [parent_map_id, building_type, position.x, position.y]
	if parent_map_id == "village_001":
		id = _stable_village_id(building_type)
	var door = position + door_offset
	return {
		"building_id": id,
		"building_type": building_type,
		"display_name": str(template.get("display_name", building_type.capitalize())),
		"position": {"x": position.x, "y": position.y},
		"size": [size.x, size.y],
		"door_position": {"x": door.x, "y": door.y},
		"door_spawn_id": "%s_door" % id,
		"interior_map_id": create_interior_map_id(id),
		"services": template.get("services", []).duplicate(true),
		"access_rules": template.get("access_rules", {}).duplicate(true),
		"interior_template": str(template.get("interior_template", "")),
		"default_npcs": template.get("default_npcs", []).duplicate(true),
		"visual_hint": str(template.get("visual_hint", "")),
		"parent_map_id": parent_map_id
	}


func create_interior_map_id(building_id: String) -> String:
	return "%s_interior" % building_id


func default_village_building_types() -> Array:
	return ["chief_house", "apothecary", "blacksmith", "inn", "general_store"]


func _stable_village_id(building_type: String) -> String:
	match building_type:
		"chief_house":
			return "chief_house_001"
		"apothecary":
			return "apothecary_001"
		"blacksmith":
			return "blacksmith_001"
		"inn":
			return "inn_001"
		"general_store":
			return "general_store_001"
		_:
			return "%s_001" % building_type


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
