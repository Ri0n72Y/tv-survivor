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
	for child in get_children():
		child.queue_free()
	for weapon_id in WeaponDefinitions.get_ids():
		var level := RunState.get_weapon_level(weapon_id)
		if level <= 0:
			continue
		var weapon := WeaponDefinitions.instantiate_runtime(weapon_id)
		if weapon == null:
			push_error("Weapon '%s' has no valid runtime implementation." % weapon_id)
			continue
		if not weapon.has_method("setup"):
			push_error("Weapon '%s' runtime must implement setup(player, enemy_provider, level)." % weapon_id)
			weapon.free()
			continue
		add_child(weapon)
		weapon.call("setup", player, Callable(self, "get_enemies"), level)

func refresh_weapons() -> void:
	_start_weapons()
