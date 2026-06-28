extends RefCounted
class_name ScopedId
## ScopedId.gd - map-scoped object ids for per-map state isolation.

const SEP := "::"


func make(map_id: String, local_id: String) -> String:
	var clean_map = str(map_id).strip_edges()
	var clean_local = str(local_id).strip_edges()
	if clean_map == "":
		return clean_local
	if clean_local == "":
		return clean_map
	if is_scoped(clean_local):
		return clean_local
	return "%s%s%s" % [clean_map, SEP, clean_local]


func split(scoped_id: String) -> Dictionary:
	var text = str(scoped_id)
	var idx = text.find(SEP)
	if idx < 0:
		return {"map_id": "", "local_id": text, "scoped_id": text, "is_scoped": false}
	return {
		"map_id": text.substr(0, idx),
		"local_id": text.substr(idx + SEP.length()),
		"scoped_id": text,
		"is_scoped": true
	}


func is_scoped(id: String) -> bool:
	return str(id).find(SEP) >= 0


func local_id(scoped_id: String) -> String:
	return split(scoped_id).get("local_id", "")


func map_id(scoped_id: String) -> String:
	return split(scoped_id).get("map_id", "")
