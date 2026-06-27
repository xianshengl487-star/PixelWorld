extends Node
## DevLogWriter.gd — 开发日志写入器
## 用于在运行时将开发相关事件写入 DEV_LOG.md

const LOG_PATH: String = "res://DEV_LOG.md"

var _buffer: Array = []


func write_update(title: String, update_type: String, changes: Array, files: Array, reason: String, todos: Array = []) -> void:
	var now = Time.get_datetime_string_from_system(true)
	var date_part = now.substr(0, 10)
	var time_part = now.substr(11, 5)
	
	var lines: Array = []
	lines.append("")
	lines.append("## %s %s — %s" % [date_part, time_part, title])
	lines.append("")
	lines.append("### 更新类型")
	lines.append("")
	lines.append(update_type)
	lines.append("")
	lines.append("### 本次改动")
	lines.append("")
	for change in changes:
		lines.append("* " + change)
	lines.append("")
	lines.append("### 涉及文件")
	lines.append("")
	for f in files:
		lines.append("* `%s`" % f)
	lines.append("")
	lines.append("### 原因")
	lines.append("")
	lines.append(reason)
	lines.append("")
	if todos.size() > 0:
		lines.append("### 后续待办")
		lines.append("")
		for todo in todos:
			lines.append("* " + todo)
		lines.append("")
	
	var entry = "\n".join(lines)
	
	# 尝试追加写入
	var file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		# 文件可能不存在
		_buffer.append(entry)
		push_warning("[DevLogWriter] 无法打开 DEV_LOG.md，已缓冲日志")
		return
	
	file.seek_end()
	file.store_string(entry)
	file.close()


## 记录新增文件
func log_file_added(file_path: String, reason: String = "") -> void:
	write_update(
		"新增文件: %s" % _get_short_path(file_path),
		"新增",
		["创建 `%s`" % file_path],
		[file_path],
		reason
	)


## 记录文件修改
func log_file_modified(file_path: String, changes: Array, reason: String = "") -> void:
	write_update(
		"修改文件: %s" % _get_short_path(file_path),
		"修改",
		changes,
		[file_path],
		reason
	)


func _get_short_path(full: String) -> String:
	return full.replace("res://", "")
