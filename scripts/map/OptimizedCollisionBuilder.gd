extends RefCounted
class_name OptimizedCollisionBuilder
## Row-merges blocking tiles into fewer StaticBody2D nodes.

const BLOCKING_TILES: Array = [2, 3, 4, 5]


func build_collisions(map_data: Dictionary, tile_size: int, parent_node: Node2D) -> int:
	if parent_node == null:
		return 0
	var tiles = map_data.get("tiles", [])
	if not (tiles is Array) or tiles.is_empty():
		return 0
	var count := 0
	for y in range(tiles.size()):
		var row = tiles[y]
		if not (row is Array) or row.is_empty():
			continue
		var x := 0
		while x < row.size():
			if not _is_blocking(int(row[x])):
				x += 1
				continue
			var run_start := x
			var run_len := 1
			var tile_type := int(row[x])
			x += 1
			while x < row.size() and int(row[x]) == tile_type and _is_blocking(int(row[x])):
				run_len += 1
				x += 1
			_add_collision_run(parent_node, run_start, y, run_len, tile_size)
			count += 1
	return count


func count_blocking_tiles(map_data: Dictionary) -> int:
	var tiles = map_data.get("tiles", [])
	var count := 0
	if not (tiles is Array):
		return count
	for row in tiles:
		if not (row is Array):
			continue
		for tile in row:
			if _is_blocking(int(tile)):
				count += 1
	return count


func _is_blocking(tile_type: int) -> bool:
	return tile_type in BLOCKING_TILES


func _add_collision_run(parent_node: Node2D, x: int, y: int, run_len: int, tile_size: int) -> void:
	var body := StaticBody2D.new()
	body.name = "CollisionRun_%d_%d_%d" % [y, x, run_len]
	body.position = Vector2((x + run_len / 2.0) * tile_size, y * tile_size + tile_size / 2.0)
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(run_len * tile_size, tile_size)
	shape.shape = rect_shape
	body.add_child(shape)
	parent_node.add_child(body)
