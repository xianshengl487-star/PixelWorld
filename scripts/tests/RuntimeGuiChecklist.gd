extends SceneTree
## RuntimeGuiChecklist.gd - non-headless helper for manual GUI validation.


func _init() -> void:
	await process_frame
	await process_frame
	var current_scene = root.get_child(root.get_child_count() - 1) if root.get_child_count() > 0 else null
	var game_world = root.get_node_or_null("GameWorld")
	if game_world == null:
		game_world = root.find_child("GameWorld", true, false)
	var player = root.find_child("Player", true, false)
	var hud = root.find_child("GameHUD", true, false)
	print("RuntimeGuiChecklist")
	print("current_scene=%s" % (current_scene.name if current_scene != null else ""))
	print("current_map_id=%s" % WorldState.current_map_id)
	print("player_exists=%s" % str(player != null))
	print("hud_exists=%s" % str(hud != null))
	if game_world != null:
		print("building_layer_exists=%s" % str(game_world.get_node_or_null("BuildingLayer") != null))
		print("transition_layer_exists=%s" % str(game_world.get_node_or_null("TransitionLayer") != null))
		if game_world.has_method("debug_summary"):
			print("debug_summary=%s" % JSON.stringify(game_world.debug_summary()))
	print("active_quest_count=%d" % _active_quest_count())
	print("map_states_count=%d" % WorldState.map_states.size())
	print("runtime_errors_count=%d" % WorldState.last_errors.size())
	quit(0)


func _active_quest_count() -> int:
	var active = WorldState.quest_state.get("active_quests", {}) if WorldState.quest_state is Dictionary else {}
	return active.size() if active is Dictionary else 0
