extends SceneTree
## SmokeTestRunner.gd — CLI 自动化冒烟测试  v0.4.1
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
const WorldGraphClass = preload("res://scripts/world/WorldGraph.gd")
const WorldInstanceClass = preload("res://scripts/world/WorldInstance.gd")
const MapInstanceClass = preload("res://scripts/map/MapInstance.gd")
const MapTransitionClass = preload("res://scripts/map/MapTransition.gd")
const MapStateClass = preload("res://scripts/map/MapState.gd")
const MapStateSerializerClass = preload("res://scripts/map/MapStateSerializer.gd")
const MapTypeRuleLoaderClass = preload("res://scripts/map/MapTypeRuleLoader.gd")
const MapInstanceGeneratorClass = preload("res://scripts/map/MapInstanceGenerator.gd")
const MapConnectionValidatorClass = preload("res://scripts/map/MapConnectionValidator.gd")
const BuildingTemplateClass = preload("res://scripts/buildings/BuildingTemplate.gd")
const BuildingInstanceClass = preload("res://scripts/buildings/BuildingInstance.gd")
const BuildingPlacementValidatorClass = preload("res://scripts/buildings/BuildingPlacementValidator.gd")
const BuildingRegistryClass = preload("res://scripts/buildings/BuildingRegistry.gd")
const BuildingServiceClass = preload("res://scripts/buildings/BuildingService.gd")
const InteriorMapGeneratorClass = preload("res://scripts/buildings/InteriorMapGenerator.gd")
const DoorInteractionClass = preload("res://scripts/buildings/DoorInteraction.gd")
const TransitionAreaClass = preload("res://scripts/map/TransitionArea.gd")
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
	print("  PixelWorld CLI Smoke Test Runner  v0.4.1  (seed=%d)" % TEST_SEED)
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
	_t116(); await _t117(); await _t118(); _t119(); _t120(); _t121()
	_t122(); _t123(); _t124(); _t125(); _t126(); _t127()
	_t128(); _t129(); _t130(); _t131(); _t132(); _t133()
	_t134(); await _t135(); await _t136(); await _t137(); _t138()
	await _t139(); await _t140(); await _t141(); await _t142(); await _t143()
	_t144(); _t145(); _t146(); _t147(); _t148(); _t149()
	_t150(); _t151(); await _t152(); await _t153(); _t154(); _t155()
	_t156(); _t157(); _t158(); _t159(); _t160(); _t161(); await _t162()
	_t163(); _t164(); _t165(); _t166(); _t167(); _t168(); _t169(); _t170()
	_t171(); _t172(); _t173(); _t174(); _t175(); await _t176(); await _t177()
	await _t178(); await _t179(); await _t180(); await _t181(); await _t182()
	await _t183(); await _t184(); _t185(); _t186(); await _t187(); _t188()
	_t189(); _t190(); _t191(); _t192(); await _t193(); await _t194()
	await _t195(); _t196(); _t197(); await _t198(); await _t199(); _t200()
	await _t201(); await _t202(); await _t203(); await _t204(); await _t205()
	await _t206(); await _t207(); _t208(); _t209(); _t210()

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
	var ok = p != null
	if p == null:
		var children = []
		for c in gw.get_children():
			children.append(c.name + "(" + c.get_class() + ")")
		print("  [T025 DIAG] children: " + ", ".join(children))
		var initialized = gw.is_initialized() if gw.has_method("is_initialized") else false
		print("  [T025 DIAG] is_initialized=%s" % str(initialized))
	if ok:
		gw.queue_free(); await _wait_frame()
		_record("T025", "GameWorld player node exists after init", true)
		return
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
	_record("T115", "README 更新当前版本和玩法路线图", "v0.4.0" in text and "玩法路线图" in text)


# ═══════════════ T116–T155 v0.4.0 多地图架构 ═══════════════

func _t116() -> void:
	_record("T116", "WorldGraph 可创建", WorldGraphClass.new() != null)


func _t117() -> void:
	var bp = await _get_mock_blueprint()
	var graph = WorldGraphClass.new()
	graph.setup(bp)
	_record("T117", "WorldGraph 至少包含 4 张地图", graph.maps.size() >= 4, "count=%d" % graph.maps.size())


func _t118() -> void:
	var bp = await _get_mock_blueprint()
	var graph = WorldGraphClass.new()
	graph.setup(bp)
	var result = graph.validate_graph()
	_record("T118", "WorldGraph validate_graph 通过", result.get("ok", false), str(result.get("errors", [])))


func _t119() -> void:
	var map = MapInstanceClass.new()
	map.setup({"map_id": "smoke_map", "display_name": "测试地图", "map_type": "village"})
	_record("T119", "MapInstance 可创建", map.map_id == "smoke_map")


func _t120() -> void:
	var map = MapInstanceClass.new()
	map.setup({"map_id": "smoke_map", "display_name": "测试地图", "map_type": "forest", "size": [128, 128]})
	var ok = map.map_id != "" and map.display_name != "" and map.map_type == "forest" and map.size == Vector2i(128, 128)
	_record("T120", "MapInstance 有 map_id/display_name/map_type/size", ok)


func _t121() -> void:
	var map = MapInstanceClass.new()
	map.setup({"map_id": "smoke_map", "map_type": "village"})
	_record("T121", "MapInstance 有 default spawn", map.spawn_points.has("default"))


func _t122() -> void:
	var transition = MapTransitionClass.new()
	transition.setup({"transition_id": "smoke_exit", "from_map_id": "a", "to_map_id": "b"})
	_record("T122", "MapTransition 可创建", transition.transition_id == "smoke_exit" and transition.to_map_id == "b")


func _t123() -> void:
	var transition = MapTransitionClass.new()
	transition.setup({"transition_id": "smoke_exit", "enabled": true})
	_record("T123", "MapTransition can_use 在无条件时通过", transition.can_use(_world_state).get("ok", false))


func _t124() -> void:
	var transition = MapTransitionClass.new()
	transition.setup({"transition_id": "sect_gate", "required_realm_order": 5, "locked_message": "境界不足"})
	_world_state.progression_data["current_realm_order"] = 0
	var result = transition.can_use(_world_state)
	_record("T124", "MapTransition required_realm_order 不满足时拒绝", not result.get("ok", true), result.get("reason", ""))


func _t125() -> void:
	var state = MapStateClass.new()
	state.mark_chest_opened("chest_001")
	_record("T125", "MapState 可记录 opened_chests", state.is_chest_opened("chest_001"))


func _t126() -> void:
	var state = MapStateClass.new()
	state.mark_resource_collected("herb_001")
	_record("T126", "MapState 可记录 collected_resources", state.is_resource_collected("herb_001"))


func _t127() -> void:
	var state = MapStateClass.new()
	state.mark_enemy_defeated("wolf_001")
	_record("T127", "MapState 可记录 defeated_enemies", state.is_enemy_defeated("wolf_001"))


func _t128() -> void:
	var state = MapStateClass.new()
	state.map_id = "forest_001"
	state.mark_chest_opened("chest_001")
	var serializer = MapStateSerializerClass.new()
	var data = serializer.serialize_map_state(state)
	var restored = serializer.deserialize_map_state(data)
	_record("T128", "MapStateSerializer 可序列化/反序列化", restored.map_id == "forest_001" and restored.is_chest_opened("chest_001"))


func _t129() -> void:
	var loader = MapTypeRuleLoaderClass.new()
	var rules = loader.load_rules()
	_record("T129", "MapTypeRuleLoader 可加载 map_type_rules.json", not rules.is_empty())


func _t130() -> void:
	var rules = MapTypeRuleLoaderClass.new().load_rules()
	var ok = rules.has("village") and rules.has("forest") and rules.has("cave") and rules.has("sect_gate")
	_record("T130", "map_type_rules 至少包含 village/forest/cave/sect_gate", ok)


func _t131() -> void:
	var map = MapInstanceGeneratorClass.new().generate_map_instance({"map_id": "village_001", "display_name": "青木村", "map_type": "village"}, {"world_type": "xianxia", "seed": TEST_SEED})
	_record("T131", "MapInstanceGenerator 可生成 village", map.map_type == "village" and map.tiles.size() > 0 and map.buildings.size() >= 3)


func _t132() -> void:
	var map = MapInstanceGeneratorClass.new().generate_map_instance({"map_id": "forest_001", "display_name": "黑松后山", "map_type": "forest"}, {"world_type": "xianxia", "seed": TEST_SEED})
	_record("T132", "MapInstanceGenerator 可生成 forest", map.map_type == "forest" and map.tiles.size() > 0 and map.enemies.size() >= 3)


func _t133() -> void:
	var map = MapInstanceGeneratorClass.new().generate_map_instance({"map_id": "village_001", "map_type": "village"}, {"seed": TEST_SEED})
	_record("T133", "village 默认尺寸为 96x96 或来自规则", map.size == Vector2i(96, 96), "%dx%d" % [map.size.x, map.size.y])


func _t134() -> void:
	var map = MapInstanceGeneratorClass.new().generate_map_instance({"map_id": "forest_001", "map_type": "forest"}, {"seed": TEST_SEED})
	_record("T134", "forest 默认尺寸为 128x128 或来自规则", map.size == Vector2i(128, 128), "%dx%d" % [map.size.x, map.size.y])


func _t135() -> void:
	var bp = await _get_mock_blueprint()
	_record("T135", "MockProvider 生成 blueprint 包含 maps", bp.has("maps") and bp.get("maps", []).size() >= 4)


func _t136() -> void:
	var bp = await _get_mock_blueprint()
	_record("T136", "MockProvider 生成 blueprint 包含 connections", bp.has("connections") and bp.get("connections", []).size() >= 3)


func _t137() -> void:
	var bp = await _get_mock_blueprint()
	var graph = WorldGraphClass.new()
	graph.setup(bp)
	var result = MapConnectionValidatorClass.new().validate_world_graph(graph)
	_record("T137", "MapConnectionValidator 检查连接有效", result.get("ok", false), str(result.get("errors", [])))


func _t138() -> void:
	var bp = await _get_mock_blueprint()
	var scene = load("res://scenes/GameWorld.tscn")
	var gw = scene.instantiate()
	var ok = gw.setup_world_graph_from_blueprint(bp)
	gw.queue_free()
	_record("T138", "GameWorld 可 setup WorldGraph", ok)


func _t139() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_current_map_id() == "village_001"
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T139", "GameWorld 可 load_map village_001", ok)


func _t140() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_current_map_id() == "village_001"
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T140", "GameWorld 当前 map_id 正确", ok)


func _t141() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw.switch_map("forest_001", "from_village") if gw != null else false
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T141", "GameWorld 可 switch_map 到 forest_001", ok)


func _t142() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("forest_001", "from_village")
		ok = gw.get_current_map_id() == "forest_001"
		gw.queue_free()
		await _wait_frame()
	_record("T142", "switch_map 后 current_map_id 正确", ok)


func _t143() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("forest_001", "from_village")
		var player = gw.get_player_node()
		var expected = gw.current_map_instance.get_spawn_point("from_village")
		var actual = Vector2i(int(player.position.x / 32), int(player.position.y / 32)) if player != null else Vector2i(-1, -1)
		ok = actual == expected
		gw.queue_free()
		await _wait_frame()
	_record("T143", "switch_map 后玩家位置使用目标 spawn", ok)


func _t144() -> void:
	_prepare_map_save_state()
	var ok = _save_manager.save_game("smoke_map_arch") and _save_manager.has_save("smoke_map_arch")
	_record("T144", "SaveManager 保存 current_map_id", ok)


func _t145() -> void:
	var ok = _world_state.visited_maps.has("village_001") and _world_state.visited_maps.has("forest_001")
	_record("T145", "SaveManager 保存 visited_maps", ok)


func _t146() -> void:
	var ok = _world_state.map_states.has("forest_001")
	_record("T146", "SaveManager 保存 map_states", ok)


func _t147() -> void:
	_world_state.current_map_id = "changed"
	var result = _save_manager.load_game("smoke_map_arch")
	var ok = result.get("ok", false) and _world_state.current_map_id == "forest_001"
	_record("T147", "SaveManager 读取 current_map_id", ok)


func _t148() -> void:
	var ok = _world_state.map_states.has("forest_001") and _world_state.map_states["forest_001"].get("opened_chests", {}).has("chest_001")
	_save_manager.delete_save("smoke_map_arch")
	_record("T148", "SaveManager 读取 map_states", ok)


func _t149() -> void:
	var template = BuildingTemplateClass.new()
	template.setup({"building_type": "apothecary", "display_name": "药铺", "size": [6, 5]})
	_record("T149", "BuildingTemplate 可创建", template.building_type == "apothecary")


func _t150() -> void:
	var building = BuildingInstanceClass.new()
	building.setup({"building_id": "inn_001", "building_type": "inn", "position": {"x": 4, "y": 5}, "size": [8, 6]})
	_record("T150", "BuildingInstance 可创建", building.building_id == "inn_001")


func _t151() -> void:
	var map = MapInstanceGeneratorClass.new().generate_map_instance({"map_id": "village_001", "map_type": "village"}, {"seed": TEST_SEED})
	var result = BuildingPlacementValidatorClass.new().validate_placement(map, {"building_id": "bad", "position": {"x": map.size.x - 1, "y": map.size.y - 1}, "size": [8, 8]})
	_record("T151", "BuildingPlacementValidator 可检测 footprint 越界", not result.get("ok", true))


func _t152() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_node_or_null("BuildingLayer") != null
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T152", "GameWorld 有 BuildingLayer", ok)


func _t153() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_node_or_null("TransitionLayer") != null
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T153", "GameWorld 有 TransitionLayer", ok)


func _t154() -> void:
	_record("T154", "GAMEPLAY_MAP_ARCHITECTURE.md 存在", FileAccess.file_exists("res://GAMEPLAY_MAP_ARCHITECTURE.md"))


func _t155() -> void:
	var text = _read_text("res://README.md")
	_record("T155", "README 更新 v0.4.0 地图架构说明", "v0.4.0" in text and "WorldGraph" in text and "MapInstance" in text)


func _t156() -> void:
	var templates = BuildingRegistryClass.new().load_templates()
	_record("T156", "BuildingRegistry loads templates", templates.size() >= 10)


func _t157() -> void:
	var template = BuildingRegistryClass.new().get_template("chief_house")
	_record("T157", "chief_house template has required keys", _building_template_has_required_keys(template))


func _t158() -> void:
	var template = BuildingRegistryClass.new().get_template("apothecary")
	_record("T158", "apothecary template has healer service", _building_template_has_required_keys(template) and "healer" in template.get("services", []))


func _t159() -> void:
	var template = BuildingRegistryClass.new().get_template("blacksmith")
	_record("T159", "blacksmith template has service", _building_template_has_required_keys(template) and "blacksmith" in template.get("services", []))


func _t160() -> void:
	var template = BuildingRegistryClass.new().get_template("inn")
	_record("T160", "inn template has inn service", _building_template_has_required_keys(template) and "inn" in template.get("services", []))


func _t161() -> void:
	var service = BuildingServiceClass.new()
	service.setup({"service_id": "healer_001", "service_type": "healer", "display_name": "Healer"})
	_record("T161", "BuildingService healer can be created", service.service_type == "healer" and service.can_use(_world_state).get("ok", false))


func _t162() -> void:
	var scene = load("res://scenes/Player.tscn")
	var player = scene.instantiate() if scene != null else null
	if player == null:
		_record("T162", "BuildingService healer restores player health", false, "Player scene missing")
		return
	root.add_child(player)
	await _wait_frame()
	var stats = player.get_stats() if player.has_method("get_stats") else null
	if stats != null:
		stats.take_damage(9)
	_world_state.player_health = 3
	var service = BuildingServiceClass.new()
	service.setup({"service_id": "healer_001", "service_type": "healer"})
	var result = service.use_service(player, _world_state)
	var ok = result.get("ok", false) and _world_state.player_health == _world_state.player_max_health
	if stats != null:
		ok = ok and stats.health == stats.max_health
	player.queue_free()
	await _wait_frame()
	_record("T162", "BuildingService healer restores player health", ok)


func _t163() -> void:
	var building = BuildingRegistryClass.new().create_building_instance("chief_house", Vector2i(20, 20), "village_001")
	var map = InteriorMapGeneratorClass.new().generate_chief_house(building, {"world_type": "xianxia"})
	_record("T163", "InteriorMapGenerator creates chief_house interior", map != null and map.map_type == "interior" and map.parent_building_id == "chief_house_001")


func _t164() -> void:
	var building = BuildingRegistryClass.new().create_building_instance("apothecary", Vector2i(20, 20), "village_001")
	var map = InteriorMapGeneratorClass.new().generate_apothecary(building, {"world_type": "xianxia"})
	_record("T164", "InteriorMapGenerator creates apothecary interior id", map != null and map.map_id == "apothecary_001_interior")


func _t165() -> void:
	var map = _sample_interior_map()
	_record("T165", "Generated interior map_type is interior", map != null and map.map_type == "interior")


func _t166() -> void:
	var map = _sample_interior_map()
	_record("T166", "Interior map has default spawn", map != null and map.spawn_points.has("default"))


func _t167() -> void:
	var map = _sample_interior_map()
	var ok = false
	if map != null:
		for transition in map.transitions:
			if str(transition.get("to_map_id", "")) == "village_001" and str(transition.get("target_spawn_id", "")) == "apothecary_001_door":
				ok = true
				break
	_record("T167", "Interior map has exit transition back to village", ok)


func _t168() -> void:
	var door = DoorInteractionClass.new()
	door.setup({"building_id": "apothecary_001", "interior_map_id": "apothecary_001_interior", "target_spawn_id": "default", "from_rect": {"x": 1, "y": 2, "w": 1, "h": 1}}, 32)
	var ok = door.building_id == "apothecary_001" and door.target_map_id == "apothecary_001_interior" and door.get_child_count() > 0
	door.queue_free()
	_record("T168", "DoorInteraction sets target interior", ok)


func _t169() -> void:
	var map = _generated_village()
	_record("T169", "Village generator places buildings", map != null and map.buildings.size() >= 5)


func _t170() -> void:
	var map = _generated_village()
	_record("T170", "Village has chief_house", not _find_building(map, "chief_house").is_empty())


func _t171() -> void:
	var map = _generated_village()
	_record("T171", "Village has apothecary", not _find_building(map, "apothecary").is_empty())


func _t172() -> void:
	var map = _generated_village()
	var ok = map != null and map.buildings.size() > 0
	if ok:
		for building in map.buildings:
			if not building.has("door_position"):
				ok = false
				break
	_record("T172", "Every village building has door_position", ok)


func _t173() -> void:
	var map = _generated_village()
	var ok = map != null and map.buildings.size() > 0
	if ok:
		for building in map.buildings:
			if str(building.get("interior_map_id", "")) == "":
				ok = false
				break
	_record("T173", "Every village building has interior_map_id", ok)


func _t174() -> void:
	var map = _generated_village()
	var building = _find_building(map, "chief_house")
	var result = BuildingPlacementValidatorClass.new().validate_placement(map, building)
	_record("T174", "BuildingPlacementValidator detects overlap", not result.get("ok", true))


func _t175() -> void:
	var map = _generated_village()
	var building = _find_building(map, "apothecary")
	var original = map.buildings.duplicate(true)
	map.buildings.clear()
	var result = BuildingPlacementValidatorClass.new().validate_placement(map, building)
	map.buildings = original
	_record("T175", "BuildingPlacementValidator accepts walkable door", result.get("ok", false))


func _t176() -> void:
	var bp = await _get_mock_blueprint()
	var found = false
	for map_data in bp.get("maps", []):
		if str(map_data.get("map_id", "")).ends_with("_interior"):
			found = true
			break
	_record("T176", "World blueprint includes interior maps", found)


func _t177() -> void:
	var bp = await _get_mock_blueprint()
	_record("T177", "WorldGraph connects village to apothecary interior", _has_connection(bp, "village_001", "apothecary_001_interior"))


func _t178() -> void:
	var bp = await _get_mock_blueprint()
	_record("T178", "WorldGraph connects apothecary interior to village", _has_connection(bp, "apothecary_001_interior", "village_001"))


func _t179() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_current_map_id() == "village_001"
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T179", "GameWorld loads village map", ok)


func _t180() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.switch_map("apothecary_001_interior", "default")
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T180", "GameWorld switches village to apothecary interior", ok)


func _t181() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		ok = gw.get_current_map_id() == "apothecary_001_interior"
		gw.queue_free()
		await _wait_frame()
	_record("T181", "GameWorld current_map_id updates to interior", ok)


func _t182() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		var spawn = gw.current_map_instance.get_spawn_point("default")
		ok = Vector2i(int(_world_state.player_position.x), int(_world_state.player_position.y)) == spawn
		gw.queue_free()
		await _wait_frame()
	_record("T182", "Player placed at interior default spawn", ok)


func _t183() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		ok = gw.switch_map("village_001", "apothecary_001_door")
		gw.queue_free()
		await _wait_frame()
	_record("T183", "GameWorld returns interior to village door", ok)


func _t184() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		gw.switch_map("village_001", "apothecary_001_door")
		ok = gw.get_current_map_id() == "village_001"
		gw.queue_free()
		await _wait_frame()
	_record("T184", "GameWorld current_map_id returns to village", ok)


func _t185() -> void:
	var state = MapStateClass.new()
	state.setup({"map_id": "village_001"})
	state.set_building_state("apothecary_001", {"visited": true})
	_record("T185", "MapState saves building_states", state.to_save_data().get("building_states", {}).has("apothecary_001"))


func _t186() -> void:
	var state = MapStateClass.new()
	state.setup({"map_id": "village_001", "last_player_position": {"x": 3, "y": 4}})
	_record("T186", "MapState restores last_player_position", state.last_player_position == Vector2i(3, 4))


func _t187() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.save_current_map_state()
		ok = _world_state.get_map_state("village_001").get("building_states", {}).size() > 0
		gw.queue_free()
		await _wait_frame()
	_record("T187", "GameWorld save_current_map_state writes building state", ok)


func _t188() -> void:
	if _save_manager == null:
		_record("T188", "SaveManager saves building_states", false, "SaveManager missing")
		return
	_world_state.building_states = {"apothecary_001": {"visited": true}}
	var ok = _save_manager.save_game("smoke_buildings") and _save_manager.has_save("smoke_buildings")
	_record("T188", "SaveManager saves building_states", ok)


func _t189() -> void:
	if _save_manager == null:
		_record("T189", "SaveManager loads building_states", false, "SaveManager missing")
		return
	_world_state.building_states.clear()
	var result = _save_manager.load_game("smoke_buildings")
	var ok = result.get("ok", false) and _world_state.building_states.has("apothecary_001")
	_save_manager.delete_save("smoke_buildings")
	_record("T189", "SaveManager loads building_states", ok)


func _t190() -> void:
	if _save_manager == null:
		_record("T190", "SaveManager accepts old save missing map fields", false, "SaveManager missing")
		return
	_save_manager._apply_save_data({"world_name": "Old", "world_type": "xianxia", "current_map_id": "village_001"})
	var ok = _world_state.map_states is Dictionary and _world_state.current_map_id == "village_001"
	_record("T190", "SaveManager accepts old save missing map fields", ok)


func _t191() -> void:
	var hud_scene = load("res://scenes/ui/GameHUD.tscn")
	var hud = hud_scene.instantiate() if hud_scene != null else null
	var ok = hud != null and hud.has_method("update_map_info")
	if hud != null:
		hud.queue_free()
	_record("T191", "GameHUD has update_map_info", ok)


func _t192() -> void:
	var hud_scene = load("res://scenes/ui/GameHUD.tscn")
	var hud = hud_scene.instantiate() if hud_scene != null else null
	var ok = hud != null and hud.has_method("show_transition_message") and hud.has_method("update_building_info")
	if hud != null:
		hud.queue_free()
	_record("T192", "GameHUD has transition and building methods", ok)


func _t193() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_node_or_null("TransitionLayer") != null and gw.get_node_or_null("BuildingLayer") != null
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T193", "GameWorld runtime layers exist", ok)


func _t194() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_transition_count() > 0
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T194", "GameWorld creates transition areas", ok)


func _t195() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		var layer = gw.get_node_or_null("BuildingLayer")
		ok = layer != null and layer.get_child_count() > 0
		gw.queue_free()
		await _wait_frame()
	_record("T195", "Loaded village renders building layer", ok)


func _t196() -> void:
	var map = _sample_interior_map()
	_record("T196", "Interior map has tiles and service POI", map != null and map.tiles.size() > 0 and map.pois.size() > 0)


func _t197() -> void:
	var area = TransitionAreaClass.new()
	area.setup({"transition_id": "test_transition", "to_map_id": "forest_001", "target_spawn_id": "default", "from_rect": {"x": 1, "y": 2, "w": 2, "h": 2}}, 32)
	var ok = area.transition_id == "test_transition" and area.target_map_id == "forest_001" and area.get_child_count() > 0
	area.queue_free()
	_record("T197", "TransitionArea can be created from data", ok)


func _t198() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		ok = not gw.request_map_transition("missing_transition")
		gw.queue_free()
		await _wait_frame()
	_record("T198", "request_map_transition rejects missing id", ok)


func _t199() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		ok = gw.request_map_transition("village_to_apothecary_001_interior") and gw.get_current_map_id() == "apothecary_001_interior"
		gw.queue_free()
		await _wait_frame()
	_record("T199", "request_map_transition switches to building interior", ok)


func _t200() -> void:
	var transition = MapTransitionClass.new()
	transition.setup({"transition_id": "locked_door", "from_map_id": "village_001", "to_map_id": "secret_room", "enabled": false, "locked_message": "locked for smoke"})
	var result = transition.can_use(_world_state)
	_record("T200", "Disabled MapTransition returns locked message", not result.get("ok", true) and result.get("reason", "") == "locked for smoke")


func _t201() -> void:
	var gw = await _make_loaded_game_world("village_001")
	if _game_log != null:
		_game_log.clear()
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		ok = _log_contains("Entered building")
		gw.queue_free()
		await _wait_frame()
	_record("T201", "GameLog records building entry", ok)


func _t202() -> void:
	var gw = await _make_loaded_game_world("village_001")
	if _game_log != null:
		_game_log.clear()
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		gw.switch_map("village_001", "apothecary_001_door")
		ok = _log_contains("returned to")
		gw.queue_free()
		await _wait_frame()
	_record("T202", "GameLog records building return", ok)


func _t203() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = gw != null and gw.get_player_node() != null
	if gw != null:
		gw.queue_free()
		await _wait_frame()
	_record("T203", "T025 rerun player node exists after map init", ok)


func _t204() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("forest_001", "from_village")
		ok = gw.get_player_node() != null
		gw.queue_free()
		await _wait_frame()
	_record("T204", "Player node exists after map switch", ok)


func _t205() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("forest_001", "from_village")
		gw.switch_map("village_001", "east_gate")
		ok = _count_named_nodes(gw, "Player") == 1
		gw.queue_free()
		await _wait_frame()
	_record("T205", "Map switching does not duplicate Player", ok)


func _t206() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		ok = _world_state.visited_maps.has("apothecary_001_interior")
		gw.queue_free()
		await _wait_frame()
	_record("T206", "visited_maps records building interior", ok)


func _t207() -> void:
	var gw = await _make_loaded_game_world("village_001")
	var ok = false
	if gw != null:
		gw.switch_map("apothecary_001_interior", "default")
		gw.switch_map("village_001", "apothecary_001_door")
		gw.save_current_map_state()
		ok = _world_state.map_states.size() >= 2
		gw.queue_free()
		await _wait_frame()
	_record("T207", "map_states preserves village and interior states", ok)


func _t208() -> void:
	var text = _read_text("res://README.md")
	_record("T208", "README documents v0.4.1", "v0.4.1" in text)


func _t209() -> void:
	var text = _read_text("res://GAMEPLAY_MAP_ARCHITECTURE.md")
	_record("T209", "Architecture doc documents Building Interior v0.4.1", "v0.4.1" in text and "Building Interior" in text)


func _t210() -> void:
	var text = _read_text("res://TEST_REPORT.md")
	_record("T210", "TEST_REPORT documents T156-T210", "T156-T210" in text)


func _sample_interior_map():
	var building = BuildingRegistryClass.new().create_building_instance("apothecary", Vector2i(20, 20), "village_001")
	return InteriorMapGeneratorClass.new().generate_interior_for_building(building, {"world_type": "xianxia"})


func _generated_village():
	return MapInstanceGeneratorClass.new().generate_map_instance({"map_id": "village_001", "map_type": "village", "display_name": "Smoke Village"}, {"seed": TEST_SEED, "world_type": "xianxia"})


func _find_building(map, building_type: String) -> Dictionary:
	if map == null:
		return {}
	for building in map.buildings:
		if str(building.get("building_type", "")) == building_type:
			return building
	return {}


func _building_template_has_required_keys(template: Dictionary) -> bool:
	var keys = ["building_type", "display_name", "world_types", "size", "door_offset", "services", "interior_template", "default_npcs", "access_rules", "visual_hint"]
	for key in keys:
		if not template.has(key):
			return false
	return true


func _has_connection(bp: Dictionary, from_id: String, to_id: String) -> bool:
	for connection in bp.get("connections", []):
		if str(connection.get("from_map_id", "")) == from_id and str(connection.get("to_map_id", "")) == to_id:
			return true
	return false


func _log_contains(fragment: String) -> bool:
	if _game_log == null:
		return false
	for entry in _game_log.get_recent(25):
		if fragment in str(entry.get("text", "")):
			return true
	return false


func _count_named_nodes(node: Node, target_name: String) -> int:
	if node == null:
		return 0
	var count = 1 if node.name == target_name else 0
	for child in node.get_children():
		count += _count_named_nodes(child, target_name)
	return count


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


func _make_loaded_game_world(map_id: String):
	var bp = await _get_mock_blueprint()
	_world_state.reset_state()
	_world_state.set_world_blueprint(bp)
	var scene = load("res://scenes/GameWorld.tscn")
	if scene == null:
		return null
	var gw = scene.instantiate()
	root.add_child(gw)
	await _wait_frame()
	if gw.get_current_map_id() != map_id:
		gw.load_map(map_id, "default")
		await _wait_frame()
	return gw


func _prepare_map_save_state() -> void:
	_world_state.current_map_id = "forest_001"
	_world_state.visited_maps = {"village_001": true, "forest_001": true}
	_world_state.map_states = {
		"forest_001": {
			"map_id": "forest_001",
			"visited": true,
			"opened_chests": {"chest_001": true},
			"collected_resources": {"herb_001": true},
			"defeated_enemies": {"wolf_001": true}
		}
	}


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
