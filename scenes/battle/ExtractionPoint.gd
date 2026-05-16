extends Node2D
class_name ExtractionPoint

var active := false
var hold_ratio := 0.0
var radius := 70.0

@onready var fill: Polygon2D = $Fill
@onready var ring: Line2D = $Ring
@onready var progress_ring: Line2D = $ProgressRing

func setup(point_position: Vector2, point_radius: float) -> void:
	global_position = point_position
	radius = point_radius
	visible = false
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func set_active(value: bool) -> void:
	active = value
	visible = value
	_sync_visuals()

func set_hold_ratio(value: float) -> void:
	hold_ratio = clampf(value, 0.0, 1.0)
	_sync_visuals()

func _sync_visuals() -> void:
	fill.polygon = _circle_points(radius, 96, false)
	ring.points = _circle_points(radius, 96, true)
	progress_ring.visible = hold_ratio > 0.0
	progress_ring.points = _arc_points(radius - 8.0, -PI / 2.0, hold_ratio, 96)

func _circle_points(point_radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	return points

func _arc_points(point_radius: float, start_angle: float, ratio: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(2, int(ceil(float(segments) * clampf(ratio, 0.0, 1.0))) + 1)
	for i in range(count):
		var t := float(i) / float(count - 1)
		var angle := start_angle + TAU * clampf(ratio, 0.0, 1.0) * t
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	return points
