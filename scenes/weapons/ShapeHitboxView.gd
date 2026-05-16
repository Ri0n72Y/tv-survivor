extends Node2D
class_name ShapeHitboxView

var length := 120.0
var width := 32.0
var lifetime := 0.4

@onready var fill: Polygon2D = $Fill
@onready var outline: Line2D = $Outline

func setup(center: Vector2, direction: Vector2, hit_length: float, hit_width: float, duration: float) -> void:
	global_position = center + direction.normalized() * hit_length * 0.5
	rotation = direction.angle()
	length = hit_length
	width = hit_width
	lifetime = duration
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _sync_visuals() -> void:
	var half_length := length * 0.5
	var half_width := width * 0.5
	var corners := PackedVector2Array([
		Vector2(-half_length, -half_width),
		Vector2(half_length, -half_width),
		Vector2(half_length, half_width),
		Vector2(-half_length, half_width),
	])
	fill.polygon = corners
	outline.points = PackedVector2Array([
		corners[0],
		corners[1],
		corners[2],
		corners[3],
		corners[0],
	])
