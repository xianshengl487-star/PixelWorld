extends RefCounted
## AIClient.gd — AI 调用客户端
## 根据配置选择 Provider，处理重试和回退

const MAX_RETRIES: int = 1
const RETRY_DELAY: float = 1.0

const AIProviderClass = preload("res://scripts/ai/providers/AIProvider.gd")
const MockProviderClass = preload("res://scripts/ai/providers/MockProvider.gd")
const MimoProviderClass = preload("res://scripts/ai/providers/MimoProvider.gd")
const NvidiaProviderClass = preload("res://scripts/ai/providers/NvidiaProvider.gd")
const LocalTinyProviderClass = preload("res://scripts/ai/providers/LocalTinyNpcProvider.gd")

var _provider = null
var _mock_provider = null
var _tiny_npc_provider = null


func _init() -> void:
	_initialize_provider()


## 初始化 Provider
func _initialize_provider() -> void:
	_mock_provider = MockProviderClass.new()
	_tiny_npc_provider = LocalTinyProviderClass.new()
	
	var provider_type = "mock"
	# 安全获取 ConfigManager（可能在 headless/extends SceneTree 上下文中不可用）
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		var config_node = root.root.get_node_or_null("ConfigManager")
		if config_node and config_node.has_method("get_ai_provider"):
			provider_type = config_node.get_ai_provider()
	
	match provider_type:
		"mimo":
			_provider = MimoProviderClass.new()
		"nvidia":
			_provider = NvidiaProviderClass.new()
		_:
			_provider = _mock_provider
	
	if _provider == null:
		_provider = _mock_provider
	
	# 安全设置 WorldState
	var ws = _get_autoload("WorldState")
	if ws: ws.ai_provider_status = provider_type
	print("[AIClient] 初始化 Provider: ", provider_type)


## 安全获取 Autoload 节点
func _get_autoload(name: String):
	var root = Engine.get_main_loop()
	if root and root is SceneTree:
		return root.root.get_node_or_null(name)
	return null


func _log_info(text: String) -> void:
	var gl = _get_autoload("GameLog")
	if gl and gl.has_method("add_entry"):
		gl.add_entry(text)
	else:
		print("[AIClient] " + text)

func _log_warning(text: String) -> void:
	var gl = _get_autoload("GameLog")
	if gl and gl.has_method("add_warning"):
		gl.add_warning(text)
	else:
		push_warning(text)

func _log_error(text: String, context: String = "") -> void:
	var gl = _get_autoload("GameLog")
	if gl and gl.has_method("add_error"):
		gl.add_error(text)
	else:
		push_error(text)
	var ws = _get_autoload("WorldState")
	if ws and ws.has_method("log_error"):
		ws.log_error(context, text)


## 生成世界蓝图
func generate_world_blueprint(prompt: String) -> Dictionary:
	_log_info("正在生成世界蓝图...")
	
	var result = await _call_provider_with_fallback(
		func(): return await _provider.generate_world_blueprint(prompt),
		func(): return await _mock_provider.generate_world_blueprint(prompt),
		"世界蓝图生成"
	)
	
	if result.get("error", "") != "":
		_log_warning("世界蓝图生成失败，使用默认世界")
	
	return result


## 生成主要 NPC 回复
func generate_major_npc_reply(context: Dictionary) -> Dictionary:
	var npc_name = context.get("npc_name", "NPC")
	
	var result = await _call_provider_with_fallback(
		func(): return await _provider.generate_major_npc_reply(context),
		func(): return await _mock_provider.generate_major_npc_reply(context),
		"主要NPC对话(%s)" % npc_name
	)
	
	# 确保有默认值
	if result.get("dialogue", "") == "":
		result["dialogue"] = "..."
	
	return result


## 生成小型 NPC 回复（始终走 LocalTinyNpcProvider）
func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
	return await _tiny_npc_provider.generate_minor_npc_reply(context)


## 解读玩家行动
func interpret_player_action(context: Dictionary) -> Dictionary:
	var action_text = context.get("player_input", "")
	
	var result = await _call_provider_with_fallback(
		func(): return await _provider.interpret_player_action(context),
		func(): return await _mock_provider.interpret_player_action(context),
		"玩家行动解读(%s)" % action_text
	)
	
	return result


## 带重试和回退的调用包装
func _call_provider_with_fallback(primary_func: Callable, fallback_func: Callable, context: String) -> Dictionary:
	# 第一次尝试
	var result = await primary_func.call()
	if result.get("error", "") == "":
		return result
	
	push_warning("[AIClient] %s 第一次调用失败: %s" % [context, result.get("error")])
	
	# 重试一次
	await _delay(RETRY_DELAY)
	
	result = await primary_func.call()
	if result.get("error", "") == "":
		return result
	
	# 回退到 fallback
	push_error("[AIClient] %s 重试后仍失败: %s, 回退到 fallback" % [context, result.get("error")])
	
	var error_message = "%s: %s" % [context, result.get("error", "未知错误")]
	_log_error(error_message, context)
	
	return await fallback_func.call()


## 延迟辅助函数
func _delay(seconds: float) -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	Engine.get_main_loop().root.add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()


## 获取所有 Provider 名称（用于调试）
func get_provider_name() -> String:
	var cm = _get_autoload("ConfigManager")
	if cm and cm.has_method("get_ai_provider"):
		return cm.get_ai_provider()
	return "mock"
