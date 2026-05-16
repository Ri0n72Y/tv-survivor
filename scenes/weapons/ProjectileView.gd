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

@onready var body: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var circle_shape: CircleShape2D = collision_shape.shape

func _ready() -> void:
	collision_layer = 0
	collision_mask = ENEMY_COLLISION_MASK
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	_sync_visuals()

func setup(start_pos: Vector2, target_enemy: Node2D, projectile_damage: float, projectile_speed: float, color: Color = Color(1.0, 0.86, 0.15), radius: float = 5.0) -> void:
	global_position = start_pos
	damage = projectile_damage
	speed = projectile_speed
	projectile_color = color
	projectile_radius = radius
	if is_node_ready():
		_sync_visuals()
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

func _on_area_entered(area: Area2D) -> void:
	if has_hit or not area.has_method("take_damage"):
		return
	has_hit = true
	area.take_damage(damage)
	queue_free()

func _sync_visuals() -> void:
	body.color = projectile_color
	body.polygon = _circle_points(5.0, 32, false)
	body.scale = Vector2.ONE * (projectile_radius / 5.0)
	if circle_shape != null:
		circle_shape.radius = projectile_radius

func _circle_points(radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
