# PixelWorld 测试报告

## 最新测试结论

- **当前版本**: v0.3.0
- **测试时间**: 2026-06-28 01:35
- **Godot 版本**: 4.7.stable.official.5b4e0cb0f
- **测试方式**: CLI headless (`--script res://scripts/tests/SmokeTestRunner.gd`)
- **JSON 模板解析**: PASS
- **git diff --check**: PASS
- **CLI 编译验证**: PASS（退出码 0）
- **SmokeTestRunner**: 96/97 PASS (99.0%)
- **新增 v0.3.0 测试**: T081-T115 全部 PASS
- **编辑器手动验证**: 未执行（需手动打开 Godot F5 运行）
- **总体结论**: 部分通过 — v0.3.0 代码审查、资产解析 fallback、成长系统模板、Stats 重构、WorldState/Save/HUD 扩展和新增测试全部完成；T025 仍需编辑器 F5 验证。

## v0.3.0 新增验证重点

* `CODE_AUDIT.md` 存在且真实记录保留风险
* `AssetResolver` 可加载 generated PNG 或安全 fallback
* `CharacterVisualProfile` 可创建和序列化
* `ProgressionTemplateLoader` 可加载并验证 8 个世界模板
* 修仙模板包含 10 个大境界、炼气 10 层、筑基到金丹心魔/雷劫、渡劫 heavenly_lightning
* `ProgressionSystem` 可初始化、获得修为、推进小境界
* `BreakthroughSystem` 可计算成功率并记录失败次数
* `TribulationSystem` 可启动和结算雷劫回合
* `RealmEffectApplier` 可写入 `Stats.progression_bonus`
* `Stats` 支持 base/equipment/progression/status/final 结构
* `SaveManager` 可保存和读取 `progression_data`
* HUD 提供 progression 显示方法
* `WorldState` 有 realm_history 和 tribulation_record

## CLI 冒烟测试汇总

| 范围 | 结果 | 备注 |
|---|---:|---|
| T001-T062 | 61/62 PASS | T025 失败；T028 本轮 PASS |
| T063-T080 | N/A | SmokeTestRunner 当前未定义这些编号 |
| T081-T115 | 35/35 PASS | v0.3.0 新增测试全部通过 |
| 实际运行总数 | 96/97 PASS | SmokeTestRunner 实际执行 97 项 |

## T001-T115 测试表

| 编号 | 测试项 | 结果 | 备注 |
|---|---|---|---|
| T001 | project.godot 存在 | PASS | |
| T002 | MainMenu.tscn 可加载 | PASS | |
| T003 | GameWorld.tscn 可加载 | PASS | |
| T004 | Player.tscn 可加载 | PASS | |
| T005 | NPC.tscn 可加载 | PASS | |
| T006 | GameHUD.tscn 可加载 | PASS | |
| T007 | DialogueBox.tscn 可加载 | PASS | |
| T008 | WorldState Autoload 存在 | PASS | |
| T009 | ConfigManager Autoload 存在 | PASS | |
| T010 | GameLog Autoload 存在 | PASS | |
| T011 | AIClient 可实例化 | PASS | |
| T012 | MockProvider 可生成世界蓝图 | PASS | 世界名: 青溪界 |
| T013 | WorldBlueprintValidator 可校验蓝图 | PASS | |
| T014 | 默认蓝图>=1个major NPC | PASS | count=3 |
| T015 | 默认蓝图>=2个minor NPC | PASS | count=4 |
| T016 | MapGenerator 可生成64x64地图 | PASS | 64x64 |
| T017 | MapValidator 可校验地图 | PASS | errors=1 |
| T018 | 出生点可行走 | PASS | pos=(5,5) |
| T019 | 出生点到村长可达 | PASS | |
| T020 | 出生点到洞口可达 | PASS | |
| T021 | 出生点到宗门入口可达 | PASS | |
| T022 | MapRepairer修复后出生点可行走 | PASS | pos=(5,5) |
| T023 | GameWorld 可实例化 | PASS | |
| T024 | GameWorld 可根据WorldState初始化 | PASS | |
| T025 | GameWorld 初始化后玩家节点存在 | FAIL | 继续保留为 CLI headless SceneTree/初始化待编辑器 F5 验证项 |
| T026 | GameWorld NPC节点>=3 | PASS | count=7 |
| T027 | 地图视觉节点存在 | PASS | count=4226 |
| T028 | 障碍物碰撞节点存在 | PASS | count=867 |
| T029 | LocalTinyNpcProvider可返回对话 | PASS | |
| T030 | AIClient可返回major NPC对话 | PASS | |
| T031 | AIClient可解释自由行动 | PASS | action_type=observe |
| T032 | action_history可写入 | PASS | |
| T033 | npc_memory可写入 | PASS | |
| T034 | API未配置时不会崩溃 | PASS | provider=mock |
| T035 | GameLog可记录日志 | PASS | |
| T036 | Stats 可扣血和治疗 | PASS | |
| T037 | Player stats 初始化 | PASS | |
| T038 | CombatSystem 伤害计算 | PASS | damage=4 |
| T039 | Enemy 可实例化 | PASS | |
| T040 | Enemy 受伤后可死亡 | PASS | |
| T041 | Inventory 添加/移除物品 | PASS | |
| T042 | SaveManager 可保存 | PASS | |
| T043 | SaveManager 可读取 | PASS | |
| T044 | ExplorationSystem 可记录发现地点 | PASS | |
| T045 | InteractionSystem 可执行草药拾取 | PASS | |
| T046 | GameWorld 可生成敌人 | PASS | count=3 |
| T047 | GameWorld 可生成资源点 | PASS | count=6 |
| T048 | HUD 生命条节点存在 | PASS | |
| T049 | 自动生成素材文件存在 | PASS | |
| T050 | ASSET_MANIFEST.md 存在 | PASS | |
| T051 | generate_pixel_assets.py 存在 | PASS | |
| T052 | art/generated 目录存在 | PASS | |
| T053 | 玩家动画素材存在 | PASS | |
| T054 | NPC 扩展素材存在 | PASS | |
| T055 | 敌人扩展素材存在 | PASS | |
| T056 | 地图瓦片扩展素材存在 | PASS | |
| T057 | 物品图标扩展素材存在 | PASS | |
| T058 | UI 扩展素材存在 | PASS | |
| T059 | 特效扩展素材存在 | PASS | |
| T060 | 预览图存在 | PASS | |
| T061 | ASSET_MANIFEST.md 包含统计信息 | PASS | 总素材数量 186，预览图 7 |
| T062 | PLACEHOLDER_ART.md 包含 v0.2.1 说明 | PASS | |
| T063 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T064 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T065 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T066 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T067 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T068 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T069 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T070 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T071 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T072 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T073 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T074 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T075 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T076 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T077 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T078 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T079 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T080 | 未定义编号 | N/A | SmokeTestRunner 当前未运行 |
| T081 | CODE_AUDIT.md 存在 | PASS | |
| T082 | AssetResolver 可加载玩家素材或 fallback | PASS | |
| T083 | AssetResolver 可加载 NPC 素材或 fallback | PASS | |
| T084 | AssetResolver 可加载敌人素材或 fallback | PASS | |
| T085 | CharacterVisualProfile 可创建 | PASS | |
| T086 | ProgressionTemplateLoader 可加载修仙模板 | PASS | |
| T087 | 修仙模板包含 10 个大境界 | PASS | count=10 |
| T088 | 修仙炼气包含 10 个小阶段 | PASS | count=10 |
| T089 | 修仙筑基到金丹包含心魔或雷劫 | PASS | |
| T090 | ProgressionSystem 可初始化 xianxia | PASS | |
| T091 | ProgressionSystem 可获得修为 | PASS | |
| T092 | ProgressionSystem 可推进小境界 | PASS | |
| T093 | BreakthroughSystem 可计算成功率 | PASS | rate=0.84 |
| T094 | BreakthroughSystem 失败会记录 failed_breakthroughs | PASS | |
| T095 | TribulationSystem 可启动雷劫 | PASS | |
| T096 | TribulationSystem 可结算雷劫轮次 | PASS | |
| T097 | RealmEffectApplier 可修改 Stats progression_bonus | PASS | |
| T098 | Stats 支持 base/equipment/progression/status/final 结构 | PASS | |
| T099 | SaveManager 保存 progression_data | PASS | |
| T100 | SaveManager 读取 progression_data | PASS | |
| T101 | magic_progression.json 存在并可加载 | PASS | |
| T102 | apocalypse_progression.json 存在并可加载 | PASS | |
| T103 | cyberpunk_progression.json 存在并可加载 | PASS | |
| T104 | wuxia_progression.json 存在并可加载 | PASS | |
| T105 | urban_ability_progression.json 存在并可加载 | PASS | |
| T106 | strange_tale_progression.json 存在并可加载 | PASS | |
| T107 | star_sci_progression.json 存在并可加载 | PASS | |
| T108 | 每个模板至少 8 个阶段 | PASS | |
| T109 | 每个模板有升级资源名称 | PASS | |
| T110 | 每个模板有失败代价配置 | PASS | |
| T111 | HUD 有 progression 显示方法 | PASS | |
| T112 | WorldState 有 realm_history | PASS | |
| T113 | WorldState 有 tribulation_record | PASS | |
| T114 | 角色材质缺失时不会崩溃 | PASS | 返回 null 并写 warning |
| T115 | README 更新当前版本和玩法路线图 | PASS | |

## 保留失败项

| 编号 | 测试项 | 结果 | 备注 |
|---|---|---|---|
| T025 | GameWorld 初始化后玩家节点存在 | FAIL | CLI headless SceneTree/初始化待验证项。没有编辑器 F5 验证前，不标记修复。 |

## 编辑器手动验证

| 编号 | 项目 | 状态 | 备注 |
|---|---|---|---|
| M001 | 玩家 WASD 实际移动手感 | 未测 | 需要编辑器中 F5 交互式运行 |
| M002 | 摄像机跟随效果 | 未测 | 需要编辑器中 F5 交互式运行 |
| M003 | UI 实际显示位置 | 未测 | 需要编辑器中 F5 交互式运行 |
| M004 | NPC 按 E 对话体验 | 未测 | 需要编辑器中 F5 交互式运行 |
| M005 | 碰撞体实际阻挡效果 | 未测 | 需要编辑器中 F5 交互式运行 |
| M006 | MainMenu→GameWorld 场景切换 | 未测 | 需要编辑器中 F5 交互式运行 |
| M007 | v0.2.1 预览图人工查看 | 未测 | 查看 `res://art/generated/previews/` |
| M008 | v0.3.0 成长 HUD 显示 | 未测 | 需要实际进入世界后观察 |
| M009 | Player/NPC/Enemy generated PNG 实际显示 | 未测 | CLI 已验证加载，仍需编辑器视觉确认 |

## 运行中出现但不计为失败的输出

- `.env` 不存在时 `ConfigManager` 警告并进入 Mock 模式：符合当前规则。
- 部分地图校验输出提示 forest 入口不可达并使用保底模板：历史地图生成/修复逻辑仍需后续调优。
- T114 故意请求缺失材质，`AssetResolver` 返回 null 并记录 warning：符合测试目标。
- Godot headless 退出时有 RID/ObjectDB 泄漏提示：当前未作为功能失败处理，后续可单独清理测试场景释放时序。

## 下一步建议

- 建议 1：优先在编辑器 F5 验证 T025 对应玩家节点、摄像机和输入链路。
- 建议 2：把 CombatSystem 接入 `Stats.get_stat()` 的 accuracy/dodge/crit/resistance。
- 建议 3：把突破条件的 required_items、required_flags、recommended_locations 接入背包、事件和地图区域。
