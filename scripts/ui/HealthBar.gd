extends Control
class_name HealthBar
## HealthBar.gd — 敌人头顶血条

var _bar: ProgressBar = null


func _ready() -> void:
	_ensure_bar()


func set_health(current: int, max_value: int) -> void:
	_ensure_bar()
	_bar.max_value = max(1, max_value)
	_bar.value = clampi(current, 0, max_value)
	visible = current > 0


func _ensure_bar() -> void:
	if _bar != null:
		return
	_bar = ProgressBar.new()
	_bar.name = "ProgressBar"
	_bar.custom_minimum_size = Vector2(36, 6)
	_bar.size = Vector2(36, 6)
	_bar.show_percentage = false
	add_child(_bar)
