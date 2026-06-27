extends RefCounted
class_name BreakthroughSystem
## BreakthroughSystem.gd - calculates and resolves bottleneck attempts.


func calculate_success_rate(progression_data: Dictionary, realm_template: Dictionary, context: Dictionary = {}) -> float:
	var breakthrough = realm_template.get("breakthrough", {})
	var required_progress = int(breakthrough.get("required_progress", 0))
	var current_progress = int(progression_data.get("current_progress", 0))
	var rate = float(breakthrough.get("success_base", 0.5))
	if current_progress < required_progress:
		rate -= 0.25
	else:
		rate += min(0.15, float(current_progress - required_progress) / max(1.0, float(required_progress)) * 0.1)
	rate += float(context.get("insight", 0)) * 0.01
	rate += float(context.get("perception", 0)) * 0.004
	rate += float(context.get("luck", 0)) * 0.005
	rate += float(context.get("vitality", 0)) * 0.003
	rate += float(context.get("preparation_score", 0)) * 0.01
	rate += float(context.get("world_region_bonus", 0)) * 0.01
	rate += float(context.get("item_bonus", 0)) * 0.01
	rate += float(progression_data.get("breakthrough_points", 0)) * 0.01
	rate -= float(progression_data.get("failed_breakthroughs", 0)) * 0.03
	rate -= float(context.get("failure_count_penalty", 0))
	return clampf(rate, 0.05, 0.95)


func attempt(progression_data: Dictionary, realm_template: Dictionary, context: Dictionary = {}) -> Dictionary:
	var breakthrough = realm_template.get("breakthrough", {})
	var rate = calculate_success_rate(progression_data, realm_template, context)
	var result_type = str(context.get("force_result", ""))
	if result_type == "":
		var roll = float(context.get("roll", randf()))
		if roll <= rate:
			result_type = "success"
		elif roll <= rate + 0.12:
			result_type = "partial_success"
		elif roll >= 0.97:
			result_type = "critical_failure"
		else:
			result_type = "failure"
	var requires_tribulation = bool(breakthrough.get("requires_tribulation", false))
	var tribulation_type = str(breakthrough.get("tribulation_type", ""))
	var risk_type = str(breakthrough.get("risk_type", ""))
	if tribulation_type == "" and ("lightning" in risk_type or "tribulation" in risk_type):
		tribulation_type = "heavenly_lightning"
		requires_tribulation = true
	if result_type in ["failure", "critical_failure"]:
		progression_data["failed_breakthroughs"] = int(progression_data.get("failed_breakthroughs", 0)) + 1
		progression_data["breakthrough_points"] = int(progression_data.get("breakthrough_points", 0)) + 1
		progression_data["last_breakthrough_result"] = {"result": result_type, "realm": realm_template.get("id", "")}
		return {
			"result": result_type,
			"success_rate": rate,
			"message": _failure_message(realm_template, result_type),
			"effects": {},
			"failure_effects": breakthrough.get("failure_effects", []),
			"requires_tribulation": false,
			"tribulation_type": ""
		}
	progression_data["last_breakthrough_result"] = {"result": result_type, "realm": realm_template.get("id", "")}
	return {
		"result": result_type,
		"success_rate": rate,
		"message": _success_message(realm_template, result_type),
		"effects": breakthrough.get("success_effects", {}),
		"failure_effects": [],
		"requires_tribulation": requires_tribulation,
		"tribulation_type": tribulation_type
	}


func _success_message(realm_template: Dictionary, result_type: String) -> String:
	if result_type == "partial_success":
		return "你勉强撬开瓶颈，境界尚需稳固。"
	return "你冲破瓶颈，完成了%s。" % realm_template.get("breakthrough", {}).get("label", "突破")


func _failure_message(realm_template: Dictionary, result_type: String) -> String:
	if result_type == "critical_failure":
		return "突破大败，根基受损，但也留下了下一次的感悟。"
	return "突破失败，瓶颈仍在，但你积累了一点突破感悟。"
