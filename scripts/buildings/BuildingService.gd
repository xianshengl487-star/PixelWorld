extends RefCounted
class_name BuildingService
## BuildingService.gd - deterministic building services for v0.4.2.

const QuestSystemClass = preload("res://scripts/quests/QuestSystem.gd")

var service_id: String = ""
var service_type: String = "dialogue_only"
var display_name: String = ""
var owner_building_id: String = ""
var npc_id: String = ""
var enabled: bool = true
var required_flags: Array = []
var required_items: Array = []
var required_realm_order: int = 0

var healer_cost: Dictionary = {"coin": 3}
var inn_cost: Dictionary = {"coin": 5}
var blacksmith_cost: Dictionary = {"coin": 10, "iron_ore": 1}
var training_cost: Dictionary = {"coin": 2}


func setup(data: Dictionary) -> void:
	service_id = str(data.get("service_id", service_id))
	service_type = str(data.get("service_type", data.get("type", service_type)))
	display_name = str(data.get("display_name", display_name))
	owner_building_id = str(data.get("owner_building_id", owner_building_id))
	npc_id = str(data.get("npc_id", npc_id))
	enabled = bool(data.get("enabled", enabled))
	required_flags = _as_array(data.get("required_flags", required_flags))
	required_items = _as_array(data.get("required_items", required_items))
	required_realm_order = int(data.get("required_realm_order", required_realm_order))
	healer_cost = _as_dict(data.get("healer_cost", healer_cost))
	inn_cost = _as_dict(data.get("inn_cost", inn_cost))
	blacksmith_cost = _as_dict(data.get("blacksmith_cost", blacksmith_cost))
	training_cost = _as_dict(data.get("training_cost", training_cost))


func can_use(world_state) -> Dictionary:
	if not enabled:
		return {"ok": false, "reason": "service_disabled"}
	if world_state == null:
		return {"ok": true, "reason": ""}
	var flags = _get_world_flags(world_state)
	for flag in required_flags:
		if not flags.get(str(flag), false):
			return {"ok": false, "reason": "missing_flag:%s" % str(flag)}
	for item in required_items:
		if not _has_item(world_state, str(item), 1):
			return {"ok": false, "reason": "missing_item:%s" % str(item)}
	if required_realm_order > 0 and _get_progression_order(world_state) < required_realm_order:
		return {"ok": false, "reason": "realm_too_low"}
	return {"ok": true, "reason": ""}


func use_service(player, world_state) -> Dictionary:
	var check = can_use(world_state)
	if not check.get("ok", false):
		_log("Service blocked: %s" % check.get("reason", "unknown"))
		return check
	match service_type:
		"healer":
			return _use_healer(player, world_state)
		"inn":
			return _use_inn(player, world_state)
		"shop":
			var goods = get_goods()
			_log("Shop opened with %d goods." % goods.size())
			return {"ok": true, "service_type": service_type, "goods": goods, "message": "shop_opened"}
		"blacksmith":
			return upgrade_weapon_level(world_state)
		"quest_board", "sect_task":
			return _use_quest_board(world_state)
		"training":
			return _use_training(world_state)
		"storage":
			return _use_storage(world_state)
		_:
			_log("Building service used: %s" % service_type)
			return {"ok": true, "service_type": service_type, "message": "placeholder"}


func get_goods() -> Array:
	return [
		{"item_id": "potion", "display_name": "Potion", "price": 4},
		{"item_id": "herb", "display_name": "Herb", "price": 1},
		{"item_id": "food_bun", "display_name": "Food Bun", "price": 2},
		{"item_id": "torch", "display_name": "Torch", "price": 2}
	]


func buy_item(item_id: String, amount: int, world_state) -> Dictionary:
	amount = max(1, amount)
	var price = -1
	for goods in get_goods():
		if str(goods.get("item_id", "")) == item_id:
			price = int(goods.get("price", 0)) * amount
			break
	if price < 0:
		return {"ok": false, "service_type": "shop", "error": "unknown_item", "item_id": item_id}
	if not _spend(world_state, {"coin": price}):
		_log("Shop purchase failed: not enough coin.")
		return {"ok": false, "service_type": "shop", "error": "not_enough_coin", "cost": {"coin": price}}
	if world_state != null and world_state.has_method("add_item"):
		world_state.add_item(item_id, amount)
	_log("Shop purchase: %s x%d." % [item_id, amount])
	return {"ok": true, "service_type": "shop", "item_id": item_id, "amount": amount, "cost": {"coin": price}}


func upgrade_weapon_level(world_state) -> Dictionary:
	if world_state == null:
		return {"ok": false, "service_type": "blacksmith", "error": "missing_world_state"}
	if not _spend(world_state, blacksmith_cost):
		_log("Blacksmith upgrade failed: missing materials.")
		return {"ok": false, "service_type": "blacksmith", "error": "not_enough_materials", "cost": blacksmith_cost.duplicate(true)}
	if not (world_state.equipment_state is Dictionary):
		world_state.equipment_state = {}
	var level = int(world_state.equipment_state.get("weapon_level", 0)) + 1
	world_state.equipment_state["weapon_level"] = level
	if not (world_state.player_stats is Dictionary):
		world_state.player_stats = {}
	var bonus = world_state.player_stats.get("equipment_bonus", {})
	if not (bonus is Dictionary):
		bonus = {}
	bonus["attack"] = int(bonus.get("attack", 0)) + 1
	world_state.player_stats["equipment_bonus"] = bonus
	_log("Blacksmith upgraded weapon to level %d." % level)
	return {"ok": true, "service_type": "blacksmith", "weapon_level": level, "cost": blacksmith_cost.duplicate(true), "effects": {"attack": 1}}


func _use_healer(player, world_state) -> Dictionary:
	var paid = _spend(world_state, healer_cost)
	if not paid:
		_restore_health(player, world_state, 5)
		_log("Healer offered basic first aid without payment.")
		return {"ok": false, "service_type": "healer", "error": "not_enough_coin", "cost": healer_cost.duplicate(true), "effects": {"heal": 5}, "message": "not_enough_coin_first_aid"}
	var amount = _restore_health(player, world_state)
	_log("Healer restored health.")
	return {"ok": true, "service_type": "healer", "cost": healer_cost.duplicate(true), "effects": {"heal": amount}, "message": "healed"}


func _use_inn(player, world_state) -> Dictionary:
	if not _spend(world_state, inn_cost):
		_log("Inn rest failed: not enough coin.")
		return {"ok": false, "service_type": "inn", "error": "not_enough_coin", "cost": inn_cost.duplicate(true)}
	var healed = _restore_health(player, world_state)
	var stamina = _restore_stamina(player, world_state)
	if world_state != null:
		world_state.current_day += 1
		world_state.current_hour = 6
	_log("Inn rest restored health and stamina.")
	return {"ok": true, "service_type": "inn", "cost": inn_cost.duplicate(true), "effects": {"heal": healed, "stamina": stamina, "day": world_state.current_day if world_state != null else 0, "hour": world_state.current_hour if world_state != null else 0}, "message": "rested"}


func _use_quest_board(world_state) -> Dictionary:
	var system = QuestSystemClass.new()
	var result = system.load_quests()
	if world_state != null and world_state.get("quest_state") != null and world_state.quest_state is Dictionary and not world_state.quest_state.is_empty():
		system.load_save_data(world_state.quest_state)
	var quests = system.get_available_quests()
	if world_state != null:
		world_state.quest_state = system.to_save_data()
	_log("Quest board opened.")
	return {"ok": result.get("ok", false), "service_type": "quest_board", "quests": quests, "message": "quest_board_opened"}


func _use_training(world_state) -> Dictionary:
	if world_state == null:
		return {"ok": false, "service_type": "training", "error": "missing_world_state"}
	var key = "day_%d" % int(world_state.current_day)
	var used = int(world_state.training_used_today.get(key, 0))
	if used >= 3:
		_log("Training limit reached.")
		return {"ok": false, "service_type": "training", "error": "daily_limit"}
	if not _spend(world_state, training_cost):
		_log("Training failed: not enough coin.")
		return {"ok": false, "service_type": "training", "error": "not_enough_coin", "cost": training_cost.duplicate(true)}
	world_state.training_used_today[key] = used + 1
	if world_state.has_method("add_progression_points"):
		world_state.add_progression_points(4, "building_training")
	_log("Training granted progress.")
	return {"ok": true, "service_type": "training", "cost": training_cost.duplicate(true), "effects": {"progression_points": 4, "used_today": used + 1}}


func _use_storage(world_state) -> Dictionary:
	if world_state != null:
		world_state.building_states[owner_building_id if owner_building_id != "" else "storage"] = {"storage_opened": true, "open": true}
	_log("Storage opened.")
	return {"ok": true, "service_type": "storage", "effects": {"storage_opened": true}, "message": "storage_opened"}


func _restore_health(player, world_state, amount: int = -1) -> int:
	var restored = 0
	var stats = player.get_stats() if player != null and player.has_method("get_stats") else null
	if stats != null and stats.has_method("heal"):
		var heal_amount = stats.max_health if amount < 0 else amount
		restored = stats.heal(heal_amount)
	if world_state != null:
		if amount < 0:
			restored = max(restored, world_state.player_max_health - world_state.player_health)
			world_state.player_health = world_state.player_max_health
		else:
			var before = world_state.player_health
			world_state.player_health = min(world_state.player_max_health, world_state.player_health + amount)
			restored = max(restored, world_state.player_health - before)
	return restored


func _restore_stamina(player, world_state) -> int:
	var restored = 0
	var stats = player.get_stats() if player != null and player.has_method("get_stats") else null
	if stats != null and stats.has_method("restore_stamina"):
		restored = stats.restore_stamina(stats.max_stamina)
	if world_state != null:
		restored = max(restored, world_state.player_max_stamina - world_state.player_stamina)
		world_state.player_stamina = world_state.player_max_stamina
	return restored


func _spend(world_state, cost: Dictionary) -> bool:
	if world_state == null:
		return cost.is_empty()
	for item_id in cost.keys():
		if not _has_item(world_state, str(item_id), int(cost[item_id])):
			return false
	for item_id in cost.keys():
		if world_state.has_method("remove_item"):
			world_state.remove_item(str(item_id), int(cost[item_id]))
	return true


func _get_world_flags(world_state) -> Dictionary:
	if world_state == null:
		return {}
	var flags = world_state.get("global_flags")
	return flags if flags is Dictionary else {}


func _get_progression_order(world_state) -> int:
	if world_state == null:
		return 0
	var progression = world_state.get("progression_data")
	return int(progression.get("current_realm_order", 0)) if progression is Dictionary else 0


func _has_item(world_state, item_id: String, amount: int) -> bool:
	if world_state == null:
		return false
	return world_state.has_method("has_item") and world_state.has_item(item_id, amount)


func _as_array(value) -> Array:
	return value.duplicate(true) if value is Array else []


func _as_dict(value) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _log(text: String) -> void:
	if Engine.get_main_loop() is SceneTree:
		var log = Engine.get_main_loop().root.get_node_or_null("GameLog")
		if log != null and log.has_method("add_entry"):
			log.add_entry(text)
