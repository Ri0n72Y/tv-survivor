extends Node2D
class_name WeaponManager

const AURA_WEAPON_SCENE := preload("res://scenes/weapons/AuraWeapon.tscn")
const BEAM_WEAPON_SCENE := preload("res://scenes/weapons/BeamWeapon.tscn")

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
	if RunState.get_weapon_level("aura") > 0:
		var aura := AURA_WEAPON_SCENE.instantiate()
		add_child(aura)
		aura.setup(player, Callable(self, "get_enemies"), RunState.get_weapon_level("aura"))
	if RunState.get_weapon_level("projectile") > 0:
		var projectile := ProjectileWeapon.new()
		add_child(projectile)
		projectile.setup(player, Callable(self, "get_enemies"), RunState.get_weapon_level("projectile"))
	if RunState.get_weapon_level("shape") > 0:
		var shape := ShapeWeapon.new()
		add_child(shape)
		shape.setup(player, Callable(self, "get_enemies"), RunState.get_weapon_level("shape"))
	if RunState.get_weapon_level("beam") > 0:
		var beam := BEAM_WEAPON_SCENE.instantiate()
		add_child(beam)
		beam.setup(player, Callable(self, "get_enemies"), RunState.get_weapon_level("beam"))

func refresh_weapons() -> void:
	_start_weapons()
