extends RefCounted
class_name QuestObjective
## QuestObjective.gd - one countable objective in a quest.

var objective_id: String = ""
var objective_type: String = ""
var target_id: String = ""
var target_type: String = ""
var required: int = 1
var progress: int = 0
var completed: bool = false


func setup(data: Dictionary) -> void:
	objective_id = str(data.get("objective_id", data.get("id", objective_id)))
	objective_type = str(data.get("type", data.get("objective_type", objective_type)))
	target_id = str(data.get("target_id", target_id))
	target_type = str(data.get("target_type", target_type))
	required = max(1, int(data.get("required", data.get("amount", required))))
	progress = clampi(int(data.get("progress", progress)), 0, required)
	completed = bool(data.get("completed", progress >= required))


func apply_event(event: Dictionary) -> bool:
	if completed:
		return false
	if str(event.get("type", "")) != objective_type:
		return false
	if target_id != "" and str(event.get("target_id", event.get("item_id", event.get("map_id", event.get("object_id", ""))))) != target_id:
		return false
	if target_type != "" and str(event.get("target_type", event.get("enemy_type", ""))) != target_type:
		return false
	progress = min(required, progress + max(1, int(event.get("amount", 1))))
	completed = progress >= required
	return true


func to_save_data() -> Dictionary:
	return {
		"objective_id": objective_id,
		"type": objective_type,
		"target_id": target_id,
		"target_type": target_type,
		"required": required,
		"progress": progress,
		"completed": completed
	}
