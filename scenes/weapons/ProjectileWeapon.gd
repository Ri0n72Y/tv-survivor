extends Node
class_name ProjectileWeapon

const Constants = preload("res://scripts/core/Constants.gd")

var player: Node2D
var enemy_provider: Callable
var level := 0
var cooldown_timer := 0.0

func setup(target_player: Node2D, enemies_callable: Callable, weapon_level: int) -> void:
	player = target_player
	enemy_provider = enemies_callable
	level = clampi(weapon_level, 0, 3)
	cooldown_timer = 0.2

func _process(delta: float) -> void:
	if level <= 0 or not is_instance_valid(player):
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		cooldown_timer = float(Constants.PROJECTILE_COOLDOWN_LV[level])
		_fire()

func _fire() -> void:
	var enemies := _valid_enemies()
	if enemies.is_empty():
		return
	enemies.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position)
	)
	var count := int(Constants.PROJECTILE_COUNT_LV[level])
	for i in range(count):
		var target: Node2D = enemies[min(i, enemies.size() - 1)]
		var projectile := ProjectileView.new()
		player.get_parent().add_child(projectile)
		projectile.setup(player.global_position, target, Constants.PROJECTILE_DAMAGE, Constants.PROJECTILE_SPEED)

func _valid_enemies() -> Array:
	var result: Array = []
	for enemy in enemy_provider.call():
		if is_instance_valid(enemy):
			result.append(enemy)
	return result
