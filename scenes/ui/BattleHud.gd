extends CanvasLayer

var sync_bar: ProgressBar
var sync_label: Label
var signal_label: Label
var time_label: Label
var score_label: Label
var weapon_label: Label
var elite_bar: ProgressBar
var elite_label: Label
var guide_label: Label

func _ready() -> void:
	var panel := Panel.new()
	panel.position = Vector2(24, 18)
	panel.size = Vector2(470, 230)
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
	sync_label = Label.new()
	box.add_child(sync_label)
	sync_bar = ProgressBar.new()
	sync_bar.max_value = 100.0
	box.add_child(sync_bar)
	signal_label = Label.new()
	box.add_child(signal_label)
	time_label = Label.new()
	box.add_child(time_label)
	weapon_label = Label.new()
	box.add_child(weapon_label)
	guide_label = Label.new()
	guide_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_label.text = "指南：WASD / 方向键移动；保持同步率，拾取绿色掉落加分；30 秒后撤离，击杀精英会自动收集并提前撤离。"
	box.add_child(guide_label)
	elite_label = Label.new()
	elite_label.text = "精英血量"
	elite_label.visible = false
	box.add_child(elite_label)
	elite_bar = ProgressBar.new()
	elite_bar.max_value = 100.0
	elite_bar.visible = false
	box.add_child(elite_bar)

func update_hud(sync_rate: float, signal_text: String, phase_text: String, weapons: Dictionary, elite_ratio: float, total_score: int) -> void:
	score_label.text = "总分：%d" % total_score
	sync_bar.value = sync_rate
	sync_label.text = "同步率：%.0f / 100" % sync_rate
	signal_label.text = signal_text
	if signal_text.contains("弱"):
		signal_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.2))
	elif signal_text.contains("断开"):
		signal_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	else:
		signal_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.text = phase_text
	weapon_label.text = "光环 Lv.%d  投掷物 Lv.%d  固定形状 Lv.%d" % [weapons["aura"], weapons["projectile"], weapons["shape"]]
	var has_elite := elite_ratio >= 0.0
	elite_label.visible = has_elite
	elite_bar.visible = has_elite
	if has_elite:
		elite_bar.value = elite_ratio * 100.0
