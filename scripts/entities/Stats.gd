extends Node
class_name Stats
## Stats.gd - compatible combat stats plus v0.3.0 layered growth bonuses.

signal health_changed(current: int, max: int)
signal stamina_changed(current: int, max: int)
signal died

@export var max_health: int = 20
@export var health: int = 20
@export var attack: int = 4
@export var defense: int = 1
@export var move_speed: float = 150.0
@export var max_stamina: int = 10
@export var stamina: int = 10

var is_dead: bool = false
var base_stats: Dictionary = {}
var equipment_bonus: Dictionary = {}
var progression_bonus: Dictionary = {}
var status_bonus: Dictionary = {}
var final_stats: Dictionary = {}


func _ready() -> void:
	if base_stats.is_empty():
		setup_defaults()
	health = clampi(health, 0, max_health)
	stamina = clampi(stamina, 0, max_stamina)
	is_dead = health <= 0


func setup_defaults() -> void:
	base_stats = {
		"strength": 1,
		"agility": 2,
		"vitality": 2,
		"perception": 1,
		"insight": 1,
		"charisma": 1,
		"luck": 1
	}
	equipment_bonus = {}
	progression_bonus = {}
	status_bonus = {}
	recalculate()
	health = max_health
	stamina = max_stamina
	is_dead = false


func configure(data: Dictionary) -> void:
	if base_stats.is_empty():
		setup_defaults()
	if data.has("base_stats") and data["base_stats"] is Dictionary:
		base_stats = data["base_stats"].duplicate(true)
	if data.has("equipment_bonus") and data["equipment_bonus"] is Dictionary:
		equipment_bonus = data["equipment_bonus"].duplicate(true)
	if data.has("progression_bonus") and data["progression_bonus"] is Dictionary:
		progression_bonus = data["progression_bonus"].duplicate(true)
	if data.has("status_bonus") and data["status_bonus"] is Dictionary:
		status_bonus = data["status_bonus"].duplicate(true)
	recalculate()
	for key in ["max_health", "max_stamina", "attack", "defense", "move_speed", "accuracy", "dodge_rate", "crit_rate", "crit_damage", "discovery_chance", "trap_awareness", "loot_bonus", "gather_power", "breakthrough_bonus", "tribulation_resistance", "spiritual_sense", "magic_affinity", "infection_resistance", "cyber_sync", "inner_power", "sanity_resistance", "technology_mastery"]:
		if data.has(key):
			final_stats[key] = data[key]
	max_health = int(final_stats.get("max_health", max_health))
	max_stamina = int(final_stats.get("max_stamina", max_stamina))
	attack = int(final_stats.get("attack", attack))
	defense = int(final_stats.get("defense", defense))
	move_speed = float(final_stats.get("move_speed", move_speed))
	health = int(data.get("health", min(health, max_health)))
	stamina = int(data.get("stamina", min(stamina, max_stamina)))
	is_dead = bool(data.get("is_dead", health <= 0))
	health = clampi(health, 0, max_health)
	stamina = clampi(stamina, 0, max_stamina)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func recalculate() -> void:
	if base_stats.is_empty():
		base_stats = {
			"strength": 1,
			"agility": 2,
			"vitality": 2,
			"perception": 1,
			"insight": 1,
			"charisma": 1,
			"luck": 1
		}
	var old_max_health = max(1, max_health)
	var old_max_stamina = max(1, max_stamina)
	var health_ratio = float(health) / float(old_max_health)
	var stamina_ratio = float(stamina) / float(old_max_stamina)
	var strength = float(_sum_stat("strength"))
	var agility = float(_sum_stat("agility"))
	var vitality = float(_sum_stat("vitality"))
	var perception = float(_sum_stat("perception"))
	var insight = float(_sum_stat("insight"))
	var luck = float(_sum_stat("luck"))
	final_stats = {
		"strength": strength,
		"agility": agility,
		"vitality": vitality,
		"perception": perception,
		"insight": insight,
		"charisma": _sum_stat("charisma"),
		"luck": luck,
		"max_health": int(20 + vitality * 5 + _direct_bonus("max_health")),
		"max_stamina": int(20 + agility * 2 + vitality + _direct_bonus("max_stamina")),
		"attack": int(3 + strength * 2 + _direct_bonus("attack")),
		"defense": int(vitality + floor(strength * 0.5) + _direct_bonus("defense")),
		"move_speed": float(100 + agility * 4 + _direct_bonus("move_speed")),
		"accuracy": min(0.99, 0.85 + perception * 0.01 + _direct_bonus("accuracy")),
		"dodge_rate": min(0.35, agility * 0.005 + _direct_bonus("dodge_rate")),
		"crit_rate": min(0.5, luck * 0.01 + _direct_bonus("crit_rate")),
		"crit_damage": 1.5 + insight * 0.01 + _direct_bonus("crit_damage"),
		"discovery_chance": min(0.5, 0.05 + perception * 0.01 + luck * 0.005 + _direct_bonus("discovery_chance")),
		"trap_awareness": min(0.5, 0.05 + perception * 0.015 + _direct_bonus("trap_awareness")),
		"loot_bonus": min(0.5, luck * 0.01 + _direct_bonus("loot_bonus")),
		"gather_power": int(1 + floor(strength / 2.0) + _direct_bonus("gather_power")),
		"breakthrough_bonus": insight * 0.01 + luck * 0.005 + _direct_bonus("breakthrough_bonus"),
		"tribulation_resistance": vitality * 0.01 + insight * 0.005 + _direct_bonus("tribulation_resistance"),
		"spiritual_sense": _direct_bonus("spiritual_sense"),
		"magic_affinity": _direct_bonus("magic_affinity"),
		"infection_resistance": _direct_bonus("infection_resistance"),
		"cyber_sync": _direct_bonus("cyber_sync"),
		"inner_power": _direct_bonus("inner_power"),
		"sanity_resistance": _direct_bonus("sanity_resistance"),
		"technology_mastery": _direct_bonus("technology_mastery")
	}
	max_health = max(1, int(final_stats.get("max_health", 20)))
	max_stamina = max(1, int(final_stats.get("max_stamina", 20)))
	attack = max(0, int(final_stats.get("attack", 1)))
	defense = max(0, int(final_stats.get("defense", 0)))
	move_speed = max(10.0, float(final_stats.get("move_speed", 100.0)))
	health = clampi(int(round(health_ratio * max_health)), 0, max_health)
	stamina = clampi(int(round(stamina_ratio * max_stamina)), 0, max_stamina)
	is_dead = health <= 0


func get_stat(stat_id: String, default_value = 0):
	if stat_id == "health":
		return health
	if stat_id == "stamina":
		return stamina
	if final_stats.has(stat_id):
		return final_stats[stat_id]
	if base_stats.has(stat_id):
		return base_stats[stat_id]
	return default_value


func set_base_stat(stat_id: String, value) -> void:
	if base_stats.is_empty():
		setup_defaults()
	base_stats[stat_id] = value
	recalculate()


func add_base_stat(stat_id: String, amount) -> void:
	set_base_stat(stat_id, get_stat(stat_id, 0) + amount)


func add_equipment_bonus(stat_id: String, amount) -> void:
	equipment_bonus[stat_id] = equipment_bonus.get(stat_id, 0) + amount
	recalculate()


func clear_equipment_bonus() -> void:
	equipment_bonus.clear()
	recalculate()


func add_progression_bonus(stat_id: String, amount) -> void:
	progression_bonus[stat_id] = progression_bonus.get(stat_id, 0) + amount
	recalculate()


func clear_progression_bonus() -> void:
	progression_bonus.clear()
	recalculate()


func add_status_bonus(stat_id: String, amount) -> void:
	status_bonus[stat_id] = status_bonus.get(stat_id, 0) + amount
	recalculate()


func clear_status_bonus() -> void:
	status_bonus.clear()
	recalculate()


func take_damage(amount: int, damage_type: String = "physical") -> int:
	if is_dead:
		return 0
	var damage = max(0, amount)
	health = clampi(health - damage, 0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0:
		die()
	return damage


func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	var before = health
	health = clampi(health + amount, 0, max_health)
	if health > 0:
		is_dead = false
	health_changed.emit(health, max_health)
	return health - before


func use_stamina(amount: int) -> bool:
	if amount <= 0:
		return true
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina, max_stamina)
	return true


func restore_stamina(amount: int) -> int:
	if amount <= 0:
		return 0
	var before = stamina
	stamina = clampi(stamina + amount, 0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)
	return stamina - before


func die() -> void:
	if is_dead:
		return
	is_dead = true
	health = 0
	health_changed.emit(health, max_health)
	died.emit()


func revive(full_restore: bool = true) -> void:
	is_dead = false
	if full_restore:
		health = max_health
		stamina = max_stamina
	else:
		health = max(1, health)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func to_save_data() -> Dictionary:
	return {
		"max_health": max_health,
		"health": health,
		"attack": attack,
		"defense": defense,
		"move_speed": move_speed,
		"max_stamina": max_stamina,
		"stamina": stamina,
		"is_dead": is_dead,
		"base_stats": base_stats,
		"equipment_bonus": equipment_bonus,
		"progression_bonus": progression_bonus,
		"status_bonus": status_bonus,
		"final_stats": final_stats
	}


func load_save_data(data: Dictionary) -> void:
	configure(data)


func to_dict() -> Dictionary:
	return to_save_data()


func _sum_stat(stat_id: String):
	return base_stats.get(stat_id, 0) + equipment_bonus.get(stat_id, 0) + progression_bonus.get(stat_id, 0) + status_bonus.get(stat_id, 0)


func _direct_bonus(stat_id: String):
	return equipment_bonus.get(stat_id, 0) + progression_bonus.get(stat_id, 0) + status_bonus.get(stat_id, 0)
