extends Node2D
class_name ExtractionPoint

var active := false
var hold_ratio := 0.0
var radius := 70.0

func setup(point_position: Vector2, point_radius: float) -> void:
	global_position = point_position
	radius = point_radius
	visible = false

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func set_hold_ratio(value: float) -> void:
	hold_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_circle(Vector2.ZERO, radius, Color(0.10, 0.90, 0.36, 0.16))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.20, 1.00, 0.45), 3.0)
	if hold_ratio > 0.0:
		draw_arc(Vector2.ZERO, radius - 8.0, -PI / 2.0, -PI / 2.0 + TAU * hold_ratio, 96, Color.WHITE, 5.0)
