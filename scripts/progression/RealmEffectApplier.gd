extends RefCounted
class_name RealmEffectApplier
## RealmEffectApplier.gd - applies realm effects into Stats progression_bonus.


func apply_effects(stats, realm_effects: Dictionary) -> Dictionary:
	var applied: Dictionary = {}
	if stats == null:
		return applied
	for key in realm_effects.keys():
		if not str(key).ends_with("_add"):
			continue
		var stat_id = str(key).substr(0, str(key).length() - 4)
		var amount = realm_effects[key]
		if stats.has_method("add_progression_bonus"):
			stats.add_progression_bonus(stat_id, amount)
			applied[stat_id] = amount
	if stats.has_method("recalculate"):
		stats.recalculate()
	return applied
