extends Control

signal enter_battle_requested
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const CELL_SCENE := preload("res://scenes/grid/GridCellView.tscn")
const WEAPON_IDS: Array[String] = ["projectile", "aura", "shape", "beam"]

var title_label: Label
var progress_label: Label
var weapon_label: Label
var score_label: Label
var guide_label: Label
var message_label: Label
var grid_container: GridContainer
var victory_panel: Panel
var upgrade_overlay: Panel
var upgrade_cards_box: HBoxContainer
var upgrade_subtitle_label: Label
var cells: Array = []
var pending_chest_cell: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_ui()
	if RunState.grid_data.is_empty():
		RunState.grid_data = GridGenerator.generate(RunState.grid_seed)
		RunState.grid_size = RunState.grid_data.size()
		RunState.total_tasks = _count_cells(GridTypes.CELL_TASK)
		RunState.player_grid_pos = _find_start_pos()
		RunState.previous_grid_pos = RunState.player_grid_pos
		_prepare_chests()
	_refresh_all()

func handle_battle_result(success: bool, final_sync_rate: float) -> void:
	var room_pos: Vector2i = RunState.current_task_pos
	var room_type := RunState.current_battle_room_type
	if success and _is_inside(room_pos):
		var cell: Dictionary = RunState.grid_data[room_pos.y][room_pos.x]
		if not bool(cell.get("cleared", false)):
			cell["cleared"] = true
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_TASK:
				RunState.completed_tasks += 1
		if RoomRules.uses_sync(room_type):
			if final_sync_rate >= 80.0:
				GridGenerator.reveal_ring(RunState.grid_data, room_pos)
			RunState.next_battle_initial_sync = 70.0 if final_sync_rate < 30.0 else 100.0
			message_label.text = "战斗成功，同步率 %.0f" % final_sync_rate
		else:
			RunState.next_battle_initial_sync = 100.0
			message_label.text = "战斗成功，竞技场已清理。"
	else:
		RunState.player_grid_pos = RunState.previous_grid_pos
		RunState.next_battle_initial_sync = 100.0
		message_label.text = "战斗失败，返回上一个格子。"
	RunState.current_task_pos = Vector2i(-1, -1)
	RunState.current_room_cell = Vector2i.ZERO
	RunState.current_battle_room_type = ""
	GridGenerator.reveal_neighbors(RunState.grid_data, RunState.player_grid_pos)
	_refresh_all()

func _build_ui() -> void:
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 28)
	root.offset_left = 32
	root.offset_top = 24
	root.offset_right = -32
	root.offset_bottom = -24
	add_child(root)

	var play_column := VBoxContainer.new()
	play_column.custom_minimum_size = Vector2(540, 0)
	play_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	play_column.add_theme_constant_override("separation", 14)
	root.add_child(play_column)

	var grid_panel := Panel.new()
	grid_panel.custom_minimum_size = Vector2(540, 540)
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_column.add_child(grid_panel)

	var grid_center := CenterContainer.new()
	grid_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_center.offset_left = 20
	grid_center.offset_top = 20
	grid_center.offset_right = -20
	grid_center.offset_bottom = -20
	grid_panel.add_child(grid_center)

	grid_container = GridContainer.new()
	grid_container.columns = RunState.grid_size
	grid_container.custom_minimum_size = Vector2(480, 480)
	grid_center.add_child(grid_container)

	var restart_button := Button.new()
	restart_button.text = "重新开始"
	restart_button.custom_minimum_size = Vector2(180, 44)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	play_column.add_child(restart_button)

	var info_column := VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_column.add_theme_constant_override("separation", 12)
	root.add_child(info_column)

	title_label = Label.new()
	title_label.text = "阵列探索验证"
	title_label.add_theme_font_size_override("font_size", 28)
	info_column.add_child(title_label)

	progress_label = Label.new()
	info_column.add_child(progress_label)

	weapon_label = Label.new()
	weapon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_column.add_child(weapon_label)

	score_label = Label.new()
	info_column.add_child(score_label)

	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.text = "操作指南：阵列界面使用 WASD / 方向键移动；只能进入已揭示的相邻非障碍格。宝箱需要金币开启，战斗房会进入幸存者战斗。"
	info_column.add_child(guide_label)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.text = "使用 WASD 或方向键移动到已揭示的相邻格。"
	info_column.add_child(message_label)

	victory_panel = Panel.new()
	victory_panel.visible = false
	victory_panel.custom_minimum_size = Vector2(520, 130)
	info_column.add_child(victory_panel)
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
	victory_label.text = "Boss 已击败"
	victory_label.add_theme_font_size_override("font_size", 24)
	victory_box.add_child(victory_label)
	var victory_detail := Label.new()
	victory_detail.name = "VictoryDetail"
	victory_box.add_child(victory_detail)
	var victory_restart := Button.new()
	victory_restart.text = "重新开始"
	victory_restart.pressed.connect(func() -> void: restart_requested.emit())
	victory_box.add_child(victory_restart)

	_build_upgrade_overlay()

func _build_upgrade_overlay() -> void:
	upgrade_overlay = Panel.new()
	upgrade_overlay.visible = false
	upgrade_overlay.z_index = 100
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(upgrade_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.035, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 40
	center.offset_top = 40
	center.offset_right = -40
	center.offset_bottom = -40
	upgrade_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 360)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var title := Label.new()
	title.text = "选择一项奖励"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	upgrade_subtitle_label = Label.new()
	upgrade_subtitle_label.text = "宝箱开启消耗 %d 金币。" % Constants.NORMAL_CHEST_COST
	upgrade_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(upgrade_subtitle_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(720, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	upgrade_cards_box = HBoxContainer.new()
	upgrade_cards_box.add_theme_constant_override("separation", 12)
	scroll.add_child(upgrade_cards_box)

func _refresh_all() -> void:
	_refresh_labels()
	_refresh_grid()
	_refresh_victory()

func _refresh_labels() -> void:
	var boss_total := _count_cells(GridTypes.CELL_BOSS)
	var boss_cleared := _count_cleared_cells(GridTypes.CELL_BOSS)
	progress_label.text = "任务进度：%d/%d  Boss：%d/%d" % [RunState.completed_tasks, RunState.total_tasks, boss_cleared, boss_total]
	weapon_label.text = "武器：%d/%d  基础弹 Lv.%d  光环 Lv.%d  固定形状 Lv.%d  射线 Lv.%d\n被动：%d/%d  移速 Lv.%d  伤害 Lv.%d  冷却 Lv.%d  吸附 Lv.%d  同步 Lv.%d  金币 Lv.%d" % [RunState.get_weapon_count(), RunState.weapon_slots, RunState.get_weapon_level("projectile"), RunState.get_weapon_level("aura"), RunState.get_weapon_level("shape"), RunState.get_weapon_level("beam"), RunState.get_passive_count(), RunState.passive_slots, RunState.get_passive_level("move_speed"), RunState.get_passive_level("damage_bonus"), RunState.get_passive_level("cooldown_bonus"), RunState.get_passive_level("pickup_bonus"), RunState.get_passive_level("sync_bonus"), RunState.get_passive_level("gold_bonus")]
	score_label.text = "金币：%d" % RunState.gold

func _refresh_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()
	grid_container.columns = RunState.grid_size
	for y in range(RunState.grid_size):
		for x in range(RunState.grid_size):
			var pos := Vector2i(x, y)
			var view := CELL_SCENE.instantiate()
			grid_container.add_child(view)
			view.setup(RunState.grid_data[y][x], pos, pos == RunState.player_grid_pos)
			cells.append(view)

func _refresh_victory() -> void:
	var won := _is_run_won()
	victory_panel.visible = won
	if won:
		message_label.text = "Boss 已清理，本局结束。"
		var detail := victory_panel.get_node("VictoryBox/VictoryDetail") as Label
		detail.text = "任务完成：%d/%d。构筑：基础弹 Lv.%d / 光环 Lv.%d / 固定形状 Lv.%d / 射线 Lv.%d" % [RunState.completed_tasks, RunState.total_tasks, RunState.get_weapon_level("projectile"), RunState.get_weapon_level("aura"), RunState.get_weapon_level("shape"), RunState.get_weapon_level("beam")]

func _input(event: InputEvent) -> void:
	if upgrade_overlay != null and upgrade_overlay.visible:
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
		message_label.text = "只能用键盘进入已揭示、相邻、非障碍格。"
		return
	RunState.previous_grid_pos = RunState.player_grid_pos
	RunState.player_grid_pos = pos
	GridGenerator.reveal_neighbors(RunState.grid_data, pos)
	var cell: Dictionary = RunState.grid_data[pos.y][pos.x]
	var cell_type := String(cell["type"])
	if cell_type == GridTypes.CELL_CHEST:
		_open_chest(cell)
	elif _is_battle_room(cell_type):
		if not bool(cell.get("cleared", false)):
			_enter_battle_room(pos, cell_type)
			return
		message_label.text = "这个战斗房已经清理。"
	else:
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
			message_label.text = "进入任务点战斗。"
	call_deferred("_emit_enter_battle_requested")

func _emit_enter_battle_requested() -> void:
	enter_battle_requested.emit()

func _open_chest(cell: Dictionary) -> void:
	if bool(cell.get("opened", false)):
		message_label.text = "宝箱已经打开。"
		return
	var cost := int(cell.get("cost", Constants.NORMAL_CHEST_COST))
	if RunState.gold < cost:
		message_label.text = "金币不足：打开宝箱需要 %d 金币。" % cost
		_refresh_all()
		return
	if _build_reward_pool().is_empty():
		cell["opened"] = true
		message_label.text = "没有可用奖励。"
		_refresh_all()
		return
	pending_chest_cell = cell
	_show_upgrade_overlay(_roll_reward_choices())

func _show_upgrade_overlay(choices: Array[Dictionary]) -> void:
	for child in upgrade_cards_box.get_children():
		child.queue_free()
	if upgrade_subtitle_label != null:
		upgrade_subtitle_label.text = "宝箱开启消耗 %d 金币。" % int(pending_chest_cell.get("cost", Constants.NORMAL_CHEST_COST))
	for choice in choices:
		upgrade_cards_box.add_child(_create_upgrade_card(choice))
	upgrade_overlay.visible = true

func _create_upgrade_card(choice: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(220, 210)
	card.text = String(choice.get("label", "奖励"))
	card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var selected_choice := choice.duplicate()
	card.pressed.connect(func() -> void: _choose_chest_reward(selected_choice))
	return card

func _choose_chest_reward(choice: Dictionary) -> void:
	var cost := int(pending_chest_cell.get("cost", Constants.NORMAL_CHEST_COST))
	if RunState.gold < cost:
		upgrade_overlay.visible = false
		message_label.text = "金币不足：打开宝箱需要 %d 金币。" % cost
		_refresh_all()
		return
	RunState.gold -= cost
	match String(choice.get("kind", "")):
		"weapon":
			var weapon_id := String(choice.get("weapon_id", "projectile"))
			RunState.weapons[weapon_id] = clampi(int(choice.get("level", 1)), 1, 3)
			message_label.text = "打开宝箱：%s 提升到 Lv.%d" % [_weapon_display_name(weapon_id), RunState.get_weapon_level(weapon_id)]
		"passive":
			var passive_id := String(choice.get("passive_id", "move_speed"))
			RunState.set_passive_level(passive_id, int(choice.get("level", 1)))
			message_label.text = "打开宝箱：%s 提升到 Lv.%d" % [_passive_display_name(passive_id), RunState.get_passive_level(passive_id)]
	pending_chest_cell["opened"] = true
	upgrade_overlay.visible = false
	pending_chest_cell = {}
	_refresh_all()

func _roll_reward_choices() -> Array[Dictionary]:
	var choices := _build_reward_pool()
	choices.shuffle()
	return choices.slice(0, mini(3, choices.size()))

func _build_reward_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for weapon_id in WEAPON_IDS:
		var weapon_level := RunState.get_weapon_level(weapon_id)
		if weapon_level > 0 and weapon_level < 3:
			pool.append(_weapon_reward(weapon_id, weapon_level + 1, "升级武器"))
		elif weapon_level <= 0 and RunState.get_weapon_count() < RunState.weapon_slots:
			pool.append(_weapon_reward(weapon_id, 1, "新武器"))
	for passive_id in RunState.PASSIVE_IDS:
		var passive_level := RunState.get_passive_level(passive_id)
		if passive_level > 0 and passive_level < 3:
			pool.append(_passive_reward(passive_id, passive_level + 1, "升级被动"))
		elif passive_level <= 0 and RunState.get_passive_count() < RunState.passive_slots:
			pool.append(_passive_reward(passive_id, 1, "新被动"))
	return pool

func _weapon_reward(weapon_id: String, level: int, prefix: String) -> Dictionary:
	return {
		"kind": "weapon",
		"weapon_id": weapon_id,
		"level": level,
		"label": "%s\n%s Lv.%d\n%s" % [prefix, _weapon_display_name(weapon_id), level, _weapon_stats_text(weapon_id, level)],
	}

func _passive_reward(passive_id: String, level: int, prefix: String) -> Dictionary:
	return {
		"kind": "passive",
		"passive_id": passive_id,
		"level": level,
		"label": "%s\n%s Lv.%d\n%s" % [prefix, _passive_display_name(passive_id), level, _passive_stats_text(passive_id, level)],
	}

func _roll_upgrade_choices(count: int) -> Array[String]:
	var shuffled: Array[String] = []
	for weapon_id in WEAPON_IDS:
		shuffled.append(weapon_id)
	shuffled.shuffle()
	var choices: Array[String] = []
	for i in range(mini(count, shuffled.size())):
		choices.append(shuffled[i])
	var has_upgradable := false
	for weapon_id in choices:
		if RunState.get_weapon_level(weapon_id) < 3:
			has_upgradable = true
			break
	if not has_upgradable:
		var upgradable := _get_upgradable_weapons()
		if not upgradable.is_empty():
			choices[choices.size() - 1] = upgradable[0]
	return choices

func _get_chest_upgrade_choices(cell: Dictionary) -> Array[String]:
	var choices: Array[String] = []
	var stored_choices: Array = cell.get("upgrade_choices", [])
	for weapon_id in stored_choices:
		choices.append(String(weapon_id))
	if choices.is_empty():
		choices = _roll_upgrade_choices(3)

	var has_upgradable := false
	for weapon_id in choices:
		if RunState.get_weapon_level(weapon_id) < 3:
			has_upgradable = true
			break
	if not has_upgradable:
		var upgradable := _get_upgradable_weapons()
		if not upgradable.is_empty():
			choices[choices.size() - 1] = upgradable[0]
	return choices

func _get_upgradable_weapons() -> Array[String]:
	var result: Array[String] = []
	for weapon_id in WEAPON_IDS:
		if RunState.get_weapon_level(weapon_id) < 3:
			result.append(weapon_id)
	return result

func _upgrade_card_text(weapon_id: String) -> String:
	var level := RunState.get_weapon_level(weapon_id)
	if level <= 0:
		return "%s\n未获得\nLv.1\n%s" % [_weapon_display_name(weapon_id), _weapon_stats_text(weapon_id, 1)]
	if level >= 3:
		return "%s\n当前 Lv.3\n%s\n已满级" % [_weapon_display_name(weapon_id), _weapon_stats_text(weapon_id, 3)]
	var next_level := level + 1
	return "%s\n当前 Lv.%d\n%s\n\n升级后 Lv.%d\n%s" % [_weapon_display_name(weapon_id), level, _weapon_stats_text(weapon_id, level), next_level, _weapon_stats_text(weapon_id, next_level)]

func _weapon_stats_text(weapon_id: String, level: int) -> String:
	var safe_level := clampi(level, 1, 3)
	match weapon_id:
		"projectile":
			return "弹数 %d / 伤害 %.1f / 冷却 %.2fs" % [Constants.PROJECTILE_COUNT_LV[safe_level], Constants.PROJECTILE_DAMAGE_LV[safe_level], Constants.PROJECTILE_COOLDOWN_LV[safe_level]]
		"aura":
			return "半径 %.0f / 伤害 %.1f / 间隔 %.2fs" % [Constants.AURA_RADIUS_LV[safe_level], Constants.AURA_DAMAGE_LV[safe_level], Constants.AURA_TICK_LV[safe_level]]
		"shape":
			return "伤害 %.1f / 冷却 %.2fs / 持续 %.1fs" % [Constants.SHAPE_DAMAGE_LV[safe_level], Constants.SHAPE_COOLDOWN_LV[safe_level], Constants.SHAPE_DURATION]
		"beam":
			return "范围 %.0f / 伤害 %.1f / 间隔 %.2fs" % [Constants.BEAM_RANGE, Constants.BEAM_DAMAGE_LV[safe_level], Constants.BEAM_TICK_LV[safe_level]]
	return ""

func _weapon_display_name(weapon_name: String) -> String:
	match weapon_name:
		"aura":
			return "光环"
		"projectile":
			return "基础弹"
		"shape":
			return "固定形状"
		"beam":
			return "射线"
	return weapon_name

func _passive_display_name(passive_id: String) -> String:
	match passive_id:
		"move_speed":
			return "移动速度"
		"damage_bonus":
			return "全武器伤害"
		"cooldown_bonus":
			return "冷却缩短"
		"pickup_bonus":
			return "金币吸附"
		"sync_bonus":
			return "同步强化"
		"gold_bonus":
			return "金币收益"
	return passive_id

func _passive_stats_text(passive_id: String, level: int) -> String:
	match passive_id:
		"move_speed":
			return "移动速度 +%d%%" % int(level * 8)
		"damage_bonus":
			return "全武器伤害 +%d%%" % int(level * 12)
		"cooldown_bonus":
			return "武器冷却 -%d%%" % int(level * 8)
		"pickup_bonus":
			return "金币吸附范围 +%d%%" % int(level * 25)
		"sync_bonus":
			return "同步上限 +%d，恢复 +%d%%" % [level * 10, level * 20]
		"gold_bonus":
			return "金币收益 +%d%%" % int(level * 15)
	return ""

func _is_battle_room(cell_type: String) -> bool:
	return cell_type == GridTypes.CELL_TASK or cell_type == GridTypes.CELL_SEARCH or cell_type == GridTypes.CELL_ELITE or cell_type == GridTypes.CELL_BOSS

func _is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < RunState.grid_size and pos.y < RunState.grid_size

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
			if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_CHEST:
				if not cell.has("cost"):
					cell["cost"] = _roll_chest_cost(Vector2i(int(cell.get("x", 0)), int(cell.get("y", 0))))
				if not cell.has("upgrade_choices"):
					var choice_count := 4 if int(cell["cost"]) >= Constants.ADVANCED_CHEST_COST else 3
					cell["upgrade_choices"] = _roll_chest_upgrade_template(Vector2i(int(cell.get("x", 0)), int(cell.get("y", 0))), choice_count)

func _roll_chest_cost(pos: Vector2i) -> int:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(RunState.grid_seed + pos.x * 61031 + pos.y * 95791)
	return Constants.ADVANCED_CHEST_COST if local_rng.randf() < 0.35 else Constants.NORMAL_CHEST_COST

func _roll_chest_upgrade_template(pos: Vector2i, count: int) -> Array[String]:
	var local_rng := RandomNumberGenerator.new()
	local_rng.seed = int(RunState.grid_seed + pos.x * 92821 + pos.y * 68917)
	var shuffled: Array[String] = []
	for weapon_id in WEAPON_IDS:
		shuffled.append(weapon_id)
	for i in range(shuffled.size() - 1, 0, -1):
		var j := local_rng.randi_range(0, i)
		var tmp := shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	var result: Array[String] = []
	for i in range(mini(count, shuffled.size())):
		result.append(shuffled[i])
	return result

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
