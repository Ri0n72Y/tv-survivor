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
	_fire_burst()

func _fire_burst() -> void:
	var count := int(Constants.PROJECTILE_COUNT_LV[level])
	var damage := float(Constants.PROJECTILE_DAMAGE_LV[level])
	for i in range(count):
		if i > 0:
			await get_tree().create_timer(0.1).timeout
		if level <= 0 or not is_instance_valid(player):
			return
		var target := _nearest_enemy()
		if target == null:
			return
		var projectile := ProjectileView.new()
		player.get_parent().add_child(projectile)
		projectile.setup(player.global_position, target, damage, Constants.PROJECTILE_SPEED)

func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy in _valid_enemies():
		var enemy_node := enemy as Node2D
		var distance := enemy_node.global_position.distance_squared_to(player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy_node
	return nearest

func _valid_enemies() -> Array:
	var result: Array = []
	for enemy in enemy_provider.call():
		if is_instance_valid(enemy):
			result.append(enemy)
	return result
