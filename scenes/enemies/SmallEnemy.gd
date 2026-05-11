extends Area2D
class_name SmallEnemy

signal died(enemy: Node)
signal damaged_player(amount: float)

const Constants = preload("res://scripts/core/Constants.gd")

var hp: float = Constants.SMALL_ENEMY_HP
var max_hp: float = Constants.SMALL_ENEMY_HP
var speed: float = Constants.SMALL_ENEMY_SPEED
var damage: float = Constants.SMALL_ENEMY_DAMAGE
var player: Node2D
var contact_timer := 0.0
var radius := 10.0

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

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.28, 0.08))
