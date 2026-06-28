extends RefCounted
class_name BuildingService
## BuildingService.gd - small runtime service attached to a building.

var service_id: String = ""
var service_type: String = "dialogue_only"
var display_name: String = ""
var owner_building_id: String = ""
var npc_id: String = ""
var enabled: bool = true
var required_flags: Array = []
var required_items: Array = []
var required_realm_order: int = 0


func setup(data: Dictionary) -> void:
	service_id = str(data.get("service_id", service_id))
	service_type = str(data.get("service_type", data.get("type", service_type)))
	display_name = str(data.get("display_name", display_name))
	owner_building_id = str(data.get("owner_building_id", owner_building_id))
	npc_id = str(data.get("npc_id", npc_id))
	enabled = bool(data.get("enabled", enabled))
	required_flags = data.get("required_flags", required_flags).duplicate(true)
	required_items = data.get("required_items", required_items).duplicate(true)
	required_realm_order = int(data.get("required_realm_order", required_realm_order))


func can_use(world_state) -> Dictionary:
	if not enabled:
		return {"ok": false, "reason": "service_disabled"}
	if world_state == null:
		return {"ok": true, "reason": ""}
	for flag in required_flags:
		if not world_state.global_flags.get(str(flag), false):
			return {"ok": false, "reason": "missing_flag:%s" % str(flag)}
	for item in required_items:
		if world_state.has_method("has_item") and not world_state.has_item(str(item), 1):
			return {"ok": false, "reason": "missing_item:%s" % str(item)}
	if required_realm_order > 0:
		var order = int(world_state.progression_data.get("current_realm_order", 0))
		if order < required_realm_order:
			return {"ok": false, "reason": "realm_too_low"}
	return {"ok": true, "reason": ""}


func use_service(player, world_state) -> Dictionary:
	var check = can_use(world_state)
	if not check.get("ok", false):
		return check
	match service_type:
		"healer":
			_restore_health(player, world_state)
			_log("Healer service restored health.")
			return {"ok": true, "service_type": service_type, "message": "health_restored"}
		"inn":
			_restore_health(player, world_state)
			_restore_stamina(player, world_state)
			_log("Inn service restored health and stamina.")
			return {"ok": true, "service_type": service_type, "message": "rested"}
		"shop":
			_log("Shop service placeholder.")
		"blacksmith":
			_log("Blacksmith service placeholder.")
		"quest_board", "sect_task":
			_log("Quest board: nearby monsters have been reported.")
		"training":
			if world_state != null and world_state.has_method("add_progression_points"):
				world_state.add_progression_points(3, "building_training")
			_log("Training service granted a small progress reward.")
		"storage":
			_log("Storage service placeholder.")
		_:
			_log("Building service placeholder.")
	return {"ok": true, "service_type": service_type, "message": "placeholder"}


func _restore_health(player, world_state) -> void:
	var stats = player.get_stats() if player != null and player.has_method("get_stats") else null
	if stats != null and stats.has_method("heal"):
		stats.heal(stats.max_health)
	if world_state != null:
		world_state.player_health = world_state.player_max_health


func _restore_stamina(player, world_state) -> void:
	var stats = player.get_stats() if player != null and player.has_method("get_stats") else null
	if stats != null and stats.has_method("restore_stamina"):
		stats.restore_stamina(stats.max_stamina)
	if world_state != null:
		world_state.player_stamina = world_state.player_max_stamina


func _log(text: String) -> void:
	if Engine.get_main_loop() is SceneTree:
		var log = Engine.get_main_loop().root.get_node_or_null("GameLog")
		if log != null and log.has_method("add_entry"):
			log.add_entry(text)
