extends RefCounted
class_name QuestSystem
## QuestSystem.gd - small deterministic quest tracker for v0.4.2.

const QuestDataClass = preload("res://scripts/quests/QuestData.gd")

var available_quests: Dictionary = {}
var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}
var turned_in_quests: Dictionary = {}


func load_quests(path: String = "res://data/quests/basic_quests.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "missing_quest_file", "path": path}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "open_failed", "path": path}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return {"ok": false, "error": "parse_failed", "path": path}
	available_quests.clear()
	for raw in parsed.get("quests", []):
		var quest = QuestDataClass.new()
		quest.setup(raw if raw is Dictionary else {})
		if quest.quest_id != "":
			available_quests[quest.quest_id] = quest
	return {"ok": true, "count": available_quests.size()}


func get_available_quests(context: Dictionary = {}) -> Array:
	var result: Array = []
	for quest_id in available_quests.keys():
		var quest = available_quests[quest_id]
		if quest == null:
			continue
		if active_quests.has(quest_id) or completed_quests.has(quest_id) or turned_in_quests.has(quest_id):
			continue
		if _can_show(quest, context):
			result.append(quest.to_save_data())
	return result


func accept_quest(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		return {"ok": true, "quest_id": quest_id, "status": "active", "message": "quest_already_active"}
	if not available_quests.has(quest_id):
		return {"ok": false, "quest_id": quest_id, "error": "quest_not_available"}
	var quest = available_quests[quest_id]
	quest.status = "active"
	active_quests[quest_id] = quest
	available_quests.erase(quest_id)
	_sync_world_state()
	_log("Quest accepted: %s" % quest.title)
	return {"ok": true, "quest_id": quest_id, "status": "active", "message": "quest_accepted"}


func update_objective(event: Dictionary) -> void:
	var changed_ids: Array = []
	for quest_id in active_quests.keys():
		var quest = active_quests[quest_id]
		if quest != null and quest.apply_event(event):
			changed_ids.append(quest_id)
			_log("Quest progress: %s" % quest.title)
	for quest_id in changed_ids:
		check_completion(quest_id)
	_sync_world_state()


func check_completion(quest_id: String) -> Dictionary:
	if not active_quests.has(quest_id):
		return {"ok": false, "quest_id": quest_id, "status": "missing"}
	var quest = active_quests[quest_id]
	if quest == null or not quest.is_complete():
		return {"ok": true, "quest_id": quest_id, "status": "active"}
	quest.status = "completed"
	completed_quests[quest_id] = quest
	active_quests.erase(quest_id)
	_log("Quest completed: %s" % quest.title)
	_sync_world_state()
	return {"ok": true, "quest_id": quest_id, "status": "completed"}


func turn_in_quest(quest_id: String) -> Dictionary:
	if not completed_quests.has(quest_id):
		return {"ok": false, "quest_id": quest_id, "error": "quest_not_completed"}
	var quest = completed_quests[quest_id]
	_apply_rewards(quest.rewards)
	quest.status = "turned_in"
	turned_in_quests[quest_id] = quest
	completed_quests.erase(quest_id)
	_log("Quest turned in: %s" % quest.title)
	_sync_world_state()
	return {"ok": true, "quest_id": quest_id, "status": "turned_in", "rewards": quest.rewards.duplicate(true)}


func get_active_quests() -> Array:
	var result: Array = []
	for quest_id in active_quests.keys():
		var quest = active_quests[quest_id]
		if quest != null:
			result.append(quest.to_save_data())
	return result


func to_save_data() -> Dictionary:
	return {
		"available_quests": _dict_to_save(available_quests),
		"active_quests": _dict_to_save(active_quests),
		"completed_quests": _dict_to_save(completed_quests),
		"turned_in_quests": _dict_to_save(turned_in_quests)
	}


func load_save_data(data: Dictionary) -> void:
	available_quests = _load_quest_dict(data.get("available_quests", {}))
	active_quests = _load_quest_dict(data.get("active_quests", {}))
	completed_quests = _load_quest_dict(data.get("completed_quests", {}))
	turned_in_quests = _load_quest_dict(data.get("turned_in_quests", {}))


func _can_show(quest, context: Dictionary) -> bool:
	var world_state = _world_state()
	if quest.required_realm_order > 0:
		var progression = world_state.progression_data if world_state != null and world_state.get("progression_data") is Dictionary else {}
		var order = int(context.get("current_realm_order", progression.get("current_realm_order", 0)))
		if order < quest.required_realm_order:
			return false
	for flag in quest.required_flags:
		var flags = world_state.global_flags if world_state != null and world_state.get("global_flags") is Dictionary else {}
		if not flags.get(str(flag), false):
			return false
	return true


func _apply_rewards(rewards: Dictionary) -> void:
	var world_state = _world_state()
	if world_state == null:
		return
	for item_id in rewards.get("items", {}).keys():
		world_state.add_item(str(item_id), int(rewards["items"][item_id]))
	if int(rewards.get("coin", 0)) > 0:
		world_state.add_item("coin", int(rewards.get("coin", 0)))
	if int(rewards.get("progression_points", 0)) > 0:
		world_state.add_progression_points(int(rewards.get("progression_points", 0)), "quest_reward")
	for faction_id in rewards.get("faction_attitude", {}).keys():
		world_state.modify_faction_attitude(str(faction_id), int(rewards["faction_attitude"][faction_id]))
	for flag in rewards.get("unlock_flags", []):
		world_state.global_flags[str(flag)] = true


func _sync_world_state() -> void:
	var world_state = _world_state()
	if world_state != null:
		world_state.quest_state = to_save_data()


func _dict_to_save(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for quest_id in source.keys():
		var quest = source[quest_id]
		result[quest_id] = quest.to_save_data() if quest != null and quest.has_method("to_save_data") else {}
	return result


func _load_quest_dict(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	if not (source is Dictionary):
		return result
	for quest_id in source.keys():
		var quest = QuestDataClass.new()
		quest.setup(source[quest_id] if source[quest_id] is Dictionary else {})
		if quest.quest_id == "":
			quest.quest_id = str(quest_id)
		result[quest.quest_id] = quest
	return result


func _log(text: String) -> void:
	if Engine.get_main_loop() is SceneTree:
		var log = Engine.get_main_loop().root.get_node_or_null("GameLog")
		if log != null and log.has_method("add_entry"):
			log.add_entry(text)


func _world_state():
	if Engine.get_main_loop() is SceneTree:
		return Engine.get_main_loop().root.get_node_or_null("WorldState")
	return null
