extends RefCounted
class_name MapInstanceGenerator
## MapInstanceGenerator.gd - builds MapInstance data from a map type and context.

const MapInstanceClass = preload("res://scripts/map/MapInstance.gd")
const MapGeneratorClass = preload("res://scripts/map/MapGenerator.gd")
const MapTypeRuleLoaderClass = preload("res://scripts/map/MapTypeRuleLoader.gd")
const BuildingRegistryClass = preload("res://scripts/buildings/BuildingRegistry.gd")
const InteriorMapGeneratorClass = preload("res://scripts/buildings/InteriorMapGenerator.gd")

var _rule_loader = MapTypeRuleLoaderClass.new()
var _building_registry = BuildingRegistryClass.new()


func generate_map_instance(map_data: Dictionary, world_context: Dictionary = {}):
	var data = map_data.duplicate(true)
	var map_type = str(data.get("map_type", data.get("type", "village")))
	if not data.has("size"):
		var rule_size = _rule_loader.get_default_size(map_type)
		data["size"] = [rule_size.x, rule_size.y]
	if not data.has("world_type"):
		data["world_type"] = world_context.get("world_type", "")
	if not data.has("seed"):
		data["seed"] = int(world_context.get("seed", 0)) + abs(str(data.get("map_id", "")).hash())

	if map_type == "interior":
		return _generate_interior_from_data(data, world_context)

	var map_instance = MapInstanceClass.new()
	map_instance.setup(data)
	var generator = MapGeneratorClass.new()
	if int(data.get("seed", 0)) != 0:
		generator.set_seed(int(data.get("seed", 0)))
	var generated = generator.generate_map_from_instance(map_instance)
	map_instance.tiles = generated.get("tiles", [])
	map_instance.walkable = generated.get("walkable", [])
	_clear_runtime_lists(map_instance)

	match map_type:
		"village", "town":
			generate_village(map_instance, world_context)
		"forest":
			generate_forest(map_instance, world_context)
		"cave", "dungeon":
			generate_cave(map_instance, world_context)
		"sect_gate":
			generate_sect_gate(map_instance, world_context)
		"secret_realm":
			generate_secret_realm(map_instance, world_context)
		_:
			generate_village(map_instance, world_context)
	return map_instance


func generate_village(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", c)
	map_instance.add_spawn_point("east_exit", Vector2i(map_instance.size.x - 4, c.y))
	map_instance.add_spawn_point("from_forest", Vector2i(map_instance.size.x - 8, c.y))
	map_instance.add_spawn_point("center", c)
	_force_walkable(map_instance, c)
	_force_walkable(map_instance, Vector2i(map_instance.size.x - 4, c.y))
	_carve_road(map_instance, Vector2i(c.x - 18, c.y), Vector2i(map_instance.size.x - 4, c.y))
	_carve_road(map_instance, Vector2i(c.x, c.y - 14), Vector2i(c.x, c.y + 16))

	_add_building(map_instance, "chief_house", c + Vector2i(-14, -12))
	_add_building(map_instance, "apothecary", c + Vector2i(5, -12))
	_add_building(map_instance, "blacksmith", c + Vector2i(-14, 6))
	_add_building(map_instance, "inn", c + Vector2i(6, 6))
	_add_building(map_instance, "general_store", c + Vector2i(-3, 14))

	map_instance.add_npc({"id": "village_elder", "name": "Village Elder", "role": "quest_giver", "importance": "major", "x": c.x - 4, "y": c.y - 2, "initial_dialogue": "The forest road has been restless lately."})
	map_instance.add_npc({"id": "doctor_01", "name": "Apothecary Doctor", "role": "doctor", "importance": "minor", "x": c.x + 8, "y": c.y - 3})
	map_instance.add_npc({"id": "guard_01", "name": "Village Guard", "role": "guard", "importance": "minor", "x": map_instance.size.x - 8, "y": c.y})
	map_instance.add_resource({"id": "village_herb_01", "display_name": "Herb", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": c.x - 8, "y": c.y + 10})
	map_instance.add_resource({"id": "village_wood_01", "display_name": "Wood", "interaction_type": "resource", "item_id": "wood", "item_amount": 1, "x": c.x + 10, "y": c.y + 9})
	map_instance.add_resource({"id": "village_herb_02", "display_name": "Herb", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": c.x - 14, "y": c.y + 7})
	map_instance.add_poi({"id": "village_sign", "display_name": "Notice Board", "interaction_type": "sign", "interaction_text": "The east road leads to the forest.", "x": c.x + 2, "y": c.y + 2})
	map_instance.add_poi({"id": "village_chest_01", "display_name": "Old Chest", "interaction_type": "chest", "x": c.x - 10, "y": c.y + 12})
	map_instance.add_poi({"id": "village_well_01", "display_name": "Old Well", "interaction_type": "sign", "interaction_text": "The well water is clear.", "x": c.x + 12, "y": c.y + 3})
	map_instance.add_transition({"transition_id": "village_to_forest", "from_map_id": map_instance.map_id, "to_map_id": "forest_001", "from_spawn_id": "east_exit", "target_spawn_id": "from_village", "transition_type": "edge_exit", "from_rect": {"x": map_instance.size.x - 3, "y": c.y - 2, "w": 2, "h": 5}})


func generate_forest(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(5, c.y))
	map_instance.add_spawn_point("from_village", Vector2i(6, c.y))
	map_instance.add_spawn_point("cave_entry", Vector2i(c.x - 22, c.y - 18))
	map_instance.add_spawn_point("sect_road", Vector2i(c.x + 28, c.y - 22))
	map_instance.add_spawn_point("from_cave", Vector2i(c.x - 18, c.y - 16))
	map_instance.add_spawn_point("from_sect_gate", Vector2i(c.x + 24, c.y - 20))
	for key in map_instance.spawn_points.keys():
		_force_walkable(map_instance, map_instance.get_spawn_point(key))
	for i in range(4):
		map_instance.add_enemy({"id": "forest_wolf_%02d" % i, "display_name": "Wolf", "enemy_type": "wolf", "x": c.x + i * 3, "y": c.y - 8 + i})
	for i in range(5):
		map_instance.add_resource({"id": "forest_herb_%02d" % i, "display_name": "Herb", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": c.x - 12 + i * 3, "y": c.y + 8})
	map_instance.add_poi({"id": "ancient_stele_001", "display_name": "Ancient Stele", "interaction_type": "sign", "interaction_text": "Weathered glyphs are carved into the stone.", "x": c.x + 12, "y": c.y - 12})
	map_instance.add_transition({"transition_id": "forest_to_village", "from_map_id": map_instance.map_id, "to_map_id": "village_001", "from_spawn_id": "from_village", "target_spawn_id": "from_forest", "transition_type": "edge_exit", "from_rect": {"x": 1, "y": c.y - 2, "w": 2, "h": 5}})
	map_instance.add_transition({"transition_id": "forest_to_cave", "from_map_id": map_instance.map_id, "to_map_id": "cave_001", "from_spawn_id": "cave_entry", "target_spawn_id": "entrance", "transition_type": "cave_entrance", "from_rect": {"x": c.x - 24, "y": c.y - 20, "w": 3, "h": 3}})
	map_instance.add_transition({"transition_id": "forest_to_sect_gate", "from_map_id": map_instance.map_id, "to_map_id": "sect_gate_001", "from_spawn_id": "sect_road", "target_spawn_id": "from_forest", "transition_type": "sect_gate", "from_rect": {"x": c.x + 26, "y": c.y - 24, "w": 4, "h": 4}, "required_realm_order": 0})


func generate_cave(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(4, c.y))
	map_instance.add_spawn_point("entrance", Vector2i(4, c.y))
	map_instance.add_spawn_point("deep", Vector2i(map_instance.size.x - 8, c.y))
	for key in map_instance.spawn_points.keys():
		_force_walkable(map_instance, map_instance.get_spawn_point(key))
	for i in range(3):
		map_instance.add_enemy({"id": "cave_slime_%02d" % i, "display_name": "Cave Slime", "enemy_type": "slime", "x": c.x + i * 4, "y": c.y + i})
	map_instance.add_poi({"id": "cave_chest_001", "display_name": "Cave Chest", "interaction_type": "chest", "x": map_instance.size.x - 10, "y": c.y - 3})
	map_instance.add_resource({"id": "cave_ore_001", "display_name": "Ore", "interaction_type": "resource", "item_id": "stone", "item_amount": 2, "x": c.x + 5, "y": c.y + 4})
	map_instance.add_transition({"transition_id": "cave_to_forest", "from_map_id": map_instance.map_id, "to_map_id": "forest_001", "from_spawn_id": "entrance", "target_spawn_id": "from_cave", "transition_type": "cave_entrance", "from_rect": {"x": 1, "y": c.y - 2, "w": 2, "h": 5}})


func generate_sect_gate(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(6, c.y))
	map_instance.add_spawn_point("from_forest", Vector2i(6, c.y))
	map_instance.add_spawn_point("trial_entry", Vector2i(c.x + 18, c.y - 8))
	for key in map_instance.spawn_points.keys():
		_force_walkable(map_instance, map_instance.get_spawn_point(key))
	_add_building(map_instance, "sect_gate", c + Vector2i(-8, -12))
	_add_building(map_instance, "task_hall", c + Vector2i(-18, 8))
	_add_building(map_instance, "training_hall", c + Vector2i(8, 8))
	map_instance.add_npc({"id": "sect_guard_01", "name": "Sect Guard", "role": "guard", "importance": "minor", "x": c.x, "y": c.y - 6})
	map_instance.add_npc({"id": "task_elder_01", "name": "Task Elder", "role": "quest_giver", "importance": "major", "x": c.x - 14, "y": c.y + 12})
	map_instance.add_transition({"transition_id": "sect_gate_to_forest", "from_map_id": map_instance.map_id, "to_map_id": "forest_001", "from_spawn_id": "from_forest", "target_spawn_id": "from_sect_gate", "transition_type": "sect_gate", "from_rect": {"x": 1, "y": c.y - 2, "w": 2, "h": 5}})


func generate_secret_realm(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(5, c.y))
	_force_walkable(map_instance, Vector2i(5, c.y))
	map_instance.add_enemy({"id": "secret_boss_001", "display_name": "Secret Realm Guard", "enemy_type": "boss_bandit", "x": c.x + 12, "y": c.y})
	map_instance.add_poi({"id": "secret_chest_001", "display_name": "Secret Chest", "interaction_type": "chest", "x": c.x + 18, "y": c.y - 6})


func _generate_interior_from_data(data: Dictionary, world_context: Dictionary):
	var building = {
		"building_id": str(data.get("parent_building_id", data.get("building_id", "building"))),
		"building_type": str(data.get("building_type", data.get("interior_template", "generic"))),
		"display_name": str(data.get("display_name", "Building")),
		"interior_map_id": str(data.get("map_id", "")),
		"parent_map_id": str(data.get("parent_map_id", "village_001")),
		"door_spawn_id": str(data.get("parent_spawn_id", "default"))
	}
	if building["building_type"] == "simple_house":
		building["building_type"] = "chief_house"
	return InteriorMapGeneratorClass.new().generate_interior_for_building(building, world_context)


func _add_building(map_instance, building_type: String, pos: Vector2i) -> void:
	var building = _building_registry.create_building_instance(building_type, pos, map_instance.map_id)
	if building.is_empty():
		return
	var door = _vec(building.get("door_position", pos))
	var spawn_id = str(building.get("door_spawn_id", "%s_door" % building.get("building_id", building_type)))
	_force_rect_blocked(map_instance, pos, _vec(building.get("size", [5, 5])))
	_force_walkable(map_instance, door)
	_carve_road(map_instance, map_instance.get_spawn_point("center"), door)
	map_instance.add_spawn_point(spawn_id, door)
	map_instance.add_building(building)
	var interior_map_id = str(building.get("interior_map_id", ""))
	if interior_map_id != "":
		map_instance.add_transition({
			"transition_id": "%s_to_%s" % [map_instance.map_id, interior_map_id],
			"from_map_id": map_instance.map_id,
			"to_map_id": interior_map_id,
			"from_spawn_id": spawn_id,
			"target_spawn_id": "default",
			"transition_type": "building_door",
			"building_id": str(building.get("building_id", "")),
			"from_rect": {"x": max(0, door.x - 1), "y": max(0, door.y - 1), "w": 3, "h": 2}
		})


func _clear_runtime_lists(map_instance) -> void:
	map_instance.spawn_points.clear()
	map_instance.transitions.clear()
	map_instance.buildings.clear()
	map_instance.npcs.clear()
	map_instance.enemies.clear()
	map_instance.resources.clear()
	map_instance.pois.clear()


func _force_rect_blocked(map_instance, pos: Vector2i, size: Vector2i) -> void:
	for y in range(max(0, pos.y), min(map_instance.size.y, pos.y + size.y)):
		for x in range(max(0, pos.x), min(map_instance.size.x, pos.x + size.x)):
			_set_tile(map_instance, Vector2i(x, y), 4, false)


func _force_walkable(map_instance, pos: Vector2i) -> void:
	_set_tile(map_instance, pos, 1, true)


func _carve_road(map_instance, start: Vector2i, target: Vector2i) -> void:
	var current = start
	while current.x != target.x:
		current.x += 1 if target.x > current.x else -1
		_force_walkable(map_instance, current)
	while current.y != target.y:
		current.y += 1 if target.y > current.y else -1
		_force_walkable(map_instance, current)


func _set_tile(map_instance, pos: Vector2i, tile: int, walk: bool) -> void:
	if pos.x < 0 or pos.y < 0 or pos.x >= map_instance.size.x or pos.y >= map_instance.size.y:
		return
	if map_instance.tiles.size() > pos.y and map_instance.tiles[pos.y].size() > pos.x:
		map_instance.tiles[pos.y][pos.x] = tile
	if map_instance.walkable.size() > pos.y and map_instance.walkable[pos.y].size() > pos.x:
		map_instance.walkable[pos.y][pos.x] = walk


func _vec(value) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))
	return Vector2i.ZERO
