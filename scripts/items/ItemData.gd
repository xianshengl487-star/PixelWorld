extends RefCounted
class_name ItemData
## ItemData.gd — v0.2.0 MVP 物品定义

const ITEMS := {
	"herb": {"name": "Herb", "display_name": "草药", "type": "resource"},
	"potion": {"name": "Potion", "display_name": "药水", "type": "consumable"},
	"wood": {"name": "Wood", "display_name": "木材", "type": "resource"},
	"stone": {"name": "Stone", "display_name": "石头", "type": "resource"},
	"coin": {"name": "Coin", "display_name": "铜钱", "type": "currency"},
	"sword": {"name": "Sword", "display_name": "短剑", "type": "weapon"}
}


static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {"name": id, "display_name": id, "type": "unknown"})


static func get_display_name(id: String) -> String:
	return get_item(id).get("display_name", id)
