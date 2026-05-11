extends Node2D

signal battle_finished(success: bool, final_sync_rate: float)
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const SIGNAL_AREA_SCENE := preload("res://scenes/battle/SignalArea.tscn")
const PLAYER_SCENE := preload("res://scenes/battle/PlayerAvatar.tscn")
const HUD_SCENE := preload("res://scenes/ui/BattleHud.tscn")
const WEAPON_MANAGER_SCENE := preload("res://scenes/weapons/WeaponManager.tscn")

var signal_center := Vector2(640, 360)
var player: PlayerAvatar
var hud: Node
var sync_controller := SyncController.new()
var spawner: EnemySpawner
var weapon_manager: WeaponManager
var enemies: Array = []
var remaining_time := Constants.BATTLE_DURATION
var finished := false

func _ready() -> void:
	_build_scene()
	sync_controller.setup(RunState.next_battle_initial_sync)
	spawner.start()

func _process(delta: float) -> void:
	if finished:
		return
	if Input.is_key_pressed(KEY_R):
		restart_requested.emit()
		return
	if Input.is_key_pressed(KEY_ESCAPE):
		# Debug-only escape hatch for fast editor iteration; not part of formal win/loss flow.
		_finish(false)
		return
	remaining_time = maxf(0.0, remaining_time - delta)
	_update_sync(delta)
	_update_hud()
	if sync_controller.sync_rate <= 0.0:
		_finish(false)
	elif remaining_time <= 0.0:
		_finish(true)

func _build_scene() -> void:
	var background := ColorRect.new()
	background.color = Color(0.045, 0.05, 0.07)
	background.size = Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
	add_child(background)
	var signal_area := SIGNAL_AREA_SCENE.instantiate()
	signal_area.global_position = signal_center
	add_child(signal_area)
	player = PLAYER_SCENE.instantiate()
	player.global_position = signal_center
	player.signal_center = signal_center
	add_child(player)
	spawner = EnemySpawner.new()
	add_child(spawner)
	spawner.setup(player, self, signal_center, Constants.SIGNAL_RADIUS)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	weapon_manager = WEAPON_MANAGER_SCENE.instantiate()
	add_child(weapon_manager)
	weapon_manager.setup(player, Callable(self, "get_enemies"))
	hud = HUD_SCENE.instantiate()
	add_child(hud)

func _update_sync(delta: float) -> void:
	var distance := player.global_position.distance_to(signal_center)
	sync_controller.update(delta, distance)
	player.controlled = sync_controller.control_state == BattleTypes.CONTROLLED
	if sync_controller.control_state == BattleTypes.DISCONNECTED and distance <= Constants.SIGNAL_RADIUS * Constants.SIGNAL_WEAK_RATIO:
		sync_controller.recover_from_disconnect()
		player.controlled = true

func _update_hud() -> void:
	var elite_ratio := -1.0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is EliteEnemy:
			elite_ratio = enemy.get_hp_ratio()
			break
	if hud.has_method("update_hud"):
		hud.update_hud(sync_controller.sync_rate, sync_controller.signal_text, remaining_time, RunState.weapons, elite_ratio)

func _on_enemy_spawned(enemy: Node) -> void:
	enemies.append(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.damaged_player.connect(_on_player_damaged)

func _on_enemy_died(enemy: Node) -> void:
	enemies.erase(enemy)

func _on_player_damaged(amount: float) -> void:
	sync_controller.apply_damage(amount)

func get_enemies() -> Array:
	enemies = enemies.filter(func(enemy: Node) -> bool: return is_instance_valid(enemy))
	return enemies

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	spawner.stop()
	battle_finished.emit(success, sync_controller.sync_rate)
