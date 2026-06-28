extends RefCounted
class_name InteriorMapGenerator
## InteriorMapGenerator.gd - creates interior MapInstance objects for buildings.

const MapInstanceClass = preload("res://scripts/map/MapInstance.gd")

const TILE_FLOOR := 7
const TILE_WALL := 4
const TILE_DOOR := 1
const TILE_COUNTER := 5


func generate_interior_for_building(building_instance, world_context: Dictionary = {}):
	var data = _building_data(building_instance)
	match str(data.get("building_type", "")):
		"chief_house":
			return generate_chief_house(data, world_context)
		"apothecary":
			return generate_apothecary(data, world_context)
		"blacksmith":
			return generate_blacksmith(data, world_context)
		"inn":
			return generate_inn(data, world_context)
		"general_store":
			return generate_general_store(data, world_context)
		_:
			return generate_generic_interior(data, world_context)


func generate_chief_house(building_instance, world_context: Dictionary):
	return _build_interior(_building_data(building_instance), world_context, Vector2i(32, 32), "village_elder", "chief_desk", "quest_board")


func generate_apothecary(building_instance, world_context: Dictionary):
	return _build_interior(_building_data(building_instance), world_context, Vector2i(32, 32), "doctor", "medicine_counter", "healer")


func generate_blacksmith(building_instance, world_context: Dictionary):
	return _build_interior(_building_data(building_instance), world_context, Vector2i(32, 32), "blacksmith", "forge_counter", "blacksmith")


func generate_inn(building_instance, world_context: Dictionary):
	return _build_interior(_building_data(building_instance), world_context, Vector2i(48, 32), "innkeeper", "inn_counter", "inn")


func generate_general_store(building_instance, world_context: Dictionary):
	return _build_interior(_building_data(building_instance), world_context, Vector2i(32, 32), "merchant", "shop_counter", "shop")


func generate_generic_interior(building_instance, world_context: Dictionary):
	return _build_interior(_building_data(building_instance), world_context, Vector2i(32, 32), "", "counter", "dialogue_only")


func _build_interior(building: Dictionary, world_context: Dictionary, size: Vector2i, npc_role: String, poi_id: String, service_type: String):
	var map_id = str(building.get("interior_map_id", "%s_interior" % str(building.get("building_id", "building"))))
	var parent_map_id = str(building.get("parent_map_id", world_context.get("parent_map_id", "village_001")))
	var parent_spawn_id = str(building.get("door_spawn_id", "%s_door" % str(building.get("building_id", "building"))))
	var map = MapInstanceClass.new()
	map.setup({
		"map_id": map_id,
		"display_name": "%s Interior" % str(building.get("display_name", "Building")),
		"map_type": "interior",
		"world_type": str(world_context.get("world_type", "")),
		"size": [size.x, size.y],
		"parent_map_id": parent_map_id,
		"parent_building_id": str(building.get("building_id", "")),
		"parent_spawn_id": parent_spawn_id
	})
	_fill_room(map, size)
	var center = Vector2i(size.x / 2, size.y / 2)
	map.add_spawn_point("default", Vector2i(center.x, size.y - 5))
	map.add_spawn_point("exit", Vector2i(center.x, size.y - 4))
	map.add_transition({
		"transition_id": "%s_to_%s" % [map_id, parent_map_id],
		"from_map_id": map_id,
		"to_map_id": parent_map_id,
		"from_spawn_id": "exit",
		"target_spawn_id": parent_spawn_id,
		"transition_type": "door_exit",
		"from_rect": {"x": center.x - 1, "y": size.y - 3, "w": 3, "h": 2}
	})
	if npc_role != "":
		map.add_npc({
			"id": "%s_%s" % [map_id, npc_role],
			"name": str(building.get("display_name", npc_role)),
			"role": npc_role,
			"importance": "minor",
			"x": center.x,
			"y": center.y - 4
		})
	map.add_poi({
		"id": "%s_%s" % [map_id, poi_id],
		"display_name": poi_id.capitalize(),
		"interaction_type": "building_service",
		"service_type": service_type,
		"building_id": str(building.get("building_id", "")),
		"x": center.x,
		"y": center.y
	})
	return map


func _fill_room(map, size: Vector2i) -> void:
	map.tiles.clear()
	map.walkable.clear()
	for y in range(size.y):
		var row: Array = []
		var walk_row: Array = []
		for x in range(size.x):
			var wall = x < 2 or y < 2 or x >= size.x - 2 or y >= size.y - 2
			var tile = TILE_WALL if wall else TILE_FLOOR
			var walk = not wall
			row.append(tile)
			walk_row.append(walk)
		map.tiles.append(row)
		map.walkable.append(walk_row)
	var door_x = size.x / 2
	for dx in range(-1, 2):
		var x = door_x + dx
		map.tiles[size.y - 2][x] = TILE_DOOR
		map.walkable[size.y - 2][x] = true
		map.tiles[size.y - 3][x] = TILE_DOOR
		map.walkable[size.y - 3][x] = true
	var counter_y = size.y / 2
	for x in range(max(3, door_x - 4), min(size.x - 3, door_x + 5)):
		map.tiles[counter_y][x] = TILE_COUNTER
		map.walkable[counter_y][x] = false


func _building_data(building_instance) -> Dictionary:
	if building_instance == null:
		return {}
	if building_instance is Dictionary:
		return building_instance.duplicate(true)
	if building_instance.has_method("to_dict"):
		return building_instance.to_dict()
	return {}
