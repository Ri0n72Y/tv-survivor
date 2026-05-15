extends Node2D
class_name BeamWeapon

const Constants = preload("res://scripts/core/Constants.gd")

const BEAM_HALF_WIDTH := 2.0

var player: Node2D
var enemy_provider: Callable
var level := 0
var tick_timer := 0.0
var locked_target: Node2D

func setup(target_player: Node2D, enemies_callable: Callable, weapon_level: int) -> void:
	player = target_player
	enemy_provider = enemies_callable
	level = clampi(weapon_level, 0, 3)
	tick_timer = 0.0

func _process(delta: float) -> void:
	if level <= 0 or not is_instance_valid(player):
		return
	global_position = player.global_position
	if not _target_is_alive():
		locked_target = _find_target()
	if not _target_is_alive():
		queue_redraw()
		return
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer = float(Constants.BEAM_TICK_LV[level])
		_damage_enemies_on_beam_path()
	queue_redraw()

func _find_target() -> Node2D:
	var best_target: Node2D = null
	var best_distance := Constants.BEAM_RANGE * Constants.BEAM_RANGE
	for enemy in enemy_provider.call():
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue
		var distance := enemy_node.global_position.distance_squared_to(player.global_position)
		if distance <= best_distance:
			best_distance = distance
			best_target = enemy_node
	return best_target

func _target_is_alive() -> bool:
	return is_instance_valid(locked_target) and not locked_target.is_queued_for_deletion()

func _damage_enemies_on_beam_path() -> void:
	var start_pos := player.global_position
	var end_pos := locked_target.global_position
	var beam_damage := float(Constants.BEAM_DAMAGE_LV[level])
	for enemy in enemy_provider.call():
		if not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null or not enemy_node.has_method("take_damage"):
			continue
		if _is_enemy_on_beam_path(enemy_node, start_pos, end_pos):
			enemy_node.take_damage(beam_damage)

func _is_enemy_on_beam_path(enemy: Node2D, start_pos: Vector2, end_pos: Vector2) -> bool:
	var hit_radius := _get_enemy_hit_radius(enemy) + BEAM_HALF_WIDTH
	return _distance_squared_to_segment(enemy.global_position, start_pos, end_pos) <= hit_radius * hit_radius

func _get_enemy_hit_radius(enemy: Node2D) -> float:
	if enemy is BaseEnemy:
		return (enemy as BaseEnemy).radius
	return 10.0

func _distance_squared_to_segment(point: Vector2, start_pos: Vector2, end_pos: Vector2) -> float:
	var segment := end_pos - start_pos
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return point.distance_squared_to(start_pos)
	var t := clampf((point - start_pos).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest_point := start_pos + segment * t
	return point.distance_squared_to(closest_point)

func _draw() -> void:
	if not _target_is_alive():
		return
	var end_pos := locked_target.global_position - global_position
	draw_line(Vector2.ZERO, end_pos, Color(0.95, 0.92, 0.62, 0.85), 4.0)
	draw_line(Vector2.ZERO, end_pos, Color(1.0, 1.0, 1.0, 0.65), 1.5)
