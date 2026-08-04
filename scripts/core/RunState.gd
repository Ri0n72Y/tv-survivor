extends Node

const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")

var grid_seed: int = 0
var pending_grid_seed_text := ""
var rng_manager: RunRngManager = RunRngManagerScript.new()
var visual_rng := RandomNumberGenerator.new()
var _build_state: BuildState = BuildState.new()

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
var minimap_unlocked: bool = true

var gold: int:
	get:
		return _build_state.gold
	set(value):
		_build_state.gold = maxi(0, value)

var total_score: int:
	get:
		return _build_state.total_score
	set(value):
		_build_state.total_score = maxi(0, value)

var weapon_slots: int:
	get:
		return _build_state.weapon_slots
	set(value):
		_build_state.weapon_slots = maxi(0, value)

var passive_slots: int:
	get:
		return _build_state.passive_slots
	set(value):
		_build_state.passive_slots = maxi(0, value)

var main_weapon_id: String:
	get:
		return _build_state.main_weapon_id
	set(value):
		_build_state.set_main_weapon_id(value)

var weapons: Dictionary:
	get:
		return _build_state.get_weapons_snapshot()
	set(value):
		_build_state.replace_weapons(value)

var passives: Dictionary:
	get:
		return _build_state.get_passives_snapshot()
	set(value):
		_build_state.replace_passives(value)

func reset_run(seed_value: Variant = null) -> void:
	grid_seed = _resolve_next_seed(seed_value)
	pending_grid_seed_text = ""
	rng_manager.start_run(grid_seed)
	completed_tasks = 0
	total_tasks = 3
	next_battle_initial_sync = 100.0
	_build_state.reset()

	grid_data = []
	player_grid_pos = Vector2i.ZERO
	previous_grid_pos = Vector2i.ZERO
	current_room_cell = Vector2i.ZERO
	current_task_pos = Vector2i(-1, -1)
	current_battle_room_type = ""

func create_battle_context(room_definition_id: String = "") -> BattleContext:
	var resolved_definition_id := room_definition_id.strip_edges()
	if resolved_definition_id.is_empty():
		resolved_definition_id = current_battle_room_type
	var room_instance_id := "%d:%d" % [current_task_pos.x, current_task_pos.y]
	return BattleContext.create(
		resolved_definition_id,
		room_instance_id,
		current_battle_room_type,
		current_task_pos,
		next_battle_initial_sync
	)

func get_weapon_ids() -> Array[String]:
	return WeaponDefinitions.get_ids()

func get_passive_ids() -> Array[String]:
	return PassiveDefinitions.get_ids()

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
	return _build_state.get_weapon_level(weapon_id)

func set_weapon_level(weapon_id: String, level: int) -> void:
	_build_state.set_weapon_level(weapon_id, level)

func add_weapon(weapon_id: String, initial_level: int = 1) -> bool:
	return _build_state.add_weapon(weapon_id, initial_level)

func get_weapon_count() -> int:
	return _build_state.get_weapon_count()

func get_total_weapon_level() -> int:
	return _build_state.get_total_weapon_level()

func get_passive_count() -> int:
	return _build_state.get_passive_count()

func get_total_passive_level() -> int:
	return _build_state.get_total_passive_level()

func get_total_upgrade_level() -> int:
	return _build_state.get_total_upgrade_level()

func get_player_difficulty_level() -> int:
	return _build_state.get_player_difficulty_level()

func get_passive_level(passive_id: String) -> int:
	return _build_state.get_passive_level(passive_id)

func set_passive_level(passive_id: String, level: int) -> void:
	_build_state.set_passive_level(passive_id, level)

func add_passive(passive_id: String, initial_level: int = 1) -> bool:
	return _build_state.add_passive(passive_id, initial_level)

func spend_gold(amount: int) -> bool:
	return _build_state.spend_gold(amount)

func add_gold(base_amount: int) -> int:
	return _build_state.add_gold(base_amount)

func build_reward_pool() -> Array[Dictionary]:
	return RewardService.build_pool(_build_state)

func build_reward_options() -> Array[RewardOption]:
	return RewardService.build_options(_build_state)

func draw_reward_options(stream_name: String, count: int) -> Array[RewardOption]:
	return RewardService.draw_options(rng_stream(stream_name), _build_state, count)

func purchase_reward(
	cost: int,
	choice: Dictionary,
	allow_slot_bypass: bool = false
) -> Dictionary:
	return RewardService.purchase_and_apply(_build_state, cost, choice, allow_slot_bypass)

func purchase_reward_option(
	cost: int,
	choice: RewardOption,
	allow_slot_bypass: bool = false
) -> RewardResolution:
	return RewardService.purchase_option_and_apply(_build_state, cost, choice, allow_slot_bypass)

func apply_reward(
	choice: Dictionary,
	allow_slot_bypass: bool = false
) -> Dictionary:
	return RewardService.apply_reward(_build_state, choice, allow_slot_bypass)

func apply_reward_option(
	choice: RewardOption,
	allow_slot_bypass: bool = false
) -> RewardResolution:
	return RewardService.apply_option(_build_state, choice, allow_slot_bypass)

func get_weapons_snapshot() -> Dictionary:
	return _build_state.get_weapons_snapshot()

func get_passives_snapshot() -> Dictionary:
	return _build_state.get_passives_snapshot()

func get_build_snapshot() -> Dictionary:
	return _build_state.get_snapshot()

func get_damage_multiplier() -> float:
	return _build_state.get_damage_multiplier()

func get_cooldown_multiplier() -> float:
	return _build_state.get_cooldown_multiplier()

func get_move_speed_multiplier() -> float:
	return _build_state.get_move_speed_multiplier()

func get_pickup_radius_multiplier() -> float:
	return _build_state.get_pickup_radius_multiplier()

func get_sync_max() -> float:
	return _build_state.get_sync_max()

func get_sync_regen_multiplier() -> float:
	return _build_state.get_sync_regen_multiplier()

func get_gold_multiplier() -> float:
	return _build_state.get_gold_multiplier()

func apply_gold_gain(base_points: int) -> int:
	return _build_state.apply_gold_gain(base_points)
