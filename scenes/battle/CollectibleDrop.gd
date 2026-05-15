extends Node2D
class_name CollectibleDrop

signal collected(drop: Node, points: int)

const Constants = preload("res://scripts/core/Constants.gd")

var points := 0
var player: Node2D
var radius := 4.0
var pulse_time := 0.0
var collecting := false

func setup(drop_points: int, target_player: Node2D) -> void:
	points = drop_points
	player = target_player

func _process(delta: float) -> void:
	pulse_time += delta
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		if distance <= Constants.COLLECTIBLE_PICKUP_RADIUS:
			collect()
			return
		if distance <= Constants.COLLECTIBLE_ATTRACT_RADIUS:
			collecting = true
		if collecting:
			var direction := global_position.direction_to(player.global_position)
			var step := Constants.COLLECTIBLE_ATTRACT_SPEED * delta
			global_position += direction * minf(step, distance)
	queue_redraw()

func collect() -> void:
	if not is_inside_tree():
		return
	collected.emit(self , points)
	queue_free()

func _draw() -> void:
	var pulse := 1.0 + sin(pulse_time * 6.0) * 0.18
	draw_circle(Vector2.ZERO, radius * pulse, Color(0.2, 0.95, 0.55))
	draw_arc(Vector2.ZERO, (radius + 4.0) * pulse, 0.0, TAU, 28, Color(0.85, 1.0, 0.45), 2.0)
	if collecting:
		draw_arc(Vector2.ZERO, radius * 1.9, 0.0, TAU, 32, Color(0.2, 1.0, 0.55, 0.45), 1.5)
