extends RefCounted
class_name ExplorationSystem
## ExplorationSystem.gd — 第一版探索发现记录

const DISCOVERY_RADIUS_TILES: float = 2.4

var discoveries: Array = [
	{"id": "cave_entrance", "name": "残破洞府入口", "position": Vector2(12, 14), "message": "你发现了残破洞府入口。"},
	{"id": "herb_patch", "name": "草药丛", "position": Vector2(34, 16), "message": "你发现了一株草药。"},
	{"id": "sect_gate", "name": "云岚宗山门", "position": Vector2(50, 12), "message": "你看见了云岚宗山门。"}
]


func update_player_tile(tile_position: Vector2) -> void:
	var world_state = _world_state()
	var game_log = _game_log()
	if world_state == null:
		return
	for discovery in discoveries:
		var id = discovery.get("id", "")
		if world_state.discovered_locations.has(id):
			continue
		var pos = discovery.get("position", Vector2.ZERO)
		if tile_position.distance_to(pos) <= DISCOVERY_RADIUS_TILES:
			world_state.discover_location(id, discovery.get("name", id))
			if game_log:
				game_log.add_entry(discovery.get("message", "你发现了新的地点。"))


func record_location(id: String, name: String) -> void:
	var world_state = _world_state()
	if world_state:
		world_state.discover_location(id, name)


func _world_state():
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		return loop.root.get_node_or_null("WorldState")
	return null


func _game_log():
	var loop = Engine.get_main_loop()
	if loop and loop is SceneTree:
		return loop.root.get_node_or_null("GameLog")
	return null
