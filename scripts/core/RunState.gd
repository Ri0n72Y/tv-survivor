extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")

var grid_seed: int = 0
var pending_grid_seed_text := ""
var rng_manager: RunRngManager = RunRngManagerScript.new()
var visual_rng := RandomNumberGenerator.new()

var grid_size: int = 6
var player_grid_pos: Vector2i = Vector2i.ZERO
var previous_grid_pos: Vector2i = Vector2i.ZERO
var current_room_cell: Vector2i = Vector2i.ZERO
var current_task_pos: Vector2i = Vector2i(-1, -1)
var current_battle_room_type: String = ""

var completed_tasks: int = 0
var total_tasks: int = 3

var next_battle_initial_sync: float = 100.0

var gold: int = 0
var total_score: int = 0

var weapon_slots: int = 4
var passive_slots: int = 4

var main_weapon_id: String = "projectile"

var weapons := {
	"projectile": 1,
}

var passives := {}

var grid_data: Array = []

const PASSIVE_IDS: Array[String] = [
	"move_speed",
	"damage_bonus",
	"cooldown_bonus",
	"pickup_bonus",
	"sync_bonus",
	"gold_bonus",
]

func reset_run(seed_value: Variant = null) -> void:
	grid_seed = _resolve_next_seed(seed_value)
	pending_grid_seed_text = ""
	rng_manager.start_run(grid_seed)
	completed_tasks = 0
	total_tasks = 3
	gold = 0
	total_score = 0
	next_battle_initial_sync = 100.0

	weapon_slots = 4
	passive_slots = Constants.BASE_PASSIVE_SLOTS

	main_weapon_id = "projectile"
	weapons = {
		"projectile": 1,
	}
	passives = {}

	grid_data = []
	player_grid_pos = Vector2i.ZERO
	previous_grid_pos = Vector2i.ZERO
	current_room_cell = Vector2i.ZERO
	current_task_pos = Vector2i(-1, -1)
	current_battle_room_type = ""

func begin_battle() -> void:
	pass

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
	return int(weapons.get(weapon_id, 0))

func get_weapon_count() -> int:
	var count := 0
	for weapon_id in weapons.keys():
		if int(weapons[weapon_id]) > 0:
			count += 1
	return count

func get_total_weapon_level() -> int:
	var total := 0
	for weapon_id in weapons.keys():
		total += maxi(0, int(weapons[weapon_id]))
	return total

func get_passive_count() -> int:
	var count := 0
	for passive_id in passives.keys():
		if int(passives[passive_id]) > 0:
			count += 1
	return count

func get_total_passive_level() -> int:
	var total := 0
	for passive_id in passives.keys():
		total += maxi(0, int(passives[passive_id]))
	return total

func get_total_upgrade_level() -> int:
	return get_total_weapon_level() + get_total_passive_level()

func get_player_difficulty_level() -> int:
	var total_level := get_total_upgrade_level()
	if total_level <= 1:
		return 0
	return int(floor(log(float(total_level)) / log(Constants.PLAYER_LEVEL_DIFFICULTY_LOG_BASE)))

func get_passive_level(passive_id: String) -> int:
	return int(passives.get(passive_id, 0))

func set_passive_level(passive_id: String, level: int) -> void:
	if not PASSIVE_IDS.has(passive_id):
		return
	passives[passive_id] = clampi(level, 0, 3)

func get_damage_multiplier() -> float:
	return 1.0 + float(get_passive_level("damage_bonus")) * 0.12

func get_cooldown_multiplier() -> float:
	return maxf(0.5, 1.0 - float(get_passive_level("cooldown_bonus")) * 0.08)

func get_move_speed_multiplier() -> float:
	return 1.0 + float(get_passive_level("move_speed")) * 0.08

func get_pickup_radius_multiplier() -> float:
	return 1.0 + float(get_passive_level("pickup_bonus")) * 0.25

func get_sync_max() -> float:
	return Constants.SYNC_MAX + float(get_passive_level("sync_bonus")) * 10.0

func get_sync_regen_multiplier() -> float:
	return 1.0 + float(get_passive_level("sync_bonus")) * 0.20

func get_gold_multiplier() -> float:
	return 1.0 + float(get_passive_level("gold_bonus")) * 0.15

func apply_gold_gain(base_points: int) -> int:
	return maxi(1, int(round(float(base_points) * get_gold_multiplier())))
