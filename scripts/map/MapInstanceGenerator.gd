extends RefCounted
class_name MapInstanceGenerator
## MapInstanceGenerator.gd - builds a MapInstance from map_type and world context.

const MapInstanceClass = preload("res://scripts/map/MapInstance.gd")
const MapGeneratorClass = preload("res://scripts/map/MapGenerator.gd")
const MapTypeRuleLoaderClass = preload("res://scripts/map/MapTypeRuleLoader.gd")

var _rule_loader = MapTypeRuleLoaderClass.new()


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
	var map_instance = MapInstanceClass.new()
	map_instance.setup(data)
	var generator = MapGeneratorClass.new()
	if int(data.get("seed", 0)) != 0:
		generator.set_seed(int(data.get("seed", 0)))
	var generated = generator.generate_map_from_instance(map_instance)
	map_instance.tiles = generated.get("tiles", [])
	map_instance.walkable = generated.get("walkable", [])
	match map_type:
		"village", "town":
			generate_village(map_instance, world_context)
		"forest":
			generate_forest(map_instance, world_context)
		"cave", "dungeon":
			generate_cave(map_instance, world_context)
		"sect_gate":
			generate_sect_gate(map_instance, world_context)
		"interior", "house", "shop":
			generate_interior(map_instance, world_context)
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
	_add_building(map_instance, "chief_house_001", "chief_house", "村长家", c + Vector2i(-12, -10), Vector2i(7, 6), ["quest"])
	_add_building(map_instance, "apothecary_001", "apothecary", "药铺", c + Vector2i(5, -10), Vector2i(6, 5), ["healer", "item_shop"])
	_add_building(map_instance, "blacksmith_001", "blacksmith", "铁匠铺", c + Vector2i(-13, 6), Vector2i(6, 5), ["weapon_shop"])
	_add_building(map_instance, "inn_001", "inn", "客栈", c + Vector2i(5, 6), Vector2i(8, 6), ["inn"])
	map_instance.add_npc({"id": "village_elder", "name": "老村长", "role": "quest_giver", "importance": "major", "x": c.x - 4, "y": c.y - 2, "initial_dialogue": "年轻人，黑松后山最近不太平。"})
	map_instance.add_npc({"id": "doctor_01", "name": "药铺医师", "role": "doctor", "importance": "minor", "x": c.x + 8, "y": c.y - 3})
	map_instance.add_npc({"id": "guard_01", "name": "村口守卫", "role": "guard", "importance": "minor", "x": map_instance.size.x - 8, "y": c.y})
	map_instance.add_resource({"id": "village_herb_01", "display_name": "草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": c.x - 8, "y": c.y + 10})
	map_instance.add_resource({"id": "village_wood_01", "display_name": "木材", "interaction_type": "resource", "item_id": "wood", "item_amount": 1, "x": c.x + 10, "y": c.y + 9})
	map_instance.add_resource({"id": "village_herb_02", "display_name": "草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": c.x - 14, "y": c.y + 7})
	map_instance.add_poi({"id": "village_sign", "display_name": "告示牌", "interaction_type": "sign", "interaction_text": "东边通向黑松后山。", "x": c.x + 2, "y": c.y + 2})
	map_instance.add_poi({"id": "village_chest_01", "display_name": "旧木宝箱", "interaction_type": "chest", "x": c.x - 10, "y": c.y + 12})
	map_instance.add_poi({"id": "village_well_01", "display_name": "古井", "interaction_type": "sign", "interaction_text": "井水很清，村民常在这里交换消息。", "x": c.x + 12, "y": c.y + 3})
	map_instance.add_transition({"transition_id": "village_to_forest", "from_map_id": map_instance.map_id, "to_map_id": "forest_001", "from_spawn_id": "east_exit", "target_spawn_id": "from_village", "transition_type": "edge_exit", "from_rect": {"x": map_instance.size.x - 3, "y": c.y - 2, "w": 2, "h": 5}})


func generate_forest(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(5, c.y))
	map_instance.add_spawn_point("from_village", Vector2i(6, c.y))
	map_instance.add_spawn_point("cave_entry", Vector2i(c.x - 22, c.y - 18))
	map_instance.add_spawn_point("sect_road", Vector2i(c.x + 28, c.y - 22))
	map_instance.add_spawn_point("from_cave", Vector2i(c.x - 18, c.y - 16))
	map_instance.add_spawn_point("from_sect_gate", Vector2i(c.x + 24, c.y - 20))
	for i in range(4):
		map_instance.add_enemy({"id": "forest_wolf_%02d" % i, "display_name": "妖狼", "enemy_type": "wolf", "x": c.x + i * 3, "y": c.y - 8 + i})
	for i in range(5):
		map_instance.add_resource({"id": "forest_herb_%02d" % i, "display_name": "草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": c.x - 12 + i * 3, "y": c.y + 8})
	map_instance.add_poi({"id": "ancient_stele_001", "display_name": "神秘石碑", "interaction_type": "sign", "interaction_text": "石碑上刻着模糊的古字。", "x": c.x + 12, "y": c.y - 12})
	map_instance.add_transition({"transition_id": "forest_to_village", "from_map_id": map_instance.map_id, "to_map_id": "village_001", "from_spawn_id": "from_village", "target_spawn_id": "from_forest", "transition_type": "edge_exit", "from_rect": {"x": 1, "y": c.y - 2, "w": 2, "h": 5}})
	map_instance.add_transition({"transition_id": "forest_to_cave", "from_map_id": map_instance.map_id, "to_map_id": "cave_001", "from_spawn_id": "cave_entry", "target_spawn_id": "entrance", "transition_type": "cave_entrance", "from_rect": {"x": c.x - 24, "y": c.y - 20, "w": 3, "h": 3}})
	map_instance.add_transition({"transition_id": "forest_to_sect_gate", "from_map_id": map_instance.map_id, "to_map_id": "sect_gate_001", "from_spawn_id": "sect_road", "target_spawn_id": "from_forest", "transition_type": "sect_gate", "from_rect": {"x": c.x + 26, "y": c.y - 24, "w": 4, "h": 4}, "required_realm_order": 0})


func generate_cave(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(4, c.y))
	map_instance.add_spawn_point("entrance", Vector2i(4, c.y))
	map_instance.add_spawn_point("deep", Vector2i(map_instance.size.x - 8, c.y))
	for i in range(3):
		map_instance.add_enemy({"id": "cave_slime_%02d" % i, "display_name": "洞窟史莱姆", "enemy_type": "slime", "x": c.x + i * 4, "y": c.y + i})
	map_instance.add_poi({"id": "cave_chest_001", "display_name": "洞府宝箱", "interaction_type": "chest", "x": map_instance.size.x - 10, "y": c.y - 3})
	map_instance.add_resource({"id": "cave_ore_001", "display_name": "灵矿", "interaction_type": "resource", "item_id": "stone", "item_amount": 2, "x": c.x + 5, "y": c.y + 4})
	map_instance.add_transition({"transition_id": "cave_to_forest", "from_map_id": map_instance.map_id, "to_map_id": "forest_001", "from_spawn_id": "entrance", "target_spawn_id": "from_cave", "transition_type": "cave_entrance", "from_rect": {"x": 1, "y": c.y - 2, "w": 2, "h": 5}})


func generate_sect_gate(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(6, c.y))
	map_instance.add_spawn_point("from_forest", Vector2i(6, c.y))
	map_instance.add_spawn_point("trial_entry", Vector2i(c.x + 18, c.y - 8))
	_add_building(map_instance, "sect_gate_building_001", "sect_gate", "云岚宗山门", c + Vector2i(-8, -12), Vector2i(16, 5), ["faction_hall"])
	_add_building(map_instance, "task_hall_001", "task_hall", "任务堂", c + Vector2i(-18, 8), Vector2i(9, 6), ["quest_board"])
	_add_building(map_instance, "training_hall_001", "training_hall", "演武场", c + Vector2i(8, 8), Vector2i(10, 8), ["training_hall"])
	map_instance.add_npc({"id": "sect_guard_01", "name": "守门弟子", "role": "guard", "importance": "minor", "x": c.x, "y": c.y - 6})
	map_instance.add_npc({"id": "task_elder_01", "name": "任务堂执事", "role": "quest_giver", "importance": "major", "x": c.x - 14, "y": c.y + 12})
	map_instance.add_transition({"transition_id": "sect_gate_to_forest", "from_map_id": map_instance.map_id, "to_map_id": "forest_001", "from_spawn_id": "from_forest", "target_spawn_id": "from_sect_gate", "transition_type": "sect_gate", "from_rect": {"x": 1, "y": c.y - 2, "w": 2, "h": 5}})


func generate_interior(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(c.x, map_instance.size.y - 4))
	map_instance.add_spawn_point("exit", Vector2i(c.x, map_instance.size.y - 4))
	map_instance.add_poi({"id": "%s_counter" % map_instance.map_id, "display_name": "柜台", "interaction_type": "sign", "interaction_text": "这里暂时只是室内占位。", "x": c.x, "y": c.y})


func generate_secret_realm(map_instance, world_context: Dictionary) -> void:
	var c = Vector2i(map_instance.size.x / 2, map_instance.size.y / 2)
	map_instance.add_spawn_point("default", Vector2i(5, c.y))
	map_instance.add_enemy({"id": "secret_boss_001", "display_name": "秘境守卫", "enemy_type": "boss_bandit", "x": c.x + 12, "y": c.y})
	map_instance.add_poi({"id": "secret_chest_001", "display_name": "秘境宝箱", "interaction_type": "chest", "x": c.x + 18, "y": c.y - 6})


func _add_building(map_instance, id: String, type: String, name: String, pos: Vector2i, size: Vector2i, services: Array) -> void:
	var door = Vector2i(pos.x + size.x / 2, pos.y + size.y)
	map_instance.add_building({
		"building_id": id,
		"building_type": type,
		"display_name": name,
		"position": {"x": pos.x, "y": pos.y},
		"size": [size.x, size.y],
		"door_position": {"x": door.x, "y": door.y},
		"interior_map_id": "%s_interior" % id,
		"services": services
	})
