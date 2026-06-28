extends RefCounted
class_name QuestData
## QuestData.gd - save-friendly quest state.

const QuestObjectiveClass = preload("res://scripts/quests/QuestObjective.gd")

var quest_id: String = ""
var title: String = ""
var description: String = ""
var source_type: String = ""
var source_id: String = ""
var status: String = "available"
var objectives: Array = []
var rewards: Dictionary = {}
var required_flags: Array = []
var required_realm_order: int = 0
var repeatable: bool = false
var map_scope: String = ""


func setup(data: Dictionary) -> void:
	quest_id = str(data.get("quest_id", data.get("id", quest_id)))
	title = str(data.get("title", title))
	description = str(data.get("description", description))
	source_type = str(data.get("source_type", source_type))
	source_id = str(data.get("source_id", source_id))
	status = str(data.get("status", status))
	rewards = data.get("rewards", rewards).duplicate(true) if data.get("rewards", rewards) is Dictionary else {}
	required_flags = data.get("required_flags", required_flags).duplicate(true) if data.get("required_flags", required_flags) is Array else []
	required_realm_order = int(data.get("required_realm_order", required_realm_order))
	repeatable = bool(data.get("repeatable", repeatable))
	map_scope = str(data.get("map_scope", map_scope))
	objectives.clear()
	for raw in data.get("objectives", []):
		var objective = QuestObjectiveClass.new()
		objective.setup(raw if raw is Dictionary else {})
		objectives.append(objective)


func is_complete() -> bool:
	if objectives.is_empty():
		return false
	for objective in objectives:
		if objective == null or not objective.completed:
			return false
	return true


func apply_event(event: Dictionary) -> bool:
	if status != "active":
		return false
	var changed = false
	for objective in objectives:
		if objective != null and objective.apply_event(event):
			changed = true
	if changed and is_complete():
		status = "completed"
	return changed


func to_save_data() -> Dictionary:
	var objective_data: Array = []
	for objective in objectives:
		objective_data.append(objective.to_save_data() if objective != null and objective.has_method("to_save_data") else {})
	return {
		"quest_id": quest_id,
		"title": title,
		"description": description,
		"source_type": source_type,
		"source_id": source_id,
		"status": status,
		"objectives": objective_data,
		"rewards": rewards,
		"required_flags": required_flags,
		"required_realm_order": required_realm_order,
		"repeatable": repeatable,
		"map_scope": map_scope
	}
