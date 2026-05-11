extends Control

signal enter_battle_requested
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const CELL_SCENE := preload("res://scenes/grid/GridCellView.tscn")

var title_label: Label
var progress_label: Label
var weapon_label: Label
var score_label: Label
var guide_label: Label
var message_label: Label
var grid_container: GridContainer
var victory_panel: Panel
var cells: Array = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_ui()
	if RunState.grid_data.is_empty():
		RunState.grid_size = Constants.GRID_SIZE
		RunState.total_tasks = Constants.TASK_COUNT
		RunState.player_grid_pos = GridGenerator.START_POS
		RunState.previous_grid_pos = RunState.player_grid_pos
		RunState.grid_data = GridGenerator.generate(RunState.grid_seed)
	_refresh_all()

func handle_battle_result(success: bool, final_sync_rate: float) -> void:
	var task_pos: Vector2i = RunState.current_task_pos
	if success and _is_inside(task_pos):
		var cell: Dictionary = RunState.grid_data[task_pos.y][task_pos.x]
		if not bool(cell.get("cleared", false)):
			cell["cleared"] = true
			RunState.completed_tasks += 1
		if final_sync_rate >= 80.0:
			GridGenerator.reveal_ring(RunState.grid_data, task_pos)
		RunState.next_battle_initial_sync = 70.0 if final_sync_rate < 30.0 else 100.0
		message_label.text = "战斗成功，同步率 %.0f" % final_sync_rate
	else:
		RunState.player_grid_pos = RunState.previous_grid_pos
		RunState.next_battle_initial_sync = 100.0
		message_label.text = "战斗失败，返回上一个格子"
	RunState.current_task_pos = Vector2i(-1, -1)
	GridGenerator.reveal_neighbors(RunState.grid_data, RunState.player_grid_pos)
	_refresh_all()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 10)
	root.offset_left = 32
	root.offset_top = 24
	root.offset_right = -32
	root.offset_bottom = -24
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 32)
	root.add_child(header)

	title_label = Label.new()
	title_label.text = "阵列探索验证"
	title_label.add_theme_font_size_override("font_size", 28)
	header.add_child(title_label)

	progress_label = Label.new()
	header.add_child(progress_label)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	header.add_child(restart_button)

	weapon_label = Label.new()
	root.add_child(weapon_label)

	score_label = Label.new()
	root.add_child(score_label)

	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.text = "操作指南：阵列界面使用 WASD / 方向键移动；只能进入已揭示的相邻非障碍格。主角默认拥有投掷物 Lv.1。进入任务点后，在战斗中移动角色、躲避敌人、收集绿色掉落物获得积分；敌人越深红越危险，击杀精英会自动收集全场掉落并触发撤离。R 重新开始。"
	root.add_child(guide_label)

	message_label = Label.new()
	message_label.text = "使用 WASD 或方向键移动到已揭示的相邻格。"
	root.add_child(message_label)

	grid_container = GridContainer.new()
	grid_container.columns = Constants.GRID_SIZE
	grid_container.custom_minimum_size = Vector2(480, 480)
	root.add_child(grid_container)

	victory_panel = Panel.new()
	victory_panel.visible = false
	victory_panel.custom_minimum_size = Vector2(520, 130)
	root.add_child(victory_panel)
	var victory_box := VBoxContainer.new()
	victory_box.name = "VictoryBox"
	victory_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_box.offset_left = 16
	victory_box.offset_top = 12
	victory_box.offset_right = -16
	victory_box.offset_bottom = -12
	victory_panel.add_child(victory_box)
	var victory_label := Label.new()
	victory_label.name = "VictoryLabel"
	victory_label.text = "验证完成"
	victory_label.add_theme_font_size_override("font_size", 24)
	victory_box.add_child(victory_label)
	var victory_detail := Label.new()
	victory_detail.name = "VictoryDetail"
	victory_box.add_child(victory_detail)
	var victory_restart := Button.new()
	victory_restart.text = "重新开始"
	victory_restart.pressed.connect(func() -> void: restart_requested.emit())
	victory_box.add_child(victory_restart)

func _refresh_all() -> void:
	_refresh_labels()
	_refresh_grid()
	_refresh_victory()

func _refresh_labels() -> void:
	progress_label.text = "任务进度：%d/%d" % [RunState.completed_tasks, RunState.total_tasks]
	weapon_label.text = "当前武器：光环 Lv.%d   投掷物 Lv.%d   固定形状 Lv.%d" % [RunState.weapons["aura"], RunState.weapons["projectile"], RunState.weapons["shape"]]
	score_label.text = "总分：%d" % RunState.total_score

func _refresh_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()
	for y in range(Constants.GRID_SIZE):
		for x in range(Constants.GRID_SIZE):
			var pos := Vector2i(x, y)
			var view := CELL_SCENE.instantiate()
			grid_container.add_child(view)
			view.setup(RunState.grid_data[y][x], pos, pos == RunState.player_grid_pos)
			cells.append(view)

func _refresh_victory() -> void:
	var won := RunState.completed_tasks >= RunState.total_tasks
	victory_panel.visible = won
	if won:
		message_label.text = "本局完成：%d/%d，验证胜利" % [RunState.completed_tasks, RunState.total_tasks]
		var detail := victory_panel.get_node("VictoryBox/VictoryDetail") as Label
		detail.text = "你完成了 3 个任务点。构筑：光环 Lv.%d / 投掷物 Lv.%d / 固定形状 Lv.%d" % [RunState.weapons["aura"], RunState.weapons["projectile"], RunState.weapons["shape"]]

func _input(event: InputEvent) -> void:
	if RunState.completed_tasks >= RunState.total_tasks:
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
	if RunState.completed_tasks >= RunState.total_tasks:
		return
	if not _can_enter(pos):
		message_label.text = "只能用键盘进入已揭示、相邻、非障碍格。"
		return
	RunState.previous_grid_pos = RunState.player_grid_pos
	RunState.player_grid_pos = pos
	GridGenerator.reveal_neighbors(RunState.grid_data, pos)
	var cell: Dictionary = RunState.grid_data[pos.y][pos.x]
	match String(cell["type"]):
		GridTypes.CELL_CHEST:
			_open_chest(cell)
		GridTypes.CELL_TASK:
			if not bool(cell.get("cleared", false)):
				RunState.current_task_pos = pos
				message_label.text = "进入任务点战斗。"
				_refresh_all()
				enter_battle_requested.emit()
				return
		_:
			message_label.text = "探索完成，迷雾已展开。"
	_refresh_all()

func _can_enter(pos: Vector2i) -> bool:
	if not _is_inside(pos):
		return false
	var distance: int = abs(pos.x - RunState.player_grid_pos.x) + abs(pos.y - RunState.player_grid_pos.y)
	if distance != 1:
		return false
	var cell: Dictionary = RunState.grid_data[pos.y][pos.x]
	if String(cell["state"]) == GridTypes.STATE_HIDDEN:
		return false
	if String(cell["type"]) == GridTypes.CELL_BLOCKED:
		return false
	return true

func _open_chest(cell: Dictionary) -> void:
	if bool(cell.get("opened", false)):
		message_label.text = "宝箱已经打开。"
		return
	var candidates := ["aura", "projectile", "shape"]
	candidates.shuffle()
	for weapon_name in candidates:
		if int(RunState.weapons[weapon_name]) < 3:
			RunState.weapons[weapon_name] = int(RunState.weapons[weapon_name]) + 1
			cell["opened"] = true
			message_label.text = "打开宝箱：%s 提升到 Lv.%d" % [_weapon_display_name(weapon_name), RunState.weapons[weapon_name]]
			return
	cell["opened"] = true
	message_label.text = "所有武器已达到 Lv.3。"

func _weapon_display_name(weapon_name: String) -> String:
	match weapon_name:
		"aura":
			return "光环"
		"projectile":
			return "投掷物"
		"shape":
			return "固定形状"
	return weapon_name

func _is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < Constants.GRID_SIZE and pos.y < Constants.GRID_SIZE
