extends Node
class_name EnemySpawner

signal enemy_spawned(enemy: Node)

const Constants = preload("res://scripts/core/Constants.gd")
const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")
const SMALL_ENEMY_SCENE := preload("res://scenes/enemies/SmallEnemy.tscn")
const ELITE_ENEMY_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")
const BOSS_ENEMY_SCENE := preload("res://scenes/enemies/BossEnemy.tscn")

var center := Vector2(640, 360)
var radius := Constants.SIGNAL_RADIUS
var player: Node2D
var spawn_parent: Node
var elapsed := 0.0
var small_timer := 0.0
var elite_spawned := false
var running := false
var rng_stream: RunRngStream
var difficulty_stage := 0
var player_total_level := 0
var room_type := "task"
var spawn_intensity := 1.0

func setup(target_player: Node2D, parent: Node, signal_center: Vector2, signal_radius: float) -> void:
	player = target_player
	spawn_parent = parent
	center = signal_center
	radius = signal_radius
	rng_stream = RunState.rng_stream(RunRngManagerScript.STREAM_BATTLE_SPAWN)

func start() -> void:
	running = true
	elapsed = 0.0
	small_timer = 0.0
	elite_spawned = false
	_spawn_initial_room_enemy()

func stop() -> void:
	running = false

func set_difficulty(stage: int, total_level: int) -> void:
	difficulty_stage = maxi(0, stage)
	player_total_level = maxi(0, total_level)

func set_room_type(value: String) -> void:
	room_type = value

func set_spawn_intensity(value: float) -> void:
	spawn_intensity = maxf(0.1, value)

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	if room_type == "task" and not elite_spawned and elapsed >= Constants.ELITE_SPAWN_TIME:
		elite_spawned = true
		_spawn(ELITE_ENEMY_SCENE, 2)
	small_timer += delta
	var spawn_interval := Constants.SMALL_ENEMY_SPAWN_INTERVAL / _get_spawn_multiplier()
	if small_timer >= spawn_interval:
		small_timer = 0.0
		_spawn(SMALL_ENEMY_SCENE, _roll_small_enemy_tier())

func _get_spawn_multiplier() -> float:
	var stage_bonus := log(float(difficulty_stage) + 1.0) * Constants.DIFFICULTY_SPAWN_LOG_MULTIPLIER
	var player_bonus := log(float(player_total_level) + 1.0) * Constants.PLAYER_LEVEL_SPAWN_LOG_MULTIPLIER
	return spawn_intensity * (1.0 + stage_bonus + player_bonus)

func _roll_small_enemy_tier() -> int:
	if difficulty_stage <= 0:
		return 0
	var tier_pressure := difficulty_stage + _get_player_level_difficulty()
	var tier_three_chance := clampf(float(tier_pressure - 5) * 0.06, 0.0, 0.18)
	if rng_stream.chance(tier_three_chance):
		return 3
	var tier_two_chance := clampf(float(tier_pressure - 2) * 0.10, 0.0, 0.35)
	if rng_stream.chance(tier_two_chance):
		return 2
	var tier_one_chance := clampf(Constants.SECOND_DIFFICULTY_SPAWN_CHANCE + float(tier_pressure) * Constants.WEAPON_LEVEL_SECOND_DIFFICULTY_CHANCE_BONUS, 0.0, 0.75)
	return 1 if rng_stream.chance(tier_one_chance) else 0

func _get_player_level_difficulty() -> int:
	if player_total_level <= 1:
		return 0
	return int(floor(log(float(player_total_level)) / log(Constants.PLAYER_LEVEL_DIFFICULTY_LOG_BASE)))

func _spawn_initial_room_enemy() -> void:
	match room_type:
		"elite":
			elite_spawned = true
			_spawn(ELITE_ENEMY_SCENE, 2)
		"boss":
			elite_spawned = true
			_spawn(BOSS_ENEMY_SCENE, 0)

func _spawn(scene: PackedScene, enemy_tier: int) -> void:
	if spawn_parent == null or not is_instance_valid(player):
		return
	var enemy := scene.instantiate()
	var angle := rng_stream.randf_range(0.0, TAU)
	enemy.global_position = center + Vector2(cos(angle), sin(angle)) * radius
	spawn_parent.add_child(enemy)
	enemy.setup(player)
	if enemy.has_method("configure_spawn_tier"):
		enemy.configure_spawn_tier(enemy_tier)
	enemy_spawned.emit(enemy)
