# PixelWorld 代码基础审查报告

## 1. 项目版本状态

- 当前目标版本: `v0.3.0`
- 上一稳定记录: `v0.2.1`
- Godot 版本目标: `4.7.stable`
- 真实 AI 接入: 暂停，仅保留 Mock/local 路径
- TileMapLayer 迁移: 暂停
- 多人联机: 未纳入当前版本

## 2. 已确认的代码基础

- 项目结构清晰，`scripts/core`, `scripts/entities`, `scripts/ui`, `scripts/map`, `scripts/ai`, `scripts/tests` 分层明确。
- `WorldState`, `ConfigManager`, `GameLog`, `SaveManager` 已通过 Autoload 组织，适合继续承载 MVP 状态。
- v0.2.0 基础玩法闭环已经存在：玩家、NPC、敌人、交互、背包、存档、HUD、地图生成与验证。
- v0.2.1 的程序生成素材包存在，且 `ASSET_MANIFEST.md` 记录 186 个 PNG。
- `SmokeTestRunner.gd` 已经形成连续测试编号，是当前项目最重要的回归保护。

## 3. 本轮已修复或增强的问题

- `Stats.gd` 过去只有简单 HP/攻击/防御字段，无法承载境界、装备、状态与世界观成长。本轮已改为 `base_stats/equipment_bonus/progression_bonus/status_bonus/final_stats` 结构，并保留旧字段兼容。
- 玩家、NPC、敌人过去没有统一素材解析入口，贴图缺失时容易分散处理。本轮新增 `AssetResolver.gd`，并接入 Player/NPC/Enemy 的安全 fallback。
- `WorldState` 过去没有成长体系状态。本轮新增 `progression_data`, `realm_history`, `breakthrough_history`, `tribulation_record`, `unlocked_features`, `world_rule_modifiers`。
- `SaveManager` 过去只保存基础世界和玩家 HP。本轮扩展保存/读取成长数据和玩家属性数据，旧存档缺字段时使用默认值。
- HUD 过去只显示 HP、体力、声望、背包和日志。本轮新增成长体系摘要显示方法和 Label。
- 成长体系过去没有数据文件。本轮新增 8 个 JSON 模板，并由 `ProgressionTemplateLoader` 统一验证和加载。

## 4. 保留的问题与风险

- `T025` 和 `T028` 仍应保留为 CLI headless SceneTree/初始化或碰撞计数待编辑器 F5 验证项，不应在没有真实编辑器验证前标记修复。
- `GameWorld.gd` 仍以 ColorRect 和代码生成节点为主，地图视觉与正式 TileSet 尚未接入。
- `CombatSystem.gd` 仍是非常简单的伤害公式，尚未真正使用 accuracy、dodge、crit、抗性等扩展属性。
- `ProgressionSystem.gd` 第一版实现了数据流和记录，但突破条件、物品消耗、地点要求、世界事件条件仍是 MVP 级。
- `TribulationSystem.gd` 第一版实现了多轮伤害和记录，尚未接入场景表现、动画、道具护盾和失败后剧情分支。
- `AssetResolver.gd` 能加载 PNG 和 fallback，但还没有统一 SpriteFrames 动画切片管理。
- `SaveManager.gd` 仍是单文件 JSON 存档，没有版本迁移器；后续字段变化多时需要 `save_version` 与迁移函数。
- `README.md`, `DEV_LOG.md`, `TEST_REPORT.md` 需要随着真实测试输出持续更新，不能把未测内容写成已通过。

## 5. 架构建议

- 继续让 `WorldState` 存运行时状态，让模板 JSON 只描述规则，不保存运行进度。
- 保持 Player/GameWorld 不写死修仙，所有世界类型通过 `ProgressionTemplateLoader` 映射进入。
- 下一轮优先让战斗和探索读取 `Stats.get_stat()`，逐步消化 v0.3.0 新属性。
- 后续为存档加入 `save_version`，避免 v0.4+ 对 v0.3.0 存档做破坏性读取。
- 编辑器 F5 手动验证需要单独记录，不能用 CLI SmokeTest 替代。

## 6. 当前结论

项目可以继续在现有代码底座上扩展。最大技术债不是目录混乱，而是玩法系统之间仍然偏 MVP：成长、战斗、地图表现、AI 叙事和存档版本尚未深度联动。本轮 v0.3.0 的重点是把成长系统的数据底座、状态底座和测试底座先立住。
