extends Control

const GRID_SCENE := preload("res://scenes/grid/GridScene.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/BattleScene.tscn")

var current_scene: Node
var grid_scene: GridScene

func _ready() -> void:
	RunState.reset_run()
	_show_grid()

func _show_grid() -> void:
	_clear_current_scene()
	grid_scene = GRID_SCENE.instantiate() as GridScene
	if grid_scene == null:
		push_error("GridScene.tscn must use GridScene.gd.")
		return
	current_scene = grid_scene
	add_child(grid_scene)
	grid_scene.enter_battle_requested.connect(_show_battle)
	grid_scene.restart_requested.connect(_restart_run)

func _show_battle() -> void:
	_clear_current_scene()
	var context := _create_current_battle_context()
	var battle_scene := BATTLE_SCENE.instantiate() as BattleScene
	if battle_scene == null:
		push_error("BattleScene.tscn must use BattleScene.gd.")
		_show_grid()
		return
	battle_scene.configure(context)
	battle_scene.battle_result_finished.connect(_on_battle_result)
	battle_scene.restart_requested.connect(_restart_run)
	current_scene = battle_scene
	add_child(battle_scene)

func _create_current_battle_context() -> BattleContext:
	var room_definition_id := RunState.current_battle_room_type
	var pos := RunState.current_task_pos
	if pos.y >= 0 and pos.y < RunState.grid_data.size() and pos.x >= 0 and pos.x < RunState.grid_data[pos.y].size():
		var cell: Dictionary = RunState.grid_data[pos.y][pos.x]
		room_definition_id = String(cell.get("definition_id", cell.get("type", room_definition_id))).strip_edges()
	return RunState.create_battle_context(room_definition_id)

func _on_battle_result(result: BattleResult) -> void:
	_show_grid()
	if grid_scene != null:
		grid_scene.apply_battle_result(result)

func _restart_run() -> void:
	RunState.reset_run()
	_show_grid()

func _clear_current_scene() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null