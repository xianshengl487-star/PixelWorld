extends CharacterBody2D
class_name Enemy
## Enemy.gd — v0.2.0 第一版敌人

const StatsClass = preload("res://scripts/entities/Stats.gd")
const CombatSystemClass = preload("res://scripts/combat/CombatSystem.gd")
const HealthBarClass = preload("res://scripts/ui/HealthBar.gd")

@export var enemy_id: String = ""
@export var display_name: String = "敌人"
@export var enemy_type: String = "slime"
@export var detection_radius: float = 160.0
@export var attack_range: float = 24.0
@export var attack_interval: float = 1.0

var stats = null
var _tile_size: int = 32
var _attack_timer: float = 0.0
var _sprite: ColorRect = null
var _label: Label = null
var _health_bar = null


func _ready() -> void:
	add_to_group("enemy")
	_ensure_collision()
	_ensure_stats()
	_create_visuals()
	_update_visuals()


func setup(data: Dictionary, tile_size: int = 32) -> void:
	enemy_id = data.get("id", enemy_id)
	display_name = data.get("display_name", data.get("name", display_name))
	enemy_type = data.get("enemy_type", data.get("type", enemy_type))
	_tile_size = tile_size
	var x = float(data.get("x", 0))
	var y = float(data.get("y", 0))
	position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
	_ensure_stats()
	stats.configure(_stats_for_type(enemy_type))
	_update_visuals()


func _physics_process(delta: float) -> void:
	if stats == null or stats.is_dead:
		velocity = Vector2.ZERO
		return
	_attack_timer = max(0.0, _attack_timer - delta)
	var player = _find_player()
	if player == null:
		velocity = Vector2.ZERO
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= detection_radius and dist > attack_range:
		velocity = global_position.direction_to(player.global_position) * stats.move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	if dist <= attack_range and _attack_timer <= 0.0:
		_attack_timer = attack_interval
		var result = CombatSystemClass.apply_damage(self, player)
		GameLog.add_entry("%s攻击了你，造成 %d 点伤害。" % [display_name, result.get("damage", 0)])


func take_damage(amount: int, attacker = null) -> int:
	_ensure_stats()
	var actual = stats.take_damage(amount)
	_update_health_bar()
	return actual


func get_stats():
	_ensure_stats()
	return stats


func get_display_name() -> String:
	return display_name


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
	stats.configure(_stats_for_type(enemy_type))
	if not stats.health_changed.is_connected(_on_health_changed):
		stats.health_changed.connect(_on_health_changed)
	if not stats.died.is_connected(_on_died):
		stats.died.connect(_on_died)


func _stats_for_type(t: String) -> Dictionary:
	match t:
		"wolf":
			return {"max_health": 14, "health": 14, "attack": 4, "defense": 1, "move_speed": 90.0, "max_stamina": 6, "stamina": 6}
		"bandit":
			return {"max_health": 18, "health": 18, "attack": 5, "defense": 2, "move_speed": 75.0, "max_stamina": 8, "stamina": 8}
		_:
			return {"max_health": 10, "health": 10, "attack": 2, "defense": 0, "move_speed": 55.0, "max_stamina": 4, "stamina": 4}


func _on_health_changed(current: int, max_value: int) -> void:
	_update_health_bar()


func _on_died() -> void:
	WorldState.mark_enemy_defeated(enemy_id)
	_drop_loot()
	GameLog.add_entry("%s倒下了。" % display_name)
	hide()
	set_physics_process(false)
	call_deferred("queue_free")


func _drop_loot() -> void:
	match enemy_type:
		"wolf":
			WorldState.add_item("wood", 1)
		"bandit":
			WorldState.add_item("coin", 3)
		_:
			WorldState.add_item("herb", 1)


func _find_player():
	if get_tree() == null:
		return null
	var player = get_tree().get_first_node_in_group("player")
	if player != null:
		return player
	return get_tree().root.find_child("Player", true, false)


func _ensure_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			return
	var shape_node = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	shape_node.shape = circle
	add_child(shape_node)


func _create_visuals() -> void:
	if _sprite == null:
		_sprite = ColorRect.new()
		_sprite.name = "Sprite"
		_sprite.size = Vector2(24, 20)
		_sprite.position = Vector2(-12, -10)
		add_child(_sprite)
	if _label == null:
		_label = Label.new()
		_label.name = "Label"
		_label.position = Vector2(-32, -38)
		_label.custom_minimum_size = Vector2(64, 14)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 10)
		add_child(_label)
	if _health_bar == null:
		_health_bar = Control.new()
		_health_bar.name = "HealthBar"
		_health_bar.set_script(HealthBarClass)
		_health_bar.position = Vector2(-18, -22)
		add_child(_health_bar)
	_update_health_bar()


func _update_visuals() -> void:
	if _sprite:
		match enemy_type:
			"wolf":
				_sprite.color = Color(0.45, 0.45, 0.48, 1)
			"bandit":
				_sprite.color = Color(0.65, 0.22, 0.16, 1)
			_:
				_sprite.color = Color(0.2, 0.72, 0.28, 1)
	if _label:
		_label.text = display_name
	_update_health_bar()


func _update_health_bar() -> void:
	if _health_bar and _health_bar.has_method("set_health") and stats:
		_health_bar.set_health(stats.health, stats.max_health)
