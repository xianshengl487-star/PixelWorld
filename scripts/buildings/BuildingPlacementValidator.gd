extends RefCounted
class_name BuildingPlacementValidator
## BuildingPlacementValidator.gd - conservative placement checks for building footprints.


func validate_placement(map_instance, building_data: Dictionary) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	if map_instance == null:
		return {"ok": false, "errors": ["map_instance is null"], "warnings": warnings}
	var pos = _vec(building_data.get("position", {"x": 0, "y": 0}))
	var size = _vec(building_data.get("size", [5, 5]))
	var door = _vec(building_data.get("door_position", {"x": pos.x + size.x / 2, "y": pos.y + size.y}))
	if pos.x < 0 or pos.y < 0 or pos.x + size.x > map_instance.size.x or pos.y + size.y > map_instance.size.y:
		errors.append("building footprint out of bounds")
	for y in range(pos.y, pos.y + size.y):
		for x in range(pos.x, pos.x + size.x):
			if map_instance.is_path_locked(Vector2i(x, y)):
				errors.append("building overlaps locked path")
				break
	if door.x < 0 or door.y < 0 or door.x >= map_instance.size.x or door.y >= map_instance.size.y:
		errors.append("door_position out of bounds")
	elif map_instance.walkable.size() > door.y and map_instance.walkable[door.y].size() > door.x and not map_instance.walkable[door.y][door.x]:
		errors.append("door_position is not walkable")
	for other in map_instance.buildings:
		if _rects_overlap(Rect2i(pos, size), Rect2i(_vec(other.get("position", {"x": 0, "y": 0})), _vec(other.get("size", [1, 1])))):
			errors.append("building overlaps another building")
			break
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


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


func _rects_overlap(a: Rect2i, b: Rect2i) -> bool:
	return a.intersects(b)
