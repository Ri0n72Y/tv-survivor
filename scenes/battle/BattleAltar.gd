extends Node2D
class_name BattleAltar

const Constants = preload("res://scripts/core/Constants.gd")

var activated := false
var completed := false
var visible_ring := false
var hold_ratio := 0.0

func setup(altar_position: Vector2) -> void:
	global_position = altar_position
	visible = false

func set_activated(value: bool) -> void:
	activated = value
	visible = true
	queue_redraw()

func set_completed(value: bool) -> void:
	completed = value
	visible = true
	queue_redraw()

func set_available(value: bool) -> void:
	visible_ring = value
	visible = value
	queue_redraw()

func set_hold_ratio(value: float) -> void:
	hold_ratio = clampf(value, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var color := Color(0.72, 0.22, 0.95)
	if activated:
		color = Color(0.95, 0.32, 0.18)
	if completed:
		color = Color(0.20, 0.86, 0.42)
	draw_circle(Vector2.ZERO, Constants.BATTLE_INTERACT_RADIUS, Color(color.r, color.g, color.b, 0.10))
	draw_arc(Vector2.ZERO, Constants.BATTLE_INTERACT_RADIUS, 0.0, TAU, 64, color, 2.0)
	if hold_ratio > 0.0:
		draw_arc(Vector2.ZERO, Constants.BATTLE_INTERACT_RADIUS - 8.0, -PI / 2.0, -PI / 2.0 + TAU * hold_ratio, 64, Color.WHITE, 5.0)
	draw_circle(Vector2.ZERO, 24.0, Color(color.r, color.g, color.b, 0.24))
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 48, color, 3.0)
	draw_line(Vector2(-12, 8), Vector2(0, -14), color, 3.0)
	draw_line(Vector2(0, -14), Vector2(12, 8), color, 3.0)
	draw_line(Vector2(-12, 8), Vector2(12, 8), color, 3.0)
