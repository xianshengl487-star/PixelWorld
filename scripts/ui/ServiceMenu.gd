extends Control
class_name ServiceMenu
## Text-first service menu summary for building services.

var _label: Label = null
var service_text: String = ""


func _ready() -> void:
	_ensure_label()


func show_service(building_name: String, service_name: String, cost: Dictionary = {}, effects: Dictionary = {}, usable: bool = true) -> void:
	_ensure_label()
	service_text = build_service_text(building_name, service_name, cost, effects, usable)
	_label.text = service_text
	visible = true


func hide_service() -> void:
	visible = false


func build_service_text(building_name: String, service_name: String, cost: Dictionary = {}, effects: Dictionary = {}, usable: bool = true) -> String:
	var cost_text := _cost_text(cost)
	var effect_text := _effect_text(effects)
	var status := "Available" if usable else "Unavailable"
	return "%s\n[E] %s\nCost: %s\nEffect: %s\nStatus: %s" % [building_name, service_name, cost_text, effect_text, status]


func get_service_text() -> String:
	return service_text


func _cost_text(cost: Dictionary) -> String:
	if cost.is_empty():
		return "Free"
	var parts: Array = []
	for key in cost.keys():
		parts.append("%s x%d" % [str(key).capitalize(), int(cost[key])])
	return ", ".join(parts)


func _effect_text(effects: Dictionary) -> String:
	if effects.is_empty():
		return "Opens service"
	var parts: Array = []
	for key in effects.keys():
		parts.append("%s +%s" % [str(key).capitalize(), str(effects[key])])
	return ", ".join(parts)


func _ensure_label() -> void:
	if _label != null:
		return
	_label = get_node_or_null("ServiceLabel")
	if _label == null:
		_label = Label.new()
		_label.name = "ServiceLabel"
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size = Vector2(360, 120)
		add_child(_label)
