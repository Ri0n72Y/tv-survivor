extends Node2D
class_name CollectibleDrop

signal collected(drop: Node, points: int)

const Constants = preload("res://scripts/core/Constants.gd")

var points := 0
var player: Node2D
var pulse_time := 0.0
var collecting := false

@onready var body: Node2D = $Body
@onready var gem: Polygon2D = $Body/Gem
@onready var ring: Line2D = $Body/Ring
@onready var attract_ring: Line2D = $AttractRing

func _ready() -> void:
	gem.polygon = _circle_points(4.0, 32, false)
	ring.points = _circle_points(8.0, 48, true)
	attract_ring.points = _circle_points(8.0, 48, true)

func setup(drop_points: int, target_player: Node2D) -> void:
	points = drop_points
	player = target_player
	if is_node_ready():
		_update_visuals()

func _process(delta: float) -> void:
	pulse_time += delta
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		if distance <= Constants.COLLECTIBLE_PICKUP_RADIUS:
			collect()
			return
		if distance <= Constants.COLLECTIBLE_ATTRACT_RADIUS * RunState.get_pickup_radius_multiplier():
			collecting = true
		if collecting:
			var direction := global_position.direction_to(player.global_position)
			var step := Constants.COLLECTIBLE_ATTRACT_SPEED * delta
			global_position += direction * minf(step, distance)
	_update_visuals()

func _update_visuals() -> void:
	var pulse := 1.0 + sin(pulse_time * 6.0) * 0.18
	body.scale = Vector2.ONE * pulse
	attract_ring.visible = collecting

func collect() -> void:
	if not is_inside_tree():
		return
	collected.emit(self , points)
	queue_free()

func _circle_points(radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
