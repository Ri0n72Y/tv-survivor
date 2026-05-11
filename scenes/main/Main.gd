extends Control

const GRID_SCENE := preload("res://scenes/grid/GridScene.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/BattleScene.tscn")

var current_scene: Node
var grid_scene: Node

func _ready() -> void:
	RunState.reset_run()
	_show_grid()

func _show_grid() -> void:
	_clear_current_scene()
	grid_scene = GRID_SCENE.instantiate()
	current_scene = grid_scene
	add_child(grid_scene)
	grid_scene.enter_battle_requested.connect(_show_battle)
	grid_scene.restart_requested.connect(_restart_run)

func _show_battle() -> void:
	_clear_current_scene()
	var battle_scene := BATTLE_SCENE.instantiate()
	current_scene = battle_scene
	add_child(battle_scene)
	battle_scene.battle_finished.connect(_on_battle_finished)
	battle_scene.restart_requested.connect(_restart_run)

func _on_battle_finished(success: bool, final_sync_rate: float) -> void:
	_show_grid()
	if grid_scene.has_method("handle_battle_result"):
		grid_scene.handle_battle_result(success, final_sync_rate)

func _restart_run() -> void:
	RunState.reset_run()
	_show_grid()

func _clear_current_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
