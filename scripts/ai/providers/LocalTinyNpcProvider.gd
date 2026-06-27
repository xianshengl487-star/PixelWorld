extends "res://scripts/ai/providers/AIProvider.gd"
class_name LocalTinyNpcProvider
## LocalTinyNpcProvider.gd — 本地小型 NPC 对话 Provider
## 第一版使用规则匹配，后续可替换为本地小模型

# 角色模板回复池
var _role_templates: Dictionary = {}
# 当前世界事件缓存
var _world_events: Array = []


func _init() -> void:
	_init_templates()


func _init_templates() -> void:
	_role_templates = {
		"villager": {
			"greetings": ["你好啊。", "今天天气不错。", "你看起来不像本地人。"],
			"topics": {
				"安全": ["最近村子周边还算太平。", "后山那边最近有点不对劲。", "我们有守卫巡逻，还算安全。"],
				"传闻": ["听说东边来了个游方道士。", "村长最近好像收到了什么消息。", "集市上的人都在议论森林里的动静。"],
				"天气": ["看天色，明天可能会下雨。", "这个季节山里经常起雾。", "今年收成应该不错。"],
				"村庄": ["我们村不大，但大家都很团结。", "村口那口井有上百年的历史了。", "每逢节日，村里都会很热闹。"]
			},
			"default": ["这个我也不太清楚。", "你去问问别人吧。", "嗯……让我想想。"]
		},
		"merchant": {
			"greetings": ["需要点什么吗？", "随便看看！", "好货不等人啊！"],
			"topics": {
				"食物": ["粮食价格最近涨了。", "我这里有刚进的干粮，保存得很好。", "听说南方的粮食减产了。"],
				"商品": ["武器我这里没有，你得找铁匠。", "药材要去药铺买。", "这条项链可是稀罕物。"],
				"路况": ["去镇上的路不太好走，最近常有野兽出没。", "山路最近塌方了，得绕道。", "往南走的路还算安全。"],
				"物价": ["做生意不容易啊。", "最近药材涨得厉害。", "矿区的物资也短缺了。"]
			},
			"default": ["这个嘛……你要是买点东西我就告诉你。", "打听消息也要有点诚意不是？"]
		},
		"guard": {
			"greetings": ["站住！", "出示通行证。", "有事吗？"],
			"topics": {
				"通行": ["没有通行证不能进去。", "村内通行自由，但晚上会宵禁。", "山那边就不归我们管了。"],
				"警戒": ["我们24小时轮班。", "最近加强了巡逻。", "只要我在，这个门就守得住。"],
				"法律": ["村规很简单：不偷不抢不伤人。", "违反规矩可不会有好果子吃。", "村长说了算。"],
				"威胁": ["有什么异常情况立刻报告。", "看到可疑的人要及时上报。", "你是陌生人，把你的目的说清楚。"]
			},
			"default": ["没事的话就请离开。", "不要在这里逗留。"]
		},
		"wanderer": {
			"greetings": ["你也出来走走？", "今天的风很舒服。", "一个人旅行吗？"],
			"topics": {
				"天气": ["看远方有乌云，恐怕要变天了。", "这种天气最适合赶路了。", "起风了，山里可能会冷。"],
				"传闻": ["我听到过一些有趣的事情……", "北边好像发现了什么东西。", "最近妖兽活动得格外频繁。"],
				"事件": ["听说森林里出现了奇怪的光芒。", "洞窟那边好像出了什么事。", "有几个猎户好几天没回来了。"],
				"旅行": ["远方有更广阔的世界。", "路还长着呢。", "世界比你想象的大得多。"]
			},
			"default": ["我也不太清楚。", "也许有人知道。", "江湖上的事，谁也说不准。"]
		}
	}


## 更新世界事件（从 WorldState 获取）
func _update_world_events() -> void:
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		var ws = root.root.get_node_or_null("WorldState")
		if ws and ws.has_method("get_active_events"):
			_world_events = ws.get_active_events()


## 生成小型 NPC 回复
func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
	var npc_role = context.get("npc_role", "villager")
	var dialogue_profile = context.get("dialogue_profile", "")
	var player_input = context.get("player_input", "")
	
	var templates = _role_templates.get(npc_role, _role_templates["villager"])
	
	var dialogue = ""
	
	if player_input != "":
		# 尝试匹配话题
		dialogue = _match_topic(player_input, templates)
	
	if dialogue == "":
		# 使用 greeting 或 default
		var greetings = templates.get("greetings", ["你好。"])
		dialogue = greetings[randi() % greetings.size()]
	
	return {
		"dialogue": dialogue,
		"attitude_change": 0,
		"memory_to_add": null,
		"event_trigger": null,
		"world_changes": []
	}


## 话题匹配
func _match_topic(input: String, templates: Dictionary) -> String:
	var lower = input.to_lower()
	var topics = templates.get("topics", {})
	
	# 关键词匹配
	for topic in topics:
		var keywords = _get_topic_keywords(topic)
		for kw in keywords:
			if kw in lower:
				var replies = topics[topic]
				return replies[randi() % replies.size()]
	
	return ""


## 话题关键词映射
func _get_topic_keywords(topic: String) -> Array:
	var mapping = {
		"安全": ["安全", "危险", "妖兽", "怪物", "害怕", "威胁"],
		"传闻": ["听说", "传闻", "消息", "知道", "什么事"],
		"天气": ["天气", "下雨", "刮风", "太阳", "冷", "热"],
		"村庄": ["村子", "村", "这里", "地方", "家乡"],
		"食物": ["吃", "粮食", "食物", "干粮", "肉", "菜"],
		"商品": ["买", "卖", "商品", "东西", "武器", "药"],
		"路况": ["路", "走", "去", "山", "道路"],
		"物价": ["价格", "贵", "便宜", "钱"],
		"通行": ["进", "通过", "通行证", "进去", "进入"],
		"警戒": ["警戒", "巡逻", "守卫", "保护", "安全"],
		"法律": ["规矩", "法律", "规定", "处罚", "罚"],
		"威胁": ["可疑", "坏人", "报告", "危险"],
		"事件": ["发生", "事故", "出事", "异动", "森林"],
		"旅行": ["旅行", "远方", "世界", "冒险", "路"]
	}
	return mapping.get(topic, [topic])
