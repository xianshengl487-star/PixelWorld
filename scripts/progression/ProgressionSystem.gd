extends RefCounted
class_name ProgressionSystem
## ProgressionSystem.gd - world-type growth, stages, bottlenecks, and breakthrough orchestration.

const BreakthroughSystemClass = preload("res://scripts/progression/BreakthroughSystem.gd")
const TribulationSystemClass = preload("res://scripts/progression/TribulationSystem.gd")
const RealmEffectApplierClass = preload("res://scripts/progression/RealmEffectApplier.gd")
const WorldRuleModifierClass = preload("res://scripts/progression/WorldRuleModifier.gd")

var _world_state = null
var _world_type: String = ""
var _template: Dictionary = {}


func setup(world_type: String, template: Dictionary) -> void:
	_world_type = world_type
	_template = template
	if _world_state == null:
		_world_state = _autoload("WorldState")
	if _world_state != null and _world_state.has_method("init_progression"):
		_world_state.init_progression(world_type, template)


func bind_world_state(world_state) -> void:
	_world_state = world_state


func get_current_realm() -> Dictionary:
	return _realm_by_id(_data().get("current_realm_id", ""))


func get_next_realm() -> Dictionary:
	var current_order = int(_data().get("current_realm_order", 0))
	for realm in _template.get("realms", []):
		if int(realm.get("order", -1)) == current_order + 1:
			return realm
	return {}


func get_current_stage_name() -> String:
	return str(_data().get("current_stage_name", ""))


func gain_progress(amount: int, reason: String = "") -> Dictionary:
	if amount <= 0:
		return {"ok": false, "message": "没有获得成长资源。"}
	var data = _data()
	data["current_progress"] = int(data.get("current_progress", 0)) + amount
	if _world_state != null and _world_state.has_method("add_progression_points"):
		_world_state.add_progression_points(0, reason)
	var can_stage = can_advance_minor_stage()
	var message = "获得 %d 点%s。" % [amount, data.get("exp_label", "成长")]
	if reason != "":
		message += " 来源: %s。" % reason
	_log(message)
	return {
		"ok": true,
		"message": message,
		"realm_changed": false,
		"stage_changed": false,
		"can_advance": can_stage.get("ok", false),
		"effects": {},
		"world_changes": {},
		"log_action": true
	}


func can_advance_minor_stage() -> Dictionary:
	var data = _data()
	var realm = get_current_realm()
	var stages = realm.get("minor_stages", [])
	var current_stage = int(data.get("current_stage", 0))
	if current_stage >= stages.size() - 1:
		data["bottleneck"] = true
		data["bottleneck_reason"] = "当前大境界已圆满，需要突破。"
		return {"ok": false, "reason": "bottleneck"}
	var required = _stage_required_progress(realm, current_stage)
	if int(data.get("current_progress", 0)) < required:
		return {"ok": false, "reason": "not_enough_progress", "required": required}
	return {"ok": true, "required": required}


func advance_minor_stage() -> Dictionary:
	var check = can_advance_minor_stage()
	if not check.get("ok", false):
		return {"ok": false, "message": "当前还不能提升小阶段。", "reason": check.get("reason", "")}
	var data = _data()
	var realm = get_current_realm()
	var stages = realm.get("minor_stages", [])
	var next_stage = int(data.get("current_stage", 0)) + 1
	data["current_stage"] = next_stage
	data["current_stage_name"] = str(stages[next_stage])
	data["current_progress"] = max(0, int(data.get("current_progress", 0)) - int(check.get("required", 0)))
	data["progress_to_next"] = _stage_required_progress(realm, next_stage)
	var entry = {
		"type": "minor_stage",
		"realm_id": realm.get("id", ""),
		"stage": next_stage,
		"stage_name": data["current_stage_name"],
		"time": Time.get_datetime_string_from_system()
	}
	if _world_state != null and _world_state.has_method("add_progression_history"):
		_world_state.add_progression_history(entry)
	_log("你提升到了%s%s。" % [realm.get("name", ""), data["current_stage_name"]])
	return {
		"ok": true,
		"message": "你提升到了%s%s。" % [realm.get("name", ""), data["current_stage_name"]],
		"realm_changed": false,
		"stage_changed": true,
		"effects": realm.get("stage_effects", {}),
		"world_changes": {},
		"log_action": true
	}


func can_breakthrough() -> Dictionary:
	var data = _data()
	var realm = get_current_realm()
	var next_realm = get_next_realm()
	if next_realm.is_empty():
		return {"ok": false, "reason": "no_next_realm"}
	var stages = realm.get("minor_stages", [])
	if int(data.get("current_stage", 0)) < stages.size() - 1:
		return {"ok": false, "reason": "minor_stage_not_complete"}
	var required = int(realm.get("breakthrough", {}).get("required_progress", 0))
	if int(data.get("current_progress", 0)) < required:
		return {"ok": false, "reason": "not_enough_progress", "required": required}
	return {"ok": true, "next_realm": next_realm}


func attempt_breakthrough(context: Dictionary = {}) -> Dictionary:
	var data = _data()
	var realm = get_current_realm()
	var next_realm = get_next_realm()
	if realm.is_empty() or next_realm.is_empty():
		return {"ok": false, "message": "没有可突破的大境界。"}
	var result = BreakthroughSystemClass.new().attempt(data, realm, context)
	var record = result.duplicate(true)
	record["from_realm"] = realm.get("id", "")
	record["to_realm"] = next_realm.get("id", "")
	if result.get("result", "") in ["success", "partial_success"]:
		if result.get("requires_tribulation", false):
			TribulationSystemClass.new().start_tribulation(result.get("tribulation_type", "minor_bottleneck"), int(realm.get("breakthrough", {}).get("tribulation_rounds", 1)), context)
		_enter_realm(next_realm)
		record["realm_changed"] = true
	else:
		record["realm_changed"] = false
	if _world_state != null and _world_state.has_method("add_breakthrough_record"):
		_world_state.add_breakthrough_record(record)
	_log(str(result.get("message", "")))
	result["ok"] = result.get("result", "") in ["success", "partial_success"]
	return result


func apply_current_realm_effects(stats) -> void:
	var realm = get_current_realm()
	RealmEffectApplierClass.new().apply_effects(stats, realm.get("base_effects", {}))


func get_display_summary() -> Dictionary:
	var data = _data()
	return {
		"system_name": data.get("system_name", ""),
		"exp_label": data.get("exp_label", "成长"),
		"stage_label": data.get("stage_label", "阶段"),
		"breakthrough_label": data.get("breakthrough_label", "突破"),
		"current_realm_name": data.get("current_realm_name", ""),
		"current_stage_name": data.get("current_stage_name", ""),
		"current_progress": data.get("current_progress", 0),
		"progress_to_next": data.get("progress_to_next", 0),
		"bottleneck": data.get("bottleneck", false),
		"bottleneck_reason": data.get("bottleneck_reason", ""),
		"tribulation_pending": data.get("tribulation_pending", false),
		"tribulation_type": data.get("tribulation_type", ""),
		"unlocked_features": data.get("unlocked_features", []),
		"world_modifiers": data.get("world_modifiers", {})
	}


func _enter_realm(realm: Dictionary) -> void:
	var data = _data()
	var stages = realm.get("minor_stages", [])
	data["current_realm_id"] = realm.get("id", "")
	data["current_realm_name"] = realm.get("name", "")
	data["current_realm_order"] = int(realm.get("order", 0))
	data["current_stage"] = 0
	data["current_stage_name"] = str(stages[0]) if stages.size() > 0 else ""
	data["current_progress"] = 0
	data["progress_to_next"] = _stage_required_progress(realm, 0)
	data["bottleneck"] = false
	data["bottleneck_reason"] = ""
	for feature in realm.get("unlock_features", []):
		if _world_state != null and _world_state.has_method("unlock_feature"):
			_world_state.unlock_feature(str(feature))
	WorldRuleModifierClass.new().apply_world_effects(_world_state, realm.get("world_effects", {}))


func _realm_by_id(id: String) -> Dictionary:
	for realm in _template.get("realms", []):
		if str(realm.get("id", "")) == id:
			return realm
	return _template.get("realms", [])[0] if _template.get("realms", []).size() > 0 else {}


func _stage_required_progress(realm: Dictionary, stage_index: int) -> int:
	var breakthrough = realm.get("breakthrough", {})
	var total = max(1, int(breakthrough.get("required_progress", 1)))
	var stages = max(1, realm.get("minor_stages", []).size())
	return max(1, int(ceil(float(total) / float(stages))))


func _data() -> Dictionary:
	if _world_state == null:
		_world_state = _autoload("WorldState")
	if _world_state != null:
		return _world_state.progression_data
	return {}


func _log(message: String) -> void:
	if message == "":
		return
	var log = _autoload("GameLog")
	if log != null and log.has_method("add_entry"):
		log.add_entry(message)
	if _world_state != null and _world_state.has_method("log_action"):
		_world_state.log_action(message, {"source": "ProgressionSystem"})


func _autoload(name: String):
	var loop = Engine.get_main_loop()
	if loop is SceneTree:
		return loop.root.get_node_or_null(name)
	return null
