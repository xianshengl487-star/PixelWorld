extends RefCounted
class_name MapRuntimeCache
## Small LRU-style cache for generated MapInstance data.

var cache: Dictionary = {}
var order: Array = []
var max_entries: int = 8


func has_map(map_id: String) -> bool:
	return cache.has(map_id)


func get_map(map_id: String):
	if not cache.has(map_id):
		return null
	_touch(map_id)
	return cache[map_id]


func set_map(map_id: String, map_instance) -> void:
	if map_id == "" or map_instance == null:
		return
	cache[map_id] = map_instance
	_touch(map_id)
	while order.size() > max_entries:
		var evicted = order.pop_front()
		cache.erase(str(evicted))


func clear() -> void:
	cache.clear()
	order.clear()


func get_cache_count() -> int:
	return cache.size()


func _touch(map_id: String) -> void:
	order.erase(map_id)
	order.append(map_id)
