extends "res://scripts/ai/providers/AIProvider.gd"
class_name MockProvider
## MockProvider.gd — 离线/Mock Provider
## 当云端 AI 不可用时，使用本地默认数据

## 默认世界蓝图（根据提示词选择匹配的世界类型）
var _default_blueprints: Dictionary = {}


func _init() -> void:
	_load_default_blueprints()


func _load_default_blueprints() -> void:
	var blueprint_types = ["xianxia", "apocalypse", "cyberpunk"]
	for type in blueprint_types:
		var path = "res://data/default_blueprints/" + type + "_default.json"
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var text = file.get_as_text()
				file.close()
				var json = JSON.parse_string(text)
				if json:
					_default_blueprints[type] = json


## 生成世界蓝图（从本地默认数据）
func generate_world_blueprint(prompt: String) -> Dictionary:
	# 尝试根据描述词匹配世界类型
	var world_type = _detect_world_type(prompt)
	
	if _default_blueprints.has(world_type):
		return _ensure_multimap_blueprint(_default_blueprints[world_type].duplicate(true))
	
	# 返回第一个可用的蓝图
	for key in _default_blueprints:
		return _ensure_multimap_blueprint(_default_blueprints[key].duplicate(true))
	
	# 最后的保底
	return _ensure_multimap_blueprint(_get_fallback_blueprint())


## 从提示词检测世界类型
func _detect_world_type(prompt: String) -> String:
	var lower = prompt.to_lower()
	if "仙" in prompt or "修真" in prompt or "修仙" in prompt or "宗门" in prompt:
		return "xianxia"
	if "末日" in prompt or "废土" in prompt or "僵尸" in prompt or "末世" in prompt:
		return "apocalypse"
	if "赛博" in prompt or "cyber" in prompt or "科技" in prompt or "黑客" in prompt:
		return "cyberpunk"
	return "xianxia"  # 默认


## 生成主要 NPC 回复（预设对话）
func generate_major_npc_reply(context: Dictionary) -> Dictionary:
	var npc_name = context.get("npc_name", "NPC")
	var npc_role = context.get("npc_role", "villager")
	var initial_dialogue = context.get("initial_dialogue", "")
	
	var replies = {
		"quest_giver": [
			"勇敢的冒险者，我需要你的帮助。",
			"最近发生了一些不寻常的事情，你有兴趣了解一下吗？",
			"你的实力不错，也许能帮我解决一些问题。"
		],
		"elder": [
			"年轻人，这个世界比你看到的复杂得多。",
			"古老的预言中提到过像你这样的人。",
			"小心行事，这个世界的平衡岌岌可危。"
		],
		"merchant": [
			"看看我的货物，都是好东西。",
			"最近进货不太顺利，山路越来越危险了。",
			"你有钱吗？没钱的话就看看好了。"
		],
		"enemy": [
			"哼，你挡住我的路了。",
			"这里不是你能来的地方。",
			"看来你还不明白自己的处境。"
		]
	}
	
	var dialogue = ""
	if initial_dialogue != "":
		dialogue = initial_dialogue
	elif replies.has(npc_role):
		dialogue = replies[npc_role][randi() % replies[npc_role].size()]
	else:
		dialogue = "有什么事吗？"
	
	return {
		"dialogue": dialogue,
		"attitude_change": randi() % 3,
		"memory_to_add": null,
		"event_trigger": null,
		"world_changes": []
	}


## 生成小型 NPC 回复（由 LocalTinyNpcProvider 处理）
func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
	return {"dialogue": "你好。"}


## 解读玩家行动（简单规则）
func interpret_player_action(context: Dictionary) -> Dictionary:
	var player_input = context.get("player_input", "")
	var lower_input = player_input.to_lower()
	
	var action_type = "other"
	var interpretation = "你什么都没做。"
	
	if "观察" in player_input or "看" in player_input or "look" in lower_input:
		action_type = "observe"
		interpretation = "你仔细观察了周围的环境。"
	elif "问" in player_input or "询问" in player_input or "ask" in lower_input:
		action_type = "talk"
		interpretation = "你主动与人交谈。"
	elif "攻击" in player_input or "打" in player_input or "attack" in lower_input:
		action_type = "attack"
		interpretation = "你发动了攻击。周围的人变得警惕起来。"
	elif "去" in player_input or "走" in player_input or "move" in lower_input:
		action_type = "move"
		interpretation = "你开始向目标方向前进。"
	elif "谣言" in player_input or "散播" in player_input:
		action_type = "spread_rumor"
		interpretation = "你开始散播消息。村民们交头接耳。"
	elif "调查" in player_input or "侦查" in player_input:
		action_type = "investigate"
		interpretation = "你开始仔细调查。"
	
	return {
		"interpretation": interpretation,
		"action_type": action_type,
		"world_changes": [],
		"narrative_result": interpretation
	}


## 绝对保底的世界蓝图
func _get_fallback_blueprint() -> Dictionary:
	return {
		"world_name": "无名之地",
		"world_type": "xianxia",
		"tone": "adventure",
		"start_region": "starting_village",
		"player_spawn": {"x": 20, "y": 20},
		"regions": [
			{"id": "starting_village", "name": "起始村", "type": "village", "safety": 90},
			{"id": "nearby_forest", "name": "附近森林", "type": "danger_zone", "safety": 50}
		],
		"factions": [
			{"id": "villagers", "name": "村民", "type": "civilian", "attitude_to_player": 0}
		],
		"major_npcs": [
			{
				"id": "village_elder",
				"name": "老村长",
				"role": "quest_giver",
				"importance": "major",
				"personality": ["和蔼", "智慧"],
				"goal": "保护村子",
				"x": 22,
				"y": 18,
				"initial_dialogue": "年轻人，欢迎来到我们村子。最近森林里不太太平，你要小心。"
			}
		],
		"minor_npcs": [
			{
				"id": "villager_01",
				"name": "村民甲",
				"role": "villager",
				"importance": "minor",
				"x": 18,
				"y": 24,
				"dialogue_profile": "普通村民，担心森林里的动静。"
			},
			{
				"id": "guard_01",
				"name": "守卫",
				"role": "guard",
				"importance": "minor",
				"x": 25,
				"y": 22,
				"dialogue_profile": "村口守卫，负责警戒。"
			}
		],
		"events": [
			{"id": "forest_threat", "name": "森林异动", "description": "附近森林出现了异常动静，村民感到不安。"}
		],
		"map_blueprint": {
			"size": {"width": 64, "height": 64},
			"required_areas": ["village", "forest", "mountain", "cave"],
			"connections": [["village", "forest"], ["forest", "cave"], ["forest", "mountain"]]
		}
	}


func _ensure_multimap_blueprint(blueprint: Dictionary) -> Dictionary:
	if not blueprint.has("seed"):
		blueprint["seed"] = abs(str(blueprint.get("world_name", "PixelWorld")).hash())
	if not blueprint.has("start_map_id"):
		blueprint["start_map_id"] = "village_001"
	if not blueprint.has("maps") or not (blueprint["maps"] is Array) or blueprint["maps"].is_empty():
		blueprint["maps"] = [
			{"map_id": "village_001", "display_name": "青木村", "map_type": "village", "size": [96, 96], "danger_level": 0},
			{"map_id": "forest_001", "display_name": "黑松后山", "map_type": "forest", "size": [128, 128], "danger_level": 2},
			{"map_id": "cave_001", "display_name": "残破洞府", "map_type": "cave", "size": [64, 64], "danger_level": 3},
			{"map_id": "sect_gate_001", "display_name": "云岚宗山门", "map_type": "sect_gate", "size": [128, 128], "danger_level": 1}
		]
	if not blueprint.has("connections") or not (blueprint["connections"] is Array) or blueprint["connections"].is_empty():
		blueprint["connections"] = [
			{"connection_id": "village_to_forest", "from_map_id": "village_001", "to_map_id": "forest_001", "connection_type": "edge_exit", "from_spawn_id": "east_exit", "to_spawn_id": "from_village"},
			{"connection_id": "forest_to_village", "from_map_id": "forest_001", "to_map_id": "village_001", "connection_type": "edge_exit", "from_spawn_id": "from_village", "to_spawn_id": "from_forest"},
			{"connection_id": "forest_to_cave", "from_map_id": "forest_001", "to_map_id": "cave_001", "connection_type": "cave_entrance", "from_spawn_id": "cave_entry", "to_spawn_id": "entrance"},
			{"connection_id": "cave_to_forest", "from_map_id": "cave_001", "to_map_id": "forest_001", "connection_type": "cave_entrance", "from_spawn_id": "entrance", "to_spawn_id": "from_cave"},
			{"connection_id": "forest_to_sect_gate", "from_map_id": "forest_001", "to_map_id": "sect_gate_001", "connection_type": "sect_gate", "from_spawn_id": "sect_road", "to_spawn_id": "from_forest", "required_realm_order": 0, "locked_message": "守门弟子拦住了你。"},
			{"connection_id": "sect_gate_to_forest", "from_map_id": "sect_gate_001", "to_map_id": "forest_001", "connection_type": "sect_gate", "from_spawn_id": "from_forest", "to_spawn_id": "from_sect_gate"}
		]
	_ensure_building_interiors(blueprint)
	if not blueprint.has("main_path"):
		blueprint["main_path"] = ["village_001", "forest_001", "sect_gate_001"]
	if not blueprint.has("side_paths"):
		blueprint["side_paths"] = [["forest_001", "cave_001"]]
	return blueprint


func _ensure_building_interiors(blueprint: Dictionary) -> void:
	var buildings = [
		{"building_id": "chief_house_001", "building_type": "chief_house", "display_name": "Chief House"},
		{"building_id": "apothecary_001", "building_type": "apothecary", "display_name": "Apothecary"},
		{"building_id": "blacksmith_001", "building_type": "blacksmith", "display_name": "Blacksmith"},
		{"building_id": "inn_001", "building_type": "inn", "display_name": "Inn"},
		{"building_id": "general_store_001", "building_type": "general_store", "display_name": "General Store"}
	]
	var existing_maps: Dictionary = {}
	for map_data in blueprint.get("maps", []):
		existing_maps[str(map_data.get("map_id", ""))] = true
	var existing_connections: Dictionary = {}
	for connection in blueprint.get("connections", []):
		existing_connections[str(connection.get("connection_id", ""))] = true
	for building in buildings:
		var building_id = str(building.get("building_id", ""))
		var interior_id = "%s_interior" % building_id
		var door_spawn = "%s_door" % building_id
		if not existing_maps.has(interior_id):
			blueprint["maps"].append({
				"map_id": interior_id,
				"display_name": "%s Interior" % str(building.get("display_name", building_id)),
				"map_type": "interior",
				"size": [32, 32],
				"danger_level": 0,
				"parent_map_id": "village_001",
				"parent_building_id": building_id,
				"parent_spawn_id": door_spawn,
				"building_type": str(building.get("building_type", ""))
			})
		var enter_id = "village_to_%s" % interior_id
		if not existing_connections.has(enter_id):
			blueprint["connections"].append({
				"connection_id": enter_id,
				"from_map_id": "village_001",
				"to_map_id": interior_id,
				"connection_type": "building_door",
				"from_spawn_id": door_spawn,
				"to_spawn_id": "default"
			})
		var exit_id = "%s_to_village" % interior_id
		if not existing_connections.has(exit_id):
			blueprint["connections"].append({
				"connection_id": exit_id,
				"from_map_id": interior_id,
				"to_map_id": "village_001",
				"connection_type": "door_exit",
				"from_spawn_id": "exit",
				"to_spawn_id": door_spawn
			})
