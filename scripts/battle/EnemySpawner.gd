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
var difficulty_level := 0

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

func set_difficulty(level: int) -> void:
	difficulty_level = maxi(0, level)

func _process(delta: float) -> void:
	if not running:
		return
	elapsed += delta
	small_timer += delta
	var spawn_interval: float = maxf(Constants.SMALL_ENEMY_MIN_SPAWN_INTERVAL, Constants.SMALL_ENEMY_SPAWN_INTERVAL - float(difficulty_level) * 0.15)
	if small_timer >= spawn_interval:
		small_timer = 0.0
		_spawn(SMALL_ENEMY_SCENE)
	if not elite_spawned and elapsed >= Constants.ELITE_SPAWN_TIME:
		elite_spawned = true
		_spawn(ELITE_ENEMY_SCENE)

func _spawn(scene: PackedScene) -> void:
	if spawn_parent == null or not is_instance_valid(player):
		return
	var enemy := scene.instantiate()
	var angle := rng.randf_range(0.0, TAU)
	enemy.global_position = center + Vector2(cos(angle), sin(angle)) * radius
	spawn_parent.add_child(enemy)
	enemy.setup(player)
	if enemy.has_method("apply_difficulty"):
		enemy.apply_difficulty(difficulty_level)
	enemy_spawned.emit(enemy)
