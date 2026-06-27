extends RefCounted
class_name AIProvider
## AIProvider.gd — AI Provider 抽象基类
## 所有 Provider 必须继承此类并实现以下方法


## 生成世界蓝图
## @param prompt: String — 玩家的世界描述文本
## @return Dictionary — 世界蓝图 JSON
func generate_world_blueprint(prompt: String) -> Dictionary:
	push_error("[AIProvider] generate_world_blueprint 未在子类中实现！")
	return {"error": "not_implemented"}


## 生成主要 NPC 回复
## @param context: Dictionary — NPC 对话上下文
##   {
##     "npc_id": String,
##     "npc_name": String,
##     "npc_role": String,
##     "npc_personality": Array,
##     "npc_goal": String,
##     "npc_memory": Dictionary,
##     "player_name": String,
##     "player_reputation": int,
##     "player_action_history": Array,
##     "current_location": String,
##     "current_event": String,
##     "world_type": String,
##     "player_input": String (可选)
##   }
## @return Dictionary
##   {
##     "dialogue": String,
##     "attitude_change": int,
##     "memory_to_add": String|null,
##     "event_trigger": String|null,
##     "world_changes": Array
##   }
func generate_major_npc_reply(context: Dictionary) -> Dictionary:
	push_error("[AIProvider] generate_major_npc_reply 未在子类中实现！")
	return {"error": "not_implemented", "dialogue": "...", "attitude_change": 0}


## 生成小型 NPC 回复
## @param context: Dictionary — NPC 对话上下文
## @return Dictionary — {"dialogue": String}
func generate_minor_npc_reply(context: Dictionary) -> Dictionary:
	push_error("[AIProvider] generate_minor_npc_reply 未在子类中实现！")
	return {"dialogue": "你好。"}


## 解读玩家自由行动
## @param context: Dictionary — 玩家行动上下文
## @return Dictionary
##   {
##     "interpretation": String,
##     "action_type": String (talk/observe/move/attack/spread_rumor/...),
##     "world_changes": Array,
##     "narrative_result": String
##   }
func interpret_player_action(context: Dictionary) -> Dictionary:
	push_error("[AIProvider] interpret_player_action 未在子类中实现！")
	return {"error": "not_implemented", "interpretation": ""}
