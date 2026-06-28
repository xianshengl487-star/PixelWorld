extends RefCounted
class_name InteractionTargetTracker
## Picks a single nearest interaction target and updates the HUD prompt.

var targets: Array = []
var hud = null
var max_distance: float = 96.0
var last_prompt_text: String = ""


func bind_hud(next_hud) -> void:
	hud = next_hud


func register_target(target) -> void:
	if target != null and not targets.has(target):
		targets.append(target)


func unregister_target(target) -> void:
	targets.erase(target)


func clear() -> void:
	targets.clear()
	last_prompt_text = ""


func get_best_target(player_pos: Vector2) -> Node:
	var best = null
	var best_dist := max_distance
	for target in targets.duplicate():
		if target == null or not is_instance_valid(target):
			targets.erase(target)
			continue
		if not (target is Node2D):
			continue
		var dist := player_pos.distance_to(target.global_position)
		if dist <= best_dist:
			best = target
			best_dist = dist
	return best


func update_prompt(player_pos: Vector2) -> void:
	var target = get_best_target(player_pos)
	if target == null:
		last_prompt_text = ""
		if hud != null and hud.has_method("hide_interaction_prompt"):
			hud.hide_interaction_prompt()
		return
	last_prompt_text = _prompt_for_target(target)
	if hud != null and hud.has_method("show_interaction_prompt"):
		hud.show_interaction_prompt(last_prompt_text)


func trigger_best_target(player_pos: Vector2, player = null) -> Dictionary:
	var target = get_best_target(player_pos)
	if target == null:
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("No nearby interaction target.")
		return {"ok": false, "error": "no_target"}
	if target.has_method("on_interact"):
		return target.on_interact(player)
	if target.has_method("activate"):
		return {"ok": bool(target.activate()), "target": target.name}
	if target.has_method("get_npc_data"):
		return {"ok": false, "error": "npc_requires_ai_client", "target": target.name}
	if target.has_method("interact"):
		target.interact(null)
		return {"ok": true, "target": target.name}
	return {"ok": false, "error": "target_not_interactable"}


func _prompt_for_target(target) -> String:
	if target.has_method("get_interaction_prompt"):
		return str(target.get_interaction_prompt())
	var target_name: String = str(target.name)
	if target.get("display_name") != null:
		target_name = str(target.get("display_name"))
	if target.has_method("get_npc_data"):
		var data = target.get_npc_data()
		target_name = str(data.get("name", target_name))
		return "[E] Talk: %s" % target_name
	if target.get("target_map_id") != null and str(target.get("target_map_id")) != "":
		return "[E] Travel: %s" % str(target.get("target_map_id"))
	return "[E] Interact: %s" % target_name
