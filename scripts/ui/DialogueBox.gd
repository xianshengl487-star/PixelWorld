extends CanvasLayer
class_name DialogueBox
## DialogueBox.gd — 对话显示框
## 显示 NPC 对话文本

@onready var _panel: Panel = $Panel
@onready var _name_label: Label = $Panel/NameLabel
@onready var _text_label: RichTextLabel = $Panel/TextLabel
@onready var _continue_hint: Label = $Panel/ContinueHint
@onready var _animation_player: AnimationPlayer = $AnimationPlayer

var _is_showing: bool = false
var _dialogue_queue: Array = []


func _ready() -> void:
	add_to_group("dialogue_box")
	hide_dialogue()


## 显示对话
func show_dialogue(npc_name: String, dialogue: String) -> void:
	_dialogue_queue.append({"name": npc_name, "text": dialogue})
	
	if not _is_showing:
		_show_next()


func _show_next() -> void:
	if _dialogue_queue.size() == 0:
		return
	
	var data = _dialogue_queue.pop_front()
	_is_showing = true
	
	if _name_label:
		_name_label.text = data.get("name", "")
	
	if _text_label:
		_text_label.text = data.get("text", "")
	
	if _panel:
		_panel.visible = true
	
	if _continue_hint:
		_continue_hint.visible = true
	
	if _animation_player and _animation_player.has_animation("fade_in"):
		_animation_player.play("fade_in")


## 隐藏对话
func hide_dialogue() -> void:
	_is_showing = false
	_dialogue_queue.clear()
	
	if _panel:
		_panel.visible = false
	
	if _name_label:
		_name_label.text = ""
	
	if _text_label:
		_text_label.text = ""
	
	if _continue_hint:
		_continue_hint.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _is_showing:
		return
	
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		
		if _dialogue_queue.size() > 0:
			_show_next()
		else:
			hide_dialogue()
