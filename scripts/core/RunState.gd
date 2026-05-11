extends Node

var grid_seed: int = 12345

var grid_size: int = 6
var player_grid_pos: Vector2i = Vector2i.ZERO
var previous_grid_pos: Vector2i = Vector2i.ZERO
var current_task_pos: Vector2i = Vector2i(-1, -1)

var completed_tasks: int = 0
var total_tasks: int = 3

var next_battle_initial_sync: float = 100.0

var weapons := {
	"aura": 0,
	"projectile": 0,
	"shape": 0,
}

var grid_data: Array = []

func reset_run() -> void:
	completed_tasks = 0
	total_tasks = 3
	next_battle_initial_sync = 100.0
	weapons = {
		"aura": 0,
		"projectile": 0,
		"shape": 0,
	}
	grid_data = []
	player_grid_pos = Vector2i.ZERO
	previous_grid_pos = Vector2i.ZERO
	current_task_pos = Vector2i(-1, -1)
