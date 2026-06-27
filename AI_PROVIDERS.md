# AI_PROVIDERS.md — AI 服务商接入方式

## Provider 抽象层设计

所有 AI Provider 必须继承 `AIProvider.gd` 基类，实现统一接口：

```gdscript
extends RefCounted
class_name AIProvider

func generate_world_blueprint(prompt: String) -> Dictionary:
    pass

func generate_major_npc_reply(context: Dictionary) -> Dictionary:
    pass

func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
    pass

func interpret_player_action(context: Dictionary) -> Dictionary:
    pass
```

### Provider 切换方式

通过 `ConfigManager` 读取 `AI_PROVIDER` 环境变量：

```
AI_PROVIDER=mimo     → MimoProvider
AI_PROVIDER=nvidia   → NvidiaProvider
AI_PROVIDER=mock     → MockProvider (开发/离线模式)
```

---

## MiMo Provider 配置方式

### 环境变量 (.env)

```env
AI_PROVIDER=mimo
MIMO_API_KEY=your_mimo_key_here
MIMO_BASE_URL=https://your-mimo-openai-compatible-endpoint
MIMO_WORLD_MODEL=mimo-world-model-name
MIMO_MAJOR_NPC_MODEL=mimo-npc-model-name
```

### 配置说明

| 变量 | 说明 | 示例 |
|------|------|------|
| `AI_PROVIDER` | 设为 `mimo` 启用 | `mimo` |
| `MIMO_API_KEY` | MiMo API 密钥 | `sk-xxxx` |
| `MIMO_BASE_URL` | OpenAI 兼容端点地址 | `https://api.mimo.com/v1` |
| `MIMO_WORLD_MODEL` | 世界生成模型 | `mimo-world-v2` |
| `MIMO_MAJOR_NPC_MODEL` | 主要 NPC 对话模型 | `mimo-chat-v1` |

### API 调用格式 (OpenAI Compatible)

```json
POST {MIMO_BASE_URL}/chat/completions
{
    "model": "{MIMO_WORLD_MODEL}",
    "messages": [
        {"role": "system", "content": "..."},
        {"role": "user", "content": "..."}
    ],
    "temperature": 0.7,
    "response_format": {"type": "json_object"}
}
```

---

## NVIDIA NIM Provider 配置方式

### 环境变量 (.env)

```env
AI_PROVIDER=nvidia
NVIDIA_API_KEY=your_nvidia_key_here
NVIDIA_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_WORLD_MODEL=your-nvidia-world-model
NVIDIA_MAJOR_NPC_MODEL=your-nvidia-npc-model
```

### 配置说明

| 变量 | 说明 | 示例 |
|------|------|------|
| `AI_PROVIDER` | 设为 `nvidia` 启用 | `nvidia` |
| `NVIDIA_API_KEY` | NVIDIA API 密钥 | `nvapi-xxxx` |
| `NVIDIA_BASE_URL` | NVIDIA NIM 端点 | `https://integrate.api.nvidia.com/v1` |
| `NVIDIA_WORLD_MODEL` | 世界生成模型 | `meta/llama-3.1-70b-instruct` |
| `NVIDIA_MAJOR_NPC_MODEL` | 主要 NPC 对话模型 | `meta/llama-3.1-8b-instruct` |

### API 调用格式 (OpenAI Compatible)

```json
POST {NVIDIA_BASE_URL}/chat/completions
{
    "model": "{NVIDIA_WORLD_MODEL}",
    "messages": [...],
    "max_tokens": 2048
}
```

---

## Local Tiny NPC Provider 配置方式

### 环境变量 (.env)

```env
LOCAL_NPC_PROVIDER=rule_based
LOCAL_NPC_MODEL_PATH=res://models/tiny_npc_model.gguf
```

### 第一版：规则驱动

第一版使用本地规则匹配，根据 NPC 角色类型返回预设回复池。

**角色映射规则**：

| NPC Role | 回复主题 | 示例 |
|----------|----------|------|
| `villager` | 村庄安全、传闻、天气 | "听说后山最近不太平..." |
| `merchant` | 物价、商品、路况 | "最近药材价格涨了不少。" |
| `guard` | 通行、警戒、法律 | "未经许可不得进入。" |
| `wanderer` | 天气、传闻、附近事件 | "你听说了吗？东边有个神秘洞穴。" |
| `default` | 通用问候 | "你好啊，冒险者。" |

### 后续可替换方案

LocalTinyNpcProvider 接口保持不变，内部实现可替换为：

1. **Ollama 本地模型**
   ```
   POST http://localhost:11434/api/generate
   { "model": "tinyllama", "prompt": "...", "stream": false }
   ```

2. **llama.cpp 进程**
   ```
   启动 llama.cpp 服务进程，Godot 通过 HTTP 或进程通信调用
   ```

3. **自定义 HTTP 小模型服务**
   ```
   任意 OpenAI-compatible 本地服务
   ```

4. **GGUF 文件加载**
   ```
   Godot 通过 GDExtension 加载 GGUF 模型文件
   ```

---

## API Key 读取方式

### 开发原型模式（模式 A）

Godot 通过 `ConfigManager` 读取本地 `.env` 文件：

```gdscript
# ConfigManager.gd
func read_env_file(path: String = "res://.env") -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        printerr("Cannot open .env file: ", path)
        return {}
    var env = {}
    while not file.eof_reached():
        var line = file.get_line().strip_edges()
        if line == "" or line.begins_with("#"):
            continue
        var parts = line.split("=", true, 1)
        if parts.size() == 2:
            env[parts[0].strip_edges()] = parts[1].strip_edges().trim_prefix('"').trim_suffix('"')
    return env
```

### 正式推荐模式（模式 B）

Godot 客户端调用本地或远程 AI Gateway：

```
Godot Client → http://localhost:8080/api/ai/generate → AI Gateway → Cloud API
```

AI Gateway 负责：
- 管理 API Key（客户端不接触）
- 请求路由和负载均衡
- 缓存和重试
- 日志和监控

客户端只需配置 Gateway 地址：

```env
AI_GATEWAY_URL=http://localhost:8080
AI_GATEWAY_AUTH_TOKEN=your_gateway_token
```

### 安全规则

- `.env` 文件已加入 `.gitignore`
- 仅提供 `.env.example` 作为模板
- 不允许在 GDScript 代码中硬编码 API Key
- AI Gateway 模式下客户端零 Key 暴露

---

## 错误重试策略

```
┌──────────┐     失败      ┌──────────┐     失败      ┌──────────────┐
│ 正常调用  │ ──────────→ │ 第一次重试 │ ──────────→ │ 切换Mock     │
│          │              │ (delay 1s)│              │ Provider     │
└──────────┘              └──────────┘              └──────────────┘
                                                          │
                                                    ┌─────┴─────┐
                                                    │ 记录错误   │
                                                    │ 通知用户   │
                                                    └───────────┘
```

重试策略代码位于 `AIClient.gd`：

```gdscript
const MAX_RETRIES = 1
const RETRY_DELAY = 1.0

func _call_with_retry(provider_func: Callable, fallback_func: Callable, error_context: String) -> Dictionary:
    var result = await provider_func.call()
    if result.get("error", "") == "":
        return result

    # 第一次重试
    await get_tree().create_timer(RETRY_DELAY).timeout
    result = await provider_func.call()
    if result.get("error", "") == "":
        return result

    # 回退到 Mock/Fallback
    GameLog.add_error("%s: %s, switching to fallback" % [error_context, result.error])
    WorldState.last_errors.append({
        "time": Time.get_datetime_string_from_system(),
        "context": error_context,
        "error": result.error
    })
    return await fallback_func.call()
```

---

## 失败回退策略

### 世界生成回退

1. Cloud API 失败 → 重试 1 次
2. 仍失败 → `MockProvider` 从 `data/default_blueprints/` 读取默认世界
3. 默认世界按 `world_type` 匹配：`xianxia_default.json` / `apocalypse_default.json` / `cyberpunk_default.json`
4. UI 提示："云端 AI 暂不可用，已使用本地默认世界生成。"

### NPC 对话回退

1. 主要 NPC (major): Cloud API 失败 → MockProvider 返回预设对话
2. 小型 NPC (minor): 始终使用 LocalTinyNpcProvider，不走回退

### 玩家行动解读回退

1. Cloud API 失败 → 本地规则解析
2. 本地规则：关键词匹配 + 简单响应生成
3. 始终返回有效 JSON（不允许 nil）
