extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")

func _draw() -> void:
	var radius := Constants.SIGNAL_RADIUS
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.42, 0.95, 0.16))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, Color(0.25, 0.62, 1.0, 0.95), 3.0)
	draw_arc(Vector2.ZERO, radius * Constants.SIGNAL_WEAK_RATIO, 0.0, TAU, 128, Color(1.0, 0.86, 0.25, 0.24), 2.0)
