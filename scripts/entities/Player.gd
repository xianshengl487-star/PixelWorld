extends CharacterBody2D
class_name Player
## Player.gd — 玩家控制脚本
## WASD / 方向键移动，摄像机跟随，碰撞检测

const StatsClass = preload("res://scripts/entities/Stats.gd")
const CombatSystemClass = preload("res://scripts/combat/CombatSystem.gd")
const InteractionSystemClass = preload("res://scripts/interactions/InteractionSystem.gd")

@export var move_speed: float = 150.0
@export var attack_cooldown: float = 0.45
@export var attack_radius: float = 40.0

var stats = null
var can_attack: bool = true

# 地图碰撞引用（由 GameWorld 设置）
var _map_walkable: Array = []
var _map_width: int = 64
var _map_height: int = 64
var _tile_size: int = 32

# 交互引用
var _ai_client = null
var _nearest_npc = null
var _interaction_system = InteractionSystemClass.new()


func _ready() -> void:
	add_to_group("player")
	# 创建碰撞形状（代码中创建，避免 .tscn SubResource 解析问题）
	if _find_collision_shape() == null:
		var shape_node = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		shape_node.shape = circle
		add_child(shape_node)
	
	_ensure_stats()
	
	# 设置初始位置（从 WorldState 获取）
	var spawn = WorldState.world_blueprint.get("player_spawn", {"x": 20, "y": 20})
	position = Vector2(
		(spawn.get("x", 20) * _tile_size) + _tile_size / 2,
		(spawn.get("y", 20) * _tile_size) + _tile_size / 2
	)


func _physics_process(delta: float) -> void:
	if stats and stats.is_dead:
		velocity = Vector2.ZERO
		return
	if stats:
		stats.restore_stamina(1 if delta > 0 else 0)
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed = stats.move_speed if stats else move_speed
	velocity = input_dir * current_speed
	move_and_slide()
	
	# 更新 WorldState 中的玩家位置
	var tile_x = int(position.x / _tile_size)
	var tile_y = int(position.y / _tile_size)
	WorldState.player_position = Vector2(tile_x, tile_y)


func _process(_delta: float) -> void:
	# 检测附近的可交互 NPC
	if Input.is_action_just_pressed("interact"):
		_try_interact()
	if Input.is_action_just_pressed("attack"):
		attack()


## 尝试与最近的 NPC 交互
func _try_interact() -> void:
	var result = _interaction_system.interact(self)
	if result.get("ok", false):
		return
	
	var player_tile = _get_tile_position()
	
	# 在场景中查找所有 NPC
	var npcs = get_tree().get_nodes_in_group("npc")
	var closest = null
	var closest_dist = 999.0
	
	for npc in npcs:
		if not npc.has_method("get_npc_data"):
			continue
		var npc_tile = npc._get_tile_position()
		var dist = player_tile.distance_to(npc_tile)
		# 交互距离：2 个瓦片内
		if dist <= 2.5 and dist < closest_dist:
			closest = npc
			closest_dist = dist
	
	if closest and closest.has_method("interact"):
		closest.interact(_ai_client)


## 初始化（由 GameWorld 调用）
func setup(map_walkable: Array, ai_client, tile_size: int = 32) -> void:
	_map_walkable = map_walkable
	_ai_client = ai_client
	_tile_size = tile_size
	_map_width = map_walkable[0].size() if map_walkable.size() > 0 else 64
	_map_height = map_walkable.size()
	_ensure_stats()


## 获取当前瓦片坐标
func _get_tile_position() -> Vector2:
	return Vector2(
		int(position.x / _tile_size),
		int(position.y / _tile_size)
	)


func attack() -> Dictionary:
	_ensure_stats()
	if stats.is_dead or not can_attack:
		return {"ok": false, "message": ""}
	if not stats.use_stamina(1):
		GameLog.add_entry("你太疲惫了，暂时无法攻击。")
		return {"ok": false, "message": "no_stamina"}
	
	can_attack = false
	if get_tree():
		var timer = get_tree().create_timer(attack_cooldown)
		timer.timeout.connect(func(): can_attack = true)
	else:
		can_attack = true
	
	var closest = null
	var closest_dist = attack_radius
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D):
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= closest_dist:
			closest = enemy
			closest_dist = dist
	
	if closest == null:
		GameLog.add_entry("你挥出一击，但没有命中目标。")
		WorldState.log_action("攻击落空", {"radius": attack_radius})
		return {"ok": false, "message": "miss"}
	
	var result = CombatSystemClass.apply_damage(self, closest)
	var enemy_name = closest.get_display_name() if closest.has_method("get_display_name") else "敌人"
	GameLog.add_entry("你攻击了%s，造成 %d 点伤害。" % [enemy_name, result.get("damage", 0)])
	if result.get("defender_dead", false):
		GameLog.add_entry("%s被击败了。" % enemy_name)
	WorldState.log_action("攻击 %s" % enemy_name, result)
	CombatSystemClass.spawn_hit_effect(get_parent(), closest.global_position)
	return result


func take_damage(amount: int, attacker = null) -> int:
	_ensure_stats()
	var actual = stats.take_damage(amount)
	WorldState.player_health = stats.health
	if actual > 0:
		GameLog.add_entry("你受到了 %d 点伤害。" % actual)
	return actual


func respawn() -> void:
	var spawn = WorldState.world_blueprint.get("player_spawn", {"x": 20, "y": 20})
	position = Vector2(
		(spawn.get("x", 20) * _tile_size) + _tile_size / 2,
		(spawn.get("y", 20) * _tile_size) + _tile_size / 2
	)
	stats.revive(true)
	WorldState.player_health = stats.health
	WorldState.player_stamina = stats.stamina
	GameLog.add_entry("你倒下了，随后在村庄醒来。")
	WorldState.log_action("玩家倒下并重生", {"event": "player_death"})


func get_stats():
	_ensure_stats()
	return stats


func is_dead() -> bool:
	return stats != null and stats.is_dead


func _ensure_stats() -> void:
	if stats != null:
		return
	stats = get_node_or_null("Stats")
	if stats == null:
		stats = StatsClass.new()
		stats.name = "Stats"
		add_child(stats)
	stats.configure({
		"max_health": WorldState.player_max_health,
		"health": WorldState.player_health,
		"attack": 5,
		"defense": 2,
		"move_speed": move_speed,
		"max_stamina": WorldState.player_max_stamina,
		"stamina": WorldState.player_stamina
	})
	if not stats.health_changed.is_connected(_on_health_changed):
		stats.health_changed.connect(_on_health_changed)
	if not stats.stamina_changed.is_connected(_on_stamina_changed):
		stats.stamina_changed.connect(_on_stamina_changed)
	if not stats.died.is_connected(_on_died):
		stats.died.connect(_on_died)


func _on_health_changed(current: int, max_value: int) -> void:
	WorldState.player_health = current
	WorldState.player_max_health = max_value


func _on_stamina_changed(current: int, max_value: int) -> void:
	WorldState.player_stamina = current
	WorldState.player_max_stamina = max_value


func _on_died() -> void:
	respawn()


func _find_collision_shape():
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null
