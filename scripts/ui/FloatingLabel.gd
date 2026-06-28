extends Label
class_name FloatingLabel
## Small readable label for buildings, exits, NPCs, and resources.


func setup(text_value: String, offset: Vector2 = Vector2.ZERO) -> void:
	text = text_value
	position = offset
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	custom_minimum_size = Vector2(120, 20)
	add_theme_font_size_override("font_size", 12)
	add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)


func set_label_text(text_value: String) -> void:
	text = text_value
