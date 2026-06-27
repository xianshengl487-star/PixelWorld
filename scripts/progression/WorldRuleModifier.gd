extends RefCounted
class_name WorldRuleModifier
## WorldRuleModifier.gd - stores world-scale modifiers on WorldState.


func apply_world_effects(world_state, effects: Dictionary) -> void:
	if world_state == null:
		return
	for key in effects.keys():
		if world_state.has_method("set_world_modifier"):
			world_state.set_world_modifier(str(key), effects[key])
		elif world_state.get("world_rule_modifiers") != null:
			world_state.world_rule_modifiers[str(key)] = effects[key]


func remove_world_effect(world_state, effect_id: String) -> void:
	if world_state == null:
		return
	if world_state.get("world_rule_modifiers") != null:
		world_state.world_rule_modifiers.erase(effect_id)


func get_modifier(world_state, effect_id: String, default_value = null):
	if world_state == null:
		return default_value
	if world_state.has_method("get_world_modifier"):
		return world_state.get_world_modifier(effect_id, default_value)
	if world_state.get("world_rule_modifiers") != null:
		return world_state.world_rule_modifiers.get(effect_id, default_value)
	return default_value
