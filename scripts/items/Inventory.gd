extends RefCounted
class_name Inventory
## Inventory.gd — 简单背包

var items: Dictionary = {}


func add_item(id: String, amount: int = 1) -> int:
	if id == "" or amount <= 0:
		return get_amount(id)
	items[id] = get_amount(id) + amount
	return items[id]


func remove_item(id: String, amount: int = 1) -> bool:
	if id == "" or amount <= 0:
		return false
	if not has_item(id, amount):
		return false
	var remain = get_amount(id) - amount
	if remain <= 0:
		items.erase(id)
	else:
		items[id] = remain
	return true


func has_item(id: String, amount: int = 1) -> bool:
	return get_amount(id) >= amount


func get_amount(id: String) -> int:
	return int(items.get(id, 0))


func get_items() -> Dictionary:
	return items.duplicate(true)


func clear() -> void:
	items.clear()


func from_dict(data: Dictionary) -> void:
	items = data.duplicate(true)


func to_dict() -> Dictionary:
	return get_items()
