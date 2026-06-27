extends RefCounted
class_name CombatSystem
## CombatSystem.gd — 第一版范围战斗结算

const StatsScript = preload("res://scripts/entities/Stats.gd")


static func calculate_damage(attacker_stats, defender_stats) -> int:
	var attack_value = _stat_value(attacker_stats, "attack", 1)
	var defense_value = _stat_value(defender_stats, "defense", 0)
	return max(1, attack_value - int(floor(defense_value * 0.5)))


static func apply_damage(attacker, defender) -> Dictionary:
	var attacker_stats = _extract_stats(attacker)
	var defender_stats = _extract_stats(defender)
	var damage = calculate_damage(attacker_stats, defender_stats)
	var applied = damage
	if defender != null and defender.has_method("take_damage"):
		applied = int(defender.take_damage(damage, attacker))
	elif defender_stats != null and defender_stats.has_method("take_damage"):
		applied = int(defender_stats.take_damage(damage))
	return {
		"damage": applied,
		"defender_dead": _is_dead(defender, defender_stats)
	}


static func spawn_hit_effect(parent: Node, world_position: Vector2) -> Node2D:
	if parent == null:
		return null
	var effect = ColorRect.new()
	effect.name = "HitEffect"
	effect.size = Vector2(18, 18)
	effect.position = world_position - Vector2(9, 9)
	effect.color = Color(1.0, 0.2, 0.15, 0.75)
	parent.add_child(effect)
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 0.15
	effect.add_child(timer)
	timer.timeout.connect(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)
	timer.start()
	return effect


static func _extract_stats(owner):
	if owner == null:
		return null
	if owner is Object and owner.get_script() == StatsScript:
		return owner
	if owner is Dictionary:
		return owner.get("stats")
	if owner.has_method("get_stats"):
		return owner.get_stats()
	var stats = owner.get("stats")
	if stats != null:
		return stats
	if owner is Node:
		return owner.get_node_or_null("Stats")
	return null


static func _stat_value(stats, key: String, fallback: int) -> int:
	if stats == null:
		return fallback
	if stats is Dictionary:
		return int(stats.get(key, fallback))
	var value = stats.get(key)
	if value == null:
		return fallback
	return int(value)


static func _is_dead(owner, stats) -> bool:
	if owner != null and owner.has_method("is_dead"):
		return bool(owner.is_dead())
	if stats == null:
		return false
	if stats is Dictionary:
		return bool(stats.get("is_dead", false))
	return bool(stats.get("is_dead"))
