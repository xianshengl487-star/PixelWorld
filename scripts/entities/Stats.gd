extends Node
class_name Stats
## Stats.gd — 基础属性组件

signal health_changed(current: int, max: int)
signal stamina_changed(current: int, max: int)
signal died

@export var max_health: int = 20
@export var health: int = 20
@export var attack: int = 4
@export var defense: int = 1
@export var move_speed: float = 150.0
@export var max_stamina: int = 10
@export var stamina: int = 10

var is_dead: bool = false


func _ready() -> void:
	health = clampi(health, 0, max_health)
	stamina = clampi(stamina, 0, max_stamina)
	is_dead = health <= 0


func configure(data: Dictionary) -> void:
	max_health = int(data.get("max_health", max_health))
	health = int(data.get("health", max_health))
	attack = int(data.get("attack", attack))
	defense = int(data.get("defense", defense))
	move_speed = float(data.get("move_speed", move_speed))
	max_stamina = int(data.get("max_stamina", max_stamina))
	stamina = int(data.get("stamina", max_stamina))
	is_dead = bool(data.get("is_dead", health <= 0))
	health = clampi(health, 0, max_health)
	stamina = clampi(stamina, 0, max_stamina)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func take_damage(amount: int) -> int:
	if is_dead:
		return 0
	var damage = max(0, amount)
	health = clampi(health - damage, 0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0:
		die()
	return damage


func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	var before = health
	health = clampi(health + amount, 0, max_health)
	if health > 0:
		is_dead = false
	health_changed.emit(health, max_health)
	return health - before


func use_stamina(amount: int) -> bool:
	if amount <= 0:
		return true
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina, max_stamina)
	return true


func restore_stamina(amount: int) -> int:
	if amount <= 0:
		return 0
	var before = stamina
	stamina = clampi(stamina + amount, 0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)
	return stamina - before


func die() -> void:
	if is_dead:
		return
	is_dead = true
	health = 0
	health_changed.emit(health, max_health)
	died.emit()


func revive(full_restore: bool = true) -> void:
	is_dead = false
	if full_restore:
		health = max_health
		stamina = max_stamina
	else:
		health = max(1, health)
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func to_dict() -> Dictionary:
	return {
		"max_health": max_health,
		"health": health,
		"attack": attack,
		"defense": defense,
		"move_speed": move_speed,
		"max_stamina": max_stamina,
		"stamina": stamina,
		"is_dead": is_dead
	}
