extends CharacterBody2D
class_name PlayerAvatar

const Constants = preload("res://scripts/core/Constants.gd")

var controlled := true
var signal_center := Vector2(640, 360)

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
		velocity = input_vector.normalized() * Constants.PLAYER_SPEED
	else:
		velocity = global_position.direction_to(signal_center) * Constants.PLAYER_SPEED
	move_and_slide()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.0, 0.78, 0.9))
	draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 32, Color.WHITE, 2.0)
