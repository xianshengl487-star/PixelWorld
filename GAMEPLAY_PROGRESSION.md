# PixelWorld 世界观成长体系

## 1. 设计目标

PixelWorld 的成长不设计成单一 `Level 1/2/3`，因为世界类型不同，玩家变强的含义也不同。修仙世界的成长是境界与心境，魔法世界是位阶和法术研究，末世世界是进化与感染压制，赛博世界是义体同步与精神风险。统一等级会让这些世界失去差异。

v0.3.0 的目标是建立一个共同数据结构，让每个世界能使用自己的资源、阶段、瓶颈、突破事件、失败代价和世界影响。

## 2. 通用成长流程

流程是：世界类型 → 成长体系 → 大阶段 → 小阶段 → 资源 → 瓶颈 → 突破 → 劫难/试炼 → 奖励或代价 → 世界影响。

玩家先通过探索、战斗、事件、对话或自由行动获得世界专属资源。资源足够后，可以推进小阶段；小阶段圆满后进入瓶颈。突破由 `BreakthroughSystem` 计算成功率，失败也会留下记录和少量感悟。部分突破会触发 `TribulationSystem`，例如雷劫、元素试炼、感染压制、义体排异、走火入魔或理智坍塌。

成功后，`RealmEffectApplier` 把属性写入 `Stats.progression_bonus`，`WorldRuleModifier` 把世界影响写入 `WorldState.world_rule_modifiers`。所有关键结果都要写入 `WorldState`，并通过 `SaveManager` 保存。

## 3. 通用数据结构

`progression_data` 是运行时成长状态，主要字段包括：

- `world_type`: 当前世界类型。
- `system_id/system_name`: 模板标识和显示名。
- `exp_label/stage_label/breakthrough_label`: UI 显示用名称。
- `current_realm_id/current_realm_name/current_realm_order`: 当前大阶段。
- `current_stage/current_stage_name`: 当前小阶段。
- `current_progress/progress_to_next`: 当前资源和下一个阶段需求。
- `bottleneck/bottleneck_reason`: 是否卡在瓶颈。
- `tribulation_pending/tribulation_type`: 是否有待处理试炼。
- `failed_breakthroughs/breakthrough_points`: 失败次数和突破感悟。
- `realm_history/breakthrough_history/tribulation_record`: 可保存的历史记录。
- `unlocked_features`: 已解锁能力。
- `world_modifiers`: 世界层面的长期影响。
- `special_flags`: 后续事件和模板扩展用标记。

## 4. 修仙境界完整设计

凡人：定位是从普通人到感应灵气。小阶段是普通凡人、强壮凡人、武者体魄、感应灵气。效果偏向生命和体力，解锁 `spirit_sense_seed`。突破条件是修为达到 50，失败代价是疲惫、经脉刺痛和引气失败瓶颈。

炼气：定位是正式踏入修行。小阶段为一层到九层和圆满，共 10 层。效果偏向体力、神识和基础法术，解锁 `basic_spells`。突破到筑基需要更高修为，推荐筑基丹和灵气充足地点。失败代价是经脉损伤、内伤和失败次数增加。

筑基：定位是稳定根基。小阶段为初期、中期、后期、圆满。效果是生命、防御和法术亲和提升，解锁 `artifact_control`。突破到金丹包含心魔和小雷劫风险，失败可能导致根基裂痕、生命降到低值和境界不稳。

金丹：定位是凝结核心战力。效果大幅提升攻击、防御和暴击，解锁 `golden_core_pressure`，世界影响会提高宗门关注。突破到元婴需要破丹成婴，风险包含金丹破碎和心魔。

元婴：定位是神魂独立。效果提升神识、闪避和发现概率，解锁 `soul_escape_once`。突破到化神的风险是神魂损伤和悟道试炼。

化神：定位是理解法则并压制区域。效果是法则感知、神识锁定和攻击提升，解锁 `law_sense`。突破到合体会面对法则反噬。

合体：定位是肉身和神魂合一。效果是生命、防御和雷劫抗性提升，解锁 `body_soul_unity`。突破到大乘的风险是道心迷失。

大乘：定位是当前世界顶级存在。效果是攻击、防御和神识大幅提升，世界影响包括宗门敬畏、凡人恐惧和世界层级关注。突破会引动渡劫标记。

渡劫：定位是面对天道考验。小阶段是一九、三九、六九、九九雷劫。效果是雷劫抗性和天雷标记。突破到飞升必须完成 `heavenly_lightning`，失败可能严重受伤、陨落或境界倒退。

飞升：定位是当前世界终局记录。第一版不生成新地图，只记录飞升准备、仙门开启、踏入上界，解锁 `new_world_seed`，并写入 `ascension_legend` 世界影响。

## 5. 雷劫系统

雷劫由突破结果触发，模板指定 `requires_tribulation`, `tribulation_type`, `tribulation_rounds`。第一版按回合结算，每轮读取基础伤害、`tribulation_resistance`、准备度和护盾状态。

抗性来自 `Stats.get_stat("tribulation_resistance")`，准备度来自上下文，道具和法宝暂时以 `shielded` 或数值 bonus 表达。失败时写入 `tribulation_record`，成功时清除待处理标记并允许后续境界效果生效。

## 6. 心魔系统

心魔是突破失败和高阶破境的风险之一。第一版通过 `risk_type` 和失败代价记录，后续可以扩成对话/选择事件。`insight` 提高理解能力，`charisma` 可影响心魔中的人际牵挂，`luck` 可提供少量保底。失败会导致内伤、境界不稳、特殊 flag 或下一轮难度变化；成功可给突破点、神识或道心稳定标记。

## 7. 魔法世界成长模板

魔法世界使用法师位阶，从无魔者到星界贤者。资源包括魔力经验、法术研究、魔晶、学院许可和元素亲和。突破事件包括法环构筑、元素试炼、禁咒反噬和星界考验。失败会带来魔力紊乱、法术反噬、元素污染或学院禁令。世界影响主要是学院关注、王室招募和怪物敏感度。

## 8. 末世世界成长模板

末世世界使用觉醒等级，从普通幸存者到末日支配者。资源包括进化值、晶核、战斗经验、感染抗性和基因稳定度。突破围绕晶核吸收、感染压制、基因重组和尸潮试炼。失败会提高感染、造成失控、留下突变标记或让基地恐惧。世界影响包括基地态度、怪物攻击性和感染区关注。

## 9. 赛博世界成长模板

赛博世界使用义体同步等级，从街头素体到机械飞升者。资源包括信用点、义体部件、神经同步率、系统破解值和黑市医生。突破事件是义体手术、神经同步测试、防火墙入侵和赛博精神病检查。失败代价包括神经损伤、义体排异、通缉等级上升和精神病风险。世界影响包括企业关注、黑市折扣和城市监控。

## 10. 武侠世界成长模板

武侠世界使用武道境界，从普通人到破碎虚空。资源包括内力、招式熟练度、秘籍、经脉打通和江湖阅历。突破事件包括打通经脉、闭关悟招、生死决斗和武林大会。失败代价是走火入魔、经脉损伤和声望下降。世界影响包括江湖名望、门派挑战和官府关注。

## 11. 都市异能模板

都市异能使用官方或地下评级，从普通人到神话级。资源包括异能熟练度、精神稳定度、异常核心和官方评级许可。突破事件包括异能测试、异常事件处理、精神污染抗性检查和评级审查。失败代价是能力暴走、官方监控和精神损伤。世界影响包括管理局关注、暴露风险和地下组织招募。

## 12. 怪谈世界模板

怪谈世界使用污染适应度，从普通人到怪谈核心。资源包括规则理解度、污染值、理智稳定度和禁忌知识。突破事件包括规则试炼、污染压制、禁忌选择和异常同化。失败代价是理智损失、污染升高、NPC 恐惧和行动限制。世界影响包括实体关注、安全区排斥和规则扭曲。

## 13. 星际科幻模板

星际科幻使用能力阶层，从星球平民到古文明继承者。资源包括科技点、舰船模块、外星遗物、声望和殖民资源。突破事件包括舰船升级、文明试炼、外交承认和古遗迹认证。失败代价是舰船损伤、势力敌意和资源损失。世界影响包括派系关注、贸易路线开放和海盗威胁。

## 14. 新世界类型如何添加成长体系

1. 新建 `data/progression_templates/<world_type>_progression.json`。
2. 定义 `system_id` 和 `display_name`。
3. 定义 `progression_resources`。
4. 定义至少 8 个 `realms`。
5. 为每个 realm 定义 `minor_stages` 和 `base_effects`。
6. 为每个 realm 定义 `breakthrough`。
7. 定义 `failure_consequences`。
8. 定义 `world_effects`。
9. 在 `ProgressionTemplateLoader.TEMPLATE_PATHS` 加入映射。
10. 在 SmokeTestRunner 加测试。

## 15. 存档字段

`SaveManager` 保存 `progression_data`, `player_stats`, `unlocked_features`, `world_rule_modifiers`, `realm_history`, `breakthrough_history`, `tribulation_record`, `progression_template_id`, `progression_world_type`。旧存档缺字段时使用默认值补全。

## 16. 测试项说明

v0.3.0 新增 T081-T115，覆盖审查文档、资产解析、角色视觉 profile、模板加载、修仙境界结构、成长初始化、修为获取、小阶段推进、突破成功率、突破失败记录、雷劫启动和结算、Stats 分层结构、存档读写、8 个模板完整性、HUD 方法、WorldState 记录字段、材质缺失 fallback 和 README 版本路线图。
