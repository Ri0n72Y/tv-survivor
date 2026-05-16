extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")

@onready var fill: Polygon2D = $Fill
@onready var outer_ring: Line2D = $OuterRing
@onready var weak_ring: Line2D = $WeakRing

func _ready() -> void:
	var signal_radius := Constants.SIGNAL_RADIUS
	fill.polygon = _circle_points(signal_radius, 96, false)
	outer_ring.points = _circle_points(signal_radius, 96, true)
	weak_ring.points = _circle_points(signal_radius * Constants.SIGNAL_WEAK_RATIO, 96, true)

func _circle_points(radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
