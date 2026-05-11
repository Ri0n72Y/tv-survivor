extends Node2D
class_name CollectibleDrop

signal collected(drop: Node, points: int)

const Constants = preload("res://scripts/core/Constants.gd")

var points := 0
var player: Node2D
var radius := 8.0
var pulse_time := 0.0

func setup(drop_points: int, target_player: Node2D) -> void:
	points = drop_points
	player = target_player

func _process(delta: float) -> void:
	pulse_time += delta
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= Constants.COLLECTIBLE_PICKUP_RADIUS:
		collect()
	queue_redraw()

func collect() -> void:
	if not is_inside_tree():
		return
	collected.emit(self, points)
	queue_free()

func _draw() -> void:
	var pulse := 1.0 + sin(pulse_time * 6.0) * 0.18
	draw_circle(Vector2.ZERO, radius * pulse, Color(0.2, 0.95, 0.55))
	draw_arc(Vector2.ZERO, (radius + 4.0) * pulse, 0.0, TAU, 28, Color(0.85, 1.0, 0.45), 2.0)
