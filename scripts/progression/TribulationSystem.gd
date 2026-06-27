extends RefCounted
class_name TribulationSystem
## TribulationSystem.gd - lightweight multi-round trial/tribulation resolver.

var current_tribulation: Dictionary = {}


func start_tribulation(type: String, rounds: int, context: Dictionary = {}) -> Dictionary:
	current_tribulation = {
		"type": type,
		"rounds": max(1, rounds),
		"current_round": 0,
		"success": false,
		"finished": false,
		"context": context,
		"entries": []
	}
	var state = _world_state()
	if state != null:
		state.progression_data["tribulation_pending"] = true
		state.progression_data["tribulation_type"] = type
		if state.has_method("add_tribulation_record"):
			state.add_tribulation_record({"event": "start", "type": type, "rounds": rounds})
	return current_tribulation


func resolve_round(round_index: int, player_stats, context: Dictionary = {}) -> Dictionary:
	if current_tribulation.is_empty():
		start_tribulation(str(context.get("type", "minor_bottleneck")), int(context.get("rounds", 1)), context)
	var base_damage = int(context.get("base_damage", current_tribulation.get("context", {}).get("base_damage", 6)))
	var resistance = float(context.get("tribulation_resistance", _stat(player_stats, "tribulation_resistance", 0.0)))
	var preparation = float(context.get("preparation_score", 0.0))
	var shielded = bool(context.get("shielded", false))
	var damage = max(0, int(round(base_damage - resistance * 10.0 - preparation)))
	if shielded:
		damage = int(floor(damage * 0.6))
	var applied = damage
	if player_stats != null and player_stats.has_method("take_damage"):
		applied = int(player_stats.take_damage(damage, "tribulation"))
	var failed = bool(player_stats != null and player_stats.get("health") != null and int(player_stats.get("health")) <= 0)
	var entry = {
		"event": "round",
		"type": current_tribulation.get("type", "minor_bottleneck"),
		"round_index": round_index,
		"damage": applied,
		"failed": failed
	}
	current_tribulation["current_round"] = round_index
	current_tribulation["entries"].append(entry)
	var state = _world_state()
	if state != null and state.has_method("add_tribulation_record"):
		state.add_tribulation_record(entry)
	return entry


func finish_tribulation() -> Dictionary:
	var failed = false
	for entry in current_tribulation.get("entries", []):
		if entry.get("failed", false):
			failed = true
			break
	current_tribulation["success"] = not failed
	current_tribulation["finished"] = true
	var result = {
		"event": "finish",
		"type": current_tribulation.get("type", "minor_bottleneck"),
		"success": not failed
	}
	var state = _world_state()
	if state != null:
		state.progression_data["tribulation_pending"] = false
		state.progression_data["tribulation_type"] = ""
		if state.has_method("add_tribulation_record"):
			state.add_tribulation_record(result)
	return result


func _stat(stats, stat_id: String, fallback):
	if stats == null:
		return fallback
	if stats.has_method("get_stat"):
		return stats.get_stat(stat_id, fallback)
	var value = stats.get(stat_id)
	return fallback if value == null else value


func _world_state():
	var loop = Engine.get_main_loop()
	if loop is SceneTree:
		return loop.root.get_node_or_null("WorldState")
	return null
