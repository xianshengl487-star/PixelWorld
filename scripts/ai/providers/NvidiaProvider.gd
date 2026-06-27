extends "res://scripts/ai/providers/AIProvider.gd"
class_name NvidiaProvider
## NvidiaProvider.gd — NVIDIA NIM 云端 AI Provider
## 通过 OpenAI-compatible API 调用 NVIDIA NIM 模型

var _api_key: String = ""
var _base_url: String = ""
var _world_model: String = ""
var _npc_model: String = ""
var _http: HTTPRequest = null


func _init() -> void:
	_api_key = _get_config("NVIDIA_API_KEY", "")
	_base_url = _get_config("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1")
	_world_model = _get_config("NVIDIA_WORLD_MODEL", "meta/llama-3.1-70b-instruct")
	_npc_model = _get_config("NVIDIA_MAJOR_NPC_MODEL", "meta/llama-3.1-8b-instruct")
	
	if _api_key == "":
		push_warning("[NvidiaProvider] NVIDIA_API_KEY 未配置！")
	
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
	return response


## 生成主要 NPC 回复
func generate_major_npc_reply(context: Dictionary) -> Dictionary:
	var system_prompt = _get_npc_dialogue_system_prompt()
	var user_content = JSON.stringify(context)
	
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": user_content}
	]
	
	var response = await _call_api(messages, _npc_model, 1024)
	return response


func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
	return {"dialogue": "你好。"}


func interpret_player_action(context: Dictionary) -> Dictionary:
	var system_prompt = _get_action_interpreter_system_prompt()
	var user_content = JSON.stringify(context)
	
	var messages = [
		{"role": "system", "content": system_prompt},
		{"role": "user", "content": user_content}
	]
	
	var response = await _call_api(messages, _npc_model, 1024)
	return response


## 调用 NVIDIA NIM API
func _call_api(messages: Array, model: String, max_tokens: int = 2048) -> Dictionary:
	if _api_key == "":
		return {"error": "NVIDIA_API_KEY 未配置"}
	
	var body = {
		"model": model,
		"messages": messages,
		"max_tokens": max_tokens,
		"temperature": 0.7,
		"top_p": 0.9
	}
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + _api_key
	]
	
	var url = _base_url.trim_suffix("/") + "/chat/completions"
	
	_http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	var response_data = await _http.request_completed
	
	var result = response_data[0]
	var response_code = response_data[1]
	var body_bytes = response_data[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"error": "HTTP 请求失败: %d" % result}
	
	if response_code != 200:
		var body_text = body_bytes.get_string_from_utf8()
		return {"error": "API 返回错误 %d: %s" % [response_code, body_text]}
	
	var body_text = body_bytes.get_string_from_utf8()
	var json = JSON.parse_string(body_text)
	
	if json == null:
		return {"error": "无法解析 API 返回的 JSON"}
	
	var choices = json.get("choices", [])
	if choices.size() == 0:
		return {"error": "API 返回了空的 choices"}
	
	var content = choices[0].get("message", {}).get("content", "")
	if content == "":
		return {"error": "API 返回了空内容"}
	
	var content_json = JSON.parse_string(content)
	if content_json != null:
		return content_json
	else:
		return {"error": "API 返回的不是有效 JSON: " + content}


## System Prompts (与 MimoProvider 相同)
func _get_world_blueprint_system_prompt() -> String:
	return """你是一个游戏世界生成器。根据玩家输入的一句话描述，生成一个完整的游戏世界蓝图。

你必须返回严格的 JSON，不包含任何其他文本。

JSON 格式：
{
  "world_name": "世界名称",
  "world_type": "xianxia/apocalypse/cyberpunk/fantasy",
  "tone": "adventure/dark/mystery",
  "start_region": "起始区域ID",
  "player_spawn": {"x": 20, "y": 20},
  "regions": [{"id": "...", "name": "...", "type": "...", "safety": 0-100}],
  "factions": [{"id": "...", "name": "...", "type": "...", "attitude_to_player": 0}],
  "major_npcs": [{"id": "...", "name": "...", "role": "...", "importance": "major", "personality": [...], "goal": "...", "x": 0-63, "y": 0-63, "initial_dialogue": "..."}],
  "minor_npcs": [{"id": "...", "name": "...", "role": "...", "importance": "minor", "x": 0-63, "y": 0-63, "dialogue_profile": "..."}],
  "events": [{"id": "...", "name": "...", "description": "..."}],
  "map_blueprint": {"size": {"width": 64, "height": 64}, "required_areas": [...], "connections": [[...]]}
}

关键要求：
- 坐标 0-63 范围
- 至少 2 个区域
- 至少 1 个主要 NPC
- 至少 1 个事件"""


func _get_npc_dialogue_system_prompt() -> String:
	return """你是游戏NPC对话生成器。返回严格JSON：
{"dialogue": "对话内容", "attitude_change": -10~10整数, "memory_to_add": "记忆或null", "event_trigger": "事件ID或null", "world_changes": []}
对话要符合NPC性格，态度变化合理。"""


func _get_action_interpreter_system_prompt() -> String:
	return """你是游戏行动解读器。返回严格JSON：
{"interpretation": "解读", "action_type": "talk/observe/move/attack/spread_rumor/use_item/other", "world_changes": [], "narrative_result": "叙事结果"}"""
