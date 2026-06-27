extends RefCounted
class_name MapTypeRuleLoader
## MapTypeRuleLoader.gd - reads map generation defaults by map_type.

const RULE_PATH := "res://data/map_generation/map_type_rules.json"

var rules: Dictionary = {}


func load_rules(path: String = RULE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Map type rules missing: %s" % path)
		rules = {}
		return rules
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Map type rules could not be opened: %s" % path)
		rules = {}
		return rules
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	rules = parsed if parsed is Dictionary else {}
	return rules


func get_rule(map_type: String) -> Dictionary:
	if rules.is_empty():
		load_rules()
	return rules.get(map_type, rules.get("village", {})).duplicate(true)


func get_default_size(map_type: String) -> Vector2i:
	var size = get_rule(map_type).get("default_size", [64, 64])
	if size is Array and size.size() >= 2:
		return Vector2i(int(size[0]), int(size[1]))
	return Vector2i(64, 64)


func validate_rules() -> Dictionary:
	if rules.is_empty():
		load_rules()
	var errors: Array = []
	for required in ["village", "forest", "cave", "sect_gate", "interior", "secret_realm"]:
		if not rules.has(required):
			errors.append("missing map_type rule: %s" % required)
	return {"ok": errors.is_empty(), "errors": errors, "warnings": []}
