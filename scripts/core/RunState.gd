extends Node

const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")
const BuildStateScript = preload("res://scripts/build/BuildState.gd")
const BattleContextScript = preload("res://scripts/battle/BattleContext.gd")

var grid_seed: int = 0
var pending_grid_seed_text := ""
var rng_manager: RunRngManager = RunRngManagerScript.new()
var visual_rng := RandomNumberGenerator.new()
var build_state: BuildState = BuildStateScript.new()

var grid_size: int = 6
var player_grid_pos: Vector2i = Vector2i.ZERO
var previous_grid_pos: Vector2i = Vector2i.ZERO
var current_room_cell: Vector2i = Vector2i.ZERO
var current_task_pos: Vector2i = Vector2i(-1, -1)
var current_battle_room_type: String = ""

var completed_tasks: int = 0
var total_tasks: int = 3
var next_battle_initial_sync: float = 100.0
var grid_data: Array = []

# Compatibility properties keep existing gameplay scripts stable while build
# ownership moves out of the global run coordinator.
var gold: int:
	get:
		return build_state.gold
	set(value):
		build_state.gold = value

var total_score: int:
	get:
		return build_state.total_score
	set(value):
		build_state.total_score = value

var weapon_slots: int:
	get:
		return build_state.weapon_slots
	set(value):
		build_state.weapon_slots = value

var passive_slots: int:
	get:
		return build_state.passive_slots
	set(value):
		build_state.passive_slots = value

var main_weapon_id: String:
	get:
		return build_state.main_weapon_id
	set(value):
		build_state.main_weapon_id = value

var weapons: Dictionary:
	get:
		return build_state.weapons
	set(value):
		build_state.weapons = value

var passives: Dictionary:
	get:
		return build_state.passives
	set(value):
		build_state.passives = value

func reset_run(seed_value: Variant = null) -> void:
	grid_seed = _resolve_next_seed(seed_value)
	pending_grid_seed_text = ""
	rng_manager.start_run(grid_seed)
	completed_tasks = 0
	total_tasks = 3
	next_battle_initial_sync = 100.0
	build_state.reset()

	grid_data = []
	player_grid_pos = Vector2i.ZERO
	previous_grid_pos = Vector2i.ZERO
	current_room_cell = Vector2i.ZERO
	current_task_pos = Vector2i(-1, -1)
	current_battle_room_type = ""

func begin_battle() -> void:
	pass

func create_battle_context() -> BattleContext:
	return BattleContextScript.create(
		current_battle_room_type,
		current_task_pos,
		next_battle_initial_sync,
		get_player_difficulty_level(),
		grid_seed
	)

func ensure_rng_started() -> void:
	if rng_manager == null:
		rng_manager = RunRngManagerScript.new()
	if rng_manager.run_seed != grid_seed:
		rng_manager.start_run(grid_seed)

func rng_stream(stream_name: String) -> RunRngStream:
	ensure_rng_started()
	return rng_manager.get_stream(stream_name)

func rng_state() -> Dictionary:
	ensure_rng_started()
	return rng_manager.save_state()

func restore_rng_state(state_data: Dictionary) -> void:
	rng_manager.restore_state(state_data)
	grid_seed = rng_manager.run_seed
	pending_grid_seed_text = ""

func _resolve_next_seed(seed_value: Variant = null) -> int:
	if seed_value != null:
		return int(seed_value)
	var pending_text := pending_grid_seed_text.strip_edges()
	if pending_text.is_valid_int():
		return int(pending_text)
	visual_rng.randomize()
	return visual_rng.randi_range(1, 2147483647)

func get_weapon_level(weapon_id: String) -> int:
	return build_state.get_weapon_level(weapon_id)

func get_weapon_count() -> int:
	return build_state.get_weapon_count()

func get_total_weapon_level() -> int:
	return build_state.get_total_weapon_level()

func get_passive_count() -> int:
	return build_state.get_passive_count()

func get_total_passive_level() -> int:
	return build_state.get_total_passive_level()

func get_total_upgrade_level() -> int:
	return build_state.get_total_upgrade_level()

func get_player_difficulty_level() -> int:
	return build_state.get_player_difficulty_level()

func get_passive_level(passive_id: String) -> int:
	return build_state.get_passive_level(passive_id)

func set_passive_level(passive_id: String, level: int) -> void:
	build_state.set_passive_level(passive_id, level)

func get_damage_multiplier() -> float:
	return build_state.get_damage_multiplier()

func get_cooldown_multiplier() -> float:
	return build_state.get_cooldown_multiplier()

func get_move_speed_multiplier() -> float:
	return build_state.get_move_speed_multiplier()

func get_pickup_radius_multiplier() -> float:
	return build_state.get_pickup_radius_multiplier()

func get_sync_max() -> float:
	return build_state.get_sync_max()

func get_sync_regen_multiplier() -> float:
	return build_state.get_sync_regen_multiplier()

func get_gold_multiplier() -> float:
	return build_state.get_gold_multiplier()

func apply_gold_gain(base_points: int) -> int:
	return build_state.apply_gold_gain(base_points)
