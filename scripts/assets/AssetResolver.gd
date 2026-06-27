extends RefCounted
class_name AssetResolver
## AssetResolver.gd - safe generated-art lookup with fallback paths.

const PLAYER_STATE_PATHS := {
	"idle_down": "res://art/generated/characters/player/player_idle_down_sheet.png",
	"walk_down": "res://art/generated/characters/player/player_walk_down_sheet.png",
	"walk_up": "res://art/generated/characters/player/player_walk_up_sheet.png",
	"walk_left": "res://art/generated/characters/player/player_walk_left_sheet.png",
	"walk_right": "res://art/generated/characters/player/player_walk_right_sheet.png",
	"attack_down": "res://art/generated/characters/player/player_attack_down_sheet.png",
	"attack_up": "res://art/generated/characters/player/player_attack_up_sheet.png",
	"attack_left": "res://art/generated/characters/player/player_attack_left_sheet.png",
	"attack_right": "res://art/generated/characters/player/player_attack_right_sheet.png",
	"hurt": "res://art/generated/characters/player/player_hurt.png",
	"dead": "res://art/generated/characters/player/player_dead.png"
}

const NPC_ROLE_PATHS := {
	"village_chief": "res://art/generated/characters/npc_chief.png",
	"chief": "res://art/generated/characters/npc_chief.png",
	"quest_giver": "res://art/generated/characters/npc_chief.png",
	"doctor": "res://art/generated/characters/npc_doctor.png",
	"merchant": "res://art/generated/characters/npc/npc_merchant.png",
	"guard": "res://art/generated/characters/npc/npc_guard.png",
	"farmer": "res://art/generated/characters/npc/npc_farmer.png",
	"blacksmith": "res://art/generated/characters/npc/npc_blacksmith.png",
	"elder": "res://art/generated/characters/npc/npc_elder.png",
	"default": "res://art/generated/characters/npc_villager.png"
}

const ENEMY_TYPE_PATHS := {
	"slime": "res://art/generated/enemies/slime/enemy_slime_green.png",
	"wolf": "res://art/generated/enemies/beast/enemy_wolf_gray.png",
	"bandit": "res://art/generated/enemies/humanoid/enemy_bandit_knife.png",
	"elite_wolf": "res://art/generated/enemies/beast/enemy_elite_wolf.png",
	"boss_bandit": "res://art/generated/enemies/humanoid/enemy_bandit_leader.png",
	"default": "res://art/generated/enemies/slime/enemy_slime_green.png"
}


func texture_exists(path: String) -> bool:
	return path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path))


func resolve_texture(path: String, fallback_path: String = "") -> Texture2D:
	var texture = _load_texture(path)
	if texture != null:
		return texture
	if fallback_path != "":
		texture = _load_texture(fallback_path)
		if texture != null:
			_warn("Texture missing: %s, using fallback: %s" % [path, fallback_path])
			return texture
	_warn("Texture missing and fallback unavailable: %s" % path)
	return null


func get_player_texture(state: String = "idle_down") -> Texture2D:
	var path = PLAYER_STATE_PATHS.get(state, PLAYER_STATE_PATHS["idle_down"])
	return resolve_texture(path, "res://art/generated/characters/player_idle.png")


func get_player_sheet(action: String, direction: String) -> Texture2D:
	var key = "%s_%s" % [action, direction]
	return get_player_texture(key)


func get_npc_texture(npc_role: String) -> Texture2D:
	var role = npc_role.strip_edges().to_lower()
	var path = NPC_ROLE_PATHS.get(role, NPC_ROLE_PATHS["default"])
	return resolve_texture(path, NPC_ROLE_PATHS["default"])


func get_enemy_texture(enemy_type: String) -> Texture2D:
	var key = enemy_type.strip_edges().to_lower()
	var path = ENEMY_TYPE_PATHS.get(key, ENEMY_TYPE_PATHS["default"])
	return resolve_texture(path, ENEMY_TYPE_PATHS["default"])


func get_item_texture(item_id: String) -> Texture2D:
	var id = item_id.strip_edges().to_lower()
	return resolve_texture("res://art/generated/items/item_%s.png" % id)


func get_tile_texture(tile_id: String) -> Texture2D:
	var id = tile_id.strip_edges().to_lower()
	return resolve_texture("res://art/generated/tiles/tile_%s.png" % id)


func get_ui_texture(icon_id: String) -> Texture2D:
	var id = icon_id.strip_edges().to_lower()
	return resolve_texture(
		"res://art/generated/ui/icons/ui_%s.png" % id,
		"res://art/generated/ui/ui_%s.png" % id
	)


func get_effect_sheet(effect_id: String) -> Texture2D:
	var id = effect_id.strip_edges().to_lower()
	return resolve_texture(
		"res://art/generated/effects/effect_%s_sheet.png" % id,
		"res://art/generated/effects/combat/effect_%s_sheet.png" % id
	)


func _load_texture(path: String) -> Texture2D:
	if not texture_exists(path):
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var image = Image.new()
		var err = image.load(path)
		if err == OK:
			return ImageTexture.create_from_image(image)
		_warn("Image load failed (%d): %s" % [err, path])
		return null
	_warn("Resource exists but is not Texture2D: %s" % path)
	return null


func _warn(message: String) -> void:
	push_warning(message)
	var log = _autoload("GameLog")
	if log != null and log.has_method("add_warning"):
		log.add_warning(message)
	var state = _autoload("WorldState")
	if state != null and state.has_method("log_error"):
		state.log_error("AssetResolver", message)


func _autoload(name: String):
	var loop = Engine.get_main_loop()
	if loop is SceneTree:
		return loop.root.get_node_or_null(name)
	return null
