extends RefCounted
class_name SceneDecorator
## Adds lightweight deterministic decoration markers.

var last_positions: Array = []


func decorate(map_instance, parent_layers: Dictionary, tile_size: int) -> Dictionary:
	last_positions.clear()
	if map_instance == null:
		return {"ok": false, "decorations": 0, "error": "missing_map"}
	var layer = parent_layers.get("DecorationLayer", null)
	if layer == null:
		return {"ok": false, "decorations": 0, "error": "missing_layer"}
	var budget = _budget_for_type(str(map_instance.map_type))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%s" % [str(map_instance.map_id), str(map_instance.seed)])
	var reserved = _reserved_tiles(map_instance)
	var placed := 0
	var attempts := 0
	while placed < budget.y and attempts < budget.y * 18:
		attempts += 1
		var x := rng.randi_range(1, max(1, map_instance.size.x - 2))
		var y := rng.randi_range(1, max(1, map_instance.size.y - 2))
		var key := "%d:%d" % [x, y]
		if reserved.has(key) or not _is_walkable(map_instance, x, y):
			continue
		if placed >= budget.x and rng.randf() < 0.35:
			continue
		var marker := _make_marker(str(map_instance.map_type), placed)
		marker.position = Vector2(x * tile_size + tile_size * 0.25, y * tile_size + tile_size * 0.25)
		marker.set_meta("tile_pos", Vector2i(x, y))
		layer.add_child(marker)
		last_positions.append(Vector2i(x, y))
		placed += 1
	return {"ok": true, "decorations": placed, "budget_min": budget.x, "budget_max": budget.y}


func _budget_for_type(map_type: String) -> Vector2i:
	match map_type:
		"forest":
			return Vector2i(60, 120)
		"cave":
			return Vector2i(30, 60)
		"sect_gate":
			return Vector2i(40, 80)
		_:
			return Vector2i(30, 60)


func _make_marker(map_type: String, index: int) -> Node2D:
	var node := Node2D.new()
	node.name = "Decor_%s_%03d" % [map_type, index]
	var rect := ColorRect.new()
	rect.size = Vector2(10, 10)
	rect.position = Vector2(-5, -5)
	rect.color = _decor_color(map_type, index)
	node.add_child(rect)
	if index % 12 == 0:
		var label := _make_label(_decor_label(map_type), Vector2(-44, -22))
		node.add_child(label)
	return node


func _make_label(text: String, offset: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = offset
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _decor_color(map_type: String, index: int) -> Color:
	match map_type:
		"forest":
			return Color(0.55, 0.85, 0.35, 0.85) if index % 3 != 0 else Color(0.4, 0.32, 0.2, 0.9)
		"cave":
			return Color(0.75, 0.68, 0.45, 0.9) if index % 4 == 0 else Color(0.34, 0.34, 0.38, 0.9)
		"sect_gate":
			return Color(0.85, 0.78, 0.45, 0.9) if index % 2 == 0 else Color(0.55, 0.72, 0.95, 0.8)
		_:
			return Color(0.9, 0.58, 0.32, 0.9) if index % 4 == 0 else Color(0.85, 0.9, 0.38, 0.8)


func _decor_label(map_type: String) -> String:
	match map_type:
		"forest":
			return "trail"
		"cave":
			return "torch"
		"sect_gate":
			return "gate"
		_:
			return "sign"


func _reserved_tiles(map_instance) -> Dictionary:
	var reserved: Dictionary = {}
	for transition in map_instance.transitions:
		var rect = transition.get("from_rect", {})
		if rect is Dictionary:
			var x0 := int(rect.get("x", 0))
			var y0 := int(rect.get("y", 0))
			var w := int(rect.get("w", rect.get("width", 1)))
			var h := int(rect.get("h", rect.get("height", 1)))
			for y in range(y0, y0 + h):
				for x in range(x0, x0 + w):
					reserved["%d:%d" % [x, y]] = true
	for building in map_instance.buildings:
		var door = building.get("door_position", {})
		if door is Dictionary:
			reserved["%d:%d" % [int(door.get("x", 0)), int(door.get("y", 0))]] = true
	return reserved


func _is_walkable(map_instance, x: int, y: int) -> bool:
	if y < 0 or y >= map_instance.walkable.size():
		return false
	if x < 0 or x >= map_instance.walkable[y].size():
		return false
	return bool(map_instance.walkable[y][x])
