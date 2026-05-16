extends Area2D
class_name BaseEnemy

signal died(enemy: Node)
signal damaged_player(amount: float)

const BaseEnemyConstants = preload("res://scripts/core/Constants.gd")

var hp: float = 1.0
var max_hp: float = 1.0
var speed: float = 0.0
var damage: float = 0.0
var player: Node2D
var contact_timer := 0.0
var difficulty_tier := 0
var overlapping_player := false
var radius := 10.0
var hit_flash_timer := 0.0
var damage_number_offset := 0

var damage_number_font_size := 18
var damage_number_color := Color(1.0, 0.95, 0.55)
var damage_number_shadow_color := Color(0.08, 0.02, 0.0, 0.8)
var damage_number_start_y := -34.0
var damage_number_float_y := -34.0
var damage_number_side_step := 10.0
var damage_number_x_bias := 10.0

@onready var body_shape: Polygon2D = $Body

func configure_base_stats(base_hp: float, base_speed: float, base_damage: float, body_radius: float) -> void:
	max_hp = base_hp
	hp = max_hp
	speed = base_speed
	damage = base_damage
	radius = body_radius

func configure_damage_number_style(font_size: int, font_color: Color, shadow_color: Color, start_y: float, float_y: float, side_step: float, x_bias: float) -> void:
	damage_number_font_size = font_size
	damage_number_color = font_color
	damage_number_shadow_color = shadow_color
	damage_number_start_y = start_y
	damage_number_float_y = float_y
	damage_number_side_step = side_step
	damage_number_x_bias = x_bias

func setup(target_player: Node2D) -> void:
	player = target_player

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sync_visuals()

func _process(delta: float) -> void:
	contact_timer = maxf(0.0, contact_timer - delta)
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	if is_instance_valid(player):
		global_position += global_position.direction_to(player.global_position) * speed * delta
		if overlapping_player and contact_timer <= 0.0:
			contact_timer = BaseEnemyConstants.ENEMY_CONTACT_COOLDOWN
			damaged_player.emit(damage)
	_sync_visuals()

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		overlapping_player = true

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		overlapping_player = false

func configure_spawn_tier(level: int) -> void:
	difficulty_tier = maxi(0, level)
	var hp_multiplier := 1.0 + float(difficulty_tier) * BaseEnemyConstants.ENEMY_DIFFICULTY_HP_MULTIPLIER
	max_hp *= hp_multiplier
	hp = max_hp

func get_drop_points(base_points: int) -> int:
	return base_points + difficulty_tier * BaseEnemyConstants.ENEMY_TIER_DROP_BONUS

func take_damage(amount: float) -> void:
	_play_hit_feedback(amount)
	hp -= amount
	if hp <= 0.0:
		died.emit(self)
		queue_free()

func get_hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)

func _sync_visuals() -> void:
	var flash_ratio := hit_flash_timer / 0.12
	body_shape.color = _get_body_color().lerp(Color.WHITE, clampf(flash_ratio, 0.0, 1.0))
	var draw_radius := radius + 2.0 * clampf(flash_ratio, 0.0, 1.0)
	body_shape.polygon = _circle_points(draw_radius, 64, false)

func _circle_points(point_radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * point_radius)
	return points

func _play_hit_feedback(amount: float) -> void:
	hit_flash_timer = 0.12
	_spawn_damage_number(amount)

func _spawn_damage_number(amount: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var label := Label.new()
	label.text = _format_damage(amount)
	label.add_theme_font_size_override("font_size", damage_number_font_size)
	label.add_theme_color_override("font_color", damage_number_color)
	label.add_theme_color_override("font_shadow_color", damage_number_shadow_color)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.z_index = 20
	parent.add_child(label)
	damage_number_offset = (damage_number_offset + 1) % 3
	var side_offset := float(damage_number_offset - 1) * damage_number_side_step
	label.global_position = global_position + Vector2(side_offset - damage_number_x_bias, damage_number_start_y)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(side_offset, damage_number_float_y), 0.45)
	tween.tween_property(label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(Callable(label, "queue_free"))

func _format_damage(amount: float) -> String:
	var rounded := roundf(amount)
	if is_equal_approx(amount, rounded):
		return str(int(rounded))
	return "%.1f" % amount

func _get_body_color() -> Color:
	return Color(1.0, 0.45, 0.32).lerp(Color(0.45, 0.0, 0.0), clampf(float(difficulty_tier) / 5.0, 0.0, 1.0))
