extends Node2D
class_name ArenaBoundary

var arena_rect := Rect2(Vector2.ZERO, Vector2(1280, 720))

func setup(rect: Rect2) -> void:
	arena_rect = rect
	queue_redraw()

func _draw() -> void:
	draw_rect(arena_rect.grow(-8.0), Color(0.95, 0.38, 0.18, 0.12), false, 12.0)
	draw_rect(arena_rect.grow(-14.0), Color(1.0, 0.78, 0.34, 0.85), false, 3.0)
