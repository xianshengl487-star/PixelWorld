extends Control
class_name QuestPanel
## Text-first quest panel summary.

var _label: Label = null
var quest_text: String = ""


func _ready() -> void:
	_ensure_label()


func show_quest(quest: Dictionary) -> void:
	_ensure_label()
	quest_text = build_quest_text(quest)
	_label.text = quest_text
	visible = true


func hide_quest() -> void:
	visible = false


func build_quest_text(quest: Dictionary) -> String:
	var title := str(quest.get("title", quest.get("quest_id", "Quest")))
	var status := str(quest.get("status", "available"))
	var objectives: Array = []
	var objectives_value: Variant = quest.get("objectives", [])
	if objectives_value is Array:
		objectives = objectives_value
	var objective_text := "Objective: --"
	if objectives is Array and objectives.size() > 0 and objectives[0] is Dictionary:
		var obj: Dictionary = objectives[0]
		objective_text = "Objective: %s %d/%d" % [
			str(obj.get("target_id", obj.get("target_type", obj.get("type", "target")))),
			int(obj.get("progress", 0)),
			int(obj.get("required", 1))
		]
	var reward_text := _reward_text(quest.get("rewards", {}))
	return "%s\n%s\nReward: %s\nStatus: %s" % [title, objective_text, reward_text, status]


func get_quest_text() -> String:
	return quest_text


func _reward_text(rewards: Variant) -> String:
	if not (rewards is Dictionary) or rewards.is_empty():
		return "--"
	var parts: Array = []
	if int(rewards.get("coin", 0)) > 0:
		parts.append("Coin x%d" % int(rewards.get("coin", 0)))
	if int(rewards.get("progression_points", 0)) > 0:
		parts.append("Progress +%d" % int(rewards.get("progression_points", 0)))
	var items: Dictionary = {}
	var items_value: Variant = rewards.get("items", {})
	if items_value is Dictionary:
		items = items_value
	for item_id in items.keys():
		parts.append("%s x%d" % [str(item_id).capitalize(), int(items[item_id])])
	return ", ".join(parts)


func _ensure_label() -> void:
	if _label != null:
		return
	_label = get_node_or_null("QuestLabel")
	if _label == null:
		_label = Label.new()
		_label.name = "QuestLabel"
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size = Vector2(420, 120)
		add_child(_label)
