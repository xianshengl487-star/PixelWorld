extends CanvasLayer
## GameLog.gd — 游戏内运行日志 Autoload 单例
## 记录和显示游戏运行时日志

const MAX_ENTRIES: int = 100

var _entries: Array = []
var _signal_log_updated: Signal = Signal()


func _ready() -> void:
	_entries.clear()


## 添加普通日志
func add_entry(text: String) -> void:
	_entries.append({"type": "info", "text": text, "time": Time.get_datetime_string_from_system()})
	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()


## 添加警告
func add_warning(text: String) -> void:
	_entries.append({"type": "warning", "text": "[警告] " + text, "time": Time.get_datetime_string_from_system()})
	push_warning(text)
	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()


## 添加错误
func add_error(text: String) -> void:
	_entries.append({"type": "error", "text": "[错误] " + text, "time": Time.get_datetime_string_from_system()})
	push_error(text)
	WorldState.log_error("GameLog", text)
	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()


## 获取最近 N 条日志
func get_recent(count: int = 10) -> Array:
	var total = _entries.size()
	var start = max(total - count, 0)
	return _entries.slice(start, total)


## 获取所有日志文本（用于界面显示）
func get_log_text(max_lines: int = 6) -> String:
	var recent = get_recent(max_lines)
	var lines: Array = []
	for entry in recent:
		lines.append(entry.text)
	return "\n".join(lines)


## 清空日志
func clear() -> void:
	_entries.clear()
