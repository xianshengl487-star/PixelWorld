extends Node
## WorldState.gd — 全局世界状态 Autoload 单例
## 保存所有游戏运行时状态

const InventoryClass = preload("res://scripts/items/Inventory.gd")
const ProgressionTemplateLoaderClass = preload("res://scripts/progression/ProgressionTemplateLoader.gd")
const WorldGraphClass = preload("res://scripts/world/WorldGraph.gd")

# ============================================
# 世界蓝图
# ============================================
var world_blueprint: Dictionary = {}
var world_name: String = ""
var world_type: String = ""
var current_world_instance = null
var current_world_graph = null
var current_map_id: String = ""
var visited_maps: Dictionary = {}
var map_states: Dictionary = {}
var world_graph_data: Dictionary = {}
var global_flags: Dictionary = {}
var player_position_by_map: Dictionary = {}
var last_spawn_id: String = "default"

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
var player_stats: Dictionary = {}

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
# 世界观成长系统
# ============================================
var progression_data: Dictionary = {}
var unlocked_features: Dictionary = {}
var world_rule_modifiers: Dictionary = {}
var realm_history: Array = []
var tribulation_record: Array = []
var breakthrough_history: Array = []

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
	current_world_instance = null
	current_world_graph = null
	current_map_id = ""
	visited_maps.clear()
	map_states.clear()
	world_graph_data = {}
	global_flags.clear()
	player_position_by_map.clear()
	last_spawn_id = "default"
	current_day = 1
	current_hour = 8
	player_reputation = 0
	player_position = Vector2.ZERO
	player_max_health = 20
	player_health = 20
	player_max_stamina = 10
	player_stamina = 10
	player_stats = {}
	action_history.clear()
	npc_memory.clear()
	discovered_locations.clear()
	collected_items.clear()
	defeated_enemies.clear()
	current_region = ""
	inventory = InventoryClass.new()
	faction_states.clear()
	event_states.clear()
	progression_data = _default_progression_data()
	unlocked_features.clear()
	world_rule_modifiers.clear()
	realm_history.clear()
	tribulation_record.clear()
	breakthrough_history.clear()
	ai_provider_status = ConfigManager.get_env("AI_PROVIDER", "mock")
	last_errors.clear()


## 设置世界蓝图
func set_world_blueprint(blueprint: Dictionary) -> void:
	world_blueprint = blueprint
	world_name = blueprint.get("world_name", "未知世界")
	world_type = blueprint.get("world_type", "unknown")
	_setup_world_graph_data(blueprint)
	current_map_id = blueprint.get("start_map_id", current_map_id)
	if current_map_id != "":
		mark_map_visited(current_map_id)
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

	var template = ProgressionTemplateLoaderClass.new().load_template(world_type)
	if not template.is_empty():
		init_progression(world_type, template)


func get_world_graph():
	if current_world_graph == null and not world_graph_data.is_empty():
		current_world_graph = WorldGraphClass.new()
		current_world_graph.setup(world_graph_data)
	return current_world_graph


func set_world_graph(graph) -> void:
	current_world_graph = graph
	world_graph_data = graph.to_save_data() if graph != null and graph.has_method("to_save_data") else {}


func mark_map_visited(map_id: String) -> void:
	if map_id != "":
		visited_maps[map_id] = true


func is_map_visited(map_id: String) -> bool:
	return bool(visited_maps.get(map_id, false))


func get_map_state(map_id: String) -> Dictionary:
	return map_states.get(map_id, {}).duplicate(true)


func set_map_state(map_id: String, state: Dictionary) -> void:
	if map_id != "":
		map_states[map_id] = state.duplicate(true)


func set_current_map_id(map_id: String, spawn_id: String = "default") -> void:
	current_map_id = map_id
	last_spawn_id = spawn_id
	mark_map_visited(map_id)
	if current_world_graph != null and current_world_graph.has_method("set_current_map"):
		current_world_graph.set_current_map(map_id)
		world_graph_data = current_world_graph.to_save_data()


## 初始化世界观成长体系
func init_progression(next_world_type: String, template: Dictionary) -> void:
	progression_data = _default_progression_data()
	world_type = next_world_type
	var realms = template.get("realms", [])
	var first_realm = realms[0] if realms.size() > 0 else {}
	var stages = first_realm.get("minor_stages", [])
	progression_data["world_type"] = next_world_type
	progression_data["system_id"] = template.get("system_id", "")
	progression_data["system_name"] = template.get("display_name", "")
	progression_data["exp_label"] = template.get("exp_label", "")
	progression_data["stage_label"] = template.get("stage_label", "")
	progression_data["breakthrough_label"] = template.get("breakthrough_label", "")
	progression_data["current_realm_id"] = first_realm.get("id", "")
	progression_data["current_realm_name"] = first_realm.get("name", "")
	progression_data["current_realm_order"] = int(first_realm.get("order", 0))
	progression_data["current_stage"] = 0
	progression_data["current_stage_name"] = str(stages[0]) if stages.size() > 0 else ""
	progression_data["progress_to_next"] = _progress_to_next_for_realm(first_realm)
	progression_data["realm_history"] = realm_history
	progression_data["breakthrough_history"] = breakthrough_history
	progression_data["tribulation_record"] = tribulation_record
	progression_data["unlocked_features"] = unlocked_features.keys()
	progression_data["world_modifiers"] = world_rule_modifiers
	for feature in first_realm.get("unlock_features", []):
		unlock_feature(str(feature))
	GameLog.add_entry("成长体系已初始化: %s" % progression_data["system_name"])


func get_progression_summary() -> Dictionary:
	var summary = progression_data.duplicate(true)
	summary["unlocked_features"] = unlocked_features.keys()
	summary["world_modifiers"] = world_rule_modifiers.duplicate(true)
	summary["realm_history"] = realm_history
	summary["breakthrough_history"] = breakthrough_history
	summary["tribulation_record"] = tribulation_record
	return summary


func add_progression_history(entry: Dictionary) -> void:
	realm_history.append(entry)
	progression_data["realm_history"] = realm_history
	log_action("成长记录: %s" % entry.get("stage_name", entry.get("type", "progression")), entry)


func add_breakthrough_record(entry: Dictionary) -> void:
	breakthrough_history.append(entry)
	progression_data["breakthrough_history"] = breakthrough_history
	log_action("突破记录: %s" % entry.get("result", "unknown"), entry)


func add_tribulation_record(entry: Dictionary) -> void:
	tribulation_record.append(entry)
	progression_data["tribulation_record"] = tribulation_record
	log_action("劫难记录: %s" % entry.get("event", "tribulation"), entry)


func unlock_feature(feature_id: String) -> void:
	if feature_id == "":
		return
	unlocked_features[feature_id] = true
	progression_data["unlocked_features"] = unlocked_features.keys()
	GameLog.add_entry("解锁能力: %s" % feature_id)


func has_feature(feature_id: String) -> bool:
	return unlocked_features.has(feature_id)


func set_world_modifier(modifier_id: String, value) -> void:
	if modifier_id == "":
		return
	world_rule_modifiers[modifier_id] = value
	progression_data["world_modifiers"] = world_rule_modifiers


func get_world_modifier(modifier_id: String, default_value = null):
	return world_rule_modifiers.get(modifier_id, default_value)


func add_progression_points(amount: int, reason: String = "") -> void:
	progression_data["current_progress"] = int(progression_data.get("current_progress", 0)) + max(0, amount)
	var label = progression_data.get("exp_label", "成长")
	if amount > 0:
		GameLog.add_entry("获得 %d 点%s%s" % [amount, label, ("（%s）" % reason) if reason != "" else ""])


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


func _default_progression_data() -> Dictionary:
	return {
		"world_type": "",
		"system_id": "",
		"system_name": "",
		"exp_label": "",
		"stage_label": "",
		"breakthrough_label": "",
		"current_realm_id": "",
		"current_realm_name": "",
		"current_realm_order": 0,
		"current_stage": 0,
		"current_stage_name": "",
		"current_progress": 0,
		"progress_to_next": 0,
		"breakthrough_points": 0,
		"bottleneck": false,
		"bottleneck_reason": "",
		"tribulation_pending": false,
		"tribulation_type": "",
		"failed_breakthroughs": 0,
		"last_breakthrough_result": {},
		"realm_history": [],
		"breakthrough_history": [],
		"tribulation_record": [],
		"unlocked_features": [],
		"world_modifiers": {},
		"special_flags": {}
	}


func _progress_to_next_for_realm(realm: Dictionary) -> int:
	var stages = max(1, realm.get("minor_stages", []).size())
	var required = int(realm.get("breakthrough", {}).get("required_progress", 1))
	return max(1, int(ceil(float(required) / float(stages))))


func _setup_world_graph_data(blueprint: Dictionary) -> void:
	if not blueprint.has("maps") or not blueprint.has("connections"):
		world_graph_data = {}
		current_world_graph = null
		return
	current_world_graph = WorldGraphClass.new()
	current_world_graph.setup(blueprint)
	world_graph_data = current_world_graph.to_save_data()
