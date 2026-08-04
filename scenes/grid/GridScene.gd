extends Control
class_name GridScene

signal enter_battle_requested
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")
const CELL_SCENE := preload("res://scenes/grid/GridCellView.tscn")
const MINIMAP_SCENE := preload("res://scenes/ui/MiniMap.tscn")
const REWARD_OVERLAY_SCENE := preload("res://scenes/ui/RewardOverlay.tscn")

var cells: Array = []
var pending_chest_cell: Dictionary = {}
var reward_overlay: RewardOverlay
var minimap: Node
var input_locked := false
var move_tween: Tween

@onready var progress_label: Label = $Root/InfoColumn/ProgressLabel
@onready var weapon_label: Label = $Root/InfoColumn/WeaponLabel
@onready var score_label: Label = $Root/InfoColumn/ScoreLabel
@onready var message_label: Label = $Root/InfoColumn/MessageLabel
@onready var map_viewport: Control = $Root/PlayColumn/GridPanel/MapViewport
@onready var map_container: Control = $Root/PlayColumn/GridPanel/MapViewport/MapContainer
@onready var grid_container: GridContainer = $Root/PlayColumn/GridPanel/MapViewport/MapContainer/GridContainer
@onready var victory_panel: Panel = $Root/InfoColumn/VictoryPanel
@onready var current_seed_label: Label = $Root/PlayColumn/RunControls/CurrentSeedLabel
@onready var seed_input: LineEdit = $Root/PlayColumn/RunControls/SeedInput
@onready var seed_hint_label: Label = $Root/PlayColumn/RunControls/SeedHintLabel
@onready var restart_button: Button = $Root/PlayColumn/RunControls/RestartButton
@onready var victory_restart_button: Button = $Root/InfoColumn/VictoryPanel/VictoryBox/VictoryRestartButton

func _ready() -> void:
	RunState.ensure_rng_started()
	_build_ui()
	if RunState.grid_data.is_empty():
		RunState.grid_data = GridGenerator.generate(RunState.grid_seed, GridGenerator.DEFAULT_MAP_PATH, RunState.rng_manager)
		RunState.grid_size = RunState.grid_data.size()
		RunState.total_tasks = _count_cells(GridTypes.CELL_TASK)
		RunState.player_grid_pos = _find_start_pos()
		RunState.previous_grid_pos = RunState.player_grid_pos
		_prepare_chests()
	_refresh_all()
	_center_camera_instant()

func apply_battle_result(result: BattleResult) -> void:
	message_label.text = BattleResultApplicator.apply(result)
	_reveal_connections(RunState.player_grid_pos)
	input_locked = false
	get_tree().paused = false
	_refresh_all()
	_center_camera_instant()

func _build_ui() -> void:
	grid_container.columns = _grid_cols()
	victory_panel.visible = false
	reward_overlay = REWARD_OVERLAY_SCENE.instantiate()
	add_child(reward_overlay)
	reward_overlay.reward_selected.connect(_choose_chest_reward)
	current_seed_label.text = "当前：%d" % RunState.grid_seed
	seed_input.text = RunState.pending_grid_seed_text
	seed_input.text_changed.connect(_on_seed_text_changed)
	seed_input.text_submitted.connect(_on_seed_submitted)
	_refresh_seed_hint()
	restart_button.pressed.connect(_on_restart_pressed)
	victory_restart_button.pressed.connect(_on_restart_pressed)
	_build_minimap()

func _build_minimap() -> void:
	if not RunState.minimap_unlocked:
		return
	minimap = MINIMAP_SCENE.instantiate()
	add_child(minimap)

func _on_restart_pressed() -> void:
	if not _apply_seed_input():
		message_label.text = "地图种子需要填写整数。"
		return
	restart_requested.emit()

func _on_seed_text_changed(_new_text: String) -> void:
	_apply_seed_input(false)
	_refresh_seed_hint()

func _on_seed_submitted(_new_text: String) -> void:
	if not _apply_seed_input():
		message_label.text = "地图种子需要填写整数。"
	seed_input.release_focus()
	_refresh_seed_hint()

func _apply_seed_input(show_error: bool = true) -> bool:
	var seed_text := seed_input.text.strip_edges()
	RunState.pending_grid_seed_text = seed_text
	if seed_text.is_empty():
		return true
	if not seed_text.is_valid_int():
		if show_error:
			seed_hint_label.text = "请输入整数种子"
		return false
	return true

func _refresh_seed_hint() -> void:
	var seed_text := seed_input.text.strip_edges()
	if seed_text.is_empty():
		seed_hint_label.text = "留空随机"
		return
	if not seed_text.is_valid_int():
		seed_hint_label.text = "请输入整数"
		return
	if int(seed_text) == RunState.grid_seed:
		seed_hint_label.text = "当前种子"
		return
	seed_hint_label.text = "重开后生效"

func _refresh_all() -> void:
	_refresh_labels()
	_refresh_grid()
	_refresh_victory()
	_refresh_minimap()

func _refresh_labels() -> void:
	var boss_total := _count_cells(GridTypes.CELL_BOSS)
	var boss_cleared := _count_cleared_cells(GridTypes.CELL_BOSS)
	var total := _count_tree_nodes() if _is_tree_mode() else RunState.grid_data.size() * _grid_cols()
	var explored := _count_revealed_nodes()
	var cleared := _count_cleared_nodes()
	progress_label.text = "Boss：%d/%d  已清理：%d  已探索：%d/%d" % [boss_cleared, boss_total, cleared, explored, total]

	var weapon_parts: Array[String] = []
	for weapon_id in WeaponDefinitions.get_ids():
		weapon_parts.append("%s Lv.%d" % [WeaponDefinitions.get_display_name(weapon_id), RunState.get_weapon_level(weapon_id)])
	var passive_parts: Array[String] = []
	for passive_id in PassiveDefinitions.get_ids():
		passive_parts.append("%s Lv.%d" % [PassiveDefinitions.get_display_name(passive_id), RunState.get_passive_level(passive_id)])
	weapon_label.text = "武器：%d/%d  %s\n被动：%d/%d  %s" % [
		RunState.get_weapon_count(),
		RunState.weapon_slots,
		" / ".join(weapon_parts),
		RunState.get_passive_count(),
		RunState.passive_slots,
		" / ".join(passive_parts),
	]
	score_label.text = "金币：%d" % RunState.gold

func _is_tree_mode() -> bool:
	for row in RunState.grid_data:
		for cell in row:
			if not (cell.get("connections", []) as Array).is_empty():
				return true
	return false

func _count_tree_nodes() -> int:
	var count := 0
	for row in RunState.grid_data:
		for cell in row:
			if String(cell.get("type", GridTypes.CELL_EMPTY)) != GridTypes.CELL_BLOCKED:
				count += 1
	return count

func _count_revealed_nodes() -> int:
	var count := 0
	for row in RunState.grid_data:
		for cell in row:
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_BLOCKED:
				continue
			if String(cell.get("state", GridTypes.STATE_HIDDEN)) != GridTypes.STATE_HIDDEN:
				count += 1
	return count

func _count_cleared_nodes() -> int:
	var count := 0
	for row in RunState.grid_data:
		for cell in row:
			if bool(cell.get("cleared", false)):
				count += 1
	return count

func _refresh_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()
	grid_container.columns = _grid_cols()
	for y in range(RunState.grid_data.size()):
		for x in range(RunState.grid_data[y].size()):
			var pos := Vector2i(x, y)
			var cell: Dictionary = RunState.grid_data[y][x]
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_CHEST and String(cell.get("state", GridTypes.STATE_HIDDEN)) != GridTypes.STATE_HIDDEN:
				_ensure_chest_rolls(cell)
			var view := CELL_SCENE.instantiate()
			grid_container.add_child(view)
			var is_void := String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_BLOCKED and String(cell.get("state", GridTypes.STATE_HIDDEN)) == GridTypes.STATE_HIDDEN
			view.setup(cell, pos, pos == RunState.player_grid_pos and not is_void, is_void)
			cells.append(view)

func _refresh_victory() -> void:
	var won := _is_run_won()
	victory_panel.visible = won
	if not won:
		return
	message_label.text = "Boss 已清理，本局结束。"
	var build_parts: Array[String] = []
	for weapon_id in WeaponDefinitions.get_ids():
		build_parts.append("%s Lv.%d" % [WeaponDefinitions.get_display_name(weapon_id), RunState.get_weapon_level(weapon_id)])
	var detail := victory_panel.get_node("VictoryBox/VictoryDetail") as Label
	detail.text = "任务完成：%d/%d。构筑：%s" % [RunState.completed_tasks, RunState.total_tasks, " / ".join(build_parts)]

func _refresh_minimap() -> void:
	if minimap != null and minimap.has_method("refresh"):
		minimap.refresh(RunState.grid_data, RunState.player_grid_pos)

func _input(event: InputEvent) -> void:
	if input_locked:
		return
	if reward_overlay != null and reward_overlay.visible:
		return
	if seed_input != null and seed_input.has_focus():
		return
	if _is_run_won():
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var direction := Vector2i.ZERO
	match event.keycode:
		KEY_W, KEY_UP:
			direction = Vector2i.UP
		KEY_S, KEY_DOWN:
			direction = Vector2i.DOWN
		KEY_A, KEY_LEFT:
			direction = Vector2i.LEFT
		KEY_D, KEY_RIGHT:
			direction = Vector2i.RIGHT
		_:
			return
	get_viewport().set_input_as_handled()
	_try_enter_cell(RunState.player_grid_pos + direction)

func _try_enter_cell(pos: Vector2i) -> void:
	if _is_run_won():
		return
	if not _can_enter(pos):
		message_label.text = "只能进入已揭示、有连接的非障碍格。"
		return
	_animate_move(pos)

func _can_enter(pos: Vector2i) -> bool:
	if not _is_inside(pos):
		return false
	var cell: Dictionary = RunState.grid_data[pos.y][pos.x]
	if String(cell.get("state", GridTypes.STATE_HIDDEN)) == GridTypes.STATE_HIDDEN:
		return false
	if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_BLOCKED:
		return false
	var current_cell: Dictionary = RunState.grid_data[RunState.player_grid_pos.y][RunState.player_grid_pos.x]
	var current_connections: Array = current_cell.get("connections", [])
	if not current_connections.is_empty():
		return current_connections.has(pos)
	return abs(pos.x - RunState.player_grid_pos.x) + abs(pos.y - RunState.player_grid_pos.y) == 1

func _animate_move(target_pos: Vector2i) -> void:
	input_locked = true
	RunState.previous_grid_pos = RunState.player_grid_pos
	if move_tween != null:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.set_parallel()
	RunState.player_grid_pos = target_pos
	_reveal_connections(target_pos)
	_animate_camera_to(target_pos)
	var cell: Dictionary = RunState.grid_data[target_pos.y][target_pos.x]
	var cell_type := String(cell.get("type", GridTypes.CELL_EMPTY))
	move_tween.chain().tween_callback(func():
		_refresh_grid()
		input_locked = false
		if cell_type == GridTypes.CELL_CHEST:
			_open_chest(cell)
			_refresh_all()
		elif _is_battle_room(cell_type):
			if not bool(cell.get("cleared", false)):
				_enter_battle_room(target_pos, cell_type)
			else:
				message_label.text = "这个战斗房已经清理。"
				_refresh_all()
		else:
			message_label.text = "探索完成。"
			_refresh_all()
	)

func _reveal_connections(pos: Vector2i) -> void:
	if not _is_inside(pos):
		return
	var connections: Array = RunState.grid_data[pos.y][pos.x].get("connections", [])
	if not connections.is_empty():
		GridGenerator.reveal_neighbors_tree(RunState.grid_data, pos)
	else:
		GridGenerator.reveal_neighbors(RunState.grid_data, pos)

func _animate_camera_to(grid_pos: Vector2i) -> void:
	var target_offset := _viewport_center_for_map() - _cell_world_position(grid_pos)
	move_tween.tween_property(map_container, "position", target_offset, Constants.GRID_CAMERA_TWEEN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _center_camera_instant() -> void:
	if map_container == null:
		return
	map_container.position = _viewport_center_for_map() - _cell_world_position(RunState.player_grid_pos)

func _cell_world_position(grid_pos: Vector2i) -> Vector2:
	var stride := Constants.GRID_CELL_SIZE + Constants.GRID_CELL_MARGIN
	return Vector2(grid_pos.x * stride + stride * 0.5, grid_pos.y * stride + stride * 0.5)

func _viewport_center_for_map() -> Vector2:
	return map_viewport.size * 0.5 if map_viewport != null else Vector2(260, 250)

func _enter_battle_room(pos: Vector2i, cell_type: String) -> void:
	RunState.current_task_pos = pos
	RunState.current_room_cell = pos
	RunState.current_battle_room_type = cell_type
	match cell_type:
		GridTypes.CELL_ELITE:
			message_label.text = "进入精英房。"
		GridTypes.CELL_BOSS:
			message_label.text = "进入 Boss 房。"
		GridTypes.CELL_SEARCH:
			message_label.text = "进入搜索房。"
		_:
			message_label.text = "进入战斗。"
	call_deferred("_emit_enter_battle_requested")

func _emit_enter_battle_requested() -> void:
	enter_battle_requested.emit()

func _open_chest(cell: Dictionary) -> void:
	if bool(cell.get("opened", false)):
		message_label.text = "宝箱已经打开。"
		return
	_ensure_chest_rolls(cell)
	var cost := int(cell.get("cost", Constants.NORMAL_CHEST_COST))
	if RunState.gold < cost:
		message_label.text = "金币不足：打开宝箱需要 %d 金币。" % cost
		_refresh_all()
		return
	if RunState.build_reward_pool().is_empty():
		cell["opened"] = true
		message_label.text = "没有可用奖励。"
		_refresh_all()
		return
	pending_chest_cell = cell
	_show_reward_overlay(_roll_reward_choices())

func _show_reward_overlay(choices: Array[Dictionary]) -> void:
	get_tree().paused = true
	var cost := int(pending_chest_cell.get("cost", Constants.NORMAL_CHEST_COST))
	reward_overlay.show_choices("阵列宝箱", "选择后消耗 %d 金币" % cost, choices)

func _choose_chest_reward(choice: Dictionary) -> void:
	var cost := int(pending_chest_cell.get("cost", Constants.NORMAL_CHEST_COST))
	var result := RunState.purchase_reward(cost, choice)
	reward_overlay.hide_overlay()
	get_tree().paused = false
	if not bool(result.get("success", false)):
		message_label.text = String(result.get("message", "奖励应用失败。"))
		pending_chest_cell = {}
		_refresh_all()
		return
	pending_chest_cell["opened"] = true
	message_label.text = "打开宝箱：%s" % String(result.get("message", "获得奖励。"))
	pending_chest_cell = {}
	_refresh_all()

func _roll_reward_choices() -> Array[Dictionary]:
	var choices := RunState.build_reward_pool()
	var choice_count := int(pending_chest_cell.get("upgrade_choice_count", 3))
	var drawn := RandomPool.draw(RunState.rng_stream(RunRngManagerScript.STREAM_CHEST_REWARD), choices, {
		"count": mini(choice_count, choices.size()),
		"allow_repeats": false,
	})
	var result: Array[Dictionary] = []
	for choice in drawn:
		result.append(choice as Dictionary)
	return result

func _is_battle_room(cell_type: String) -> bool:
	return GridTypes.BATTLE_ROOMS.has(cell_type)

func _is_inside(pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < RunState.grid_data.size() and pos.x >= 0 and pos.x < RunState.grid_data[pos.y].size()

func _grid_cols() -> int:
	return RunState.grid_size if RunState.grid_data.is_empty() else int(RunState.grid_data[0].size())

func _find_start_pos() -> Vector2i:
	for y in range(RunState.grid_data.size()):
		for x in range(RunState.grid_data[y].size()):
			if String(RunState.grid_data[y][x].get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_START:
				return Vector2i(x, y)
	return GridGenerator.START_POS

func _count_cells(cell_type: String) -> int:
	var count := 0
	for row in RunState.grid_data:
		for cell in row:
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == cell_type:
				count += 1
	return count

func _prepare_chests() -> void:
	for row in RunState.grid_data:
		for cell in row:
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_CHEST and not cell.has("opened"):
				cell["opened"] = false

func _ensure_chest_rolls(cell: Dictionary) -> void:
	if cell.has("cost"):
		return
	cell["cost"] = _roll_chest_cost()
	cell["upgrade_choice_count"] = 4 if int(cell["cost"]) >= Constants.ADVANCED_CHEST_COST else 3

func _roll_chest_cost() -> int:
	var chest_type_stream := RunState.rng_stream(RunRngManagerScript.STREAM_CHEST_TYPE)
	var base_cost := Constants.ADVANCED_CHEST_COST if chest_type_stream.chance(0.35) else Constants.NORMAL_CHEST_COST
	return base_cost + RunState.get_player_difficulty_level() * Constants.GRID_CHEST_COST_PER_DIFFICULTY

func _count_cleared_cells(cell_type: String) -> int:
	var count := 0
	for row in RunState.grid_data:
		for cell in row:
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == cell_type and bool(cell.get("cleared", false)):
				count += 1
	return count

func _is_run_won() -> bool:
	var boss_total := _count_cells(GridTypes.CELL_BOSS)
	return boss_total > 0 and _count_cleared_cells(GridTypes.CELL_BOSS) >= boss_total
