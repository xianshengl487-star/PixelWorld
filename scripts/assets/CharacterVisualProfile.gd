extends RefCounted
class_name CharacterVisualProfile
## CharacterVisualProfile.gd - serializable visual metadata for entities.

var entity_type: String = ""
var role_or_type: String = ""
var idle_texture_path: String = ""
var walk_sheet_path: String = ""
var attack_sheet_path: String = ""
var hurt_texture_path: String = ""
var dead_texture_path: String = ""
var fallback_color: Color = Color(0.8, 0.8, 0.8, 1.0)
var sprite_size: Vector2i = Vector2i(32, 32)
var frame_count: int = 1


func to_dict() -> Dictionary:
	return {
		"entity_type": entity_type,
		"role_or_type": role_or_type,
		"idle_texture_path": idle_texture_path,
		"walk_sheet_path": walk_sheet_path,
		"attack_sheet_path": attack_sheet_path,
		"hurt_texture_path": hurt_texture_path,
		"dead_texture_path": dead_texture_path,
		"fallback_color": {
			"r": fallback_color.r,
			"g": fallback_color.g,
			"b": fallback_color.b,
			"a": fallback_color.a
		},
		"sprite_size": {"x": sprite_size.x, "y": sprite_size.y},
		"frame_count": frame_count
	}


func from_dict(data: Dictionary) -> void:
	entity_type = str(data.get("entity_type", entity_type))
	role_or_type = str(data.get("role_or_type", role_or_type))
	idle_texture_path = str(data.get("idle_texture_path", idle_texture_path))
	walk_sheet_path = str(data.get("walk_sheet_path", walk_sheet_path))
	attack_sheet_path = str(data.get("attack_sheet_path", attack_sheet_path))
	hurt_texture_path = str(data.get("hurt_texture_path", hurt_texture_path))
	dead_texture_path = str(data.get("dead_texture_path", dead_texture_path))
	var color_data = data.get("fallback_color", {})
	if color_data is Dictionary:
		fallback_color = Color(
			float(color_data.get("r", fallback_color.r)),
			float(color_data.get("g", fallback_color.g)),
			float(color_data.get("b", fallback_color.b)),
			float(color_data.get("a", fallback_color.a))
		)
	var size_data = data.get("sprite_size", {})
	if size_data is Dictionary:
		sprite_size = Vector2i(int(size_data.get("x", sprite_size.x)), int(size_data.get("y", sprite_size.y)))
	frame_count = int(data.get("frame_count", frame_count))
