extends RefCounted
class_name ChunkedMapRenderer
## Merges consecutive same-type tiles in each row into one ColorRect.


func render(map_data: Dictionary, tile_size: int, parent: Node, options: Dictionary = {}) -> Dictionary:
	if parent == null:
		return {"ok": false, "error": "missing_parent", "node_count": 0, "tile_count": 0, "merged_rect_count": 0, "mode": "none"}
	var tiles = map_data.get("tiles", [])
	if not (tiles is Array) or tiles.is_empty():
		return {"ok": false, "error": "missing_tiles", "node_count": 0, "tile_count": 0, "merged_rect_count": 0, "mode": "none"}
	if bool(options.get("clear_existing", true)):
		for child in parent.get_children():
			child.queue_free()
	var tile_count := 0
	var node_count := 0
	for y in range(tiles.size()):
		var row = tiles[y]
		if not (row is Array) or row.is_empty():
			continue
		var x := 0
		while x < row.size():
			var tile_type := int(row[x])
			var run_start := x
			var run_len := 1
			x += 1
			while x < row.size() and int(row[x]) == tile_type:
				run_len += 1
				x += 1
			var rect := ColorRect.new()
			rect.name = "TileRun_%d_%d_%d" % [y, run_start, tile_type]
			rect.size = Vector2(run_len * tile_size, tile_size)
			rect.position = Vector2(run_start * tile_size, y * tile_size)
			rect.color = _tile_color(tile_type)
			parent.add_child(rect)
			node_count += 1
			tile_count += run_len
	return {
		"ok": true,
		"node_count": node_count,
		"tile_count": tile_count,
		"merged_rect_count": node_count,
		"mode": "merged_color_rect"
	}


func _tile_color(tile_type: int) -> Color:
	match tile_type:
		0:
			return Color(0.20, 0.50, 0.15)
		1:
			return Color(0.55, 0.45, 0.30)
		2:
			return Color(0.10, 0.35, 0.10)
		3:
			return Color(0.15, 0.30, 0.70, 0.80)
		4:
			return Color(0.55, 0.35, 0.20)
		5:
			return Color(0.35, 0.35, 0.35)
		6:
			return Color(0.15, 0.10, 0.05)
		7:
			return Color(0.70, 0.65, 0.50)
		_:
			return Color(0.20, 0.50, 0.15)
