extends Node
## WorldState.gd — 全局世界状态 Autoload 单例
## 保存所有游戏运行时状态

const InventoryClass = preload("res://scripts/items/Inventory.gd")

# ============================================
# 世界蓝图
# ============================================
var world_blueprint: Dictionary = {}
var world_name: String = ""
var world_type: String = ""

# ============================================
# 时间系统
# ============================================
var current_day: int = 1
var current_hour: int = 8

# ============================================
# 玩家状态
# ============================================
var player_reputation: int = 0
var player_position: Vector2 = Vector2.ZERO
var player_max_health: int = 20
var player_health: int = 20
var player_max_stamina: int = 10
var player_stamina: int = 10

# ============================================
# 历史记录
# ============================================
var action_history: Array = []
var npc_memory: Dictionary = {}
var discovered_locations: Dictionary = {}
var collected_items: Array = []
var defeated_enemies: Array = []
var current_region: String = ""
var inventory = InventoryClass.new()

# ============================================
# 势力与事件
# ============================================
var faction_states: Dictionary = {}
var event_states: Dictionary = {}

# ============================================
# AI Provider 状态
# ============================================
var ai_provider_status: String = "mock"
var last_errors: Array = []


func _ready() -> void:
	reset_state()


## 重置所有状态（用于新游戏）
func reset_state() -> void:
	world_blueprint = {}
	world_name = ""
	world_type = ""
	current_day = 1
	current_hour = 8
	player_reputation = 0
	player_position = Vector2.ZERO
	player_max_health = 20
	player_health = 20
	player_max_stamina = 10
	player_stamina = 10
	action_history.clear()
	npc_memory.clear()
	discovered_locations.clear()
	collected_items.clear()
	defeated_enemies.clear()
	current_region = ""
	inventory = InventoryClass.new()
	faction_states.clear()
	event_states.clear()
	ai_provider_status = ConfigManager.get_env("AI_PROVIDER", "mock")
	last_errors.clear()


## 设置世界蓝图
func set_world_blueprint(blueprint: Dictionary) -> void:
	world_blueprint = blueprint
	world_name = blueprint.get("world_name", "未知世界")
	world_type = blueprint.get("world_type", "unknown")
	current_region = blueprint.get("start_region", "")
	player_position = Vector2(
		blueprint.get("player_spawn", {}).get("x", 20),
		blueprint.get("player_spawn", {}).get("y", 20)
	)
	player_health = player_max_health
	player_stamina = player_max_stamina
	
	# 初始化势力状态
	for faction in blueprint.get("factions", []):
		var fid = faction.get("id", "")
		faction_states[fid] = {
			"attitude_to_player": faction.get("attitude_to_player", 0),
			"name": faction.get("name", fid)
		}
	
	# 初始化事件状态
	for event in blueprint.get("events", []):
		var eid = event.get("id", "")
		event_states[eid] = {
			"active": true,
			"name": event.get("name", eid),
			"progress": 0
		}


## 记录玩家行动
func log_action(action: String, result: Dictionary = {}) -> void:
	var entry = {
		"day": current_day,
		"hour": current_hour,
		"time": Time.get_datetime_string_from_system(),
		"action": action,
		"result": result,
		"position": {"x": player_position.x, "y": player_position.y}
	}
	action_history.append(entry)
	GameLog.add_entry("[第%d天 %d:00] %s" % [current_day, current_hour, action])


## 背包操作
func add_item(item_id: String, amount: int = 1) -> void:
	inventory.add_item(item_id, amount)


func remove_item(item_id: String, amount: int = 1) -> bool:
	return inventory.remove_item(item_id, amount)


func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.has_item(item_id, amount)


func get_inventory_items() -> Dictionary:
	return inventory.get_items()


func set_inventory_items(data: Dictionary) -> void:
	inventory.from_dict(data)


## 探索与战斗记录
func discover_location(location_id: String, display_name: String = "") -> void:
	if location_id == "":
		return
	if not discovered_locations.has(location_id):
		discovered_locations[location_id] = {
			"name": display_name if display_name != "" else location_id,
			"day": current_day,
			"hour": current_hour
		}


func mark_enemy_defeated(enemy_id: String) -> void:
	if enemy_id == "":
		return
	if not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)


## 设置 NPC 记忆
func set_npc_memory(npc_id: String, memory_key: String, memory_value) -> void:
	if not npc_memory.has(npc_id):
		npc_memory[npc_id] = {}
	npc_memory[npc_id][memory_key] = memory_value


## 获取 NPC 记忆
func get_npc_memory(npc_id: String, memory_key: String = ""):
	if not npc_memory.has(npc_id):
		return {} if memory_key == "" else null
	if memory_key == "":
		return npc_memory[npc_id]
	return npc_memory[npc_id].get(memory_key, null)


## 记录错误
func log_error(context: String, error_message: String) -> void:
	last_errors.append({
		"time": Time.get_datetime_string_from_system(),
		"context": context,
		"error": error_message
	})
	# 限制错误记录数量
	while last_errors.size() > 50:
		last_errors.pop_front()


## 获取主要 NPC 列表
func get_major_npcs() -> Array:
	var npcs: Array = []
	for npc in world_blueprint.get("major_npcs", []):
		npcs.append(npc)
	return npcs


## 获取小 NPC 列表
func get_minor_npcs() -> Array:
	var npcs: Array = []
	for npc in world_blueprint.get("minor_npcs", []):
		npcs.append(npc)
	return npcs


## 获取所有 NPC
func get_all_npcs() -> Array:
	return get_major_npcs() + get_minor_npcs()


## 获取区域信息
func get_region(region_id: String) -> Dictionary:
	for region in world_blueprint.get("regions", []):
		if region.get("id") == region_id:
			return region
	return {}


## 获取势力对玩家态度
func get_faction_attitude(faction_id: String) -> int:
	if faction_states.has(faction_id):
		return faction_states[faction_id].get("attitude_to_player", 0)
	return 0


## 修改势力对玩家态度
func modify_faction_attitude(faction_id: String, delta: int) -> void:
	if not faction_states.has(faction_id):
		return
	faction_states[faction_id]["attitude_to_player"] += delta


## 设置事件进度
func set_event_progress(event_id: String, progress: int) -> void:
	if event_states.has(event_id):
		event_states[event_id]["progress"] = progress


## 获取事件
func get_active_events() -> Array:
	var active: Array = []
	for eid in event_states:
		if event_states[eid].get("active", false):
			active.append(eid)
	return active
