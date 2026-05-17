extends Node2D
class_name ArenaBoundary

var arena_rect := Rect2(Vector2.ZERO, Vector2(1280, 720))
var arena_center := Vector2(640, 360)
var arena_radius := 360.0
var use_circle := false

@onready var outer_line: Line2D = $OuterLine
@onready var inner_line: Line2D = $InnerLine

func setup(rect: Rect2) -> void:
	arena_rect = rect
	use_circle = false
	if is_node_ready():
		_sync_visuals()

func setup_circle(center: Vector2, radius: float) -> void:
	arena_center = center
	arena_radius = radius
	use_circle = true
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func _sync_visuals() -> void:
	if use_circle:
		outer_line.points = _circle_points(arena_center, arena_radius, 128)
		inner_line.points = _circle_points(arena_center, arena_radius - 8.0, 128)
		return
	outer_line.points = _rect_points(arena_rect.grow(-8.0))
	inner_line.points = _rect_points(arena_rect.grow(-14.0))

func _rect_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	])

func _circle_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments + 1):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points
