extends Node
## ConfigManager.gd — 配置管理器 Autoload 单例
## 负责读取 .env 文件和提供环境变量访问

var _env_data: Dictionary = {}


func _ready() -> void:
	load_env()


## 加载 .env 文件
func load_env(path: String = "res://.env") -> void:
	_env_data.clear()
	
	# 首先尝试从环境变量读取（系统环境变量优先级最高）
	var system_env = OS.get_environment("AI_PROVIDER")
	if system_env != "":
		_env_data["AI_PROVIDER"] = system_env
	
	# 然后读取 .env 文件
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		# 尝试从用户目录读取
		file = FileAccess.open("user://.env", FileAccess.READ)
		if file == null:
			push_warning("[ConfigManager] 无法读取 .env 文件，使用默认 Mock 模式")
			_env_data["AI_PROVIDER"] = "mock"
			return
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var parts = line.split("=", true, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			# 去掉引号
			if value.begins_with('"') and value.ends_with('"'):
				value = value.substr(1, value.length() - 2)
			if value.begins_with("'") and value.ends_with("'"):
				value = value.substr(1, value.length() - 2)
			# env 文件中不覆盖系统环境变量
			if not _env_data.has(key):
				_env_data[key] = value
	
	file.close()


## 获取环境变量
func get_env(key: String, default: String = "") -> String:
	# 优先从系统环境变量读取
	var sys_val = OS.get_environment(key)
	if sys_val != "":
		return sys_val
	return _env_data.get(key, default)


## 获取整数环境变量
func get_env_int(key: String, default: int = 0) -> int:
	var val = get_env(key, str(default))
	return int(val)


## 获取布尔环境变量
func get_env_bool(key: String, default: bool = false) -> bool:
	var val = get_env(key, str(default)).to_lower()
	return val == "true" or val == "1"


## 获取当前 AI Provider 类型
func get_ai_provider() -> String:
	return get_env("AI_PROVIDER", "mock")


## 获取 AI Gateway URL
func get_ai_gateway_url() -> String:
	return get_env("AI_GATEWAY_URL", "")
