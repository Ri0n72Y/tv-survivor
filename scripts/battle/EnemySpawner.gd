extends Node
class_name EnemySpawner

signal enemy_spawned(enemy: Node)

const Constants = preload("res://scripts/core/Constants.gd")
const SMALL_ENEMY_SCENE := preload("res://scenes/enemies/SmallEnemy.tscn")
const ELITE_ENEMY_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")

var center := Vector2(640, 360)
var radius := Constants.SIGNAL_RADIUS
var player: Node2D
var spawn_parent: Node
var elapsed := 0.0
var small_timer := 0.0
var elite_spawned := false
var running := false
var rng := RandomNumberGenerator.new()
var difficulty_stage := 0
var weapon_level_sum := 0

func setup(target_player: Node2D, parent: Node, signal_center: Vector2, signal_radius: float) -> void:
	player = target_player
	spawn_parent = parent
	center = signal_center
	radius = signal_radius
	rng.randomize()

func start() -> void:
	running = true
	elapsed = 0.0
	small_timer = 0.0
	elite_spawned = false

func stop() -> void:
	running = false

func set_difficulty(stage: int, weapon_sum: int) -> void:
	var previous_stage := difficulty_stage
	difficulty_stage = maxi(0, stage)
	weapon_level_sum = maxi(0, weapon_sum)
	if running and not elite_spawned and previous_stage < 2 and difficulty_stage >= 2:
		elite_spawned = true
		_spawn(ELITE_ENEMY_SCENE, 2)

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	small_timer += delta
	var spawn_interval := Constants.SMALL_ENEMY_SPAWN_INTERVAL / _get_spawn_multiplier()
	if small_timer >= spawn_interval:
		small_timer = 0.0
		_spawn(SMALL_ENEMY_SCENE, _roll_small_enemy_tier())

func _get_spawn_multiplier() -> float:
	if difficulty_stage >= 1:
		return Constants.FIRST_DIFFICULTY_SPAWN_MULTIPLIER
	return 1.0

func _roll_small_enemy_tier() -> int:
	if difficulty_stage <= 0:
		return 0
	var chance := Constants.SECOND_DIFFICULTY_SPAWN_CHANCE + float(weapon_level_sum) * Constants.WEAPON_LEVEL_SECOND_DIFFICULTY_CHANCE_BONUS
	if difficulty_stage >= 2:
		chance += 0.25
	return 1 if rng.randf() < clampf(chance, 0.0, 0.85) else 0

func _spawn(scene: PackedScene, enemy_tier: int) -> void:
	if spawn_parent == null or not is_instance_valid(player):
		return
	var enemy := scene.instantiate()
	var angle := rng.randf_range(0.0, TAU)
	enemy.global_position = center + Vector2(cos(angle), sin(angle)) * radius
	spawn_parent.add_child(enemy)
	enemy.setup(player)
	if enemy.has_method("configure_spawn_tier"):
		enemy.configure_spawn_tier(enemy_tier)
	enemy_spawned.emit(enemy)
