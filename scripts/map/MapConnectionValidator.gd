extends RefCounted
class_name MapConnectionValidator
## MapConnectionValidator.gd - validates WorldGraph, MapInstance, transitions, and spawns.


func validate_world_graph(graph) -> Dictionary:
	if graph == null:
		return {"ok": false, "errors": ["graph is null"], "warnings": []}
	if graph.has_method("validate_graph"):
		return graph.validate_graph()
	return {"ok": false, "errors": ["graph has no validate_graph"], "warnings": []}


func validate_map_instance(map_instance) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	if map_instance == null:
		errors.append("map_instance is null")
		return {"ok": false, "errors": errors, "warnings": warnings}
	if str(map_instance.get("map_id")) == "":
		errors.append("map_id missing")
	if str(map_instance.get("map_type")) == "":
		errors.append("map_type missing")
	if not map_instance.spawn_points.has("default"):
		errors.append("default spawn missing")
	if map_instance.tiles.size() > 0 and map_instance.tiles.size() != map_instance.size.y:
		warnings.append("tiles height does not match map size")
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


func validate_transitions(graph) -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	if graph == null:
		return {"ok": false, "errors": ["graph is null"], "warnings": warnings}
	for connection in graph.connections:
		var from_id = str(connection.get("from_map_id", ""))
		var to_id = str(connection.get("to_map_id", ""))
		if not graph.has_map(from_id):
			errors.append("transition from missing: %s" % from_id)
		if not graph.has_map(to_id):
			errors.append("transition to missing: %s" % to_id)
		var target = graph.get_map(to_id)
		var spawn_id = str(connection.get("to_spawn_id", connection.get("target_spawn_id", "default")))
		if target != null and not target.spawn_points.has(spawn_id):
			warnings.append("target spawn missing, will fallback default: %s/%s" % [to_id, spawn_id])
		if int(connection.get("required_realm_order", 0)) < 0:
			errors.append("negative required_realm_order: %s" % connection.get("connection_id", ""))
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings}


func validate_spawn_points(map_instance) -> Dictionary:
	var errors: Array = []
	if map_instance == null:
		errors.append("map_instance is null")
		return {"ok": false, "errors": errors, "warnings": []}
	if not map_instance.spawn_points.has("default"):
		errors.append("default spawn missing")
	for spawn_id in map_instance.spawn_points.keys():
		var pos = map_instance.get_spawn_point(spawn_id)
		if pos.x < 0 or pos.y < 0 or pos.x >= map_instance.size.x or pos.y >= map_instance.size.y:
			errors.append("spawn out of bounds: %s" % spawn_id)
	return {"ok": errors.is_empty(), "errors": errors, "warnings": []}
