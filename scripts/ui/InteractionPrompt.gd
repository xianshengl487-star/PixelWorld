extends Control
class_name InteractionPrompt
## Compact contextual interaction prompt.

var _label: Label = null
var prompt_text: String = ""


func _ready() -> void:
	_ensure_label()
	hide_prompt()


func show_prompt(action: String, target_name: String, key_name: String = "E") -> void:
	_ensure_label()
	prompt_text = "[%s] %s: %s" % [key_name, action, target_name]
	_label.text = prompt_text
	visible = true


func show_text(text: String) -> void:
	_ensure_label()
	prompt_text = text
	_label.text = text
	visible = true


func hide_prompt() -> void:
	visible = false


func is_prompt_visible() -> bool:
	return visible


func get_prompt_text() -> String:
	return prompt_text


func _ensure_label() -> void:
	if _label != null:
		return
	_label = get_node_or_null("PromptLabel")
	if _label == null:
		_label = Label.new()
		_label.name = "PromptLabel"
		_label.add_theme_font_size_override("font_size", 18)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.custom_minimum_size = Vector2(420, 28)
		add_child(_label)
