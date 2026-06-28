extends Area2D
class_name DoorInteraction
## DoorInteraction.gd - simple door trigger for building interiors.

var building_id: String = ""
var target_map_id: String = ""
var target_spawn_id: String = "default"
var locked_message: String = "This door cannot be entered yet."


func setup(data: Dictionary, tile_size: int = 32) -> void:
	building_id = str(data.get("building_id", building_id))
	target_map_id = str(data.get("target_map_id", data.get("interior_map_id", target_map_id)))
	target_spawn_id = str(data.get("target_spawn_id", target_spawn_id))
	locked_message = str(data.get("locked_message", locked_message))
	var rect = data.get("from_rect", {"x": int(data.get("x", 0)), "y": int(data.get("y", 0)), "w": 1, "h": 1})
	var shape_node = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var w = int(rect.get("w", rect.get("width", 1))) if rect is Dictionary else 1
	var h = int(rect.get("h", rect.get("height", 1))) if rect is Dictionary else 1
	shape.size = Vector2(w * tile_size, h * tile_size)
	shape_node.shape = shape
	add_child(shape_node)
	if rect is Dictionary:
		position = Vector2((int(rect.get("x", 0)) + w / 2.0) * tile_size, (int(rect.get("y", 0)) + h / 2.0) * tile_size)
	body_entered.connect(_on_body_entered)


func activate() -> bool:
	var gw = get_tree().get_first_node_in_group("game_world") if get_tree() != null else null
	if gw != null and gw.has_method("switch_map") and target_map_id != "":
		return gw.switch_map(target_map_id, target_spawn_id)
	if Engine.get_main_loop() is SceneTree:
		var log = Engine.get_main_loop().root.get_node_or_null("GameLog")
		if log != null and log.has_method("add_entry"):
			log.add_entry(locked_message)
	return false


func _on_body_entered(body: Node2D) -> void:
	if body == null or not body.is_in_group("player"):
		return
	activate()
