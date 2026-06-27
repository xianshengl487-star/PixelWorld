extends RefCounted
class_name MapRepairer
## MapRepairer.gd — 地图修复器

const MapValidatorClass = preload("res://scripts/map/MapValidator.gd")

const MAP_WIDTH: int = 64
const MAP_HEIGHT: int = 64

# 最多修复次数
const MAX_REPAIR_ATTEMPTS: int = 3


## 修复地图
## @param map_data: Dictionary — { tiles, walkable, width, height }
## @param blueprint: Dictionary — 世界蓝图
## @param errors: Array — 校验器返回的错误列表
## @return Dictionary — { "repaired": bool, "map_data": Dictionary, "repair_log": Array }
func repair(map_data: Dictionary, blueprint: Dictionary, errors: Array) -> Dictionary:
	var repair_log: Array = []
	var current_data = _clone_map_data(map_data)
	
	for attempt in range(MAX_REPAIR_ATTEMPTS):
		repair_log.append("修复尝试 %d/%d" % [attempt + 1, MAX_REPAIR_ATTEMPTS])
		
		# 1. 修复出生点
		_repair_spawn_point(current_data, blueprint, repair_log)
		
		# 2. 修复 NPC 位置
		_repair_npc_positions(current_data, blueprint, repair_log)
		
		# 3. 修复道路连通性
		_repair_road_connectivity(current_data, blueprint, repair_log)
		
		# 再次验证
		var validator = MapValidatorClass.new()
		var result = validator.validate(current_data, blueprint)
		
		if result.valid:
			repair_log.append("地图修复成功！")
			return {"repaired": true, "map_data": current_data, "repair_log": repair_log}
		else:
			repair_log.append("仍有 %d 个错误" % result.errors.size())
			errors = result.errors
	
	repair_log.append("达到最大修复次数 (%d)，修复失败" % MAX_REPAIR_ATTEMPTS)
	
	# 加载保底地图模板
	var safe_data = _load_safe_template()
	if safe_data:
		repair_log.append("已使用保底地图模板")
		# 确保出生点在保底模板上可行走
		_sanitize_spawn_on_template(safe_data, blueprint, repair_log)
		return {"repaired": false, "map_data": safe_data, "repair_log": repair_log}
	
	return {"repaired": false, "map_data": current_data, "repair_log": repair_log}


## 修复出生点不可行走
func _repair_spawn_point(map_data: Dictionary, blueprint: Dictionary, log: Array) -> void:
	var walkable = map_data.get("walkable", [])
	var spawn = blueprint.get("player_spawn", {"x": 20, "y": 20})
	var sp_x = int(spawn.get("x", 20))
	var sp_y = int(spawn.get("y", 20))
	
	if sp_x >= 0 and sp_x < MAP_WIDTH and sp_y >= 0 and sp_y < MAP_HEIGHT:
		if walkable[sp_y][sp_x]:
			return  # 已可行走
	
	log.append("修复出生点...")
	
	# 搜索最近的可行走地块
	var nearest = _find_nearest_walkable(walkable, sp_x, sp_y, 10)
	if nearest:
		blueprint["player_spawn"] = {"x": nearest.x, "y": nearest.y}
		log.append("  出生点移动到 (%d, %d)" % [nearest.x, nearest.y])
	else:
		# 强制清理出生点
		var tiles = map_data.get("tiles", [])
		tiles[sp_y][sp_x] = 1  # ROAD
		walkable[sp_y][sp_x] = true
		log.append("  强制清理出生点 (%d, %d)" % [sp_x, sp_y])


## 修复 NPC 位置
func _repair_npc_positions(map_data: Dictionary, blueprint: Dictionary, log: Array) -> void:
	var walkable = map_data.get("walkable", [])
	var all_npcs = []
	
	# 收集所有 NPC
	for npc in blueprint.get("major_npcs", []):
		all_npcs.append(npc)
	for npc in blueprint.get("minor_npcs", []):
		all_npcs.append(npc)
	
	for npc in all_npcs:
		var nx = int(npc.get("x", 0))
		var ny = int(npc.get("y", 0))
		var npc_name = npc.get("name", "NPC")
		
		if nx < 0 or nx >= MAP_WIDTH or ny < 0 or ny >= MAP_HEIGHT:
			# 坐标越界
			var backup = _find_nearest_walkable(walkable, 32, 28, 20)
			if backup:
				npc["x"] = backup.x
				npc["y"] = backup.y
				log.append("  NPC '%s' 坐标越界，移动到 (%d, %d)" % [npc_name, backup.x, backup.y])
			continue
		
		if not walkable[ny][nx]:
			var nearest = _find_nearest_walkable(walkable, nx, ny, 8)
			if nearest:
				npc["x"] = nearest.x
				npc["y"] = nearest.y
				log.append("  NPC '%s' 移动到最近可行走地块 (%d, %d)" % [npc_name, nearest.x, nearest.y])
			else:
				# 强制清理
				map_data["tiles"][ny][nx] = 1  # ROAD
				walkable[ny][nx] = true
				log.append("  强制清理 NPC '%s' 位置 (%d, %d)" % [npc_name, nx, ny])


## 修复道路连通性
func _repair_road_connectivity(map_data: Dictionary, blueprint: Dictionary, log: Array) -> void:
	var walkable = map_data.get("walkable", [])
	var tiles = map_data.get("tiles", [])
	var spawn = blueprint.get("player_spawn", {"x": 20, "y": 20})
	var sp_x = int(spawn.get("x", 20))
	var sp_y = int(spawn.get("y", 20))
	
	var targets = _get_key_targets(blueprint)
	
	for target in targets:
		var tx = target.x
		var ty = target.y
		
		# 检查是否可达
		if not _is_reachable(walkable, sp_x, sp_y, tx, ty):
			log.append("  修复从出生点到 '%s' 的道路..." % target.name)
			_force_build_road(tiles, walkable, sp_x, sp_y, tx, ty)
			log.append("    已修路: (%d,%d) → (%d,%d)" % [sp_x, sp_y, tx, ty])


## 强制修建道路
func _force_build_road(tiles: Array, walkable: Array, x1: int, y1: int, x2: int, y2: int) -> void:
	var dx = abs(x2 - x1)
	var dy = -abs(y2 - y1)
	var sx = 1 if x1 < x2 else -1
	var sy = 1 if y1 < y2 else -1
	var err = dx + dy
	
	var cx = x1
	var cy = y1
	
	while true:
		if cx >= 0 and cx < MAP_WIDTH and cy >= 0 and cy < MAP_HEIGHT:
			tiles[cy][cx] = 1  # ROAD
			walkable[cy][cx] = true
		
		if cx == x2 and cy == y2:
			break
		
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy


## 加载保底地图模板
func _load_safe_template() -> Dictionary:
	var path = "res://data/map_templates/xianxia_safe_start.json"
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(text)
	if json == null:
		return {}
	
	# 将模板转换为 map_data 格式
	var tiles: Array = []
	var walkable: Array = []
	
	for y in range(MAP_HEIGHT):
		var row: Array = []
		var walk_row: Array = []
		var template_row = json.get("tiles", [])
		
		for x in range(MAP_WIDTH):
			var tile = 0
			if y < template_row.size():
				var tr = template_row[y]
				if x < tr.size():
					tile = tr[x]
			
			row.append(tile)
			var is_walkable = tile in [0, 1, 6, 7]  # GRASS, ROAD, CAVE, SECT_FLOOR
			walk_row.append(is_walkable)
		
		tiles.append(row)
		walkable.append(walk_row)
	
	return {
		"tiles": tiles,
		"walkable": walkable,
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT
	}


## 查找最近可行走地块
func _find_nearest_walkable(walkable: Array, start_x: int, start_y: int, max_range: int):
	for dist in range(1, max_range + 1):
		for dy in range(-dist, dist + 1):
			for dx in range(-dist, dist + 1):
				var nx = start_x + dx
				var ny = start_y + dy
				if nx >= 0 and nx < MAP_WIDTH and ny >= 0 and ny < MAP_HEIGHT:
					if walkable[ny][nx]:
						return {"x": nx, "y": ny}
	return null


## 检查可达性
func _is_reachable(walkable: Array, from_x: int, from_y: int, to_x: int, to_y: int) -> bool:
	var visited: Array = []
	for y in range(MAP_HEIGHT):
		var row: Array = []
		for x in range(MAP_WIDTH):
			row.append(false)
		visited.append(row)
	
	var queue: Array = [[from_x, from_y]]
	visited[from_y][from_x] = true
	
	var directions = [[0, 1], [0, -1], [1, 0], [-1, 0]]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var cx = current[0]
		var cy = current[1]
		
		if cx == to_x and cy == to_y:
			return true
		
		for dir in directions:
			var nx = cx + dir[0]
			var ny = cy + dir[1]
			
			if nx < 0 or nx >= MAP_WIDTH or ny < 0 or ny >= MAP_HEIGHT:
				continue
			if visited[ny][nx]:
				continue
			if not walkable[ny][nx]:
				continue
			
			visited[ny][nx] = true
			queue.append([nx, ny])
	
	return false


## 获取关键目标点
func _get_key_targets(blueprint: Dictionary) -> Array:
	var targets: Array = []
	
	for npc in blueprint.get("major_npcs", []):
		targets.append({
			"name": npc.get("name", "NPC"),
			"x": int(npc.get("x", 0)),
			"y": int(npc.get("y", 0))
		})
	
	# 关键区域入口
	var area_positions = {
		"village": {"x": 32, "y": 28},
		"forest": {"x": 32, "y": 12},
		"cave": {"x": 12, "y": 14},
		"sect_gate": {"x": 50, "y": 12},
		"mountain": {"x": 12, "y": 14}
	}
	
	var map_bp = blueprint.get("map_blueprint", {})
	for area in map_bp.get("required_areas", []):
		var area_lower = area.to_lower()
		if area_positions.has(area_lower):
			var pos = area_positions[area_lower]
			targets.append({"name": "(%s入口)" % area, "x": pos.x, "y": pos.y})
	
	return targets


## 在保底模板上确保出生点可行走
func _sanitize_spawn_on_template(safe_data: Dictionary, blueprint: Dictionary, log: Array) -> void:
	var walkable = safe_data.get("walkable", [])
	var tiles = safe_data.get("tiles", [])
	var spawn = blueprint.get("player_spawn", {"x": 20, "y": 20})
	var sx = int(spawn.get("x", 20))
	var sy = int(spawn.get("y", 20))
	
	if sx >= 0 and sx < MAP_WIDTH and sy >= 0 and sy < MAP_HEIGHT:
		if walkable[sy][sx]:
			return  # 已可行走
	
	log.append("保底模板出生点 (%d,%d) 不可行走，修复中..." % [sx, sy])
	
	# 找最近可行走点
	var nearest = _find_nearest_walkable(walkable, sx, sy, 30)
	if nearest:
		blueprint["player_spawn"] = {"x": nearest.x, "y": nearest.y}
		log.append("  出生点移动到保底模板可行走位置 (%d, %d)" % [nearest.x, nearest.y])
	else:
		# 最后的兜底：强制清理(1,1)并设置出生点
		for dx in range(0, 5):
			for dy in range(0, 5):
				var cx = 3 + dx; var cy = 3 + dy
				if cx < MAP_WIDTH and cy < MAP_HEIGHT:
					tiles[cy][cx] = 1; walkable[cy][cx] = true
		blueprint["player_spawn"] = {"x": 5, "y": 5}
		log.append("  强制清理左上方区域，出生点移至 (5, 5)")

## 克隆地图数据
func _clone_map_data(data: Dictionary) -> Dictionary:
	return {
		"tiles": data.get("tiles", []).duplicate(true),
		"walkable": data.get("walkable", []).duplicate(true),
		"width": data.get("width", MAP_WIDTH),
		"height": data.get("height", MAP_HEIGHT)
	}
