extends Area2D
class_name TransitionArea
## TransitionArea.gd - scene trigger that asks GameWorld to switch maps.

var transition_id: String = ""
var target_map_id: String = ""
var target_spawn_id: String = "default"
var locked_message: String = ""


func setup(data: Dictionary, tile_size: int = 32) -> void:
	transition_id = str(data.get("transition_id", data.get("connection_id", transition_id)))
	target_map_id = str(data.get("target_map_id", data.get("to_map_id", target_map_id)))
	target_spawn_id = str(data.get("target_spawn_id", data.get("to_spawn_id", target_spawn_id)))
	locked_message = str(data.get("locked_message", locked_message))
	var rect = data.get("from_rect", {"x": int(data.get("x", 0)), "y": int(data.get("y", 0)), "w": 2, "h": 2})
	var shape_node = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var w = int(rect.get("w", rect.get("width", 2))) if rect is Dictionary else 2
	var h = int(rect.get("h", rect.get("height", 2))) if rect is Dictionary else 2
	shape.size = Vector2(w * tile_size, h * tile_size)
	shape_node.shape = shape
	add_child(shape_node)
	if rect is Dictionary:
		position = Vector2((int(rect.get("x", 0)) + w / 2.0) * tile_size, (int(rect.get("y", 0)) + h / 2.0) * tile_size)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("_try_interact"):
		return
	var gw = get_tree().get_first_node_in_group("game_world")
	if gw != null and gw.has_method("request_map_transition"):
		gw.request_map_transition(transition_id)
