extends Node2D
class_name ShapeHitboxView

var length := 120.0
var width := 32.0
var lifetime := 0.4

func setup(center: Vector2, direction: Vector2, hit_length: float, hit_width: float, duration: float) -> void:
	global_position = center + direction.normalized() * hit_length * 0.5
	rotation = direction.angle()
	length = hit_length
	width = hit_width
	lifetime = duration

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width))
	draw_rect(rect, Color(1.0, 0.92, 0.65, 0.24), true)
	draw_rect(rect, Color(1.0, 0.96, 0.78, 0.72), false, 2.0)
