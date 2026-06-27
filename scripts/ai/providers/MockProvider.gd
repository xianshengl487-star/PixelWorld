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
		return _default_blueprints[world_type].duplicate(true)
	
	# 返回第一个可用的蓝图
	for key in _default_blueprints:
		return _default_blueprints[key].duplicate(true)
	
	# 最后的保底
	return _get_fallback_blueprint()


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
