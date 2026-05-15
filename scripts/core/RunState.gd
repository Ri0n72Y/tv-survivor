extends Node

var grid_seed: int = 12345

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
var passive_slots: int = 6

var main_weapon_id: String = "projectile"

var weapons := {
	"projectile": 1,
}

var passives := {}

var grid_data: Array = []

func reset_run() -> void:
	completed_tasks = 0
	total_tasks = 3
	gold = 0
	total_score = 0
	next_battle_initial_sync = 100.0

	weapon_slots = 4
	passive_slots = 6

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

func get_weapon_level(weapon_id: String) -> int:
	return int(weapons.get(weapon_id, 0))

func get_weapon_count() -> int:
	var count := 0
	for weapon_id in weapons.keys():
		if int(weapons[weapon_id]) > 0:
			count += 1
	return count

func get_passive_count() -> int:
	var count := 0
	for passive_id in passives.keys():
		if int(passives[passive_id]) > 0:
			count += 1
	return count
