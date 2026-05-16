extends CanvasLayer

var sync_bar: ProgressBar
var sync_label: Label
var signal_label: Label
var time_label: Label
var score_label: Label
var objective_label: Label
var status_label: Label
var weapon_label: Label
var elite_bar: ProgressBar
var elite_label: Label
var guide_label: Label

func _ready() -> void:
	var panel := Panel.new()
	panel.position = Vector2(24, 18)
	panel.size = Vector2(520, 310)
	add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 12
	box.offset_top = 10
	box.offset_right = -12
	box.offset_bottom = -10
	panel.add_child(box)
	score_label = Label.new()
	box.add_child(score_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(objective_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)
	sync_label = Label.new()
	box.add_child(sync_label)
	sync_bar = ProgressBar.new()
	box.add_child(sync_bar)
	signal_label = Label.new()
	box.add_child(signal_label)
	time_label = Label.new()
	box.add_child(time_label)
	weapon_label = Label.new()
	box.add_child(weapon_label)
	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(guide_label)
	elite_label = Label.new()
	elite_label.text = "精英 / Boss 血量"
	elite_label.visible = false
	box.add_child(elite_label)
	elite_bar = ProgressBar.new()
	elite_bar.max_value = 100.0
	elite_bar.visible = false
	box.add_child(elite_bar)

func update_hud(
	sync_rate: float,
	signal_text: String,
	phase_text: String,
	_weapons: Dictionary,
	elite_ratio: float,
	gold: int,
	uses_sync: bool = true,
	room_type: String = GridTypes.CELL_TASK,
	objective_text: String = "",
	status_text: String = ""
) -> void:
	score_label.text = "金币：%d" % gold
	objective_label.text = objective_text
	status_label.text = status_text
	sync_label.visible = uses_sync
	sync_bar.visible = uses_sync
	signal_label.visible = uses_sync
	sync_bar.max_value = RunState.get_sync_max()
	sync_bar.value = sync_rate
	sync_label.text = "同步率：%.0f / %.0f" % [sync_rate, RunState.get_sync_max()]
	signal_label.text = signal_text
	if signal_text.contains("弱"):
		signal_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.2))
	elif signal_text.contains("断开"):
		signal_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	else:
		signal_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.text = phase_text
	guide_label.text = _guide_text(uses_sync, room_type)
	weapon_label.text = "武器：%d/%d  基础弹 Lv.%d  光环 Lv.%d  固定形状 Lv.%d  射线 Lv.%d\n被动：%d/%d  移速 Lv.%d  伤害 Lv.%d  冷却 Lv.%d  吸附 Lv.%d  同步 Lv.%d  金币 Lv.%d" % [RunState.get_weapon_count(), RunState.weapon_slots, RunState.get_weapon_level("projectile"), RunState.get_weapon_level("aura"), RunState.get_weapon_level("shape"), RunState.get_weapon_level("beam"), RunState.get_passive_count(), RunState.passive_slots, RunState.get_passive_level("move_speed"), RunState.get_passive_level("damage_bonus"), RunState.get_passive_level("cooldown_bonus"), RunState.get_passive_level("pickup_bonus"), RunState.get_passive_level("sync_bonus"), RunState.get_passive_level("gold_bonus")]
	var has_elite := elite_ratio >= 0.0
	elite_label.visible = has_elite
	elite_bar.visible = has_elite
	if has_elite:
		elite_bar.value = elite_ratio * 100.0

func _guide_text(uses_sync: bool, room_type: String) -> String:
	match room_type:
		GridTypes.CELL_SEARCH:
			return "指南：靠近宝箱自动开箱；宝箱消耗 30 金币；祭坛出现后站圈 3 秒激活。"
		GridTypes.CELL_BOSS:
			return "指南：封闭 Boss 竞技场；边缘是墙，清理 Boss 后胜利。"
		GridTypes.CELL_ELITE:
			return "指南：封闭精英竞技场；边缘是墙，击杀精英后选择奖励并返回阵列。"
		_:
			if uses_sync:
				return "指南：WASD / 方向键移动；保持同步率，拾取绿色掉落金币；撤离中需要等待倒计时。"
	return "指南：WASD / 方向键移动。"
