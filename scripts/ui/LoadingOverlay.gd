extends Control
class_name LoadingOverlay
## Lightweight loading veil for map transitions.

var _message_label: Label = null
var _tip_label: Label = null
var _background: ColorRect = null


func _ready() -> void:
	_ensure_nodes()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_loading(target_name: String = "") -> void:
	_ensure_nodes()
	visible = true
	modulate.a = 1.0
	set_message("Loading..." if target_name == "" else "Traveling to: %s" % target_name)
	set_tip("WASD move  |  E interact  |  Q quests  |  F3 debug  |  F6 save")


func hide_loading() -> void:
	visible = false


func set_message(text: String) -> void:
	_ensure_nodes()
	_message_label.text = text


func set_tip(text: String) -> void:
	_ensure_nodes()
	_tip_label.text = text


func is_loading_visible() -> bool:
	return visible


func _ensure_nodes() -> void:
	if _background == null:
		_background = get_node_or_null("Background")
		if _background == null:
			_background = ColorRect.new()
			_background.name = "Background"
			_background.color = Color(0, 0, 0, 0.62)
			_background.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(_background)
	if _message_label == null:
		_message_label = get_node_or_null("MessageLabel")
		if _message_label == null:
			_message_label = Label.new()
			_message_label.name = "MessageLabel"
			_message_label.set_anchors_preset(Control.PRESET_CENTER)
			_message_label.offset_left = -260
			_message_label.offset_top = -40
			_message_label.offset_right = 260
			_message_label.offset_bottom = 4
			_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_message_label.add_theme_font_size_override("font_size", 24)
			add_child(_message_label)
	if _tip_label == null:
		_tip_label = get_node_or_null("TipLabel")
		if _tip_label == null:
			_tip_label = Label.new()
			_tip_label.name = "TipLabel"
			_tip_label.set_anchors_preset(Control.PRESET_CENTER)
			_tip_label.offset_left = -360
			_tip_label.offset_top = 8
			_tip_label.offset_right = 360
			_tip_label.offset_bottom = 42
			_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_tip_label.add_theme_font_size_override("font_size", 15)
			add_child(_tip_label)
