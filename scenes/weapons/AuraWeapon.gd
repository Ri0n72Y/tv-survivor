extends Node2D
class_name AuraWeapon

const Constants = preload("res://scripts/core/Constants.gd")

var player: Node2D
var enemy_provider: Callable
var level := 0
var tick_timer := 0.0

func setup(target_player: Node2D, enemies_callable: Callable, weapon_level: int) -> void:
	player = target_player
	enemy_provider = enemies_callable
	level = clampi(weapon_level, 0, 3)
	tick_timer = 0.0

func _process(delta: float) -> void:
	if level <= 0 or not is_instance_valid(player):
		return
	global_position = player.global_position
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = float(Constants.AURA_TICK_LV[level]) * RunState.get_cooldown_multiplier()
		_apply_damage()
	queue_redraw()

func _apply_damage() -> void:
	var radius := float(Constants.AURA_RADIUS_LV[level])
	var damage := float(Constants.AURA_DAMAGE_LV[level]) * RunState.get_damage_multiplier()
	for enemy in enemy_provider.call():
		if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage)

func _draw() -> void:
	if level <= 0:
		return
	var radius := float(Constants.AURA_RADIUS_LV[level])
	draw_circle(Vector2.ZERO, radius, Color(0.0, 0.82, 0.9, 0.10))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.0, 0.9, 1.0, 0.55), 4.0)
