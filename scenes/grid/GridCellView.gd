extends Control

const Constants = preload("res://scripts/core/Constants.gd")

var cell_data: Dictionary = {}
var cell_pos: Vector2i = Vector2i.ZERO
var is_player_here := false

@onready var background: ColorRect = $Background
@onready var player_highlight: ColorRect = $PlayerHighlight
@onready var player_frame: Panel = $PlayerFrame
@onready var player_badge: Label = $PlayerBadge
@onready var mark_label: Label = $MarkLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(data: Dictionary, pos: Vector2i, player_here: bool) -> void:
	cell_data = data
	cell_pos = pos
	is_player_here = player_here
	_update_background()
	_update_label()

func _update_background() -> void:
	var state := String(cell_data.get("state", GridTypes.STATE_HIDDEN))
	var cell_type := String(cell_data.get("type", GridTypes.CELL_EMPTY))
	var color := Color(0.12, 0.12, 0.14)
	if state == GridTypes.STATE_REVEALED:
		color = Color(0.35, 0.36, 0.38)
	elif state == GridTypes.STATE_VISITED:
		color = Color(0.12, 0.20, 0.26)
	if state != GridTypes.STATE_HIDDEN:
		match cell_type:
			GridTypes.CELL_START:
				color = Color(0.16, 0.62, 0.22)
			GridTypes.CELL_CHEST:
				color = Color(0.92, 0.66, 0.12)
			GridTypes.CELL_TASK:
				color = Color(0.48, 0.24, 0.75) if not bool(cell_data.get("cleared", false)) else Color(0.24, 0.12, 0.36)
			GridTypes.CELL_SEARCH:
				color = Color(0.12, 0.50, 0.78) if not bool(cell_data.get("cleared", false)) else Color(0.06, 0.22, 0.34)
			GridTypes.CELL_ELITE:
				color = Color(0.72, 0.18, 0.18) if not bool(cell_data.get("cleared", false)) else Color(0.30, 0.08, 0.08)
			GridTypes.CELL_BOSS:
				color = Color(0.95, 0.30, 0.08) if not bool(cell_data.get("cleared", false)) else Color(0.38, 0.10, 0.02)
			GridTypes.CELL_BLOCKED:
				color = Color(0.03, 0.03, 0.04)
	background.color = color
	player_highlight.visible = is_player_here
	player_frame.visible = is_player_here
	player_badge.visible = is_player_here

func _update_label() -> void:
	if mark_label == null:
		return
	var state := String(cell_data.get("state", GridTypes.STATE_HIDDEN))
	if state == GridTypes.STATE_HIDDEN:
		mark_label.text = ""
		return
	var cell_type := String(cell_data.get("type", GridTypes.CELL_EMPTY))
	if _is_battle_room(cell_type) and bool(cell_data.get("cleared", false)):
		mark_label.text = "完成"
	elif cell_type == GridTypes.CELL_CHEST and bool(cell_data.get("opened", false)):
		mark_label.text = "已开"
	elif cell_type == GridTypes.CELL_TASK:
		mark_label.text = "任务"
	elif cell_type == GridTypes.CELL_SEARCH:
		mark_label.text = "搜索"
	elif cell_type == GridTypes.CELL_ELITE:
		mark_label.text = "精英"
	elif cell_type == GridTypes.CELL_BOSS:
		mark_label.text = "Boss"
	elif cell_type == GridTypes.CELL_CHEST:
		mark_label.text = "宝箱\n%d" % int(cell_data.get("cost", Constants.NORMAL_CHEST_COST))
	elif cell_type == GridTypes.CELL_START:
		mark_label.text = "起点"
	else:
		mark_label.text = ""

func _is_battle_room(cell_type: String) -> bool:
	return cell_type == GridTypes.CELL_TASK or cell_type == GridTypes.CELL_SEARCH or cell_type == GridTypes.CELL_ELITE or cell_type == GridTypes.CELL_BOSS
