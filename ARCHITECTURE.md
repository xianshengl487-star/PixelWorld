# ARCHITECTURE.md — PixelWorld 项目架构

## 一、游戏整体架构

```
┌─────────────────────────────────────────────────┐
│                  Godot 4 Client                  │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐ │
│  │ MainMenu │  │GameWorld │  │  UI System     │ │
│  │  Scene   │→ │  Scene   │  │ DialogueBox    │ │
│  │          │  │          │  │ GameHUD        │ │
│  └──────────┘  └──────────┘  │ GameLog        │ │
│                               └───────────────┘ │
│  ┌──────────────────────────────────────────────┐│
│  │            Core Systems (Autoload)            ││
│  │  WorldState  │  ConfigManager  │ DevLogWriter││
│  └──────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────┐│
│  │              AI Layer                         ││
│  │  AIClient → AIProviderAdapter → Providers    ││
│  │  (Mimo / NVIDIA / Mock / LocalTinyNPC)       ││
│  └──────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────┐│
│  │           World & Map System                  ││
│  │  WorldBlueprintValidator                     ││
│  │  MapGenerator → MapValidator → MapRepairer   ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌─────────────────┐    ┌──────────────────────┐
│  AI Gateway     │    │  Local AI Service    │
│  (推荐模式)      │    │  (Ollama / llama.cpp)│
└────────┬────────┘    └──────────┬───────────┘
         │                        │
         ▼                        ▼
┌─────────────────┐    ┌──────────────────────┐
│  Cloud APIs     │    │  Local GGUF Models   │
│  MiMo / NVIDIA  │    │  (Tiny NPC Models)   │
└─────────────────┘    └──────────────────────┘
```

### 系统分层

| 层级 | 职责 | 核心脚本 |
|------|------|----------|
| **场景层** | 游戏场景管理、UI 渲染 | MainMenu, GameWorld, DialogueBox, GameHUD |
| **核心系统层** | 全局状态、配置、日志 | WorldState, ConfigManager, DevLogWriter |
| **AI 层** | AI 调用抽象、Provider 切换 | AIClient, AIProvider, MimoProvider, NvidiaProvider, MockProvider, LocalTinyNpcProvider |
| **世界层** | 世界蓝图校验 | WorldBlueprintValidator |
| **地图层** | 地图生成、校验、修复 | MapGenerator, MapValidator, MapRepairer |
| **实体层** | 玩家、NPC 逻辑 | Player, NPC |

---

## 二、AI 调用架构

```
玩家输入一句话
       │
       ▼
┌─────────────┐     ┌──────────────────────┐
│  AIClient    │────→│  AIProviderAdapter   │
│  (单例)      │     │  (根据配置选择)       │
└─────────────┘     └──────────┬───────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                     │
          ▼                    ▼                     ▼
   ┌──────────────┐   ┌──────────────┐    ┌──────────────────┐
   │ MimoProvider │   │NvidiaProvider│    │ MockProvider     │
   │ (云端API)    │   │ (云端API)    │    │ (本地默认世界)    │
   └──────────────┘   └──────────────┘    └──────────────────┘
                                                     │
                                          ┌──────────┴──────────┐
                                          │                     │
                                          ▼                     ▼
                                   ┌──────────────┐    ┌──────────────────┐
                                   │LocalTinyNpc  │    │  后续可扩展:      │
                                   │Provider      │    │  OllamaProvider   │
                                   │(小NPC规则)   │    │  LlamaCppProvider │
                                   └──────────────┘    └──────────────────┘
```

### AI 调用分工

| 调用场景 | 使用 Provider | 模型类型 |
|----------|--------------|----------|
| 世界蓝图生成 | MimoProvider / NvidiaProvider | 云端大模型 |
| 主要 NPC 对话 | MimoProvider / NvidiaProvider | 云端大模型 |
| 小型 NPC 对话 | LocalTinyNpcProvider | 本地规则（可替换为本地小模型） |
| 玩家自由行动解读 | MimoProvider / NvidiaProvider | 云端大模型 |
| API 不可用时 | MockProvider | 本地默认数据 |

### 错误处理与回退策略

```
API Call
  │
  ├─ 成功 → 返回结果
  │
  └─ 失败 → 重试 1 次
       │
       ├─ 成功 → 返回结果
       │
       └─ 失败 → 切换 MockProvider
            │
            ├─ 记录错误到 GameLog
            ├─ 记录错误到 WorldState.last_errors
            └─ UI 提示用户
```

---

## 三、世界生成流程

```
1. 玩家在 MainMenu 输入世界描述文本
       │
2. AIClient.generate_world_blueprint(prompt)
       │
3. Cloud Provider 返回 JSON（或 MockProvider 返回默认蓝图）
       │
4. WorldBlueprintValidator 校验 JSON
       │
       ├─ 校验通过 → 继续
       │
       └─ 校验失败
            ├─ 尝试修复 JSON
            ├─ 尝试补全缺失字段
            ├─ 仍失败 → 使用默认世界蓝图
            └─ 记录错误到 GameLog
       │
5. WorldState.world_blueprint = validated_data
       │
6. 切换到 GameWorld 场景
```

---

## 四、地图生成流程

```
1. GameWorld._ready() 读取 WorldState.world_blueprint
       │
2. MapGenerator.generate(blueprint)
       │
       ├─ 生成 64x64 瓦片数组
       ├─ 中央生成村庄（道路 + 房子）
       ├─ 北部生成森林（树 + 怪物区域）
       ├─ 山体中生成洞口
       ├─ 东北角生成宗门入口
       ├─ 生成连通道路
       └─ 放置 NPC 到地图
       │
3. MapValidator.validate(map_data, blueprint)
       │
       ├─ 所有检查通过 → 继续
       │
       └─ 任一检查失败
            │
4. MapRepairer.repair(map_data, blueprint, errors)
       │
       ├─ 修复道路连通
       ├─ 移动错误放置的 NPC
       ├─ 移动出生点
       └─ 最多修复 3 次
            │
            ├─ 修复成功 → 继续
            │
            └─ 修复失败 → 使用保底地图模板 (xianxia_safe_start.json)
       │
5. 渲染地图瓦片
6. 生成玩家 (player_spawn)
7. 生成所有 NPC
8. 开始游戏循环
```

---

## 五、NPC 对话流程

```
玩家按 E 靠近 NPC
       │
       ├─ NPC.importance == "major"
       │     │
       │     ▼
       │   AIClient.generate_major_npc_reply(context)
       │     │
       │     ├─ 云端 API 成功 → 返回 dialogue JSON
       │     ├─ 云端 API 失败 → MockProvider 返回默认对话
       │     └─ 结果写入 WorldState.npc_memory
       │
       └─ NPC.importance == "minor"
             │
             ▼
           AIClient.generate_minor_npc_reply(context)
             │
             ├─ LocalTinyNpcProvider 规则匹配回复
             └─ 结果写入 WorldState.npc_memory
       │
       ▼
   DialogueBox 显示对话
   GameLog 记录对话
```

---

## 六、本地小模型 / 本地规则 NPC 流程

```
LocalTinyNpcProvider.generate_minor_npc_reply(context)
       │
       ├─ 读取 NPC.dialogue_profile
       ├─ 读取 NPC.role
       ├─ 读取当前世界事件
       │
       ▼
   规则匹配
       │
       ├─ role == "villager" → 围绕村庄、安全、传闻
       ├─ role == "merchant" → 围绕物价、商品、路况
       ├─ role == "guard"    → 围绕通行、警戒、法律
       ├─ role == "wanderer" → 围绕天气、传闻、附近事件
       └─ role == "default"  → 通用问候
       │
       ▼
   返回 { "dialogue": "...", "attitude_change": 0, "memory_to_add": null }
```

### 后续可替换为本地模型

LocalTinyNpcProvider 接口设计为可替换：
- `res://models/tiny_npc_model.gguf` — 本地 GGUF 模型
- Ollama HTTP API — `http://localhost:11434/api/generate`
- llama.cpp 进程通信
- 自定义 HTTP 小模型服务

替换时只需修改 LocalTinyNpcProvider 内部实现，不影响调用方。

---

## 七、未来多人联机预留设计

### 架构预留

```
┌─────────────────────────────────────────────────┐
│              Server (未来实现)                    │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐ │
│  │ World    │  │ Player   │  │ AI Gateway    │ │
│  │ Server   │  │ Manager  │  │ (集中管理Key)  │ │
│  └──────────┘  └──────────┘  └───────────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │           Database (SQLite / PostgreSQL)  │   │
│  │  WorldState, NPC Memory, Events          │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
         ▲                          ▲
         │       WebSocket          │
         │                          │
┌────────┴────────┐    ┌───────────┴─────────┐
│  Client A       │    │  Client B           │
│  (Godot)        │    │  (Godot)            │
└─────────────────┘    └─────────────────────┘
```

### 已预留接口

- `WorldState` 设计为 Autoload 单例，后续可替换为网络同步单例
- `NPC.gd` 的对话系统通过 AI Provider 抽象，多客户端可共享 NPC 记忆
- `Player.gd` 移动逻辑与输入解耦，后续可接受网络输入
- `ConfigManager` 可配置服务器地址、端口
- AI Provider 层可集中到 Gateway，避免每个客户端暴露 API Key

### 联机模式关键变化

1. WorldState 从客户端 Autoload 变为服务端权威状态
2. AI 调用从客户端直连变为通过 Gateway 中转
3. 地图生成在服务端执行，广播给所有客户端
4. NPC 对话记忆在服务端存储，多玩家共享世界
5. 自由行动输入需要服务端验证（防作弊）
