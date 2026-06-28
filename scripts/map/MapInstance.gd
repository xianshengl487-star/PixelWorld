extends RefCounted
class_name MapInstance
## MapInstance.gd - one independently generated and saved area map.

const DEFAULT_SIZES := {
	"house": Vector2i(32, 32),
	"shop": Vector2i(32, 32),
	"interior": Vector2i(32, 32),
	"cave": Vector2i(64, 64),
	"dungeon": Vector2i(64, 64),
	"village": Vector2i(96, 96),
	"forest": Vector2i(128, 128),
	"mountain": Vector2i(128, 128),
	"sect_gate": Vector2i(128, 128),
	"sect_inner": Vector2i(128, 128),
	"town": Vector2i(128, 128),
	"city": Vector2i(160, 160),
	"secret_realm": Vector2i(96, 96)
}

var map_id: String = ""
var display_name: String = ""
var map_type: String = "village"
var world_type: String = ""
var size: Vector2i = Vector2i(64, 64)
var seed: int = 0
var danger_level: int = 0
var biome: String = ""
var parent_map_id: String = ""
var parent_building_id: String = ""
var parent_spawn_id: String = ""
var metadata: Dictionary = {}

var tiles: Array = []
var walkable: Array = []
var locked_path_tiles: Dictionary = {}
var spawn_points: Dictionary = {}
var transitions: Array = []
var buildings: Array = []
var npcs: Array = []
var enemies: Array = []
var resources: Array = []
var pois: Array = []
var traps: Array = []
var state = null


func setup(data: Dictionary) -> void:
	map_id = str(data.get("map_id", map_id))
	display_name = str(data.get("display_name", data.get("name", display_name)))
	map_type = str(data.get("map_type", data.get("type", map_type)))
	world_type = str(data.get("world_type", world_type))
	seed = int(data.get("seed", seed))
	danger_level = int(data.get("danger_level", danger_level))
	biome = str(data.get("biome", biome))
	parent_map_id = str(data.get("parent_map_id", parent_map_id))
	parent_building_id = str(data.get("parent_building_id", parent_building_id))
	parent_spawn_id = str(data.get("parent_spawn_id", parent_spawn_id))
	metadata = data.get("metadata", metadata).duplicate(true)
	size = _parse_size(data.get("size", size), map_type)
	tiles = data.get("tiles", tiles).duplicate(true)
	walkable = data.get("walkable", walkable).duplicate(true)
	locked_path_tiles = data.get("locked_path_tiles", locked_path_tiles).duplicate(true)
	spawn_points = data.get("spawn_points", data.get("spawns", spawn_points)).duplicate(true)
	transitions = data.get("transitions", transitions).duplicate(true)
	buildings = data.get("buildings", buildings).duplicate(true)
	npcs = data.get("npcs", npcs).duplicate(true)
	enemies = data.get("enemies", enemies).duplicate(true)
	resources = data.get("resources", resources).duplicate(true)
	pois = data.get("pois", pois).duplicate(true)
	traps = data.get("traps", traps).duplicate(true)
	if not spawn_points.has("default"):
		add_spawn_point("default", Vector2i(size.x / 2, size.y / 2))


func get_spawn_point(spawn_id: String = "default") -> Vector2i:
	var value = spawn_points.get(spawn_id, spawn_points.get("default", {"x": size.x / 2, "y": size.y / 2}))
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(int(value.get("x", size.x / 2)), int(value.get("y", size.y / 2))) if value is Dictionary else Vector2i(size.x / 2, size.y / 2)


func add_spawn_point(spawn_id: String, pos: Vector2i) -> void:
	spawn_points[spawn_id] = {"x": clampi(pos.x, 0, size.x - 1), "y": clampi(pos.y, 0, size.y - 1)}


func add_transition(transition_data: Dictionary) -> void:
	transitions.append(transition_data.duplicate(true))


func add_building(building_data: Dictionary) -> void:
	buildings.append(building_data.duplicate(true))


func add_npc(npc_data: Dictionary) -> void:
	npcs.append(npc_data.duplicate(true))


func add_enemy(enemy_data: Dictionary) -> void:
	enemies.append(enemy_data.duplicate(true))


func add_resource(resource_data: Dictionary) -> void:
	resources.append(resource_data.duplicate(true))


func add_poi(poi_data: Dictionary) -> void:
	pois.append(poi_data.duplicate(true))


func mark_path_tile(pos: Vector2i) -> void:
	locked_path_tiles[_pos_key(pos)] = true


func is_path_locked(pos: Vector2i) -> bool:
	return bool(locked_path_tiles.get(_pos_key(pos), false))


func to_save_data() -> Dictionary:
	return {
		"map_id": map_id,
		"display_name": display_name,
		"map_type": map_type,
		"world_type": world_type,
		"size": [size.x, size.y],
		"seed": seed,
		"danger_level": danger_level,
		"biome": biome,
		"parent_map_id": parent_map_id,
		"parent_building_id": parent_building_id,
		"parent_spawn_id": parent_spawn_id,
		"metadata": metadata,
		"tiles": tiles,
		"walkable": walkable,
		"locked_path_tiles": locked_path_tiles,
		"spawn_points": spawn_points,
		"transitions": transitions,
		"buildings": buildings,
		"npcs": npcs,
		"enemies": enemies,
		"resources": resources,
		"pois": pois,
		"traps": traps
	}


func load_save_data(data: Dictionary) -> void:
	setup(data)


func _parse_size(value, type_id: String) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	if value is Array and value.size() >= 2:
		return Vector2i(max(8, int(value[0])), max(8, int(value[1])))
	if value is Dictionary:
		return Vector2i(max(8, int(value.get("width", value.get("x", 64)))), max(8, int(value.get("height", value.get("y", 64)))))
	return DEFAULT_SIZES.get(type_id, Vector2i(64, 64))


func _pos_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]
