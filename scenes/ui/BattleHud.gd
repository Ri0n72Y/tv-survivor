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
var danger_target := 0.0
var danger_rise_speed := 0.8
var danger_fall_speed := 1.6

func _ready() -> void:
	elite_label.visible = false
	elite_bar.visible = false
	elite_bar.max_value = 100.0
	damage_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_update_damage_feedback()

func _process(delta: float) -> void:
	damage_pulse_left = maxf(0.0, damage_pulse_left - delta)
	var danger_speed := danger_rise_speed if danger_target > danger_ratio else danger_fall_speed
	danger_ratio = move_toward(danger_ratio, danger_target, danger_speed * delta)
	_update_damage_feedback()

func update_hud(
	sync_rate: float,
	signal_text: String,
	phase_text: String,
	build_snapshot: Dictionary,
	elite_ratio: float,
	gold: int,
	uses_sync: bool = true,
	room_type: String = GridTypes.CELL_TASK,
	objective_text: String = "",
	status_text: String = "",
	active_buffs: Array[Dictionary] = []
) -> void:
	var sync_max := _sync_max_from_snapshot(build_snapshot)
	score_label.text = "金币：%d" % gold
	objective_label.text = objective_text
	status_label.text = status_text
	sync_label.visible = uses_sync
	sync_bar.visible = uses_sync
	signal_label.visible = uses_sync
	sync_bar.max_value = sync_max
	sync_bar.value = sync_rate
	sync_label.text = "同步率：%.0f / %.0f" % [sync_rate, sync_max]
	_update_danger_target(sync_rate, sync_max, signal_text, uses_sync)
	signal_label.text = signal_text
	var buff_summary := _buff_summary(active_buffs)
	if not buff_summary.is_empty():
		signal_label.text = "%s  %s" % [signal_text, buff_summary]
	if signal_text.contains("下降") or signal_text.contains("弱"):
		signal_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.2))
	elif signal_text.contains("断开"):
		signal_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	else:
		signal_label.add_theme_color_override("font_color", Color.WHITE)
	time_label.text = phase_text
	guide_label.text = _guide_text(uses_sync, room_type)
	weapon_label.text = _build_label(build_snapshot)
	var has_elite := elite_ratio >= 0.0
	elite_label.visible = has_elite
	elite_bar.visible = has_elite
	if has_elite:
		elite_bar.value = elite_ratio * 100.0

func play_damage_feedback(_amount: float = 0.0) -> void:
	damage_pulse_left = damage_pulse_duration
	_update_damage_feedback()

func _build_label(snapshot: Dictionary) -> String:
	var weapons: Dictionary = snapshot.get("weapons", {})
	var passives: Dictionary = snapshot.get("passives", {})
	var weapon_parts: Array[String] = []
	for weapon_id in WeaponDefinitions.get_ids():
		weapon_parts.append("%s Lv.%d" % [
			WeaponDefinitions.get_display_name(weapon_id),
			_snapshot_level(weapons, weapon_id, WeaponDefinitions.get_max_level(weapon_id)),
		])
	var passive_parts: Array[String] = []
	for passive_id in PassiveDefinitions.get_ids():
		passive_parts.append("%s Lv.%d" % [
			PassiveDefinitions.get_display_name(passive_id),
			_snapshot_level(passives, passive_id, PassiveDefinitions.get_max_level(passive_id)),
		])
	return "武器：%d/%d  %s\n被动：%d/%d  %s" % [
		_count_owned(weapons, WeaponDefinitions.get_ids(), true),
		maxi(0, int(snapshot.get("weapon_slots", 0))),
		" / ".join(weapon_parts),
		_count_owned(passives, PassiveDefinitions.get_ids(), false),
		maxi(0, int(snapshot.get("passive_slots", 0))),
		" / ".join(passive_parts),
	]

func _sync_max_from_snapshot(snapshot: Dictionary) -> float:
	var passives: Dictionary = snapshot.get("passives", {})
	return BuildAttributes.evaluate(passives, BuildAttributes.SYNC_MAX)

static func _count_owned(values: Dictionary, ids: Array[String], weapon_values: bool) -> int:
	var count := 0
	for content_id in ids:
		var max_level := WeaponDefinitions.get_max_level(content_id) if weapon_values else PassiveDefinitions.get_max_level(content_id)
		if _snapshot_level(values, content_id, max_level) > 0:
			count += 1
	return count

static func _snapshot_level(values: Dictionary, content_id: String, max_level: int) -> int:
	var value: Variant = values.get(content_id, 0)
	var parsed := 0
	match typeof(value):
		TYPE_INT:
			parsed = int(value)
		TYPE_FLOAT:
			var number := float(value)
			parsed = 0 if is_nan(number) or is_inf(number) else int(number)
		TYPE_STRING, TYPE_STRING_NAME:
			var text := String(value).strip_edges()
			parsed = int(text) if text.is_valid_int() else 0
	return clampi(parsed, 0, max_level)

func _update_danger_target(sync_rate: float, sync_max: float, signal_text: String, uses_sync: bool) -> void:
	if not uses_sync:
		danger_target = 0.0
		return
	var sync_danger := 0.0
	if sync_max > 0.0:
		var hp_ratio := clampf(sync_rate / sync_max, 0.0, 1.0)
		sync_danger = clampf((0.55 - hp_ratio) / 0.45, 0.0, 1.0)
	var signal_danger := 0.0
	if signal_text == BattleTypes.SIGNAL_DECLINING:
		signal_danger = 0.48
	elif signal_text == BattleTypes.SIGNAL_WEAK:
		signal_danger = 0.68
	elif signal_text == BattleTypes.SIGNAL_DISCONNECTED:
		signal_danger = 0.82
	danger_target = maxf(sync_danger, signal_danger)

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

func _buff_summary(active_buffs: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for buff in active_buffs:
		if str(buff.get("id", "")) == "sync_stable":
			continue
		var buff_name := str(buff.get("name", ""))
		if buff_name.is_empty():
			continue
		var stacks := int(buff.get("stacks", 0))
		if stacks <= 0:
			continue
		parts.append("%s x%d" % [buff_name, stacks] if stacks > 1 else buff_name)
	return "  ".join(parts)
