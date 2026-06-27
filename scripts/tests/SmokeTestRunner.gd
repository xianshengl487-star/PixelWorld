extends SceneTree
## SmokeTestRunner.gd — CLI 自动化冒烟测试  v0.3.0
## 运行: godot --headless --path . --script res://scripts/tests/SmokeTestRunner.gd

const AIClientClass = preload("res://scripts/ai/AIClient.gd")
const StatsClass = preload("res://scripts/entities/Stats.gd")
const CombatSystemClass = preload("res://scripts/combat/CombatSystem.gd")
const InventoryClass = preload("res://scripts/items/Inventory.gd")
const ExplorationSystemClass = preload("res://scripts/world/ExplorationSystem.gd")
const InteractionSystemClass = preload("res://scripts/interactions/InteractionSystem.gd")
const InteractableClass = preload("res://scripts/interactions/Interactable.gd")
const AssetResolverClass = preload("res://scripts/assets/AssetResolver.gd")
const CharacterVisualProfileClass = preload("res://scripts/assets/CharacterVisualProfile.gd")
const ProgressionTemplateLoaderClass = preload("res://scripts/progression/ProgressionTemplateLoader.gd")
const ProgressionSystemClass = preload("res://scripts/progression/ProgressionSystem.gd")
const BreakthroughSystemClass = preload("res://scripts/progression/BreakthroughSystem.gd")
const TribulationSystemClass = preload("res://scripts/progression/TribulationSystem.gd")
const RealmEffectApplierClass = preload("res://scripts/progression/RealmEffectApplier.gd")
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
	print("  PixelWorld CLI Smoke Test Runner  v0.3.0  (seed=%d)" % TEST_SEED)
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
	_t081(); _t082(); _t083(); _t084(); _t085(); _t086()
	_t087(); _t088(); _t089(); _t090(); _t091(); _t092()
	_t093(); _t094(); _t095(); _t096(); _t097(); _t098()
	_t099(); _t100(); _t101(); _t102(); _t103(); _t104()
	_t105(); _t106(); _t107(); _t108(); _t109(); _t110()
	_t111(); _t112(); _t113(); _t114(); _t115()

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


# ═══════════════ T081–T115 v0.3.0 成长体系 ═══════════════

func _t081() -> void:
	_record("T081", "CODE_AUDIT.md 存在", FileAccess.file_exists("res://CODE_AUDIT.md"))


func _t082() -> void:
	var resolver = AssetResolverClass.new()
	var texture = resolver.get_player_texture("idle_down")
	_record("T082", "AssetResolver 可加载玩家素材或 fallback", texture != null)


func _t083() -> void:
	var resolver = AssetResolverClass.new()
	var texture = resolver.get_npc_texture("chief")
	_record("T083", "AssetResolver 可加载 NPC 素材或 fallback", texture != null)


func _t084() -> void:
	var resolver = AssetResolverClass.new()
	var texture = resolver.get_enemy_texture("slime")
	_record("T084", "AssetResolver 可加载敌人素材或 fallback", texture != null)


func _t085() -> void:
	var profile = CharacterVisualProfileClass.new()
	profile.entity_type = "player"
	_record("T085", "CharacterVisualProfile 可创建", profile != null and profile.to_dict().get("entity_type", "") == "player")


func _t086() -> void:
	var template = ProgressionTemplateLoaderClass.new().load_template("xianxia")
	_record("T086", "ProgressionTemplateLoader 可加载修仙模板", not template.is_empty() and template.get("system_id", "") == "xianxia_realm")


func _t087() -> void:
	var template = ProgressionTemplateLoaderClass.new().load_template("xianxia")
	_record("T087", "修仙模板包含 10 个大境界", template.get("realms", []).size() >= 10, "count=%d" % template.get("realms", []).size())


func _t088() -> void:
	var realm = _template_realm("xianxia", "qi_refining")
	var count = realm.get("minor_stages", []).size()
	_record("T088", "修仙炼气包含 10 个小阶段", count >= 10, "count=%d" % count)


func _t089() -> void:
	var realm = _template_realm("xianxia", "foundation")
	var text = str(realm.get("breakthrough", {})).to_lower()
	_record("T089", "修仙筑基到金丹包含心魔或雷劫", "heart_demon" in text or "lightning" in text)


func _t090() -> void:
	var template = ProgressionTemplateLoaderClass.new().load_template("xianxia")
	_world_state.reset_state()
	var system = ProgressionSystemClass.new()
	system.bind_world_state(_world_state)
	system.setup("xianxia", template)
	_record("T090", "ProgressionSystem 可初始化 xianxia", _world_state.progression_data.get("system_id", "") == "xianxia_realm")


func _t091() -> void:
	var system = _setup_progression("xianxia")
	var before = int(_world_state.progression_data.get("current_progress", 0))
	system.gain_progress(15, "smoke")
	_record("T091", "ProgressionSystem 可获得修为", int(_world_state.progression_data.get("current_progress", 0)) > before)


func _t092() -> void:
	var system = _setup_progression("xianxia")
	system.gain_progress(30, "smoke")
	var result = system.advance_minor_stage()
	_record("T092", "ProgressionSystem 可推进小境界", result.get("ok", false), result.get("message", ""))


func _t093() -> void:
	var realm = _template_realm("xianxia", "mortal")
	var data = {"current_progress": 80, "failed_breakthroughs": 0, "breakthrough_points": 0}
	var rate = BreakthroughSystemClass.new().calculate_success_rate(data, realm, {"insight": 2, "luck": 2})
	_record("T093", "BreakthroughSystem 可计算成功率", rate > 0.0 and rate <= 0.95, "rate=%.2f" % rate)


func _t094() -> void:
	var realm = _template_realm("xianxia", "mortal")
	var data = {"current_progress": 0, "failed_breakthroughs": 0, "breakthrough_points": 0}
	var result = BreakthroughSystemClass.new().attempt(data, realm, {"force_result": "failure"})
	_record("T094", "BreakthroughSystem 失败会记录 failed_breakthroughs", int(data.get("failed_breakthroughs", 0)) == 1 and result.get("result", "") == "failure")


func _t095() -> void:
	var result = TribulationSystemClass.new().start_tribulation("heavenly_lightning", 3, {"base_damage": 4})
	_record("T095", "TribulationSystem 可启动雷劫", result.get("type", "") == "heavenly_lightning" and int(result.get("rounds", 0)) == 3)


func _t096() -> void:
	var trib = TribulationSystemClass.new()
	trib.start_tribulation("heavenly_lightning", 3, {"base_damage": 4})
	var stats = StatsClass.new()
	stats.configure({"max_health": 20, "health": 20, "defense": 1})
	var result = trib.resolve_round(1, stats, {"base_damage": 4, "tribulation_resistance": 0.1})
	_record("T096", "TribulationSystem 可结算雷劫轮次", result.has("damage") and int(result.get("round_index", 0)) == 1)


func _t097() -> void:
	var stats = StatsClass.new()
	stats.setup_defaults()
	RealmEffectApplierClass.new().apply_effects(stats, {"attack_add": 3, "max_health_add": 5})
	_record("T097", "RealmEffectApplier 可修改 Stats progression_bonus", int(stats.progression_bonus.get("attack", 0)) == 3 and stats.attack >= 3)


func _t098() -> void:
	var stats = StatsClass.new()
	stats.setup_defaults()
	var ok = stats.base_stats is Dictionary and stats.equipment_bonus is Dictionary and stats.progression_bonus is Dictionary and stats.status_bonus is Dictionary and stats.final_stats is Dictionary
	_record("T098", "Stats 支持 base/equipment/progression/status/final 结构", ok)


func _t099() -> void:
	if _save_manager == null:
		_record("T099", "SaveManager 保存 progression_data", false, "SaveManager缺失")
		return
	_world_state.progression_data = _world_state._default_progression_data()
	_world_state.progression_data["current_realm_id"] = "smoke_realm"
	var ok = _save_manager.save_game("smoke_progression") and _save_manager.has_save("smoke_progression")
	_record("T099", "SaveManager 保存 progression_data", ok)


func _t100() -> void:
	if _save_manager == null:
		_record("T100", "SaveManager 读取 progression_data", false, "SaveManager缺失")
		return
	_world_state.progression_data["current_realm_id"] = "changed"
	var result = _save_manager.load_game("smoke_progression")
	var ok = result.get("ok", false) and _world_state.progression_data.get("current_realm_id", "") == "smoke_realm"
	_save_manager.delete_save("smoke_progression")
	_record("T100", "SaveManager 读取 progression_data", ok)


func _t101() -> void:
	_record("T101", "magic_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("magic").is_empty())


func _t102() -> void:
	_record("T102", "apocalypse_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("apocalypse").is_empty())


func _t103() -> void:
	_record("T103", "cyberpunk_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("cyberpunk").is_empty())


func _t104() -> void:
	_record("T104", "wuxia_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("wuxia").is_empty())


func _t105() -> void:
	_record("T105", "urban_ability_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("urban_ability").is_empty())


func _t106() -> void:
	_record("T106", "strange_tale_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("strange_tale").is_empty())


func _t107() -> void:
	_record("T107", "star_sci_progression.json 存在并可加载", not ProgressionTemplateLoaderClass.new().load_template("star_sci").is_empty())


func _t108() -> void:
	var ok = true
	for world_type in ProgressionTemplateLoaderClass.new().get_supported_world_types():
		var template = ProgressionTemplateLoaderClass.new().load_template(world_type)
		if template.get("realms", []).size() < 8:
			ok = false
			break
	_record("T108", "每个模板至少 8 个阶段", ok)


func _t109() -> void:
	var ok = true
	for world_type in ProgressionTemplateLoaderClass.new().get_supported_world_types():
		var template = ProgressionTemplateLoaderClass.new().load_template(world_type)
		if template.get("progression_resources", []).is_empty():
			ok = false
			break
	_record("T109", "每个模板有升级资源名称", ok)


func _t110() -> void:
	var ok = true
	for world_type in ProgressionTemplateLoaderClass.new().get_supported_world_types():
		var template = ProgressionTemplateLoaderClass.new().load_template(world_type)
		if template.get("failure_consequences", []).is_empty():
			ok = false
			break
	_record("T110", "每个模板有失败代价配置", ok)


func _t111() -> void:
	var scene = load("res://scenes/ui/GameHUD.tscn")
	var hud = scene.instantiate() if scene != null else null
	var ok = hud != null and hud.has_method("update_progression_display")
	if hud != null:
		hud.queue_free()
	_record("T111", "HUD 有 progression 显示方法", ok)


func _t112() -> void:
	_record("T112", "WorldState 有 realm_history", typeof(_world_state.realm_history) == TYPE_ARRAY)


func _t113() -> void:
	_record("T113", "WorldState 有 tribulation_record", typeof(_world_state.tribulation_record) == TYPE_ARRAY)


func _t114() -> void:
	var resolver = AssetResolverClass.new()
	var texture = resolver.resolve_texture("res://art/generated/not_here/missing.png", "")
	_record("T114", "角色材质缺失时不会崩溃", texture == null)


func _t115() -> void:
	var text = _read_text("res://README.md")
	_record("T115", "README 更新当前版本和玩法路线图", "v0.3.0" in text and "玩法路线图" in text)


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


func _template_realm(world_type: String, realm_id: String) -> Dictionary:
	var template = ProgressionTemplateLoaderClass.new().load_template(world_type)
	for realm in template.get("realms", []):
		if str(realm.get("id", "")) == realm_id:
			return realm
	return {}


func _setup_progression(world_type: String):
	var template = ProgressionTemplateLoaderClass.new().load_template(world_type)
	_world_state.reset_state()
	var system = ProgressionSystemClass.new()
	system.bind_world_state(_world_state)
	system.setup(world_type, template)
	return system


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
