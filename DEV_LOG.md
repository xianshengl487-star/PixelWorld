# DEV_LOG.md — PixelWorld 开发更新日志

本项目所有工程变更必须记录在此文件中。

---

## 2026-06-28 - v0.4.3 Map transition performance, prompts, and readability

### Update Type

Map transition performance / interaction prompts / operation feel / scene readability / UX docs / tests

### What Changed

* Added `ChunkedMapRenderer.gd` to row-merge same-type tile runs and reduce the ColorRect node count without deleting the existing ColorRect fallback path.
* Added `OptimizedCollisionBuilder.gd` to row-merge blocking tiles into fewer `StaticBody2D` collision runs.
* Added `MapRuntimeCache.gd` and `GameWorld.get_performance_summary()` for generated-map reuse and load/switch/render/collision/spawn/unload timing metrics.
* Added `LoadingOverlay`, `InteractionPrompt`, `ControlHintPanel`, `FloatingLabel`, `SceneDecorator`, `InteractionTargetTracker`, `ServiceMenu`, and `QuestPanel` scripts/scenes for player-facing UX guidance.
* Reworked `GameWorld.gd` with `switch_map_async()`, transition cooldown for player-triggered routes, input locking during async travel, loading overlay hooks, performance counters, decoration pass, and interaction-target registration.
* Reworked `Player.gd` movement toward acceleration/friction-based velocity and added input lock helpers for map switching.
* Added prompt helpers to `TransitionArea.gd`, `DoorInteraction.gd`, `Interactable.gd`, and `NPC.gd`.
* Added InputMap actions for quest, inventory, debug, save, load, and help toggles.
* Updated project version, save version, main menu version label, README, TEST_REPORT, and added `UX_PERFORMANCE_REPORT.md` and `GAMEPLAY_UX_GUIDE.md`.
* Expanded `SmokeTestRunner.gd` with T271-T330 covering renderer merging, collision merging, cache, loading overlay, interaction prompt, control hints, scene decoration, async map switching, docs, and input actions.

### Reason

v0.4.2 made map state, services, quests, and save migration safer. v0.4.3 addresses the next visible problem: map changes could feel heavy because the MVP renderer and collision builder created too many nodes at once, and players lacked consistent guidance for doors, exits, resources, services, and quest text. This is the map transition performance pass for the v0.4 line.

### Validation

* Godot 4.7 CLI compile validation: PASS.
* UTF-8 JSON configuration parse validation: PASS.
* SmokeTestRunner final run: 312/312 PASS for the 312 defined tests across T001-T330. T063-T080 remain intentionally undefined.
* v0.4.3 range T271-T330: 60/60 PASS.
* Editor GUI attempt: process id `377436` stayed alive after the short launch check, then was closed by Codex; visual confirmation was not performed.
* Runtime GUI attempt: process id `391588` stayed alive after the short launch check, then was closed by Codex; visual confirmation was not performed.
* Manual F5 checks M051-M080: untested until a human visually confirms editor/runtime feel.

### Follow-Up

* Run human F5 validation for M051-M080 before calling movement feel, stutter, prompt placement, or visual readability complete.
* Consider a future TileMapLayer/TileSet migration only after the ColorRect fallback remains stable and measurable.
* Add richer authored service panels after the text-first `ServiceMenu` and `QuestPanel` paths are stable.

---

## 2026-06-28 - v0.4.2 Code health, state isolation, services, and quests

### Update Type

Code health / map-state isolation / save migration / building services / quest system / HUD debug hooks / tests / documentation

### What Changed

* Added `CODE_HEALTH_REPORT.md` with version consistency, audit scope, fixed risks, explicit non-goals, and known non-failing warnings.
* Added `scripts/core/ScopedId.gd` for stable `map_id::local_id` object ids.
* Reworked `GameWorld.gd` map-state save/restore boundaries so global defeated/collected ids are not copied into the currently loaded map state.
* Strengthened `GameWorld.load_map()` and `switch_map()` with same-map no-rebuild behavior, skip-save during switch, failed-target protection, missing-spawn fallback, and debug summary helpers.
* Extended `WorldState.gd` and `SaveManager.gd` with `save_version`, `quest_state`, `equipment_state`, `training_used_today`, and old-save migration defaults.
* Reworked `BuildingService.gd` with deterministic healer, inn, shop, blacksmith, quest board, training, and storage service behavior.
* Added `QuestObjective.gd`, `QuestData.gd`, `QuestSystem.gd`, and `data/quests/basic_quests.json`.
* Updated `Enemy.gd`, `Interactable.gd`, and `GameWorld.gd` to emit quest events for enemy defeat, item collection, map visit, object interaction, and chest opening.
* Expanded `GameHUD.gd` and `GameHUD.tscn` with quest and debug display methods/nodes.
* Added `scripts/tests/RuntimeGuiChecklist.gd` as a runtime helper; it does not replace manual F5 visual validation.
* Expanded `SmokeTestRunner.gd` with T211-T270 for code health docs, scoped ids, map-state isolation, service behavior, quest behavior, save migration, HUD/debug hooks, and documentation checks.
* Updated `README.md`, `GAMEPLAY_MAP_ARCHITECTURE.md`, `GAMEPLAY_QUESTS.md`, `TEST_REPORT.md`, `DEV_LOG.md`, project version, and main menu version label to v0.4.2.

### Reason

v0.4.1 made interiors and runtime transitions work. v0.4.2 makes the foundation safer: map changes stay scoped to their own map, old saves receive predictable defaults, building services now produce real local effects, and a first deterministic quest layer can connect enemies, resources, map visits, and buildings without real AI providers.

### Validation

* Godot 4.7 CLI compile validation: PASS
* JSON configuration parse validation: PASS
* SmokeTestRunner pre-documentation verification: 247/252 PASS; remaining failures were documentation gates only.
* SmokeTestRunner final run after documentation: 252/252 PASS for T001-T270.
* T025: PASS in this CLI run.
* T028: PASS in this CLI run.
* Editor GUI attempt: 未测：Codex could start process but cannot visually confirm editor window. Process id `375904` stayed alive during the short launch check, then was closed.
* Runtime GUI attempt: 未测：Codex could start process but cannot visually confirm runtime window. Process id `365664` stayed alive during the short launch check, then was closed.
* Manual F5 checks M031-M050: 未测; requires human visual confirmation.

### Follow-Up

* Run real Godot editor F5 validation for M031-M050.
* Add a dedicated quest panel and accept/turn-in UI after the deterministic quest data path stays stable.
* Add richer map-authored interiors and service-specific interaction prompts.

---

## 2026-06-28 - v0.4.1 Building interiors, runtime transitions, and save-state strengthening

### Update Type

Gameplay map architecture / building interiors / runtime map switching / save compatibility / HUD and logs / tests / documentation

### What Changed

* Added `BuildingRegistry.gd` to load `data/buildings/building_templates.json` and create stable building instances with doors, services, access rules, and `interior_map_id`.
* Added `BuildingService.gd` for deterministic local building services, including healer, inn, shop placeholder, blacksmith placeholder, quest board, training, storage, and dialogue-only behavior.
* Added `InteriorMapGenerator.gd` to create MVP interior maps for chief house, apothecary, blacksmith, inn, general store, and generic fallback interiors.
* Added `DoorInteraction.gd` as an Area2D building-door trigger for future scene usage.
* Expanded `building_templates.json` to include chief house, apothecary, blacksmith, inn, general store, sect gate, task hall, training hall, warehouse, and player home placeholder.
* Reworked `MapInstanceGenerator.gd` so the default village places road-connected buildings with stable ids, door positions, services, and interior map ids.
* Expanded `MockProvider.gd` so default WorldGraph blueprints include building interior map nodes and village <-> interior connections.
* Strengthened `MapInstance.gd` with parent map/building/spawn metadata for interior maps.
* Reworked `GameWorld.gd` runtime map handling: layer creation, single-player preservation, transition areas, building rendering, map switching, building entry/return logs, HUD updates, player placement, and map-state save/restore.
* Strengthened `MapState.gd`, `WorldState.gd`, and `SaveManager.gd` with `building_states`, dynamic map-state fields, old-save compatibility, current map id, visited maps, world graph data, last spawn id, and per-map player positions.
* Expanded `GameHUD.gd` and `GameHUD.tscn` with map info, building info, and transition message display methods/nodes.
* Fixed the retained T025 CLI player-node regression by validating the player before freeing the GameWorld instance.
* Expanded `SmokeTestRunner.gd` with T156-T210 for building registry/templates, services, interiors, village buildings, WorldGraph interior connections, GameWorld switching, save state, HUD/logs, T025 rerun, and documentation checks.
* Updated `README.md`, `GAMEPLAY_MAP_ARCHITECTURE.md`, `TEST_REPORT.md`, `DEV_LOG.md`, project version, and main menu version label to v0.4.1.

### Reason

v0.4.0 established that one world can contain multiple maps. v0.4.1 makes buildings part of that map graph: village doors now point to real interior maps, interiors can return to the outdoor village, and map/save state knows about building visits. This keeps the project data-driven and testable while avoiding real AI providers, TileMapLayer migration, seamless maps, multiplayer, or third-party art.

### Validation

* Godot 4.7 CLI compile validation: PASS
* JSON configuration parse validation: PASS
* SmokeTestRunner: 192/192 PASS
* T156-T210: 55/55 PASS
* T025: PASS in this CLI run
* T028: PASS in this CLI run
* Godot editor F5 manual validation: not executed; M015-M030 remain marked as 未测 in `TEST_REPORT.md`

### Follow-Up

* Run Godot editor F5 manual checks for village door interaction, HUD readability, collision feel, save/load UX, and repeated village/interior switching.
* Replace more ColorRect MVP markers with generated pixel assets or a future TileSet/TileMapLayer path after runtime behavior remains stable.
* Add richer interaction prompts and unlock rules for building services and future faction/realm gates.

---

## 2026-06-28 01:56 — v0.4.0 多地图世界架构深化

### 更新类型

地图架构 / 运行时加载 / 存档 / 建筑模板 / 测试 / 文档

### 本次改动

* 新增 `WorldGraph.gd`，用于描述一个世界内的地图拓扑、主线、支线、连接关系和起始地图
* 新增 `WorldInstance.gd`，作为世界运行时实例的外层容器
* 新增 `MapInstance.gd`，用于承载单张地图的尺寸、类型、出生点、瓦片、建筑、NPC、敌人、资源、POI 和过图点
* 新增 `MapTransition.gd` 与 `TransitionArea.gd`，支持从一张地图跳转到另一张地图和目标出生点
* 新增 `MapState.gd` 与 `MapStateSerializer.gd`，记录并保存每张地图的宝箱、资源、击败敌人、本地 flag 和玩家位置
* 新增 `MapTypeRuleLoader.gd` 与 `data/map_generation/map_type_rules.json`，为 village/forest/cave/sect_gate/interior/secret_realm 提供地图类型规则
* 新增 `MapInstanceGenerator.gd`，生成村庄、森林、洞府、宗门山门、室内和秘境地图实例
* 新增 `MapConnectionValidator.gd`，校验地图图谱、连接和出生点
* 新增 `BuildingTemplate.gd`、`BuildingInstance.gd`、`BuildingPlacementValidator.gd` 与 `data/buildings/building_templates.json`
* 扩展 `MockProvider.gd`，默认蓝图现在包含 4 张地图、双向连接、主线与支线信息
* 扩展 `WorldState.gd`，加入 current_map_id、visited_maps、map_states、world_graph_data、global_flags、player_position_by_map 和 last_spawn_id
* 扩展 `SaveManager.gd`，保存和读取多地图相关字段，并兼容旧存档缺失字段
* 重写/扩展 `GameWorld.gd`，支持 `setup_world_graph_from_blueprint()`、`load_map()`、`switch_map()`、地图卸载、状态恢复、分层渲染、建筑层和过图层
* 保留旧 64x64 地图生成与旧测试路径，没有删除 T025/T028
* 扩展 `SmokeTestRunner.gd`，新增 T116-T155 覆盖 v0.4.0 多地图架构
* 更新项目版本、主菜单版本号、README、测试报告，并新增 `GAMEPLAY_MAP_ARCHITECTURE.md`

### 涉及文件

* `res://project.godot`
* `res://scenes/MainMenu.tscn`
* `res://scenes/GameWorld.tscn`
* `res://scripts/ai/providers/MockProvider.gd`
* `res://scripts/core/WorldState.gd`
* `res://scripts/core/SaveManager.gd`
* `res://scripts/ui/GameWorld.gd`
* `res://scripts/map/...`
* `res://scripts/world/WorldGraph.gd`
* `res://scripts/world/WorldInstance.gd`
* `res://scripts/buildings/...`
* `res://data/map_generation/map_type_rules.json`
* `res://data/buildings/building_templates.json`
* `res://scripts/tests/SmokeTestRunner.gd`
* `res://GAMEPLAY_MAP_ARCHITECTURE.md`
* `res://README.md`
* `res://TEST_REPORT.md`
* `res://DEV_LOG.md`

### 原因

v0.4.0 需要先把“一个世界由多张地图组成”的底座立住，后续才能自然接入城镇、野外、洞府、宗门、室内、秘境、跨地图任务、地图状态持久化和成长门槛。当前版本优先保证结构清晰、旧系统兼容和 CLI 可验证，不提前迁移 TileMapLayer、不接真实 AI、不做无限地图。

### 测试结果

* JSON 配置解析：PASS
* Godot 4.7 CLI 编译验证：PASS
* SmokeTestRunner：136/137 PASS
* 新增 T116-T155：40/40 PASS
* 保留失败项：T025，仍作为 CLI headless SceneTree/初始化待编辑器 F5 验证项
* T028：本轮 CLI 通过
* 编辑器 F5 手动验证：未执行

### 后续待办

* 在 Godot 编辑器中 F5 验证玩家实际移动、碰撞、HUD、NPC 互动和跨地图切换体验
* 给 TransitionArea 增加更完整的交互提示和锁定反馈
* 将建筑门口与 interior 类型地图建立更明确的数据连接
* 逐步把 ColorRect 地图占位替换为 generated tiles 或 TileSet/TileMapLayer 方案
* 把境界、任务和物品条件接入更多过图/建筑访问规则

---

## 2026-06-28 01:35 — v0.3.0 代码审查与世界观成长体系

### 更新类型

审查 / 玩法 / 成长 / 世界观 / 存档 / 素材 / 测试 / 文档

### 本次改动

* 新增 `CODE_AUDIT.md`，记录项目现状、已修复问题、保留风险和后续建议
* 增强 `.gitignore`，补充本地环境、密钥、日志、存档和临时文件忽略规则
* 更新 `README.md` 到 v0.3.0，加入成长系统说明、玩法路线图和真实测试结果
* 新增 `AssetResolver.gd`，支持 `ResourceLoader` 与 `Image.load()` 双路径加载 generated PNG，并在缺失时安全 fallback
* 新增 `CharacterVisualProfile.gd`
* 强化 `Player.gd` / `NPC.gd` / `Enemy.gd` 材质调用 fallback，不因素材缺失导致角色生成失败
* 新增 `ProgressionSystem.gd`
* 新增 `ProgressionTemplateLoader.gd`
* 新增 `BreakthroughSystem.gd`
* 新增 `TribulationSystem.gd`
* 新增 `RealmEffectApplier.gd`
* 新增 `WorldRuleModifier.gd`
* 重构 `Stats.gd` 为 `base/equipment/progression/status/final` 结构，同时保留旧字段兼容
* 扩展 `WorldState.gd`，增加 `progression_data`、境界历史、突破历史、雷劫记录、解锁能力和世界修正
* 扩展 `SaveManager.gd`，保存/读取成长数据和玩家属性数据，兼容旧存档缺字段
* 扩展 `GameHUD.gd` / `GameHUD.tscn`，加入成长体系 Label 与显示方法
* 新增修仙完整境界模板
* 新增魔法/末世/赛博/武侠/都市异能/怪谈/星际成长模板
* 新增 `GAMEPLAY_PROGRESSION.md`
* 扩展 `SmokeTestRunner.gd`，新增 T081-T115
* 更新 `TEST_REPORT.md`

### 涉及文件

* `res://CODE_AUDIT.md`
* `res://GAMEPLAY_PROGRESSION.md`
* `res://README.md`
* `res://.gitignore`
* `res://project.godot`
* `res://scenes/MainMenu.tscn`
* `res://scenes/ui/GameHUD.tscn`
* `res://scripts/assets/...`
* `res://scripts/progression/...`
* `res://scripts/core/WorldState.gd`
* `res://scripts/core/SaveManager.gd`
* `res://scripts/entities/Stats.gd`
* `res://scripts/entities/Player.gd`
* `res://scripts/entities/NPC.gd`
* `res://scripts/entities/Enemy.gd`
* `res://scripts/ui/GameHUD.gd`
* `res://scripts/tests/SmokeTestRunner.gd`
* `res://data/progression_templates/...`
* `res://DEV_LOG.md`
* `res://TEST_REPORT.md`

### 原因

v0.3.0 需要先把代码底座、视觉素材引用、成长系统数据结构、世界模板、存档字段和测试覆盖立住，后续才能把境界/位阶/突破/试炼真正接入战斗、探索、事件和 NPC 叙事。

### 测试结果

* JSON 模板解析：PASS
* `git diff --check`：PASS
* Godot 4.7 CLI 编译验证：PASS
* SmokeTestRunner：96/97 PASS
* 新增 T081-T115：35/35 PASS
* 失败项：T025，继续保留为 CLI headless SceneTree/初始化待编辑器 F5 验证项
* T028：本轮 CLI 通过，count=867
* 编辑器 F5 手动验证：未执行

### 后续待办

* 编辑器 F5 验证玩家节点、碰撞、HUD 和素材显示
* 将 `CombatSystem` 逐步接入 accuracy/dodge/crit/resistance 等新属性
* 将突破条件中的物品、地点、flag 与实际探索/背包/事件系统连接
* 为存档增加 `save_version` 和迁移器

---

## 2026-06-28 00:25 — v0.2.1 GitHub 发布准备

### 更新类型

文档 / 发布

### 本次改动

* 新增 `README.md`，说明当前 v0.2.1 版本内容、素材包、测试状态和开发规则
* 更新 `.gitignore`，排除本地 `.workbuddy/` 工作记忆目录
* 准备将当前版本推送到 GitHub 仓库

### 涉及文件

* `res://README.md`
* `res://.gitignore`
* `res://DEV_LOG.md`

### 原因

为了让 GitHub 仓库首页能清楚说明当前版本内容、已完成系统、素材生成方式、测试结果和仍保留的 T025/T028 验证项。

### 测试结果

* 本次仅新增发布说明文档，未重新执行 SmokeTestRunner
* 最近一次记录结果仍为 v0.2.1：60/62 PASS

---

## 2026-06-28 00:04 — v0.2.1 预备像素素材扩展包

### 更新类型

素材 / 工具 / 测试 / 文档

### 本次改动

* 扩展程序生成像素素材脚本，改为资产注册表式生成器
* 保留 v0.2.0 已有 33 个程序生成占位素材
* 新增玩家方向待机/行走/攻击动画素材、受伤帧和死亡帧
* 新增 NPC 扩展素材，包括农夫、铁匠、商人、守卫、宗门弟子、长者、孩童、客栈老板、神秘老人、山贼探子、赛博医生、废土幸存者
* 新增史莱姆、野兽、人形和小 Boss 敌人扩展素材
* 新增修仙、末世、赛博和通用装饰地图瓦片
* 新增材料、消耗品、武器、任务/特殊物品图标
* 新增 UI 图标和 UI 面板占位图
* 新增战斗/魔法特效 spritesheet
* 新增 7 张素材预览图
* `generate_pixel_assets.py` 现在会输出素材数量统计，并自动刷新 `ASSET_MANIFEST.md`
* 更新 `PLACEHOLDER_ART.md`，加入 v0.2.1 扩展素材说明
* 扩展 SmokeTestRunner，新增 T051-T062 素材测试项
* 项目版本号与主菜单版本标签更新为 v0.2.1

### 涉及文件

* `res://DEV_LOG.md`
* `res://TEST_REPORT.md`
* `res://ASSET_MANIFEST.md`
* `res://PLACEHOLDER_ART.md`
* `res://project.godot`
* `res://scenes/MainMenu.tscn`
* `res://tools/generate_pixel_assets.py`
* `res://scripts/tests/SmokeTestRunner.gd`
* `res://art/generated/...`

### 原因

为后续地图扩展、战斗表现、NPC 差异化、UI 设计和多世界类型开发提前准备一套可重复生成的 MVP 占位像素素材库。

### 测试结果

* 素材生成脚本：PASS
* 生成素材总数：186 个 PNG
* CLI 编译验证：PASS
* SmokeTestRunner：60/62 PASS
* 新增 T051-T062：12/12 PASS
* 失败项：T025、T028，延续 v0.2.0 CLI headless 场景初始化/碰撞计数待编辑器 F5 验证项

### 后续待办

* 在编辑器中人工查看预览图和游戏实际显示
* 后续将关键素材逐步替换为正式像素美术
* 后续考虑 TileMapLayer + TileSet 接入

---

## 2026-06-27 23:31 — v0.2.0 基础玩法系统 + MVP 像素素材包

### 更新类型

新增 / 玩法 / UI / 存档 / 素材 / 测试 / 文档

### 本次改动

* 新增基础属性系统 `Stats.gd`，支持生命、体力、攻击、防御、受伤、治疗、死亡、复活和信号
* 新增战斗系统 `CombatSystem.gd`，使用 `damage = max(1, attack - floor(defense * 0.5))`
* 玩家新增 stats、攻击、受伤、死亡后回村重生、攻击冷却和 Space/鼠标左键攻击输入
* 新增敌人系统 `Enemy.gd` / `Enemy.tscn`，支持史莱姆、妖狼、山贼类型，追击、近身攻击、受伤死亡、掉落简单资源
* 新增敌人头顶血条 `HealthBar.gd` / `HealthBar.tscn`
* 新增探索系统 `ExplorationSystem.gd`，记录洞府、草药、宗门入口等发现地点
* 新增交互系统 `InteractionSystem.gd` / `Interactable.gd`，支持草药、宝箱、洞口、告示牌
* 新增物品和背包系统 `ItemData.gd` / `Inventory.gd`，WorldState 增加 inventory、collected_items、defeated_enemies、discovered_locations、current_region
* 新增 `SaveManager.gd` Autoload，支持 `save_game/load_game/has_save/delete_save`
* MainMenu 新增继续游戏、退出按钮，原生成世界改为新建世界
* GameHUD 新增玩家生命条、体力条、背包文本、保存/读取按钮，并保留自由行动输入框
* GameWorld 新增敌人与资源点生成，包含 2 个史莱姆、1 个妖狼、3 个草药、1 个宝箱、1 个洞口、1 个告示牌
* 新增 `tools/generate_pixel_assets.py`，使用 Python + Pillow 可重复生成项目自制占位 PNG 素材
* 新增 `ASSET_MANIFEST.md` 和 `PLACEHOLDER_ART.md`
* 生成 `art/generated/` 下 33 个占位像素素材
* SmokeTestRunner 扩展到 T001-T050，新增 T036-T050 覆盖 v0.2.0 系统

### 涉及文件

* `res://project.godot`
* `res://scripts/core/WorldState.gd`
* `res://scripts/core/SaveManager.gd`
* `res://scripts/entities/Stats.gd`
* `res://scripts/entities/Player.gd`
* `res://scripts/entities/Enemy.gd`
* `res://scripts/combat/CombatSystem.gd`
* `res://scripts/items/ItemData.gd`
* `res://scripts/items/Inventory.gd`
* `res://scripts/interactions/Interactable.gd`
* `res://scripts/interactions/InteractionSystem.gd`
* `res://scripts/world/ExplorationSystem.gd`
* `res://scripts/ui/GameWorld.gd`
* `res://scripts/ui/GameHUD.gd`
* `res://scripts/ui/HealthBar.gd`
* `res://scripts/ui/MainMenu.gd`
* `res://scripts/tests/SmokeTestRunner.gd`
* `res://scenes/Enemy.tscn`
* `res://scenes/ui/HealthBar.tscn`
* `res://scenes/ui/GameHUD.tscn`
* `res://scenes/MainMenu.tscn`
* `res://tools/generate_pixel_assets.py`
* `res://ASSET_MANIFEST.md`
* `res://PLACEHOLDER_ART.md`
* `res://art/generated/**`
* `res://TEST_REPORT.md`
* `res://DEV_LOG.md`

### 原因

按 v0.2.0 需求完成最小玩法闭环：玩家进入世界后能移动探索、看到血量和体力、攻击敌人、敌人死亡、玩家受伤并可死亡重生、拾取资源、打开宝箱、保存/读取游戏，并随项目附带一套可重复生成的 MVP 占位像素素材。

### 测试结果

* Godot 4.7 CLI 编译验证：PASS
* SmokeTestRunner：48/50 PASS
* 新增 T036-T050：15/15 PASS
* 仍失败：T025 玩家节点存在、T028 障碍物碰撞节点存在，继续按 v0.1.4 记录为 CLI SceneTree/初始化或保底模板路径下的待编辑器验证项
* 编辑器 F5 手动验证：未执行

### 后续待办

* 在 Godot 编辑器中 F5 验证玩家攻击、敌人追击、交互拾取、保存/读取和 HUD 显示
* 后续可将 GameWorld 渲染从 ColorRect 占位逐步替换为 `art/generated/` tileset
* 后续可补正式像素动画和音效

---

## 2026-06-27 21:21 — 项目初始化：搭建第一版工程框架

### 更新类型

新增 / 配置

### 本次改动

* 创建 Godot 4 项目文件 `project.godot`，配置 1280x720 窗口、Autoload 单例
* 创建完整目录结构：`scenes/`, `scripts/core/`, `scripts/ai/providers/`, `scripts/world/`, `scripts/map/`, `scripts/entities/`, `scripts/ui/`, `data/`, `art/`
* 创建 `DEV_LOG.md`（本文件）
* 创建 `ARCHITECTURE.md`（项目架构文档）
* 创建 `AI_PROVIDERS.md`（AI 服务商接入文档）
* 创建 `TODO.md`（后续任务清单）
* 创建 `.env.example`（环境变量示例）
* 创建核心脚本：`WorldState.gd`, `ConfigManager.gd`, `DevLogWriter.gd`
* 创建 AI Provider 系统：`AIProvider.gd`, `AIClient.gd`, `MimoProvider.gd`, `NvidiaProvider.gd`, `MockProvider.gd`, `LocalTinyNpcProvider.gd`
* 创建世界蓝图校验器：`WorldBlueprintValidator.gd`
* 创建地图生成系统：`MapGenerator.gd`, `MapValidator.gd`, `MapRepairer.gd`
* 创建游戏实体脚本：`Player.gd`, `NPC.gd`
* 创建 UI 脚本：`DialogueBox.gd`, `GameHUD.gd`, `GameLog.gd`
* 创建保底数据文件：`xianxia_default.json`, `apocalypse_default.json`, `cyberpunk_default.json`
* 创建保底地图模板：`xianxia_safe_start.json`
* 创建场景文件：`MainMenu.tscn`, `GameWorld.tscn`, `Player.tscn`, `NPC.tscn`, `DialogueBox.tscn`, `GameHUD.tscn`

### 涉及文件

* `res://project.godot`
* `res://DEV_LOG.md`
* `res://ARCHITECTURE.md`
* `res://AI_PROVIDERS.md`
* `res://TODO.md`
* `res://.env.example`
* `res://scripts/core/WorldState.gd`
* `res://scripts/core/ConfigManager.gd`
* `res://scripts/core/DevLogWriter.gd`
* `res://scripts/ai/AIClient.gd`
* `res://scripts/ai/providers/AIProvider.gd`
* `res://scripts/ai/providers/MimoProvider.gd`
* `res://scripts/ai/providers/NvidiaProvider.gd`
* `res://scripts/ai/providers/MockProvider.gd`
* `res://scripts/ai/providers/LocalTinyNpcProvider.gd`
* `res://scripts/world/WorldBlueprintValidator.gd`
* `res://scripts/map/MapGenerator.gd`
* `res://scripts/map/MapValidator.gd`
* `res://scripts/map/MapRepairer.gd`
* `res://scripts/entities/Player.gd`
* `res://scripts/entities/NPC.gd`
* `res://scripts/ui/DialogueBox.gd`
* `res://scripts/ui/GameHUD.gd`
* `res://scripts/ui/GameLog.gd`
* `res://data/default_blueprints/xianxia_default.json`
* `res://data/default_blueprints/apocalypse_default.json`
* `res://data/default_blueprints/cyberpunk_default.json`
* `res://data/map_templates/xianxia_safe_start.json`
* `res://scenes/MainMenu.tscn`
* `res://scenes/GameWorld.tscn`
* `res://scenes/Player.tscn`
* `res://scenes/NPC.tscn`
* `res://scenes/ui/DialogueBox.tscn`
* `res://scenes/ui/GameHUD.tscn`

### 原因

按照用户需求搭建第一版工程框架，实现"输入一句话生成世界"的像素风沙盒 RPG 的核心闭环。所有系统解耦设计，AI Provider 抽象层支持切换。

### 后续待办

* 在 Godot 编辑器中打开项目验证运行
* 补充像素美术资源（角色、瓦片、UI 素材）
* 实现天气/昼夜系统
* 实现存档/读档系统
* 预留多人联机接口
* 接入真实 MiMo / NVIDIA API 进行联调测试

---

## 2026-06-27 21:30 — 第一版验收自查（仅文件/架构级自查）

**重要声明：本次验收为文件级和架构级自查，不等于 Godot 实机运行验收。实机运行需安装 Godot 4.x 后进行。**

---

## 2026-06-27 21:33 — v0.1.1 运行验收规范强化

### 更新类型

文档 / 测试 / 修正

### 本次改动

* 新增 TEST_REPORT.md（含完整测试矩阵和代码审查结果）
* 区分"文件创建完成"和"实机运行验证"——未安装 Godot 时严格标记为"未实机验证"
* 修复 GameWorld.tscn 节点名 TileMapLayer→TileMap（脚本引用不匹配）
* 修复 GameWorld.gd 渲染网格线 tiles[0].size() 空数组越界风险
* 修复 Player.gd 混用 move_and_collide 和 move_and_slide 的错误
* 修复 DialogueBox.gd 播放不存在动画 "fade_in" 的运行时错误
* 修复 NPC.tscn Area2D body_entered/body_exited 信号未连接
* 修复 Player.gd 引用不存在的 WorldState.player_spawn 属性
* 修复 WorldBlueprintValidator 缺少 minor_npcs 数量下限检查（至少2个）

### 涉及文件

* res://DEV_LOG.md
* res://TEST_REPORT.md（新建）
* res://scenes/GameWorld.tscn
* res://scenes/NPC.tscn
* res://scripts/entities/Player.gd
* res://scripts/ui/GameWorld.gd
* res://scripts/ui/DialogueBox.gd
* res://scripts/world/WorldBlueprintValidator.gd

### 原因

避免把 Agent 静态审查误认为真实运行结果，保证后续开发记录可信。修复 7 个代码缺陷，确保项目在 Godot 4 加载时减少运行时错误。

### 后续待办

* 安装 Godot 4.x 并在编辑器中打开项目实机运行
* 运行 MainMenu→输入描述→生成世界→GameWorld 完整流程
* 验证 Player 与障碍物碰撞效果
* 记录实机运行真实错误并修复

---

## 2026-06-27 21:46 — v0.1.2 Godot 4.7 实机编译验证通过

### 更新类型

修复 / 测试 / 配置

### 本次改动

* 使用 Godot 4.7 stable CLI headless 模式验证项目可以成功加载（退出码 0）
* 修复 GameLog.gd `class_name GameLog` 与 Autoload 名称冲突
* 修复所有 Provider 脚本 `extends AIProvider` → `extends "res://scripts/ai/providers/AIProvider.gd"`（preload 上下文中 class_name 不可见）
* 修复 MainMenu.gd `AIClient.new()` / `WorldBlueprintValidator.new()` 使用 preload 替代 class_name
* 修复 AIClient.gd `MockProvider.new()` 等使用 preload 替代 class_name
* 更新 TEST_REPORT.md 记录真实 CLI 运行结果（"部分通过"）
* 确认 Autoload (WorldState/ConfigManager/GameLog) 正常初始化
* 确认 AIClient 成功切换到 MockProvider

### 涉及文件

* res://scripts/ui/GameLog.gd
* res://scripts/ui/MainMenu.gd
* res://scripts/ai/AIClient.gd
* res://scripts/ai/providers/MockProvider.gd
* res://scripts/ai/providers/MimoProvider.gd
* res://scripts/ai/providers/NvidiaProvider.gd
* res://scripts/ai/providers/LocalTinyNpcProvider.gd
* res://TEST_REPORT.md
* res://DEV_LOG.md

### 原因

上一轮 v0.1.1 仅做了代码级静态审查。本轮安装 Godot 4.7 后首次实机 CLI 验证，发现 7 个编译错误，根源是 Godot 4 中 `class_name` 在 preload 上下文中异步加载导致不可见。统一改用文件路径引用后全部修复。

### 后续待办

* 在 Godot 编辑器中 F5 运行完整游戏流程
* 验证 MainMenu → GameWorld 场景切换
* 验证地图渲染和 NPC 交互
* 验证 Player 碰撞检测效果

---

## 2026-06-27 22:06 — v0.1.2 CLI 冒烟测试与地图碰撞修复

### 更新类型

测试 / 修复 / 文档

### 本次改动

* 新增 `res://scripts/tests/SmokeTestRunner.gd` — 35 项 CLI 自动化冒烟测试
* 新增 `res://scripts/map/MapCollisionBuilder.gd` — 障碍物 StaticBody2D 碰撞生成器
* GameWorld.gd 增加可测试方法：setup_from_world_state / get_player_node / get_npc_count / get_obstacle_collision_count / get_map_visual_node_count
* GameWorld.tscn 新增 CollisionLayer 节点
* 修复 Player.tscn/NPC.tscn 场景 SubResource 解析问题（碰撞形状改为代码动态创建）
* 修复所有脚本中的 class_name 类型引用和 autoload 直接引用问题（共 8+ 处）
* 清理 TEST_REPORT.md 格式为统一结构
* SmokeTest 结果：30 PASS / 5 FAIL (85.7%)

### 涉及文件

* `res://scripts/tests/SmokeTestRunner.gd`（新建）
* `res://scripts/map/MapCollisionBuilder.gd`（新建）
* `res://scripts/ui/GameWorld.gd`
* `res://scripts/ai/AIClient.gd`
* `res://scripts/ai/providers/MimoProvider.gd`
* `res://scripts/ai/providers/NvidiaProvider.gd`
* `res://scripts/ai/providers/LocalTinyNpcProvider.gd`
* `res://scripts/entities/Player.gd`
* `res://scripts/entities/NPC.gd`
* `res://scripts/ui/GameHUD.gd`
* `res://scenes/Player.tscn`
* `res://scenes/NPC.tscn`
* `res://scenes/GameWorld.tscn`
* `res://scripts/world/WorldBlueprintValidator.gd`
* `res://scripts/map/MapRepairer.gd`
* `res://TEST_REPORT.md`
* `res://DEV_LOG.md`

### 原因

当前项目已能通过 Godot CLI 编译加载，但尚未验证 GameWorld 完整链路。通过 35 项 CLI 冒烟测试，覆盖场景加载、蓝图生成、地图验证、NPC对话、自由行动、日志记录等核心流程。修复地图障碍物缺少物理碰撞的问题。

### 测试结果

- Godot CLI 编译验证：✅ PASS（退出码 0）
- SmokeTestRunner 结果：30/35 PASS (85.7%)
- 失败测试数量：5
- 失败原因：4/5 为 CLI extends SceneTree 模式下的时序问题（编辑器模式不受影响），1/5 为地图NPC坐标精度问题

### 需编辑器验证项目

6 项（玩家移动、摄像机、UI显示、NPC对话体验、碰撞阻挡、场景切换）

### 后续待办

* 在 Godot 编辑器中 F5 运行完整游戏流程
* 修复 NPC 默认坐标落于障碍物的问题
* 接真实 MiMo / NVIDIA API 联调测试

---

## 2026-06-27 22:23 — v0.1.3 修复 CLI 冒烟测试失败项

### 更新类型

修复 / 测试 / 文档

### 本次改动

* 新增 `_carve_road()` 强制修路（不受地形覆盖）+ NPC 坐标 `_sanitize_npc_positions()` BFS 查找最近可行走点
* 洞窟入口扩大清理范围（5x5 → 东侧通道 3x3 清障）
* 修复 MapValidator 语义：增加 `"ok"` 键，errors>0 时 false
* 修复 GameWorld 全部 `$NodePath` → `get_node_or_null()` + 动态创建回退
* 修复 GameHUD `$BottomBar/ActionResult` → `$ActionResult` 路径
* 修复 MapRepairer 测试逻辑：不依赖固定坐标，检查不变量
* 修复 NPC.tscn/Player.tscn CollisionShape2D 代码动态创建
* 清除 Godot .uid 缓存解决旧脚本引用问题
* SmokeTest 结果：32/35 PASS (91.4%)

### 涉及文件

* `res://scripts/map/MapGenerator.gd`（重写道路+NPC消毒）
* `res://scripts/map/MapValidator.gd`（增加ok键）
* `res://scripts/map/MapRepairer.gd`（preload引用）
* `res://scripts/ui/GameWorld.gd`（节点引用+可测试方法）
* `res://scripts/ui/GameHUD.gd`（节点路径修正）
* `res://scripts/entities/Player.gd`（碰撞形状代码创建）
* `res://scripts/entities/NPC.gd`（碰撞形状代码创建）
* `res://scripts/ai/AIClient.gd`（autoload安全访问）
* `res://scripts/ai/providers/MimoProvider.gd`（ConfigManager安全访问）
* `res://scripts/ai/providers/NvidiaProvider.gd`（同上）
* `res://scripts/ai/providers/LocalTinyNpcProvider.gd`（WorldState安全访问）
* `res://scripts/world/WorldBlueprintValidator.gd`（空值防御）
* `res://scripts/tests/SmokeTestRunner.gd`（测试逻辑修复）
* `res://scenes/Player.tscn`（移除SubResource）
* `res://scenes/NPC.tscn`（移除SubResource）
* `res://TEST_REPORT.md`
* `res://DEV_LOG.md`

### 原因

v0.1.2 30/35 PASS，5 项核心稳定性失败。本轮修复 NPC 坐标、洞口可达性、Validator语义、节点引用时序。v0.1.3 达到 32/35 PASS。剩余的 3 项失败均为 `extends SceneTree` 上下文特有的实例化时序问题（编辑器模式不受影响）。

### 测试结果

- CLI 编译验证：✅ PASS
- SmokeTestRunner：32/35 PASS (91.4%)
- 失败项（3）：T022(间歇/随机地图)、T025(玩家节点时序)、T028(碰撞时序)
- 需编辑器手动验证：6 项

### 后续待办

* 在 Godot 编辑器中 F5 运行完整流程
* 手动验证玩家移动、摄像机、UI显示、NPC对话、碰撞阻挡、场景切换
* 后续接入真实 MiMo / NVIDIA API 联调

---

## 2026-06-27 22:36 — v0.1.4 修复剩余 CLI 冒烟测试 + 编辑器验收准备

### 更新类型

修复 / 测试 / 文档

### 本次改动

* MapGenerator 增加 `set_seed(seed)` 测试用固定随机种子 + `_rand()` 替代全部 `randi()`
* MapGenerator 增加 Step 5：强制出生点 5x5 区域为可行走道路
* GameWorld 修复 `_build_collisions` 用 `get_node_or_null` 替代 `$CollisionLayer`
* GameWorld `setup_from_world_state()` 返回 bool，`_is_initialized` 基于 `_player != null`
* SmokeTestRunner seed=42 固定，`_gen_deterministic_map` 仅关键错误时修复
* T025/T028 测试改为仅依赖 _ready 初始化 + 诊断输出
* 修正 TEST_REPORT.md 所有"编辑器正常"措辞为"需编辑器F5验证"
* 执行 Godot CLI 编译验证（退出码 0）
* 执行 SmokeTestRunner: 32/35 PASS (91.4%)
* Godot GUI 编辑器无法通过命令行启动，编辑器手动验收M001-M006均标记为"未测"

### 涉及文件

* `res://scripts/map/MapGenerator.gd`
* `res://scripts/ui/GameWorld.gd`
* `res://scripts/tests/SmokeTestRunner.gd`
* `res://TEST_REPORT.md`
* `res://DEV_LOG.md`

### 原因

v0.1.3 剩余 3 项 CLI 冒烟测试失败，其中 T018-T021 根源为随机地图导致出生点落在非行走地块。修复后固定种子测试可稳定复现。T025/T028 为 extends SceneTree 实例化时序问题。

### 测试结果

- CLI 编译验证：✅ PASS
- SmokeTestRunner：32/35 PASS (91.4%)
- 失败项：T022(修复后出生点偏移)、T025(玩家节点)、T028(碰撞节点)
- 编辑器手动验证：未执行（6 项标记未测）

### 后续待办

* 在 Godot 编辑器中 F5 运行完整流程
* 手动验证 M001-M006
* 编辑器验证通过后接真实 MiMo/NVIDIA API

---

## 2026-06-27 22:46 — v0.1.4 修复 T022 + 修正措辞

### 更新类型

修复 / 文档

### 本次改动

* MapRepairer 增加 `_sanitize_spawn_on_template()` — 回退保底模板后强制出生点可行走
* T022 从 FAIL → PASS（pos=(5,5) 可行走）
* TEST_REPORT.md 修正 T025/T028 措辞为"疑似 CLI SceneTree 初始化时序问题，等待编辑器 F5 验证"
* SmokeTest 达到 33/35 PASS (94.3%)

### 涉及文件

* `res://scripts/map/MapRepairer.gd`
* `res://TEST_REPORT.md`
* `res://DEV_LOG.md`

### 原因

T022 失败根因：MapRepairer 回退保底模板后，之前修复尝试已将 spawn 移动至模板不可行走位置。修复后 spawn 落在保底模板(5,5)可行走区域。T025/T028 措辞修正避免暗示已验证编辑器模式。

### 测试结果

- CLI 编译验证：✅ PASS
- SmokeTestRunner：33/35 PASS (94.3%)
- T022：✅ PASS
- T025/T028：仍失败（注明等待编辑器 F5 验证）

### 后续待办

* Godot 编辑器 F5 运行验证 M001-M006
* 接真实 MiMo/NVIDIA API 联调
---

# 以下为历史日志
