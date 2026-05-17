extends CanvasLayer

@onready var score_label: Label = $Root/StatusPanel/StatusBox/MainInfo/ScoreLabel
@onready var time_label: Label = $Root/StatusPanel/StatusBox/MainInfo/TimeLabel
@onready var objective_label: Label = $Root/StatusPanel/StatusBox/MainInfo/ObjectiveLabel
@onready var status_label: Label = $Root/StatusPanel/StatusBox/MainInfo/StatusLabel
@onready var sync_label: Label = $Root/StatusPanel/StatusBox/SyncInfo/SyncLabel
@onready var sync_bar: ProgressBar = $Root/StatusPanel/StatusBox/SyncInfo/SyncBar
@onready var signal_label: Label = $Root/StatusPanel/StatusBox/SyncInfo/SignalLabel
@onready var weapon_label: Label = $Root/StatusPanel/StatusBox/BuildInfo/WeaponLabel
@onready var elite_label: Label = $Root/StatusPanel/StatusBox/BuildInfo/EliteLabel
@onready var elite_bar: ProgressBar = $Root/StatusPanel/StatusBox/BuildInfo/EliteBar
@onready var guide_label: Label = $Root/GuidePanel/GuideLabel
@onready var damage_feedback: Control = $Root/DamageFeedback
@onready var damage_edges: Array[ColorRect] = [
	$Root/DamageFeedback/TopEdge,
	$Root/DamageFeedback/BottomEdge,
	$Root/DamageFeedback/LeftEdge,
	$Root/DamageFeedback/RightEdge,
]

var damage_pulse_left := 0.0
var damage_pulse_duration := 0.45
var danger_ratio := 0.0

func _ready() -> void:
	elite_label.visible = false
	elite_bar.visible = false
	elite_bar.max_value = 100.0
	damage_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_damage_feedback()

func _process(delta: float) -> void:
	damage_pulse_left = maxf(0.0, damage_pulse_left - delta)
	_update_damage_feedback()

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
	_update_danger_ratio(sync_rate, RunState.get_sync_max(), uses_sync)
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

func play_damage_feedback(_amount: float = 0.0) -> void:
	damage_pulse_left = damage_pulse_duration
	_update_damage_feedback()

func _update_danger_ratio(sync_rate: float, sync_max: float, uses_sync: bool) -> void:
	if not uses_sync or sync_max <= 0.0:
		danger_ratio = 0.0
		return
	var hp_ratio := clampf(sync_rate / sync_max, 0.0, 1.0)
	danger_ratio = clampf((0.55 - hp_ratio) / 0.45, 0.0, 1.0)

func _update_damage_feedback() -> void:
	var pulse_ratio := 0.0
	if damage_pulse_duration > 0.0:
		pulse_ratio = clampf(damage_pulse_left / damage_pulse_duration, 0.0, 1.0)
	var pulse_alpha := 0.86 * pulse_ratio * pulse_ratio
	var danger_alpha := 0.58 * danger_ratio
	var alpha := clampf(maxf(pulse_alpha, danger_alpha), 0.0, 0.9)
	for edge in damage_edges:
		edge.color = Color(0.86, 0.0, 0.0, alpha)
	if alpha <= 0.01:
		damage_feedback.visible = false
		damage_feedback.position = Vector2.ZERO
		return
	damage_feedback.visible = true
	damage_feedback.position = Vector2.ZERO

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
