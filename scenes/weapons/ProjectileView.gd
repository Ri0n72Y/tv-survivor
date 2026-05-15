extends Area2D
class_name ProjectileView

const ENEMY_COLLISION_MASK := 1 << 1

var damage := 0.0
var speed := 360.0
var lifetime := 3.0
var direction := Vector2.RIGHT
var projectile_color := Color(1.0, 0.86, 0.15)
var projectile_radius := 5.0
var has_hit := false
var collision_shape: CollisionShape2D
var circle_shape: CircleShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = ENEMY_COLLISION_MASK
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	_ensure_collision_shape()

func setup(start_pos: Vector2, target_enemy: Node2D, projectile_damage: float, projectile_speed: float, color: Color = Color(1.0, 0.86, 0.15), radius: float = 5.0) -> void:
	global_position = start_pos
	damage = projectile_damage
	speed = projectile_speed
	projectile_color = color
	projectile_radius = radius
	_sync_collision_radius()
	if is_instance_valid(target_enemy):
		direction = global_position.direction_to(target_enemy.global_position)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if has_hit:
		return
	global_position += direction * speed * delta
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	if has_hit or not area.has_method("take_damage"):
		return
	has_hit = true
	area.take_damage(damage)
	queue_free()

func _ensure_collision_shape() -> void:
	if collision_shape != null:
		return
	circle_shape = CircleShape2D.new()
	collision_shape = CollisionShape2D.new()
	collision_shape.shape = circle_shape
	add_child(collision_shape)
	_sync_collision_radius()

func _sync_collision_radius() -> void:
	if circle_shape != null:
		circle_shape.radius = projectile_radius

func _draw() -> void:
	draw_circle(Vector2.ZERO, projectile_radius, projectile_color)
