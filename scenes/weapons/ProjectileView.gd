extends Node2D
class_name ProjectileView

var target: Node2D
var damage := 0.0
var speed := 360.0
var lifetime := 3.0
var direction := Vector2.RIGHT

func setup(start_pos: Vector2, target_enemy: Node2D, projectile_damage: float, projectile_speed: float) -> void:
	global_position = start_pos
	target = target_enemy
	damage = projectile_damage
	speed = projectile_speed
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if is_instance_valid(target):
		direction = global_position.direction_to(target.global_position)
		global_position += direction * speed * delta
		if global_position.distance_to(target.global_position) <= 14.0:
			if target.has_method("take_damage"):
				target.take_damage(damage)
			queue_free()
	else:
		global_position += direction * speed * delta
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.86, 0.15))
