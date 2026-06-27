extends Node2D
class_name Interactable
## Interactable.gd — 第一版可交互物体

@export var id: String = ""
@export var display_name: String = "可交互物"
@export var interaction_type: String = "sign"
@export var interaction_text: String = ""

var item_id: String = ""
var item_amount: int = 1
var is_consumed: bool = false
var _label: Label = null
var _sprite: ColorRect = null


func _ready() -> void:
	add_to_group("interactable")
	if _sprite == null:
		_create_visuals()


func setup(data: Dictionary, tile_size: int = 32) -> void:
	id = data.get("id", id)
	display_name = data.get("display_name", display_name)
	interaction_type = data.get("interaction_type", interaction_type)
	interaction_text = data.get("interaction_text", interaction_text)
	item_id = data.get("item_id", item_id)
	item_amount = int(data.get("item_amount", item_amount))
	var x = float(data.get("x", 0))
	var y = float(data.get("y", 0))
	position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
	if _label:
		_label.text = display_name
	if _sprite:
		_sprite.color = _color_for_type(interaction_type)


func on_interact(player) -> Dictionary:
	var world_state = _world_state()
	var game_log = _game_log()
	if world_state == null:
		return {"ok": false, "message": "WorldState 不可用"}
	if is_consumed:
		return {"ok": false, "message": "%s 已经被处理过了。" % display_name}
	var message = interaction_text if interaction_text != "" else "你查看了 %s。" % display_name
	match interaction_type:
		"resource":
			var gained = item_id if item_id != "" else "herb"
			_add_item(gained, item_amount)
			_mark_consumed()
			message = "你拾取了 %s x%d。" % [display_name, item_amount]
		"chest":
			_add_item("coin", 5)
			_add_item("potion", 1)
			world_state.collected_items.append(id)
			_mark_consumed()
			message = "你打开了%s，获得铜钱和药水。" % display_name
		"door", "cave", "sign":
			pass
	if game_log:
		game_log.add_entry(message)
	world_state.log_action("交互: %s" % display_name, {"type": interaction_type, "id": id})
	return {"ok": true, "message": message, "id": id, "type": interaction_type}


func _add_item(gained_id: String, amount: int) -> void:
	var world_state = _world_state()
	if world_state == null:
		return
	world_state.add_item(gained_id, amount)
	if not world_state.collected_items.has(id):
		world_state.collected_items.append(id)


func _mark_consumed() -> void:
	is_consumed = true
	visible = false
	set_process(false)


func _create_visuals() -> void:
	_sprite = ColorRect.new()
	_sprite.name = "Sprite"
	_sprite.size = Vector2(18, 18)
	_sprite.position = Vector2(-9, -9)
	_sprite.color = _color_for_type(interaction_type)
	add_child(_sprite)
	_label = Label.new()
	_label.name = "Label"
	_label.text = display_name
	_label.position = Vector2(-28, -30)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.custom_minimum_size = Vector2(56, 14)
	_label.add_theme_font_size_override("font_size", 10)
	add_child(_label)


func _color_for_type(t: String) -> Color:
	match t:
		"resource":
			return Color(0.35, 0.85, 0.25, 1)
		"chest":
			return Color(0.95, 0.62, 0.18, 1)
		"cave":
			return Color(0.18, 0.14, 0.1, 1)
		"door":
			return Color(0.55, 0.45, 0.9, 1)
		_:
			return Color(0.85, 0.85, 0.65, 1)


func _world_state():
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		return loop.root.get_node_or_null("WorldState")
	return null


func _game_log():
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		return loop.root.get_node_or_null("GameLog")
	return null
