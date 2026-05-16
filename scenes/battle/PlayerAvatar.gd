extends CharacterBody2D
class_name PlayerAvatar

const Constants = preload("res://scripts/core/Constants.gd")

var controlled := true
var signal_center := Vector2(640, 360)
var arena_bounds_enabled := false
var arena_rect := Rect2(Vector2.ZERO, Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT))
var arena_margin := 14.0
var hit_tween: Tween

@onready var body: Polygon2D = $Body
@onready var outline: Line2D = $Outline
@onready var hit_effect: Node2D = $HitEffect
@onready var hit_effect_ring: Line2D = $HitEffect/Ring

func _ready() -> void:
	_sync_circle_visuals()
	hit_effect.visible = false

func _physics_process(_delta: float) -> void:
	if controlled:
		var input_vector := Vector2.ZERO
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input_vector.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input_vector.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vector.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vector.y += 1.0
		velocity = input_vector.normalized() * Constants.PLAYER_SPEED * RunState.get_move_speed_multiplier()
	else:
		velocity = global_position.direction_to(signal_center) * Constants.PLAYER_SPEED * RunState.get_move_speed_multiplier()
	move_and_slide()
	if arena_bounds_enabled:
		global_position.x = clampf(global_position.x, arena_rect.position.x + arena_margin, arena_rect.end.x - arena_margin)
		global_position.y = clampf(global_position.y, arena_rect.position.y + arena_margin, arena_rect.end.y - arena_margin)

func play_hit_feedback(duration: float) -> void:
	if hit_tween != null and hit_tween.is_valid():
		hit_tween.kill()
	body.modulate = Color(1.0, 0.35, 0.35)
	outline.default_color = Color(1.0, 0.95, 0.55)
	hit_effect.visible = true
	hit_effect.scale = Vector2.ONE
	hit_effect.modulate = Color(1.0, 0.18, 0.12, 0.9)
	hit_tween = create_tween()
	hit_tween.set_parallel(true)
	hit_tween.tween_property(body, "modulate", Color.WHITE, duration)
	hit_tween.tween_property(outline, "default_color", Color.WHITE, duration)
	hit_tween.tween_property(hit_effect, "scale", Vector2.ONE * 2.2, duration)
	hit_tween.tween_property(hit_effect, "modulate:a", 0.0, duration)
	hit_tween.set_parallel(false)
	hit_tween.tween_callback(func() -> void:
		hit_effect.visible = false
		hit_effect.modulate = Color.WHITE
	)

func _sync_circle_visuals() -> void:
	var player_radius := 14.0
	var points := _circle_points(player_radius, 64, true)
	body.polygon = _circle_points(player_radius, 64, false)
	outline.points = points
	hit_effect_ring.points = _circle_points(player_radius + 4.0, 64, true)

func _circle_points(radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
