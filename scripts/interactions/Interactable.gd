extends Node2D
class_name Interactable
## Interactable.gd - simple map-scoped interactable object.

const ScopedIdClass = preload("res://scripts/core/ScopedId.gd")
const MapStateClass = preload("res://scripts/map/MapState.gd")

@export var id: String = ""
@export var display_name: String = "Interactable"
@export var interaction_type: String = "sign"
@export var interaction_text: String = ""

var item_id: String = ""
var item_amount: int = 1
var is_consumed: bool = false
var map_id: String = ""
var scoped_id: String = ""

var _label: Label = null
var _sprite: ColorRect = null


func _ready() -> void:
	add_to_group("interactable")
	if _sprite == null:
		_create_visuals()


func setup(data: Dictionary, tile_size: int = 32) -> void:
	id = str(data.get("id", id))
	display_name = str(data.get("display_name", display_name))
	interaction_type = str(data.get("interaction_type", interaction_type))
	interaction_text = str(data.get("interaction_text", interaction_text))
	item_id = str(data.get("item_id", item_id))
	item_amount = int(data.get("item_amount", item_amount))
	map_id = str(data.get("map_id", map_id))
	if map_id == "":
		var world_state = _world_state()
		if world_state != null:
			map_id = str(world_state.current_map_id)
	scoped_id = str(data.get("scoped_id", scoped_id))
	if scoped_id == "":
		scoped_id = ScopedIdClass.new().make(map_id, id)
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
		return {"ok": false, "message": "WorldState unavailable"}
	if is_consumed:
		return {"ok": false, "message": "%s already handled." % display_name}
	var message = interaction_text if interaction_text != "" else "You inspect %s." % display_name
	match interaction_type:
		"resource":
			var gained = item_id if item_id != "" else "herb"
			_add_item(gained, item_amount)
			_mark_resource_collected()
			_update_quest({"type": "collect_item", "target_id": gained, "item_id": gained, "amount": item_amount})
			_mark_consumed()
			message = "Collected %s x%d." % [display_name, item_amount]
		"chest":
			_add_item("coin", 5)
			_add_item("potion", 1)
			_mark_chest_opened()
			_update_quest({"type": "open_chest", "target_id": id, "object_id": id, "amount": 1})
			_mark_consumed()
			message = "Opened %s and found coin and potion." % display_name
		"door", "cave", "sign":
			_update_quest({"type": "interact_object", "target_id": id, "object_id": id, "amount": 1})
	if game_log:
		game_log.add_entry(message)
	world_state.log_action("Interact: %s" % display_name, {"type": interaction_type, "id": id, "scoped_id": scoped_id})
	return {"ok": true, "message": message, "id": id, "scoped_id": scoped_id, "type": interaction_type}


func _add_item(gained_id: String, amount: int) -> void:
	var world_state = _world_state()
	if world_state == null:
		return
	world_state.add_item(gained_id, amount)
	if not world_state.collected_items.has(scoped_id):
		world_state.collected_items.append(scoped_id)


func _mark_resource_collected() -> void:
	var state = _map_state()
	state.mark_resource_collected(scoped_id)
	_save_state(state)


func _mark_chest_opened() -> void:
	var state = _map_state()
	state.mark_chest_opened(scoped_id)
	_save_state(state)


func _map_state():
	var state = MapStateClass.new()
	var world_state = _world_state()
	if world_state != null:
		state.load_save_data(world_state.get_map_state(map_id))
	state.map_id = map_id
	state.mark_visited()
	return state


func _save_state(state) -> void:
	var world_state = _world_state()
	if world_state != null:
		world_state.set_map_state(map_id, state.to_save_data())


func _update_quest(event: Dictionary) -> void:
	var world_state = _world_state()
	if world_state != null and world_state.has_method("update_quest_objective"):
		event["map_id"] = map_id
		world_state.update_quest_objective(event)


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
