extends RefCounted
class_name MapGenerator
## MapGenerator.gd — 地图生成器
## 根据世界蓝图生成 64x64 瓦片地图

# 瓦片类型常量
enum TileType {
	GRASS = 0,
	ROAD = 1,
	TREE = 2,
	WATER = 3,
	HOUSE = 4,
	MOUNTAIN = 5,
	CAVE = 6,
	SECT_FLOOR = 7
}

const MAP_WIDTH: int = 64
const MAP_HEIGHT: int = 64
const WALKABLE_TILES: Array = [TileType.GRASS, TileType.ROAD, TileType.SECT_FLOOR, TileType.CAVE]
const BLOCKING_TILES: Array = [TileType.TREE, TileType.WATER, TileType.HOUSE, TileType.MOUNTAIN]

# 随机数生成器（测试可用固定种子）
var _rng := RandomNumberGenerator.new()
var _has_fixed_seed: bool = false


## 设置固定种子（测试用）
func set_seed(s: int) -> void:
	_rng.seed = s
	_has_fixed_seed = true


## 准备随机数（有种子用种子，无种子随机化）
func _rand() -> int:
	if _has_fixed_seed:
		return _rng.randi()
	else:
		# 首次调用时随机化
		if not _rng.state:
			_rng.randomize()
		return _rng.randi()


func generate(blueprint: Dictionary) -> Dictionary:
	var tiles: Array = []
	var walkable: Array = []
	
	# 初始化全部为草地
	for y in range(MAP_HEIGHT):
		var row: Array = []
		var walk_row: Array = []
		for x in range(MAP_WIDTH):
			row.append(TileType.GRASS)
			walk_row.append(true)
		tiles.append(row)
		walkable.append(walk_row)
	
	var map_bp = blueprint.get("map_blueprint", {})
	
	# Step 1: Border
	_generate_border(tiles, walkable)
	
	# Step 2: Terrain areas (villages, forests, mountains, water)
	_generate_village(tiles, walkable, 28, 28, 12, 10)
	
	var forest_x = 32; var forest_y = 12
	_generate_forest(tiles, walkable, forest_x, forest_y, 20, 14)
	
	var mountain_x = 12; var mountain_y = 14
	_generate_area(tiles, walkable, mountain_x, mountain_y, 10, 10, TileType.MOUNTAIN)
	tiles[mountain_y][mountain_x] = TileType.CAVE
	walkable[mountain_y][mountain_x] = true
	
	var sect_x = 50; var sect_y = 10
	_generate_area(tiles, walkable, sect_x, sect_y, 6, 5, TileType.SECT_FLOOR)
	# sect walls
	for y in range(sect_y - 2, sect_y + 4):
		if y >= 0 and y < MAP_HEIGHT:
			tiles[y][sect_x - 3] = TileType.MOUNTAIN; walkable[y][sect_x - 3] = false
			tiles[y][sect_x + 3] = TileType.MOUNTAIN; walkable[y][sect_x + 3] = false
	for x in range(sect_x - 3, sect_x + 4):
		if x >= 0 and x < MAP_WIDTH:
			tiles[sect_y + 3][x] = TileType.MOUNTAIN; walkable[sect_y + 3][x] = false
	# sect gate
	tiles[sect_y + 2][sect_x] = TileType.ROAD; walkable[sect_y + 2][sect_x] = true
	
	_generate_water(tiles, walkable, 50, 45, 8, 6)
	_generate_scattered_trees(tiles, walkable, 32, 50, 20, 10)
	
	# Step 3: Roads (carved AFTER all terrain, forces walkability)
	var village_center = Vector2i(32, 28)
	var forest_entry = Vector2i(forest_x, forest_y + 6)
	var cave_entry = Vector2i(mountain_x, mountain_y)
	var sect_entry = Vector2i(sect_x, sect_y + 3)
	
	# Internal village roads
	_carve_road(tiles, walkable, 24, 28, 40, 28)   # horizontal
	_carve_road(tiles, walkable, 32, 24, 32, 34)    # vertical
	
	# Village → Forest
	_carve_road(tiles, walkable, village_center.x, village_center.y, forest_entry.x, forest_entry.y)
	# Forest → Cave
	_carve_road(tiles, walkable, forest_entry.x, forest_entry.y, cave_entry.x, cave_entry.y)
	# Forest → Sect
	_carve_road(tiles, walkable, forest_entry.x, forest_entry.y, sect_entry.x, sect_entry.y)
	
	# Cave entrance clearance (wider)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var cx = cave_entry.x + dx; var cy = cave_entry.y + dy
			if cx >= 0 and cx < MAP_WIDTH and cy >= 0 and cy < MAP_HEIGHT:
				tiles[cy][cx] = TileType.ROAD
				walkable[cy][cx] = true
	
	# Also clear the approach to cave from the east
	for step in range(1, 5):
		var cx = cave_entry.x + step; var cy = cave_entry.y
		if cx < MAP_WIDTH:
			tiles[cy][cx] = TileType.ROAD; walkable[cy][cx] = true
			tiles[cy - 1][cx] = TileType.ROAD; walkable[cy - 1][cx] = true
			tiles[cy + 1][cx] = TileType.ROAD; walkable[cy + 1][cx] = true
	
	# Step 4: Sanitize NPC positions
	_sanitize_npc_positions(tiles, walkable, blueprint, village_center)
	
	# Step 5: Force spawn point to be walkable
	var spawn = blueprint.get("player_spawn", {"x": 20, "y": 20})
	var spx = int(spawn.get("x", 20)); var spy = int(spawn.get("y", 20))
	if spx >= 0 and spx < MAP_WIDTH and spy >= 0 and spy < MAP_HEIGHT:
		if not walkable[spy][spx]:
			# Force clear spawn area
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var cx = spx + dx; var cy = spy + dy
					if cx >= 0 and cx < MAP_WIDTH and cy >= 0 and cy < MAP_HEIGHT:
						tiles[cy][cx] = TileType.ROAD
						walkable[cy][cx] = true
	
	return {
		"tiles": tiles,
		"walkable": walkable,
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT
	}


func generate_map(width: int, height: int, context: Dictionary = {}) -> Dictionary:
	var tiles: Array = []
	var walkable: Array = []
	width = max(8, width)
	height = max(8, height)
	var map_type = str(context.get("map_type", "village"))
	var locked_paths = context.get("locked_path_tiles", {})
	for y in range(height):
		var row: Array = []
		var walk_row: Array = []
		for x in range(width):
			var tile = _base_tile_for_type(map_type)
			if x == 0 or y == 0 or x == width - 1 or y == height - 1:
				tile = TileType.MOUNTAIN if map_type != "interior" else TileType.HOUSE
			row.append(tile)
			walk_row.append(tile in WALKABLE_TILES)
		tiles.append(row)
		walkable.append(walk_row)
	_generate_dynamic_content(tiles, walkable, map_type, locked_paths)
	return {"tiles": tiles, "walkable": walkable, "width": width, "height": height}


func generate_map_from_instance(map_instance) -> Dictionary:
	var context = {
		"map_type": map_instance.map_type,
		"world_type": map_instance.world_type,
		"locked_path_tiles": map_instance.locked_path_tiles
	}
	return generate_map(map_instance.size.x, map_instance.size.y, context)


## 强制修路（不受已有地形影响，直接覆盖为道路）
func _carve_road(tiles: Array, walkable: Array, x1: int, y1: int, x2: int, y2: int) -> void:
	var dx = abs(x2 - x1)
	var dy = -abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx + dy
	var cx = x1; var cy = y1
	
	while true:
		if cx >= 0 and cx < MAP_WIDTH and cy >= 0 and cy < MAP_HEIGHT:
			tiles[cy][cx] = TileType.ROAD
			walkable[cy][cx] = true
		if cx == x2 and cy == y2: break
		var e2 = 2 * err
		if e2 >= dy: err += dy; cx += sx
		if e2 <= dx: err += dx; cy += sy


## 确保所有 NPC 坐标在可行走地块
func _sanitize_npc_positions(tiles: Array, walkable: Array, blueprint: Dictionary, fallback_center: Vector2i) -> void:
	for npc in blueprint.get("major_npcs", []):
		var nx = int(npc.get("x", 0)); var ny = int(npc.get("y", 0))
		if not _is_walkable(tiles, walkable, nx, ny):
			var safe = find_nearest_walkable(walkable, nx, ny, fallback_center)
			npc["x"] = safe.x; npc["y"] = safe.y
	
	for npc in blueprint.get("minor_npcs", []):
		var nx = int(npc.get("x", 0)); var ny = int(npc.get("y", 0))
		if not _is_walkable(tiles, walkable, nx, ny):
			var safe = find_nearest_walkable(walkable, nx, ny, fallback_center)
			npc["x"] = safe.x; npc["y"] = safe.y


## 查找最近可行走地块 (BFS)
static func find_nearest_walkable(walkable: Array, start_x: int, start_y: int, fallback: Vector2i) -> Vector2i:
	for dist in range(1, 20):
		for dy in range(-dist, dist + 1):
			for dx in range(-dist, dist + 1):
				var nx = start_x + dx; var ny = start_y + dy
				if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
					if walkable[ny][nx]:
						return Vector2i(nx, ny)
	return fallback


static func _is_walkable(tiles: Array, walkable: Array, x: int, y: int) -> bool:
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT: return false
	return walkable[y][x]


## 用 tiles 数据做安全的位置修正
static func sanitize_single_position(tiles: Array, x: int, y: int, fallback: Vector2i) -> Dictionary:
	# Build walkable from tiles if not provided
	var w: Array = []
	for yy in range(tiles.size()):
		var row: Array = []
		for xx in range(tiles[yy].size()):
			row.append(tiles[yy][xx] not in BLOCKING_TILES)
		w.append(row)
	
	if w.size() > y and y >= 0 and w[y].size() > x and x >= 0:
		if w[y][x]: return {"x": x, "y": y}
	
	var safe = find_nearest_walkable(w, x, y, fallback)
	return {"x": safe.x, "y": safe.y}


# ═══════════ Terrain generators ═══════════

func _generate_border(tiles: Array, walkable: Array) -> void:
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			if x < 2 or x >= MAP_WIDTH - 2 or y < 2 or y >= MAP_HEIGHT - 2:
				if _rand() % 3 == 0:
					tiles[y][x] = TileType.WATER
				else:
					tiles[y][x] = TileType.MOUNTAIN
				walkable[y][x] = false


func _generate_village(tiles: Array, walkable: Array, cx: int, cy: int, w: int, h: int) -> void:
	var house_positions = [
		[cx - 4, cy - 3], [cx + 2, cy - 3], [cx - 4, cy + 2],
		[cx + 2, cy + 2], [cx - 1, cy - 3], [cx - 1, cy + 2]
	]
	for pos in house_positions:
		var hx = pos[0]; var hy = pos[1]
		if hx >= 0 and hx < MAP_WIDTH and hy >= 0 and hy < MAP_HEIGHT:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var tx = hx + dx; var ty = hy + dy
					if tx >= 0 and tx < MAP_WIDTH and ty >= 0 and ty < MAP_HEIGHT:
						tiles[ty][tx] = TileType.HOUSE
						walkable[ty][tx] = false


func _generate_forest(tiles: Array, walkable: Array, cx: int, cy: int, w: int, h: int) -> void:
	for y in range(cy - h / 2, cy + h / 2):
		for x in range(cx - w / 2, cx + w / 2):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				if tiles[y][x] == TileType.GRASS and _rand() % 3 != 0:
					tiles[y][x] = TileType.TREE
					walkable[y][x] = false


func _generate_area(tiles: Array, walkable: Array, cx: int, cy: int, w: int, h: int, tile_type: int) -> void:
	for y in range(cy - h / 2, cy + h / 2):
		for x in range(cx - w / 2, cx + w / 2):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				if tiles[y][x] == TileType.GRASS:
					tiles[y][x] = tile_type
					walkable[y][x] = (tile_type in WALKABLE_TILES)


func _generate_water(tiles: Array, walkable: Array, cx: int, cy: int, w: int, h: int) -> void:
	for y in range(cy - h / 2, cy + h / 2):
		for x in range(cx - w / 2, cx + w / 2):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				var dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2))
				var max_dist = sqrt(pow(w / 2.0, 2) + pow(h / 2.0, 2))
				if dist <= max_dist * 0.7:
					tiles[y][x] = TileType.WATER
					walkable[y][x] = false


func _generate_scattered_trees(tiles: Array, walkable: Array, cx: int, cy: int, w: int, h: int) -> void:
	for y in range(cy - h / 2, cy + h / 2):
		for x in range(cx - w / 2, cx + w / 2):
			if x >= 0 and x < MAP_WIDTH and y >= 0 and y < MAP_HEIGHT:
				if tiles[y][x] == TileType.GRASS and _rand() % 8 == 0:
					tiles[y][x] = TileType.TREE
					walkable[y][x] = false


func _normalize_areas(areas: Array) -> Array:
	var normalized: Array = []
	for area in areas:
		normalized.append(area.to_lower())
	return normalized


static func is_walkable(walkable_data: Array, x: int, y: int) -> bool:
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT: return false
	return walkable_data[y][x]


func _base_tile_for_type(map_type: String) -> int:
	match map_type:
		"cave", "dungeon":
			return TileType.CAVE
		"sect_gate", "sect_inner":
			return TileType.SECT_FLOOR
		"interior", "house", "shop":
			return TileType.SECT_FLOOR
		_:
			return TileType.GRASS


func _generate_dynamic_content(tiles: Array, walkable: Array, map_type: String, locked_paths: Dictionary) -> void:
	var height = tiles.size()
	var width = tiles[0].size() if height > 0 else 0
	var center = Vector2i(width / 2, height / 2)
	_carve_dynamic_road(tiles, walkable, center.x, center.y, max(2, width - 3), center.y, locked_paths)
	_carve_dynamic_road(tiles, walkable, center.x, center.y, center.x, max(2, height - 3), locked_paths)
	_carve_dynamic_road(tiles, walkable, center.x, center.y, 2, center.y, locked_paths)
	match map_type:
		"forest":
			_scatter_dynamic(tiles, walkable, TileType.TREE, 35, locked_paths)
			_scatter_dynamic(tiles, walkable, TileType.WATER, 3, locked_paths)
		"cave", "dungeon":
			_scatter_dynamic(tiles, walkable, TileType.MOUNTAIN, 20, locked_paths)
			_carve_dynamic_road(tiles, walkable, 2, center.y, width - 3, center.y, locked_paths)
		"sect_gate":
			_scatter_dynamic(tiles, walkable, TileType.MOUNTAIN, 10, locked_paths)
			for x in range(max(1, center.x - 8), min(width - 1, center.x + 9)):
				for y in range(max(1, center.y - 4), min(height - 1, center.y + 5)):
					tiles[y][x] = TileType.SECT_FLOOR
					walkable[y][x] = true
		"interior", "house", "shop":
			for y in range(height):
				for x in range(width):
					var wall = x < 2 or y < 2 or x >= width - 2 or y >= height - 2
					tiles[y][x] = TileType.HOUSE if wall else TileType.SECT_FLOOR
					walkable[y][x] = not wall
			tiles[height - 2][center.x] = TileType.ROAD
			walkable[height - 2][center.x] = true
		"secret_realm":
			_scatter_dynamic(tiles, walkable, TileType.WATER, 8, locked_paths)
			_scatter_dynamic(tiles, walkable, TileType.MOUNTAIN, 12, locked_paths)
		_:
			_scatter_dynamic(tiles, walkable, TileType.HOUSE, 3, locked_paths)


func _carve_dynamic_road(tiles: Array, walkable: Array, x1: int, y1: int, x2: int, y2: int, locked_paths: Dictionary) -> void:
	var width = tiles[0].size()
	var height = tiles.size()
	var dx = abs(x2 - x1)
	var dy = -abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx + dy
	var cx = x1
	var cy = y1
	while true:
		if cx >= 0 and cx < width and cy >= 0 and cy < height:
			tiles[cy][cx] = TileType.ROAD
			walkable[cy][cx] = true
			locked_paths["%d,%d" % [cx, cy]] = true
		if cx == x2 and cy == y2:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy


func _scatter_dynamic(tiles: Array, walkable: Array, tile_type: int, chance_percent: int, locked_paths: Dictionary) -> void:
	var height = tiles.size()
	var width = tiles[0].size() if height > 0 else 0
	for y in range(2, height - 2):
		for x in range(2, width - 2):
			if locked_paths.get("%d,%d" % [x, y], false):
				continue
			if _rand() % 100 < chance_percent and tiles[y][x] in WALKABLE_TILES:
				tiles[y][x] = tile_type
				walkable[y][x] = tile_type in WALKABLE_TILES
