extends Area2D
class_name EliteEnemy

signal died(enemy: Node)
signal damaged_player(amount: float)

const Constants = preload("res://scripts/core/Constants.gd")

var hp: float = Constants.ELITE_HP
var max_hp: float = Constants.ELITE_HP
var speed: float = Constants.ELITE_SPEED
var damage: float = Constants.ELITE_DAMAGE
var player: Node2D
var contact_timer := 0.0
var radius := 22.0

func setup(target_player: Node2D) -> void:
	player = target_player

func _process(delta: float) -> void:
	contact_timer = maxf(0.0, contact_timer - delta)
	if is_instance_valid(player):
		global_position += global_position.direction_to(player.global_position) * speed * delta
		if global_position.distance_to(player.global_position) <= radius + 14.0 and contact_timer <= 0.0:
			contact_timer = Constants.ENEMY_CONTACT_COOLDOWN
			damaged_player.emit(damage)
	queue_redraw()

func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0.0:
		died.emit(self)
		queue_free()

func get_hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.78, 0.12, 0.46))
	var bar_back := Rect2(Vector2(-28, -38), Vector2(56, 6))
	draw_rect(bar_back, Color(0.12, 0.02, 0.06), true)
	draw_rect(Rect2(bar_back.position, Vector2(bar_back.size.x * get_hp_ratio(), bar_back.size.y)), Color(0.95, 0.25, 0.7), true)
	draw_rect(bar_back, Color.WHITE, false, 1.0)
