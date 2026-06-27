extends "res://scripts/ai/providers/AIProvider.gd"
class_name MimoProvider
## MimoProvider.gd — MiMo 云端 AI Provider
## 通过 OpenAI-compatible API 调用 MiMo 模型

var _api_key: String = ""
var _base_url: String = ""
var _world_model: String = ""
var _npc_model: String = ""
var _http: HTTPRequest = null


func _init() -> void:
	# 安全获取配置（可能在 extends SceneTree 上下文中不可用）
	_api_key = _get_config("MIMO_API_KEY", "")
	_base_url = _get_config("MIMO_BASE_URL", "")
	_world_model = _get_config("MIMO_WORLD_MODEL", "mimo-world-model")
	_npc_model = _get_config("MIMO_MAJOR_NPC_MODEL", "mimo-npc-model")
	
	if _api_key == "":
		push_warning("[MimoProvider] MIMO_API_KEY 未配置！")
	
	_http = HTTPRequest.new()
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		root.root.add_child(_http)


func _get_config(key: String, default: String) -> String:
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		var cm = root.root.get_node_or_null("ConfigManager")
		if cm and cm.has_method("get_env"):
			return cm.get_env(key, default)
	return default


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _http:
		_http.queue_free()


## 生成世界蓝图
func generate_world_blueprint(prompt: String) -> Dictionary:
	var system_prompt = _get_world_blueprint_system_prompt()
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": prompt}
	]
	
	var response = await _call_api(messages, _world_model, 2048)
	return _parse_json_response(response)


## 生成主要 NPC 回复
func generate_major_npc_reply(context: Dictionary) -> Dictionary:
	var system_prompt = _get_npc_dialogue_system_prompt()
	var user_content = JSON.stringify(context)
	
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": user_content}
	]
	
	var response = await _call_api(messages, _npc_model, 1024)
	return _parse_json_response(response)


## 生成小型 NPC 回复（可能需要云端）
func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
	# 小 NPC 不应调用此方法，应由 LocalTinyNpcProvider 处理
	return {"dialogue": "你好，旅行者。"}


## 解读玩家行动
func interpret_player_action(context: Dictionary) -> Dictionary:
	var system_prompt = _get_action_interpreter_system_prompt()
	var user_content = JSON.stringify(context)
	
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": user_content}
	]
	
	var response = await _call_api(messages, _npc_model, 1024)
	return _parse_json_response(response)


## 调用 OpenAI-compatible API
func _call_api(messages: Array, model: String, max_tokens: int = 2048) -> Dictionary:
	if _api_key == "":
		return {"error": "MIMO_API_KEY 未配置"}
	
	var body = {
		"model": model,
		"messages": messages,
		"max_tokens": max_tokens,
		"temperature": 0.7,
		"response_format": {"type": "json_object"}
	}
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + _api_key
	]
	
	var url = _base_url.trim_suffix("/") + "/chat/completions"
	
	_http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	var response_data = await _http.request_completed
	
	return _handle_http_response(response_data)


## 处理 HTTP 响应
func _handle_http_response(response_data) -> Dictionary:
	if response_data == null:
		return {"error": "HTTP 请求返回空"}
	
	var result = response_data[0]
	var response_code = response_data[1]
	var headers = response_data[2]
	var body_bytes = response_data[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"error": "HTTP 请求失败: %d" % result}
	
	if response_code != 200:
		var body_text = body_bytes.get_string_from_utf8()
		return {"error": "API 返回错误 %d: %s" % [response_code, body_text]}
	
	var body_text = body_bytes.get_string_from_utf8()
	var json = JSON.parse_string(body_text)
	
	if json == null:
		return {"error": "无法解析 API 返回的 JSON: " + body_text}
	
	# 提取 choices[0].message.content
	var choices = json.get("choices", [])
	if choices.size() == 0:
		return {"error": "API 返回了空的 choices"}
	
	var message = choices[0].get("message", {})
	var content = message.get("content", "")
	
	if content == "":
		return {"error": "API 返回了空内容"}
	
	# 尝试将 content 解析为 JSON
	var content_json = JSON.parse_string(content)
	if content_json != null:
		return content_json
	else:
		return {"error": "API 返回的不是有效 JSON: " + content}


## 解析 JSON 响应（带错误处理）
func _parse_json_response(response: Dictionary) -> Dictionary:
	if response.get("error", "") != "":
		return response
	return response


## 世界蓝图生成的 System Prompt
func _get_world_blueprint_system_prompt() -> String:
	return """你是一个游戏世界生成器。根据玩家输入的一句话描述，生成一个完整的游戏世界蓝图。

你必须返回严格的 JSON，不包含任何其他文本。

JSON 格式必须包含以下字段：
- world_name: 世界名称 (字符串)
- world_type: 世界类型，如 xianxia/apocalypse/cyberpunk/fantasy (字符串)
- tone: 世界观基调，如 adventure/dark/mystery (字符串)
- start_region: 玩家起始区域 ID (字符串)
- player_spawn: 玩家出生坐标 {"x": int, "y": int}
- regions: 区域列表，每项含 id, name, type, safety
- factions: 势力列表，每项含 id, name, type, attitude_to_player
- major_npcs: 主要 NPC 列表，每项含 id, name, role, importance="major", personality, goal, x, y, initial_dialogue
- minor_npcs: 小 NPC 列表，每项含 id, name, role, importance="minor", x, y, dialogue_profile
- events: 事件列表，每项含 id, name, description
- map_blueprint: 地图蓝图，含 size {"width":64, "height":64}, required_areas, connections

重要：所有坐标必须在 0-63 范围内。至少包含 2 个区域、1 个主要 NPC、1 个事件。"""


## NPC 对话生成的 System Prompt
func _get_npc_dialogue_system_prompt() -> String:
	return """你是一个游戏 NPC 对话生成器。根据 NPC 的上下文信息，生成自然而符合角色设定的回复。

你必须返回严格的 JSON：
{
  "dialogue": "NPC说的话语",
  "attitude_change": 整数(-10到10, 表示对玩家态度变化),
  "memory_to_add": "需要记录的新记忆，或null",
  "event_trigger": "触发的事件ID，或null",
  "world_changes": []
}

注意：
- 对话要符合NPC性格和角色
- 态度变化要合理（一次对话最多变化5点）
- 只在确实有必要时触发事件
- 不要输出任何 JSON 以外的文本"""


## 玩家行动解读的 System Prompt
func _get_action_interpreter_system_prompt() -> String:
	return """你是一个游戏行动解读器。解读玩家输入的自由行动，判断行动类型和后果。

你必须返回严格的 JSON：
{
  "interpretation": "解读文本，描述玩家行为",
  "action_type": "talk/observe/move/attack/spread_rumor/use_item/other",
  "world_changes": [],
  "narrative_result": "叙事结果文本，显示给玩家"
}

world_changes 数组中每个元素为：
{
  "type": "reputation/faction/event/npc_memory",
  "target": "目标ID",
  "delta": 变化值
}"""
