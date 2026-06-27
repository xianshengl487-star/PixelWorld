extends RefCounted
class_name ProgressionTemplateLoader
## ProgressionTemplateLoader.gd - loads and validates world-type progression JSON.

const TEMPLATE_PATHS := {
	"xianxia": "res://data/progression_templates/xianxia_progression.json",
	"magic": "res://data/progression_templates/magic_progression.json",
	"apocalypse": "res://data/progression_templates/apocalypse_progression.json",
	"cyberpunk": "res://data/progression_templates/cyberpunk_progression.json",
	"wuxia": "res://data/progression_templates/wuxia_progression.json",
	"urban_ability": "res://data/progression_templates/urban_ability_progression.json",
	"strange_tale": "res://data/progression_templates/strange_tale_progression.json",
	"star_sci": "res://data/progression_templates/star_sci_progression.json"
}


func load_template(world_type: String) -> Dictionary:
	var key = world_type.strip_edges().to_lower()
	if not TEMPLATE_PATHS.has(key):
		_warn("Unknown progression world_type: %s" % world_type)
		return {}
	return load_template_by_path(TEMPLATE_PATHS[key])


func load_template_by_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_warn("Progression template file missing: %s" % path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_warn("Progression template could not be opened: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or not (parsed is Dictionary):
		_warn("Progression template parse failed: %s" % path)
		return {}
	var validation = validate_template(parsed)
	if not validation.get("ok", false):
		_warn("Progression template invalid: %s errors=%s" % [path, str(validation.get("errors", []))])
	return parsed


func validate_template(template: Dictionary) -> Dictionary:
	var errors: Array = []
	var required = [
		"system_id",
		"display_name",
		"exp_label",
		"stage_label",
		"breakthrough_label",
		"realms",
		"failure_consequences",
		"world_effects",
		"progression_resources"
	]
	for key in required:
		if not template.has(key):
			errors.append("missing:%s" % key)
	var realms = template.get("realms", [])
	if not (realms is Array) or realms.size() < 8:
		errors.append("realms:min_8")
	else:
		for i in range(realms.size()):
			var realm = realms[i]
			if not (realm is Dictionary):
				errors.append("realm_%d:not_dictionary" % i)
				continue
			for key in ["id", "name", "order", "minor_stages", "base_effects", "breakthrough"]:
				if not realm.has(key):
					errors.append("realm_%s:missing_%s" % [realm.get("id", str(i)), key])
			var breakthrough = realm.get("breakthrough", {})
			if breakthrough is Dictionary:
				for key in ["required_progress", "success_base", "risk_type", "failure_effects"]:
					if not breakthrough.has(key):
						errors.append("breakthrough_%s:missing_%s" % [realm.get("id", str(i)), key])
			else:
				errors.append("realm_%s:breakthrough_not_dictionary" % realm.get("id", str(i)))
	return {"ok": errors.is_empty(), "errors": errors}


func get_supported_world_types() -> Array:
	return TEMPLATE_PATHS.keys()


func _warn(message: String) -> void:
	push_warning(message)
	var loop = Engine.get_main_loop()
	if loop is SceneTree:
		var log = loop.root.get_node_or_null("GameLog")
		if log != null and log.has_method("add_warning"):
			log.add_warning(message)
