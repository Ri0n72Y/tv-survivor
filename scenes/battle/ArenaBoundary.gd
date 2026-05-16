extends Node2D
class_name ArenaBoundary

var arena_rect := Rect2(Vector2.ZERO, Vector2(1280, 720))

@onready var outer_line: Line2D = $OuterLine
@onready var inner_line: Line2D = $InnerLine

func setup(rect: Rect2) -> void:
	arena_rect = rect
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func _sync_visuals() -> void:
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
