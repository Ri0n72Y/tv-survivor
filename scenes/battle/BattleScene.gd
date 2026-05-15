extends Node2D

signal battle_finished(success: bool, final_sync_rate: float)
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const SIGNAL_AREA_SCENE := preload("res://scenes/battle/SignalArea.tscn")
const PLAYER_SCENE := preload("res://scenes/battle/PlayerAvatar.tscn")
const HUD_SCENE := preload("res://scenes/ui/BattleHud.tscn")
const WEAPON_MANAGER_SCENE := preload("res://scenes/weapons/WeaponManager.tscn")
const COLLECTIBLE_DROP_SCENE := preload("res://scenes/battle/CollectibleDrop.gd")

var signal_center := Vector2(640, 360)
var player: PlayerAvatar
var hud: Node
var sync_controller := SyncController.new()
var spawner: EnemySpawner
var weapon_manager: WeaponManager
var enemies: Array = []
var drops: Array = []
var task_time_left := Constants.TASK_DURATION
var extraction_time_left := Constants.EXTRACTION_COUNTDOWN
var extraction_active := false
var finished := false
var difficulty_stage := 0
var battle_room_type := GridTypes.CELL_TASK
var room_rules: Dictionary = {}

func _ready() -> void:
	RunState.begin_battle()
	battle_room_type = RunState.current_battle_room_type if RunState.current_battle_room_type != "" else GridTypes.CELL_TASK
	room_rules = RoomRules.for_room_type(battle_room_type)
	_build_scene()
	sync_controller.setup(RunState.next_battle_initial_sync)
	_update_difficulty()
	spawner.start()
	_update_hud()

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
	if _uses_sync():
		_update_sync(delta)
	else:
		player.controlled = true
	if extraction_active:
		extraction_time_left = maxf(0.0, extraction_time_left - delta)
		if extraction_time_left <= 0.0:
			_finish(true)
	else:
		task_time_left = maxf(0.0, task_time_left - delta)
		_update_difficulty()
		if task_time_left <= 0.0:
			if _requires_target_kill():
				_finish(false)
			else:
				_start_extraction()
	_update_hud()
	if _uses_sync() and sync_controller.sync_rate <= 0.0:
		_finish(false)

func _build_scene() -> void:
	var background := ColorRect.new()
	background.color = Color(0.045, 0.05, 0.07)
	background.size = Vector2(Constants.SCREEN_WIDTH, Constants.SCREEN_HEIGHT)
	add_child(background)
	if bool(room_rules.get(RoomRules.SHOW_SIGNAL_AREA, true)):
		var signal_area := SIGNAL_AREA_SCENE.instantiate()
		signal_area.global_position = signal_center
		add_child(signal_area)
	player = PLAYER_SCENE.instantiate()
	player.global_position = signal_center
	player.signal_center = signal_center
	player.arena_bounds_enabled = bool(room_rules.get(RoomRules.EDGE_IS_WALL, false))
	add_child(player)
	spawner = EnemySpawner.new()
	add_child(spawner)
	spawner.setup(player, self, signal_center, Constants.SIGNAL_RADIUS)
	spawner.set_room_type(battle_room_type)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	weapon_manager = WEAPON_MANAGER_SCENE.instantiate()
	add_child(weapon_manager)
	weapon_manager.setup(player, Callable(self, "get_enemies"))
	hud = HUD_SCENE.instantiate()
	add_child(hud)

func _update_difficulty() -> void:
	var elapsed := Constants.TASK_DURATION - task_time_left
	var next_stage := int(floor(elapsed / Constants.DIFFICULTY_STEP_SECONDS))
	if next_stage != difficulty_stage:
		difficulty_stage = next_stage
	spawner.set_difficulty(difficulty_stage, _get_weapon_level_sum())

func _get_weapon_level_sum() -> int:
	return RunState.get_weapon_level("projectile") + RunState.get_weapon_level("aura") + RunState.get_weapon_level("shape") + RunState.get_weapon_level("beam")

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
		if is_instance_valid(enemy) and (enemy is EliteEnemy or enemy is BossEnemy):
			elite_ratio = enemy.get_hp_ratio()
			break
	var phase_text := _get_phase_text()
	if hud.has_method("update_hud"):
		hud.update_hud(sync_controller.sync_rate, sync_controller.signal_text, phase_text, RunState.weapons, elite_ratio, RunState.gold, _uses_sync(), battle_room_type)

func _get_phase_text() -> String:
	if extraction_active:
		return "撤离倒计时：%.1f" % extraction_time_left
	var room_label := "任务"
	match battle_room_type:
		GridTypes.CELL_ELITE:
			room_label = "精英房"
		GridTypes.CELL_BOSS:
			room_label = "Boss 房"
	return "%s剩余：%.1f  难度阶段：%d（武器等级和：%d）" % [room_label, task_time_left, difficulty_stage, _get_weapon_level_sum()]

func _on_enemy_spawned(enemy: Node) -> void:
	enemies.append(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.damaged_player.connect(_on_player_damaged)

func _on_enemy_died(enemy: Node) -> void:
	var is_boss := enemy is BossEnemy
	var is_elite := enemy is EliteEnemy
	if is_elite or is_boss:
		RunState.total_score += Constants.SCORE_ELITE_KILL
	else:
		RunState.total_score += Constants.SCORE_SMALL_KILL
	var drop_points := Constants.SCORE_SMALL_DROP
	if is_boss:
		drop_points = Constants.BOSS_GOLD
	elif is_elite:
		drop_points = Constants.SCORE_ELITE_DROP
	_spawn_drop(enemy.global_position, drop_points)
	enemies.erase(enemy)
	if is_boss:
		_collect_all_drops()
		_finish(true)
		return
	if is_elite:
		_collect_all_drops()
		_start_extraction()

func _spawn_drop(drop_position: Vector2, points: int) -> void:
	var drop := COLLECTIBLE_DROP_SCENE.new()
	drop.global_position = drop_position
	add_child(drop)
	drop.setup(points, player)
	drop.collected.connect(_on_drop_collected)
	drops.append(drop)

func _on_drop_collected(drop: Node, points: int) -> void:
	drops.erase(drop)
	RunState.gold += points
	RunState.total_score += points

func _collect_all_drops() -> void:
	for drop in drops.duplicate():
		if is_instance_valid(drop) and drop.has_method("collect"):
			drop.collect()

func _start_extraction() -> void:
	if extraction_active:
		return
	extraction_active = true
	extraction_time_left = Constants.EXTRACTION_COUNTDOWN
	spawner.stop()

func _on_player_damaged(amount: float) -> void:
	if _uses_sync():
		sync_controller.apply_damage(amount)

func get_enemies() -> Array:
	enemies = enemies.filter(func(enemy: Node) -> bool: return is_instance_valid(enemy))
	return enemies

func _requires_target_kill() -> bool:
	return battle_room_type == GridTypes.CELL_ELITE or battle_room_type == GridTypes.CELL_BOSS

func _uses_sync() -> bool:
	return bool(room_rules.get(RoomRules.USES_SYNC, true))

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	spawner.stop()
	var final_sync_rate := sync_controller.sync_rate if _uses_sync() else RunState.next_battle_initial_sync
	battle_finished.emit(success, final_sync_rate)
