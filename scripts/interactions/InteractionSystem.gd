extends RefCounted
class_name InteractionSystem
## InteractionSystem.gd — 搜索并执行附近交互

const DEFAULT_RADIUS: float = 72.0


func find_nearest_interactable(player: Node2D, radius: float = DEFAULT_RADIUS):
	if player == null or player.get_tree() == null:
		return null
	var closest = null
	var closest_dist = radius
	for node in player.get_tree().get_nodes_in_group("interactable"):
		if not (node is Node2D):
			continue
		if not node.visible:
			continue
		var dist = player.global_position.distance_to(node.global_position)
		if dist <= closest_dist:
			closest = node
			closest_dist = dist
	return closest


func interact(player: Node2D) -> Dictionary:
	var target = find_nearest_interactable(player)
	if target == null:
		return {"ok": false, "message": ""}
	if target.has_method("on_interact"):
		return target.on_interact(player)
	return {"ok": false, "message": ""}
