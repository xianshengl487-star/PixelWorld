extends Control
class_name ControlHintPanel
## Shows basic controls for new players.

var _label: Label = null


func _ready() -> void:
	_ensure_label()
	show_panel()


func show_panel() -> void:
	_ensure_label()
	visible = true


func hide_panel() -> void:
	visible = false


func toggle_panel() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()


func get_hint_text() -> String:
	return "WASD/Arrows Move | E Interact | Space/Mouse Attack | Q Quests | I Bag | F3 Debug | F6 Save | F7 Load | H Help"


func _ensure_label() -> void:
	if _label != null:
		return
	_label = get_node_or_null("HintLabel")
	if _label == null:
		_label = Label.new()
		_label.name = "HintLabel"
		_label.add_theme_font_size_override("font_size", 13)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size = Vector2(460, 52)
		add_child(_label)
	_label.text = get_hint_text()
