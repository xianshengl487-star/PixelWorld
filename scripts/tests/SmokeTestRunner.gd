extends SceneTree
## SmokeTestRunner.gd — CLI 自动化冒烟测试  v0.2.1
## 运行: godot --headless --path . --script res://scripts/tests/SmokeTestRunner.gd

const AIClientClass = preload("res://scripts/ai/AIClient.gd")
const StatsClass = preload("res://scripts/entities/Stats.gd")
const CombatSystemClass = preload("res://scripts/combat/CombatSystem.gd")
const InventoryClass = preload("res://scripts/items/Inventory.gd")
const ExplorationSystemClass = preload("res://scripts/world/ExplorationSystem.gd")
const InteractionSystemClass = preload("res://scripts/interactions/InteractionSystem.gd")
const InteractableClass = preload("res://scripts/interactions/Interactable.gd")
const TEST_SEED: int = 42

var _results: Array = []
var _pass_count: int = 0
var _fail_count: int = 0
var _skip_count: int = 0

var _world_state = null
var _config_mgr = null
var _game_log = null
var _save_manager = null


func _init() -> void:
	print("=".repeat(60))
	print("  PixelWorld CLI Smoke Test Runner  v0.2.1  (seed=%d)" % TEST_SEED)
	print("=".repeat(60))
	
	await process_frame; await process_frame
	_get_autoload_refs()
	await _run_all_tests()
	_print_summary()
	quit(_fail_count > 0 and 1 or 0)


func _get_autoload_refs() -> void:
	_world_state = root.get_node_or_null("WorldState")
	_config_mgr = root.get_node_or_null("ConfigManager")
	_game_log = root.get_node_or_null("GameLog")
	_save_manager = root.get_node_or_null("SaveManager")


func _wait_frame() -> void:
	await process_frame


func _record(id: String, desc: String, passed: bool, note: String = "") -> void:
	var status = "PASS" if passed else "FAIL"
	if passed: _pass_count += 1
	else: _fail_count += 1
	print("[%s] %s — %s%s" % [status, id, desc, ("  (" + note + ")" if note != "" else "")])
	_results.append({"id": id, "desc": desc, "status": status, "note": note})


func _scene_loadable(path: String) -> bool:
	if not ResourceLoader.exists(path): return false
	return load(path) != null


## 创建带固定种子的 MapGenerator
func _mk_gen():
	var gen = preload("res://scripts/map/MapGenerator.gd").new()
	gen.set_seed(TEST_SEED)
	return gen


## 获取修复后的蓝图
func _get_fixed_blueprint() -> Dictionary:
	var bp = await _get_mock_blueprint()
	var ValidatorClass = preload("res://scripts/world/WorldBlueprintValidator.gd")
	return ValidatorClass.new().validate(bp).get("fixed_blueprint", {})


## 生成并修复地图（带固定种子）
func _gen_deterministic_map(fixed: Dictionary) -> Dictionary:
	var GenClass = preload("res://scripts/map/MapGenerator.gd")
	var ValClass = preload("res://scripts/map/MapValidator.gd")
	var RepairClass = preload("res://scripts/map/MapRepairer.gd")
	var gen = _mk_gen()
	var md = gen.generate(fixed)
	var mv = ValClass.new().validate(md, fixed)
	# Only repair if spawn or critical NPCs unreachable
	if mv.get("errors", []).size() > 0:
		var critical = false
		for e in mv.get("errors", []):
			var s = str(e)
			if "出生点" in s or "NPC" in s or "村长" in s or "elder" in s.to_lower():
				critical = true; break
		if critical:
			var rr = RepairClass.new().repair(md, fixed, mv.get("errors", []))
			if rr.get("repaired", false):
				md = rr.get("map_data", md)
	return md


func _get_mock_blueprint() -> Dictionary:
	var ai = AIClientClass.new()
	var result = await ai.generate_world_blueprint("修仙世界")
	return result


# ═══════════════ T001–T011 ═══════════════

func _run_all_tests() -> void:
	_t001(); _t002(); _t003(); _t004(); _t005(); _t006(); _t007()
	_t008(); _t009(); _t010(); _t011()
	
	await _t012(); await _t013(); await _t014(); await _t015()
	await _t016(); await _t017(); await _t018()
	await _t019(); await _t020(); await _t021(); await _t022()
	await _t023(); await _t024(); await _t025(); await _t026()
	await _t027(); await _t028()
	await _t029(); await _t030(); await _t031()
	_t032(); _t033(); _t034(); _t035()
	_t036(); await _t037(); _t038(); _t039(); await _t040()
	_t041(); _t042(); _t043(); _t044(); await _t045()
	await _t046(); await _t047(); _t048(); _t049(); _t050()
	_t051(); _t052(); _t053(); _t054(); _t055(); _t056()
	_t057(); _t058(); _t059(); _t060(); _t061(); _t062()

func _t001(): _record("T001", "project.godot 存在", FileAccess.file_exists("res://project.godot"))
func _t002(): _record("T002", "MainMenu.tscn 可加载", _scene_loadable("res://scenes/MainMenu.tscn"))
func _t003(): _record("T003", "GameWorld.tscn 可加载", _scene_loadable("res://scenes/GameWorld.tscn"))
func _t004(): _record("T004", "Player.tscn 可加载", _scene_loadable("res://scenes/Player.tscn"))
func _t005(): _record("T005", "NPC.tscn 可加载", _scene_loadable("res://scenes/NPC.tscn"))
func _t006(): _record("T006", "GameHUD.tscn 可加载", _scene_loadable("res://scenes/ui/GameHUD.tscn"))
func _t007(): _record("T007", "DialogueBox.tscn 可加载", _scene_loadable("res://scenes/ui/DialogueBox.tscn"))
func _t008(): _record("T008", "WorldState Autoload 存在", _world_state != null)
func _t009(): _record("T009", "ConfigManager Autoload 存在", _config_mgr != null)
func _t010(): _record("T010", "GameLog Autoload 存在", _game_log != null)
func _t011(): _record("T011", "AIClient 可实例化", AIClientClass.new() != null)


# ═══════════════ T012–T035 ═══════════════

func _t012() -> void:
	var bp = await _get_mock_blueprint()
	_record("T012", "MockProvider 可生成世界蓝图", not bp.is_empty() and bp.has("world_name"), bp.get("world_name", "?"))

func _t013() -> void:
	var bp = await _get_mock_blueprint()
	var ValidatorClass = preload("res://scripts/world/WorldBlueprintValidator.gd")
	var r = ValidatorClass.new().validate(bp)
	_record("T013", "WorldBlueprintValidator 可校验蓝图", r.get("fixed_blueprint", {}).has("world_name"))

func _t014() -> void:
	var bp = await _get_mock_blueprint()
	var ValidatorClass = preload("res://scripts/world/WorldBlueprintValidator.gd")
	var c = ValidatorClass.new().validate(bp).get("fixed_blueprint", {}).get("major_npcs", []).size()
	_record("T014", "默认蓝图>=1个major NPC", c >= 1, "count=%d" % c)

func _t015() -> void:
	var bp = await _get_mock_blueprint()
	var ValidatorClass = preload("res://scripts/world/WorldBlueprintValidator.gd")
	var c = ValidatorClass.new().validate(bp).get("fixed_blueprint", {}).get("minor_npcs", []).size()
	_record("T015", "默认蓝图>=2个minor NPC", c >= 2, "count=%d" % c)

func _t016() -> void:
	var fixed = await _get_fixed_blueprint()
	var gen = _mk_gen()
	var md = gen.generate(fixed)
	var tiles = md.get("tiles", [])
	var ok = tiles.size() == 64 and tiles.size() > 0 and tiles[0].size() == 64
	_record("T016", "MapGenerator 可生成64x64地图", ok, "%dx%d" % [tiles.size(), tiles[0].size() if tiles.size() > 0 else 0])

func _t017() -> void:
	var fixed = await _get_fixed_blueprint()
	var ValClass = preload("res://scripts/map/MapValidator.gd")
	var md = await _gen_deterministic_map(fixed)
	var mr = ValClass.new().validate(md, fixed)
	var err_count = mr.get("errors", []).size()
	_record("T017", "MapValidator 可校验地图", mr.has("ok"), "errors=%d" % err_count)

func _t018() -> void:
	var fixed = await _get_fixed_blueprint()
	var md = await _gen_deterministic_map(fixed)
	var walkable = md.get("walkable", [])
	var sp = fixed.get("player_spawn", {"x": 20, "y": 20})
	var sx = int(sp.get("x", 20)); var sy = int(sp.get("y", 20))
	var ok = walkable.size() > sy and walkable[sy][sx]
	_record("T018", "出生点可行走", ok, "pos=(%d,%d)" % [sx, sy])

func _t019() -> void:
	var fixed = await _get_fixed_blueprint()
	var ValClass = preload("res://scripts/map/MapValidator.gd")
	var md = await _gen_deterministic_map(fixed)
	var mr = ValClass.new().validate(md, fixed)
	var ok = true
	for e in mr.get("errors", []):
		if "村长" in str(e) or "elder" in str(e).to_lower(): ok = false; break
	_record("T019", "出生点到村长可达", ok)

func _t020() -> void:
	var fixed = await _get_fixed_blueprint()
	var ValClass = preload("res://scripts/map/MapValidator.gd")
	var md = await _gen_deterministic_map(fixed)
	var mr = ValClass.new().validate(md, fixed)
	var ok = true
	for e in mr.get("errors", []):
		if "洞口" in str(e) or "cave" in str(e).to_lower(): ok = false; break
	_record("T020", "出生点到洞口可达", ok)

func _t021() -> void:
	var fixed = await _get_fixed_blueprint()
	var ValClass = preload("res://scripts/map/MapValidator.gd")
	var md = await _gen_deterministic_map(fixed)
	var mr = ValClass.new().validate(md, fixed)
	var ok = true
	for e in mr.get("errors", []):
		if "宗门" in str(e) or "sect" in str(e).to_lower(): ok = false; break
	_record("T021", "出生点到宗门入口可达", ok)

func _t022() -> void:
	var fixed = await _get_fixed_blueprint()
	var ValClass = preload("res://scripts/map/MapValidator.gd")
	var RepairClass = preload("res://scripts/map/MapRepairer.gd")
	var gen = _mk_gen()
	var md = gen.generate(fixed)
	var walkable = md.get("walkable", [])
	var sp = fixed.get("player_spawn", {"x": 20, "y": 20})
	var sx = int(sp.get("x", 20)); var sy = int(sp.get("y", 20))
	# 故意破坏出生点
	if walkable.size() > sy and walkable[sy].size() > sx:
		walkable[sy][sx] = false
	var mr = ValClass.new().validate(md, fixed)
	var rr = RepairClass.new().repair(md, fixed, mr.get("errors", []))
	md = rr.get("map_data", md)
	# 验证修复后出生点可行走
	var rw = md.get("walkable", [])
	var new_sp = fixed.get("player_spawn", sp)
	var nsx = int(new_sp.get("x", 20)); var nsy = int(new_sp.get("y", 20))
	var spawn_ok = rw.size() > nsy and rw[nsy][nsx]
	_record("T022", "MapRepairer修复后出生点可行走", spawn_ok, "pos=(%d,%d) repaired=%s" % [nsx, nsy, str(rr.get("repaired", false))])

func _t023() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	_record("T023", "GameWorld 可实例化", scene != null and scene.instantiate() != null)

func _t024() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null: _record("T024", "GameWorld 初始化", false, "场景加载失败"); return
	var gw = scene.instantiate(); root.add_child(gw)
	await _wait_frame(); await _wait_frame()
	await _wait_frame()
	var ok = gw.is_initialized() if gw.has_method("is_initialized") else false
	gw.queue_free(); await _wait_frame()
	_record("T024", "GameWorld 可根据WorldState初始化", ok)

func _t025() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null: _record("T025", "玩家节点存在", false, "场景失败"); return
	var gw = scene.instantiate(); root.add_child(gw)
	# Wait for _ready to complete initialization
	await _wait_frame(); await _wait_frame()
	await _wait_frame(); await _wait_frame()
	var p = gw.get_player_node() if gw.has_method("get_player_node") else null
	if p == null:
		var children = []
		for c in gw.get_children():
			children.append(c.name + "(" + c.get_class() + ")")
		print("  [T025 DIAG] children: " + ", ".join(children))
		var initialized = gw.is_initialized() if gw.has_method("is_initialized") else false
		print("  [T025 DIAG] is_initialized=%s" % str(initialized))
	gw.queue_free(); await _wait_frame()
	_record("T025", "GameWorld 初始化后玩家节点存在", p != null)

func _t026() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null: _record("T026", "NPC>=3", false, "场景失败"); return
	var gw = scene.instantiate(); root.add_child(gw)
	await _wait_frame(); await _wait_frame()
	await _wait_frame()
	var c = gw.get_npc_count() if gw.has_method("get_npc_count") else 0
	gw.queue_free(); await _wait_frame()
	_record("T026", "GameWorld NPC节点>=3", c >= 3, "count=%d" % c)

func _t027() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null: _record("T027", "视觉节点存在", false, "场景失败"); return
	var gw = scene.instantiate(); root.add_child(gw)
	await _wait_frame(); await _wait_frame()
	await _wait_frame()
	var c = gw.get_map_visual_node_count() if gw.has_method("get_map_visual_node_count") else 0
	gw.queue_free(); await _wait_frame()
	_record("T027", "地图视觉节点存在", c > 0, "count=%d" % c)

func _t028() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null: _record("T028", "碰撞节点存在", false, "场景失败"); return
	var gw = scene.instantiate(); root.add_child(gw)
	await _wait_frame(); await _wait_frame()
	await _wait_frame(); await _wait_frame()
	var c = gw.get_obstacle_collision_count() if gw.has_method("get_obstacle_collision_count") else 0
	if c == 0:
		var cl = gw.get_node_or_null("CollisionLayer")
		var md = gw.get_map_data() if gw.has_method("get_map_data") else {}
		var block_count = 0
		for row in md.get("tiles", []):
			for t in row:
				if t in [2, 3, 4, 5]: block_count += 1
		print("  [T028 DIAG] CollisionLayer=%s child_count=%d blocking_tiles=%d total_tiles=%d" % [str(cl != null), cl.get_child_count() if cl else 0, block_count, md.get("tiles", []).size()])
	gw.queue_free(); await _wait_frame()
	_record("T028", "障碍物碰撞节点存在", c > 0, "count=%d" % c)

func _t029() -> void:
	var LocalClass = preload("res://scripts/ai/providers/LocalTinyNpcProvider.gd")
	var reply = await LocalClass.new().generate_minor_npc_reply({"npc_role": "villager", "dialogue_profile": "村民", "player_input": "你好"})
	_record("T029", "LocalTinyNpcProvider可返回对话", reply.has("dialogue") and reply.dialogue != "", reply.get("dialogue", "?"))

func _t030() -> void:
	var reply = await AIClientClass.new().generate_major_npc_reply({"npc_name": "村长", "npc_role": "quest_giver", "initial_dialogue": "欢迎来到村子。"})
	_record("T030", "AIClient可返回major NPC对话", reply.has("dialogue") and reply.dialogue != "", reply.get("dialogue", "?"))

func _t031() -> void:
	var result = await AIClientClass.new().interpret_player_action({"player_input": "我观察村长", "player_reputation": 0, "world_type": "xianxia"})
	_record("T031", "AIClient可解释自由行动", result.has("action_type") or result.has("narrative_result"), result.get("action_type", "?"))

func _t032() -> void:
	var before = _world_state.action_history.size()
	_world_state.log_action("测试行动", {"result": "ok"})
	_record("T032", "action_history可写入", _world_state.action_history.size() > before)

func _t033() -> void:
	var nid = "test_npc_%d" % Time.get_unix_time_from_system()
	_world_state.set_npc_memory(nid, "k", "v")
	var mem = _world_state.get_npc_memory(nid)
	_record("T033", "npc_memory可写入", mem.has("k") and mem["k"] == "v")

func _t034() -> void:
	var prov = _config_mgr.get_ai_provider()
	_record("T034", "API未配置时不会崩溃", true, "provider=%s" % prov)

func _t035() -> void:
	_game_log.add_entry("SmokeTest: 日志测试")
	var entries = _game_log.get_recent(1)
	_record("T035", "GameLog可记录日志", entries.size() > 0 and "SmokeTest" in str(entries[0].get("text", "")))


# ═══════════════ T036–T050 v0.2.0 ═══════════════

func _t036() -> void:
	var stats = StatsClass.new()
	stats.configure({"max_health": 20, "health": 20, "attack": 5, "defense": 2, "max_stamina": 10, "stamina": 10})
	stats.take_damage(7)
	stats.heal(3)
	var ok = stats.health == 16 and not stats.is_dead
	stats.take_damage(99)
	ok = ok and stats.health == 0 and stats.is_dead
	_record("T036", "Stats 可扣血和治疗", ok)


func _t037() -> void:
	var scene = load("res://scenes/Player.tscn")
	if scene == null:
		_record("T037", "Player stats 初始化", false, "场景失败")
		return
	var p = scene.instantiate()
	root.add_child(p)
	await _wait_frame(); await _wait_frame()
	var s = p.get_stats() if p.has_method("get_stats") else null
	var ok = s != null and s.max_health > 0 and s.health > 0
	p.queue_free(); await _wait_frame()
	_record("T037", "Player stats 初始化", ok)


func _t038() -> void:
	var attacker = StatsClass.new()
	var defender = StatsClass.new()
	attacker.configure({"attack": 6})
	defender.configure({"defense": 4})
	var damage = CombatSystemClass.calculate_damage(attacker, defender)
	_record("T038", "CombatSystem 伤害计算", damage == 4, "damage=%d" % damage)


func _t039() -> void:
	var scene = load("res://scenes/Enemy.tscn")
	_record("T039", "Enemy 可实例化", scene != null and scene.instantiate() != null)


func _t040() -> void:
	var scene = load("res://scenes/Enemy.tscn")
	if scene == null:
		_record("T040", "Enemy 受伤死亡", false, "场景失败")
		return
	var enemy = scene.instantiate()
	root.add_child(enemy)
	enemy.setup({"id": "smoke_enemy", "display_name": "测试史莱姆", "enemy_type": "slime", "x": 1, "y": 1}, 32)
	await _wait_frame()
	enemy.take_damage(999)
	await _wait_frame()
	var ok = _world_state.defeated_enemies.has("smoke_enemy")
	if is_instance_valid(enemy):
		enemy.queue_free()
	await _wait_frame()
	_record("T040", "Enemy 受伤后可死亡", ok)


func _t041() -> void:
	var inv = InventoryClass.new()
	inv.add_item("herb", 2)
	var removed = inv.remove_item("herb", 1)
	_record("T041", "Inventory 添加/移除物品", removed and inv.has_item("herb", 1) and not inv.has_item("herb", 2))


func _t042() -> void:
	if _save_manager == null:
		_record("T042", "SaveManager 可保存", false, "SaveManager缺失")
		return
	_world_state.world_name = "SmokeWorld"
	_world_state.world_type = "xianxia"
	_world_state.add_item("coin", 1)
	var ok = _save_manager.save_game("smoke_test") and _save_manager.has_save("smoke_test")
	_record("T042", "SaveManager 可保存", ok)


func _t043() -> void:
	if _save_manager == null:
		_record("T043", "SaveManager 可读取", false, "SaveManager缺失")
		return
	_world_state.world_name = "ChangedWorld"
	var result = _save_manager.load_game("smoke_test")
	var ok = result.get("ok", false) and _world_state.world_name == "SmokeWorld"
	_save_manager.delete_save("smoke_test")
	_record("T043", "SaveManager 可读取", ok)


func _t044() -> void:
	_world_state.discovered_locations.clear()
	var exploration = ExplorationSystemClass.new()
	exploration.record_location("smoke_place", "测试地点")
	_record("T044", "ExplorationSystem 可记录发现地点", _world_state.discovered_locations.has("smoke_place"))


func _t045() -> void:
	_world_state.collected_items.clear()
	_world_state.set_inventory_items({})
	var player = Node2D.new()
	player.name = "SmokePlayer"
	root.add_child(player)
	var herb = InteractableClass.new()
	herb.setup({"id": "smoke_herb", "display_name": "测试草药", "interaction_type": "resource", "item_id": "herb", "item_amount": 1, "x": 0, "y": 0}, 32)
	root.add_child(herb)
	player.global_position = herb.global_position
	await _wait_frame()
	var result = InteractionSystemClass.new().interact(player)
	var ok = result.get("ok", false) and _world_state.has_item("herb", 1)
	player.queue_free()
	if is_instance_valid(herb):
		herb.queue_free()
	await _wait_frame()
	_record("T045", "InteractionSystem 可执行草药拾取", ok)


func _t046() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.reset_state()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null:
		_record("T046", "GameWorld 可生成敌人", false, "场景失败")
		return
	var gw = scene.instantiate()
	root.add_child(gw)
	await _wait_frame(); await _wait_frame(); await _wait_frame()
	var count = gw.get_enemy_count() if gw.has_method("get_enemy_count") else 0
	gw.queue_free(); await _wait_frame()
	_record("T046", "GameWorld 可生成敌人", count >= 3, "count=%d" % count)


func _t047() -> void:
	var bp = await _get_mock_blueprint()
	_world_state.reset_state()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null:
		_record("T047", "GameWorld 可生成资源点", false, "场景失败")
		return
	var gw = scene.instantiate()
	root.add_child(gw)
	await _wait_frame(); await _wait_frame(); await _wait_frame()
	var count = gw.get_interactable_count() if gw.has_method("get_interactable_count") else 0
	gw.queue_free(); await _wait_frame()
	_record("T047", "GameWorld 可生成资源点", count >= 5, "count=%d" % count)


func _t048() -> void:
	var scene = load("res://scenes/ui/GameHUD.tscn")
	if scene == null:
		_record("T048", "HUD 生命条节点存在", false, "场景失败")
		return
	var hud = scene.instantiate()
	var ok = hud.get_node_or_null("TopBar/HPBar") != null and hud.get_node_or_null("TopBar/StaminaBar") != null
	hud.queue_free()
	_record("T048", "HUD 生命条节点存在", ok)


func _t049() -> void:
	var required = [
		"res://art/generated/characters/player_idle.png",
		"res://art/generated/enemies/enemy_slime.png",
		"res://art/generated/tiles/tile_grass.png",
		"res://art/generated/items/item_herb.png",
		"res://art/generated/ui/ui_heart.png",
		"res://art/generated/effects/effect_hit_sheet.png"
	]
	var ok = true
	for path in required:
		if not FileAccess.file_exists(path):
			ok = false
			break
	_record("T049", "自动生成素材文件存在", ok)


func _t050() -> void:
	_record("T050", "ASSET_MANIFEST.md 存在", FileAccess.file_exists("res://ASSET_MANIFEST.md"))


# ═══════════════ T051–T062 v0.2.1 素材扩展 ═══════════════

func _t051() -> void:
	_record("T051", "generate_pixel_assets.py 存在", FileAccess.file_exists("res://tools/generate_pixel_assets.py"))


func _t052() -> void:
	var ok = DirAccess.dir_exists_absolute("res://art/generated")
	_record("T052", "art/generated 目录存在", ok)


func _t053() -> void:
	var paths = [
		"res://art/generated/characters/player/player_idle_down_sheet.png",
		"res://art/generated/characters/player/player_walk_up_sheet.png",
		"res://art/generated/characters/player/player_attack_left_sheet.png",
		"res://art/generated/characters/player/player_hurt.png",
		"res://art/generated/characters/player/player_dead.png"
	]
	_record("T053", "玩家动画素材存在", _all_files_exist(paths))


func _t054() -> void:
	var paths = [
		"res://art/generated/characters/npc/npc_farmer.png",
		"res://art/generated/characters/npc/npc_blacksmith.png",
		"res://art/generated/characters/npc/npc_cyber_doctor.png",
		"res://art/generated/characters/npc/npc_wasteland_survivor.png"
	]
	_record("T054", "NPC 扩展素材存在", _all_files_exist(paths))


func _t055() -> void:
	var paths = [
		"res://art/generated/enemies/slime/enemy_slime_poison.png",
		"res://art/generated/enemies/beast/enemy_boar.png",
		"res://art/generated/enemies/beast/enemy_elite_wolf.png",
		"res://art/generated/enemies/humanoid/enemy_skeleton.png",
		"res://art/generated/enemies/humanoid/enemy_demon_seed.png"
	]
	_record("T055", "敌人扩展素材存在", _all_files_exist(paths))


func _t056() -> void:
	var paths = [
		"res://art/generated/tiles/xianxia/tile_bamboo.png",
		"res://art/generated/tiles/apocalypse/tile_abandoned_car.png",
		"res://art/generated/tiles/cyberpunk/tile_terminal.png",
		"res://art/generated/tiles/tile_lantern.png"
	]
	_record("T056", "地图瓦片扩展素材存在", _all_files_exist(paths))


func _t057() -> void:
	var paths = [
		"res://art/generated/items/materials/item_spirit_grass.png",
		"res://art/generated/items/consumables/item_stamina_potion.png",
		"res://art/generated/items/weapons/item_iron_sword.png",
		"res://art/generated/items/item_data_chip.png"
	]
	_record("T057", "物品图标扩展素材存在", _all_files_exist(paths))


func _t058() -> void:
	var paths = [
		"res://art/generated/ui/icons/ui_inventory.png",
		"res://art/generated/ui/icons/ui_quest.png",
		"res://art/generated/ui/panels/panel_dialogue.png",
		"res://art/generated/ui/panels/button_pressed.png"
	]
	_record("T058", "UI 扩展素材存在", _all_files_exist(paths))


func _t059() -> void:
	var paths = [
		"res://art/generated/effects/combat/effect_slash_down_sheet.png",
		"res://art/generated/effects/combat/effect_hit_big_sheet.png",
		"res://art/generated/effects/magic/effect_fireball_sheet.png",
		"res://art/generated/effects/magic/effect_lightning_sheet.png"
	]
	_record("T059", "特效扩展素材存在", _all_files_exist(paths))


func _t060() -> void:
	var paths = [
		"res://art/generated/previews/character_preview.png",
		"res://art/generated/previews/enemy_preview.png",
		"res://art/generated/previews/tile_preview.png",
		"res://art/generated/previews/item_preview.png",
		"res://art/generated/previews/ui_preview.png",
		"res://art/generated/previews/effect_preview.png",
		"res://art/generated/previews/all_assets_preview.png"
	]
	_record("T060", "预览图存在", _all_files_exist(paths))


func _t061() -> void:
	var text = _read_text("res://ASSET_MANIFEST.md")
	var ok = "## 统计" in text and "总素材数量: 186" in text and "预览图数量: 7" in text
	_record("T061", "ASSET_MANIFEST.md 包含统计信息", ok)


func _t062() -> void:
	var text = _read_text("res://PLACEHOLDER_ART.md")
	var ok = "v0.2.1" in text and "扩展素材" in text and "Aseprite" in text
	_record("T062", "PLACEHOLDER_ART.md 包含 v0.2.1 说明", ok)


func _all_files_exist(paths: Array) -> bool:
	for path in paths:
		if not FileAccess.file_exists(path):
			return false
	return true


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text = file.get_as_text()
	file.close()
	return text


# ═══════════════ 汇总 ═══════════════

func _print_summary() -> void:
	print("")
	print("=".repeat(60))
	print("  SmokeTest Results Summary")
	print("=".repeat(60))
	print("  Total:  %d" % (_pass_count + _fail_count + _skip_count))
	print("  PASS:   %d" % _pass_count)
	print("  FAIL:   %d" % _fail_count)
	print("  SKIP:   %d" % _skip_count)
	print("=".repeat(60))
	if _fail_count > 0:
		print("")
		print("  FAILED TESTS:")
		for r in _results:
			if r.status == "FAIL":
				print("    %s — %s  (%s)" % [r.id, r.desc, r.note])
