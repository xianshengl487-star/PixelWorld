extends RefCounted
class_name WorldBlueprintValidator
## WorldBlueprintValidator.gd — 世界蓝图校验器
## 校验 AI 生成的世界蓝图 JSON 是否符合规范

# 最大允许的地图尺寸
const MAX_MAP_SIZE: int = 128
const MIN_MAP_SIZE: int = 16

# 必须包含的顶层字段
const REQUIRED_FIELDS: Array = [
	"world_name", "world_type", "player_spawn",
	"regions", "factions", "major_npcs", "minor_npcs", "events", "map_blueprint"
]

# 区域必须字段
const REGION_REQUIRED: Array = ["id", "name", "type", "safety"]
# 势力必须字段
const FACTION_REQUIRED: Array = ["id", "name", "type", "attitude_to_player"]
# 主要 NPC 必须字段
const MAJOR_NPC_REQUIRED: Array = ["id", "name", "role", "importance", "x", "y"]
# 小 NPC 必须字段
const MINOR_NPC_REQUIRED: Array = ["id", "name", "role", "importance", "x", "y"]
# 事件必须字段
const EVENT_REQUIRED: Array = ["id", "name"]
# 地图蓝图必须字段
const MAP_BLUEPRINT_REQUIRED: Array = ["size", "required_areas", "connections"]


## 校验世界蓝图
## @param blueprint: Dictionary — 待校验的世界蓝图
## @return Dictionary — { "valid": bool, "errors": Array, "warnings": Array, "fixed_blueprint": Dictionary }
func validate(blueprint: Dictionary) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var fixed = blueprint.duplicate(true)
	
	# 检查顶层字段
	_check_required_fields(fixed, REQUIRED_FIELDS, "顶层", errors, true)
	
	if errors.size() > 0:
		# 尝试补全缺失字段
		_auto_fill_missing_fields(fixed, errors)
	
	# 校验 player_spawn
	var spawn = fixed.get("player_spawn", {})
	var map_size = _get_map_size(fixed)
	if not _validate_coordinates(spawn.get("x", -1), spawn.get("y", -1), map_size.x, map_size.y):
		errors.append("player_spawn 坐标不合法，已重置为 (20, 20)")
		fixed["player_spawn"] = {"x": 20, "y": 20}
	
	# 校验 regions
	var regions = fixed.get("regions", [])
	if regions.size() < 2:
		errors.append("区域数量不足（至少2个），已添加默认区域")
		_regions_ensure_minimum(fixed)
		regions = fixed.get("regions", [])
	
	var region_ids: Array = []
	for i in range(regions.size()):
		var region = regions[i]
		for field in REGION_REQUIRED:
			if not region.has(field):
				errors.append("regions[%d] 缺少字段 '%s'" % [i, field])
				region[field] = _default_for_field(field)
		region_ids.append(region.get("id", ""))
	
	# 校验 factions
	var factions = fixed.get("factions", [])
	for i in range(factions.size()):
		var faction = factions[i]
		for field in FACTION_REQUIRED:
			if not faction.has(field):
				errors.append("factions[%d] 缺少字段 '%s'" % [i, field])
				faction[field] = _default_for_field(field)
	
	# 校验 major_npcs
	var major_npcs = fixed.get("major_npcs", [])
	for i in range(major_npcs.size()):
		var npc = major_npcs[i]
		for field in MAJOR_NPC_REQUIRED:
			if not npc.has(field):
				errors.append("major_npcs[%d] 缺少字段 '%s'" % [i, field])
				npc[field] = _default_for_field(field)
		# 确保 importance 为 major
		npc["importance"] = "major"
		# 校验坐标
		if not _validate_coordinates(npc.get("x", -1), npc.get("y", -1), map_size.x, map_size.y):
			errors.append("major_npcs[%d] (%s) 坐标不合法，已重置" % [i, npc.get("name", "?")])
			npc["x"] = 20 + i * 2
			npc["y"] = 20 + i * 2
	
	if major_npcs.size() < 1:
		errors.append("主要 NPC 数量不足（至少1个），已添加默认NPC")
		fixed["major_npcs"] = [{
			"id": "default_npc",
			"name": "神秘人",
			"role": "quest_giver",
			"importance": "major",
			"personality": ["神秘"],
			"goal": "探索真相",
			"x": 22,
			"y": 18,
			"initial_dialogue": "你终于来了……"
		}]
	
	# 校验 minor_npcs
	var minor_npcs = fixed.get("minor_npcs", [])
	if minor_npcs.size() < 2:
		errors.append("小 NPC 数量不足（至少2个），已添加默认NPC")
		fixed["minor_npcs"] = [
			{"id": "villager_01", "name": "村民甲", "role": "villager", "importance": "minor", "x": 18, "y": 24, "dialogue_profile": "普通村民。"},
			{"id": "guard_01", "name": "守卫乙", "role": "guard", "importance": "minor", "x": 26, "y": 22, "dialogue_profile": "村口守卫。"}
		]
		minor_npcs = fixed.get("minor_npcs", [])
	for i in range(minor_npcs.size()):
		var npc = minor_npcs[i]
		for field in MINOR_NPC_REQUIRED:
			if not npc.has(field):
				errors.append("minor_npcs[%d] 缺少字段 '%s'" % [i, field])
				npc[field] = _default_for_field(field)
		npc["importance"] = "minor"
		if not _validate_coordinates(npc.get("x", -1), npc.get("y", -1), map_size.x, map_size.y):
			errors.append("minor_npcs[%d] (%s) 坐标不合法，已重置" % [i, npc.get("name", "?")])
			npc["x"] = 15 + i * 3
			npc["y"] = 22 + i * 3
	
	# 校验 events
	var events = fixed.get("events", [])
	if events.size() < 1:
		errors.append("事件数量不足（至少1个），已添加默认事件")
		fixed["events"] = [{"id": "default_event", "name": "未知事件", "description": "世界正在发生变化。"}]
	
	for i in range(events.size()):
		var event = events[i]
		for field in EVENT_REQUIRED:
			if not event.has(field):
				errors.append("events[%d] 缺少字段 '%s'" % [i, field])
				event[field] = _default_for_field(field)
	
	# 校验 map_blueprint
	var map_bp = fixed.get("map_blueprint", {})
	for field in MAP_BLUEPRINT_REQUIRED:
		if not map_bp.has(field):
			errors.append("map_blueprint 缺少字段 '%s'" % field)
			map_bp[field] = _default_for_field(field)
	
	# 校验地图尺寸
	var size = map_bp.get("size", {})
	if size.get("width", 0) < MIN_MAP_SIZE or size.get("width", 0) > MAX_MAP_SIZE:
		errors.append("地图宽度不合法，已重置为 64")
		size["width"] = 64
	if size.get("height", 0) < MIN_MAP_SIZE or size.get("height", 0) > MAX_MAP_SIZE:
		errors.append("地图高度不合法，已重置为 64")
		size["height"] = 64
	map_bp["size"] = size
	
	# 校验 connections 引用的区域 ID
	var connections = map_bp.get("connections", [])
	for i in range(connections.size()):
		var conn = connections[i]
		if conn.size() >= 2:
			var from_id = conn[0]
			var to_id = conn[1]
			if from_id not in region_ids:
				errors.append("connections[%d] 源区域 '%s' 不存在" % [i, from_id])
				connections[i] = [region_ids[0], to_id]
			if to_id not in region_ids:
				errors.append("connections[%d] 目标区域 '%s' 不存在" % [i, to_id])
				connections[i] = [from_id, region_ids[regions.size() - 1]]
	
	var valid = errors.size() == 0 or _all_errors_fixable(errors)
	
	return {
		"valid": valid,
		"errors": errors,
		"warnings": warnings,
		"fixed_blueprint": fixed
	}


## 检查必须字段
func _check_required_fields(data: Dictionary, required: Array, context: String, errors: Array, auto_fix: bool = false) -> void:
	for field in required:
		if not data.has(field):
			errors.append("%s 缺少必填字段 '%s'" % [context, field])
			if auto_fix:
				data[field] = _default_for_field(field)


## 自动补全缺失字段
func _auto_fill_missing_fields(data: Dictionary, errors: Array) -> void:
	var defaults = {
		"world_name": "未知世界",
		"world_type": "xianxia",
		"tone": "adventure",
		"start_region": "village",
		"player_spawn": {"x": 20, "y": 20},
		"regions": [
			{"id": "village", "name": "村庄", "type": "village", "safety": 90},
			{"id": "forest", "name": "森林", "type": "danger_zone", "safety": 50}
		],
		"factions": [],
		"major_npcs": [],
		"minor_npcs": [],
		"events": [],
		"map_blueprint": {
			"size": {"width": 64, "height": 64},
			"required_areas": ["village", "forest"],
			"connections": [["village", "forest"]]
		}
	}
	
	for key in defaults:
		if not data.has(key):
			data[key] = defaults[key]


## 校验坐标
func _validate_coordinates(x, y, max_x: int, max_y: int) -> bool:
	return x >= 0 and x < max_x and y >= 0 and y < max_y


## 获取地图尺寸
func _get_map_size(blueprint: Dictionary) -> Vector2:
	if blueprint == null or blueprint.is_empty():
		return Vector2(64, 64)
	var map_bp = blueprint.get("map_blueprint", {})
	if map_bp == null:
		return Vector2(64, 64)
	var size = map_bp.get("size", {"width": 64, "height": 64})
	if size == null:
		return Vector2(64, 64)
	return Vector2(int(size.get("width", 64)), int(size.get("height", 64)))


## 确保至少 2 个区域
func _regions_ensure_minimum(blueprint: Dictionary) -> void:
	var regions = blueprint.get("regions", [])
	if regions.size() < 2:
		var needed = 2 - regions.size()
		for i in range(needed):
			regions.append({
				"id": "region_%d" % (regions.size() + 1),
				"name": "区域%d" % (regions.size() + 1),
				"type": "unknown",
				"safety": 50
			})
	blueprint["regions"] = regions


## 字段默认值
func _default_for_field(field: String):
	var defaults = {
		"id": "auto_generated",
		"name": "未命名",
		"type": "unknown",
		"safety": 50,
		"attitude_to_player": 0,
		"role": "villager",
		"importance": "minor",
		"x": 0,
		"y": 0,
		"size": {"width": 64, "height": 64},
		"required_areas": ["village"],
		"connections": [],
		"events": [],
		"description": "未知事件。"
	}
	return defaults.get(field, null)


## 判断错误是否可修复
func _all_errors_fixable(errors: Array) -> bool:
	# 所有校验错误都在 auto_fix 中处理了，视为可修复
	return true
