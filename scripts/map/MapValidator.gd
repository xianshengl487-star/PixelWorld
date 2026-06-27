extends RefCounted
class_name MapValidator
## MapValidator.gd — 地图校验器
## 校验生成的地图是否满足所有约束

const MAP_WIDTH: int = 64
const MAP_HEIGHT: int = 64


## 校验地图
## @param map_data: Dictionary — { tiles, walkable, width, height }
## @param blueprint: Dictionary — 世界蓝图
## @return Dictionary — { "valid": bool, "errors": Array, "warnings": Array }
func validate(map_data: Dictionary, blueprint: Dictionary) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var walkable = map_data.get("walkable", [])
	var width = int(map_data.get("width", walkable[0].size() if walkable.size() > 0 else MAP_WIDTH))
	var height = int(map_data.get("height", walkable.size() if walkable.size() > 0 else MAP_HEIGHT))
	
	if walkable.size() == 0:
		errors.append("地图数据为空")
		return {"valid": false, "errors": errors, "warnings": warnings}
	
	# 1. 出生点是否可行走
	var spawn = blueprint.get("player_spawn", {"x": 20, "y": 20})
	var sp_x = int(spawn.get("x", 20))
	var sp_y = int(spawn.get("y", 20))
	
	if not _is_walkable(walkable, sp_x, sp_y, width, height):
		errors.append("出生点 (%d, %d) 不可行走" % [sp_x, sp_y])
	
	# 2. 检查所有 NPC 是否在可行走地块
	var all_npcs = []
	var major_npcs = blueprint.get("major_npcs", [])
	var minor_npcs = blueprint.get("minor_npcs", [])
	for npc in major_npcs:
		all_npcs.append(npc)
	for npc in minor_npcs:
		all_npcs.append(npc)
	
	var npc_positions_not_walkable = []
	for npc in all_npcs:
		var nx = int(npc.get("x", 0))
		var ny = int(npc.get("y", 0))
		if not _is_walkable(walkable, nx, ny, width, height):
			npc_positions_not_walkable.append({"id": npc.get("id", ""), "name": npc.get("name", ""), "x": nx, "y": ny})
	
	if npc_positions_not_walkable.size() > 0:
		for item in npc_positions_not_walkable:
			errors.append("NPC '%s' (%d, %d) 不在可行走地块" % [item.name, item.x, item.y])
	
	# 3. 可达性检查
	var reachable_targets = _collect_reachable_targets(blueprint)
	for target in reachable_targets:
		if not _path_exists(walkable, sp_x, sp_y, target.x, target.y, width, height):
			errors.append("出生点到 '%s' (%d, %d) 路径不可达" % [target.name, target.x, target.y])
	
	# 4. 关键地点是否在障碍物上
	var map_bp = blueprint.get("map_blueprint", {})
	var _conn_check = map_bp  # 暂不深度检查
	
	# 5. 检查是否有足够多的可行走区域
	var walkable_count = 0
	for y in range(height):
		for x in range(width):
			if y < walkable.size() and x < walkable[y].size() and walkable[y][x]:
				walkable_count += 1
	
	var total = max(1, width * height)
	var walkable_ratio = float(walkable_count) / float(total)
	if walkable_ratio < 0.3:
		warnings.append("可行走区域占比过低 (%.1f%%)" % (walkable_ratio * 100))
	if walkable_ratio > 0.9:
		warnings.append("可行走区域占比过高 (%.1f%%)，缺少障碍物" % (walkable_ratio * 100))
	
	return {
		"ok": errors.size() == 0,
		"valid": errors.size() == 0,
		"errors": errors,
		"warnings": warnings
	}


## 收集需要可达性检查的目标点
func _collect_reachable_targets(blueprint: Dictionary) -> Array:
	var targets: Array = []
	
	# 主要 NPC 位置
	for npc in blueprint.get("major_npcs", []):
		targets.append({
			"name": npc.get("name", "NPC"),
			"x": int(npc.get("x", 0)),
			"y": int(npc.get("y", 0))
		})
	
	# 地图蓝图中的关键连接区域中心
	var map_bp = blueprint.get("map_blueprint", {})
	var required_areas = map_bp.get("required_areas", [])
	
	# 区域到坐标的映射（基于 MapGenerator 的生成规则）
	var area_positions = {
		"village": {"x": 32, "y": 28},
		"forest": {"x": 32, "y": 12},
		"mountain": {"x": 12, "y": 14},
		"cave": {"x": 12, "y": 14},
		"sect_gate": {"x": 50, "y": 10},
		"water": {"x": 50, "y": 45}
	}
	
	for area in required_areas:
		var area_lower = area.to_lower()
		if area_positions.has(area_lower):
			var pos = area_positions[area_lower]
			targets.append({"name": "(%s入口)" % area, "x": pos.x, "y": pos.y})
	
	return targets


## 检查两点间是否存在路径（BFS）
func _path_exists(walkable: Array, from_x: int, from_y: int, to_x: int, to_y: int, width: int = MAP_WIDTH, height: int = MAP_HEIGHT) -> bool:
	if from_x == to_x and from_y == to_y:
		return true
	if not _is_walkable(walkable, from_x, from_y, width, height):
		return false
	if not _is_walkable(walkable, to_x, to_y, width, height):
		return false
	
	var visited: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
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
			
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			if visited[ny][nx]:
				continue
			if not walkable[ny][nx]:
				continue
			
			visited[ny][nx] = true
			queue.append([nx, ny])
	
	return false


## 获取可行走地块
func _is_walkable(walkable: Array, x: int, y: int, width: int = MAP_WIDTH, height: int = MAP_HEIGHT) -> bool:
	if x < 0 or x >= width or y < 0 or y >= height:
		return false
	if y >= walkable.size() or x >= walkable[y].size():
		return false
	return walkable[y][x]
