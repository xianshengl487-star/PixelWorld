# PixelWorld 测试报告

## 最新测试结论

- **当前版本**: v0.2.1
- **测试时间**: 2026-06-28 00:04
- **Godot 版本**: 4.7.stable.official.5b4e0cb0f
- **测试方式**: CLI headless (`--script res://scripts/tests/SmokeTestRunner.gd`)
- **素材生成脚本**: PASS (`python tools/generate_pixel_assets.py`)
- **CLI 编译验证**: PASS（退出码 0）
- **SmokeTest**: 60/62 PASS (96.8%)
- **新增 v0.2.1 测试**: T051-T062 全部 PASS
- **编辑器手动验证**: 未执行（需手动打开 Godot F5 运行）
- **总体结论**: 部分通过 — v0.2.1 预备像素素材扩展包生成、清单、说明文档和素材测试全部通过；T025/T028 继续保留为 CLI headless/SceneTree 或保底模板路径下的待编辑器验证项

## v0.2.1 新增验证重点

* `tools/generate_pixel_assets.py` 存在且可运行
* `art/generated` 目录存在
* 玩家方向动画、受伤帧、死亡帧存在
* NPC 扩展素材存在
* 敌人扩展素材存在
* 修仙/末世/赛博/通用瓦片存在
* 材料/消耗品/武器/特殊物品图标存在
* UI 图标与面板存在
* 战斗/魔法特效存在
* 7 张预览图存在
* `ASSET_MANIFEST.md` 包含统计信息
* `PLACEHOLDER_ART.md` 包含 v0.2.1 扩展说明

## 素材生成结果

| 分类 | 数量 |
|---|---:|
| 角色素材 | 17 |
| NPC 素材 | 15 |
| 敌人素材 | 21 |
| 地图瓦片 | 46 |
| 物品图标 | 36 |
| UI 素材 | 31 |
| 特效素材 | 13 |
| 预览图 | 7 |
| 总素材数量 | 186 |

预览图：

* `res://art/generated/previews/character_preview.png`
* `res://art/generated/previews/enemy_preview.png`
* `res://art/generated/previews/tile_preview.png`
* `res://art/generated/previews/item_preview.png`
* `res://art/generated/previews/ui_preview.png`
* `res://art/generated/previews/effect_preview.png`
* `res://art/generated/previews/all_assets_preview.png`

## CLI 冒烟测试

| 范围 | 结果 | 备注 |
|---|---:|---|
| T001-T050 | 48/50 PASS | v0.2.0 原有测试未新增倒退项，仍为 T025/T028 失败 |
| T051-T062 | 12/12 PASS | v0.2.1 素材扩展测试全部通过 |
| T001-T062 | 60/62 PASS | 总体 96.8% |

## v0.2.1 测试明细

| 编号 | 测试项 | 结果 | 备注 |
|---|---|---|---|
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

## 保留失败项

| 编号 | 测试项 | 结果 | 备注 |
|---|---|---|---|
| T025 | GameWorld 初始化后玩家节点存在 | FAIL | 延续 v0.2.0 CLI headless 场景初始化待验证项 |
| T028 | 障碍物碰撞节点存在 | FAIL | CLI 路径下 CollisionLayer 存在但 count=0，等待编辑器 F5 验证 |

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
| M008 | 关键素材在游戏内替换显示 | 未测 | 后续接 TileSet/贴图引用时验证 |

## 下一步建议

- 建议 1：人工查看 `art/generated/previews/all_assets_preview.png`，快速筛掉难辨识的占位图。
- 建议 2：下一轮优先把生成的 tiles/items/ui 图标接入实际场景显示，而不是继续扩素材数量。
- 建议 3：编辑器 F5 验证 T025/T028 对应的玩家节点与碰撞体实际表现。
