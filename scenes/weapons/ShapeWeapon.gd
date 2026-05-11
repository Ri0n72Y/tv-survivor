extends Node
class_name ShapeWeapon

const Constants = preload("res://scripts/core/Constants.gd")

var player: Node2D
var enemy_provider: Callable
var level := 0
var cooldown_timer := 0.0

func setup(target_player: Node2D, enemies_callable: Callable, weapon_level: int) -> void:
	player = target_player
	enemy_provider = enemies_callable
	level = clampi(weapon_level, 0, 3)
	cooldown_timer = 0.5

func _process(delta: float) -> void:
	if level <= 0 or not is_instance_valid(player):
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		cooldown_timer = float(Constants.SHAPE_COOLDOWN_LV[level])
		_trigger()

func _trigger() -> void:
	var directions := [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	if level >= 3:
		directions.append_array([Vector2(1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, 1).normalized(), Vector2(-1, -1).normalized()])
	var length := 110.0 + float(level - 1) * 30.0
	var width := 34.0
	var damage := float(Constants.SHAPE_DAMAGE_LV[level])
	for direction in directions:
		_spawn_view(direction, length, width)
		_damage_in_rect(direction.normalized(), length, width, damage)

func _spawn_view(direction: Vector2, length: float, width: float) -> void:
	var view := ShapeHitboxView.new()
	player.get_parent().add_child(view)
	view.setup(player.global_position, direction, length, width, Constants.SHAPE_DURATION)

func _damage_in_rect(direction: Vector2, length: float, width: float, damage: float) -> void:
	var perpendicular := Vector2(-direction.y, direction.x)
	for enemy in enemy_provider.call():
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - player.global_position
		var along := to_enemy.dot(direction)
		var side := absf(to_enemy.dot(perpendicular))
		if along >= 0.0 and along <= length and side <= width * 0.5 and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
