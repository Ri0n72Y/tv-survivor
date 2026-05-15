extends Node2D
class_name BattleChest

var opened := false
var interactable := true
var cost := 30

func setup(chest_position: Vector2, chest_cost: int) -> void:
	global_position = chest_position
	cost = chest_cost

func mark_opened() -> void:
	opened = true
	interactable = false
	queue_redraw()

func _draw() -> void:
	var body_color := Color(0.95, 0.66, 0.16) if not opened else Color(0.30, 0.22, 0.10)
	draw_rect(Rect2(Vector2(-22, -16), Vector2(44, 32)), body_color, true)
	draw_rect(Rect2(Vector2(-22, -16), Vector2(44, 32)), Color(0.08, 0.07, 0.05), false, 2.0)
	draw_line(Vector2(-22, -2), Vector2(22, -2), Color(0.08, 0.07, 0.05), 2.0)
	draw_circle(Vector2.ZERO, 4.0, Color(0.12, 0.08, 0.02))
	if not opened:
		draw_string(ThemeDB.fallback_font, Vector2(-18, -26), "%dG" % cost, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color(1.0, 0.95, 0.65))
