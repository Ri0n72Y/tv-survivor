extends Node2D
class_name BattleAltar

const Constants = preload("res://scripts/core/Constants.gd")

var activated := false
var completed := false
var visible_ring := false
var hold_ratio := 0.0

@onready var range_fill: Polygon2D = $RangeFill
@onready var range_ring: Line2D = $RangeRing
@onready var progress_ring: Line2D = $ProgressRing
@onready var core_fill: Polygon2D = $CoreFill
@onready var core_ring: Line2D = $CoreRing
@onready var glyph: Line2D = $Glyph

func setup(altar_position: Vector2) -> void:
	global_position = altar_position
	visible = false
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func set_activated(value: bool) -> void:
	activated = value
	visible = true
	_sync_visuals()

func set_completed(value: bool) -> void:
	completed = value
	visible = true
	_sync_visuals()

func set_available(value: bool) -> void:
	visible_ring = value
	visible = value
	_sync_visuals()

func set_hold_ratio(value: float) -> void:
	hold_ratio = clampf(value, 0.0, 1.0)
	_sync_visuals()

func _sync_visuals() -> void:
	var color := Color(0.72, 0.22, 0.95)
	if activated:
		color = Color(0.95, 0.32, 0.18)
	if completed:
		color = Color(0.20, 0.86, 0.42)
	range_fill.color = Color(color.r, color.g, color.b, 0.10)
	range_ring.default_color = color
	core_fill.color = Color(color.r, color.g, color.b, 0.24)
	core_ring.default_color = color
	glyph.default_color = color
	range_fill.polygon = _circle_points(Constants.BATTLE_INTERACT_RADIUS, 96, false)
	range_ring.points = _circle_points(Constants.BATTLE_INTERACT_RADIUS, 96, true)
	core_fill.polygon = _circle_points(24.0, 64, false)
	core_ring.points = _circle_points(24.0, 64, true)
	progress_ring.visible = hold_ratio > 0.0
	progress_ring.points = _arc_points(Constants.BATTLE_INTERACT_RADIUS - 8.0, -PI / 2.0, hold_ratio, 96)

func _circle_points(radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _arc_points(radius: float, start_angle: float, ratio: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(2, int(ceil(float(segments) * clampf(ratio, 0.0, 1.0))) + 1)
	for i in range(count):
		var t := float(i) / float(count - 1)
		var angle := start_angle + TAU * clampf(ratio, 0.0, 1.0) * t
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
