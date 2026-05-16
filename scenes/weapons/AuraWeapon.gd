extends Node2D
class_name AuraWeapon

const Constants = preload("res://scripts/core/Constants.gd")

var player: Node2D
var enemy_provider: Callable
var level := 0
var tick_timer := 0.0

@onready var fill: Polygon2D = $Fill
@onready var ring: Line2D = $Ring

func setup(target_player: Node2D, enemies_callable: Callable, weapon_level: int) -> void:
	player = target_player
	enemy_provider = enemies_callable
	level = clampi(weapon_level, 0, 3)
	tick_timer = 0.0
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func _process(delta: float) -> void:
	if level <= 0 or not is_instance_valid(player):
		return
	global_position = player.global_position
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = float(Constants.AURA_TICK_LV[level]) * RunState.get_cooldown_multiplier()
		_apply_damage()

func _apply_damage() -> void:
	var radius := float(Constants.AURA_RADIUS_LV[level])
	var damage := float(Constants.AURA_DAMAGE_LV[level]) * RunState.get_damage_multiplier()
	for enemy in enemy_provider.call():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func _sync_visuals() -> void:
	visible = level > 0
	if level <= 0:
		return
	var radius := float(Constants.AURA_RADIUS_LV[level])
	fill.polygon = _circle_points(radius, 96, false)
	ring.points = _circle_points(radius, 96, true)

func _circle_points(radius: float, segments: int, close_loop: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := segments + 1 if close_loop else segments
	for i in range(count):
		var angle := TAU * float(i % segments) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
