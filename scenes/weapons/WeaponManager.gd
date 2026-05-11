extends Node2D
class_name WeaponManager

var player: Node2D
var enemy_provider: Callable

func setup(target_player: Node2D, enemies_callable: Callable) -> void:
	player = target_player
	enemy_provider = enemies_callable
	_start_weapons()

func get_enemies() -> Array:
	if enemy_provider.is_valid():
		return enemy_provider.call()
	return []

func _start_weapons() -> void:
	if int(RunState.weapons["aura"]) > 0:
		var aura := AuraWeapon.new()
		add_child(aura)
		aura.setup(player, Callable(self, "get_enemies"), int(RunState.weapons["aura"]))
	if int(RunState.weapons["projectile"]) > 0:
		var projectile := ProjectileWeapon.new()
		add_child(projectile)
		projectile.setup(player, Callable(self, "get_enemies"), int(RunState.weapons["projectile"]))
	if int(RunState.weapons["shape"]) > 0:
		var shape := ShapeWeapon.new()
		add_child(shape)
		shape.setup(player, Callable(self, "get_enemies"), int(RunState.weapons["shape"]))
