extends Node2D
class_name BattleChest

var opened := false
var interactable := true
var cost := 30

@onready var body: Polygon2D = $Body
@onready var cost_label: Label = $CostLabel

func setup(chest_position: Vector2, chest_cost: int) -> void:
	global_position = chest_position
	cost = chest_cost
	if is_node_ready():
		_sync_visuals()

func _ready() -> void:
	_sync_visuals()

func mark_opened() -> void:
	opened = true
	interactable = false
	_sync_visuals()

func _sync_visuals() -> void:
	body.color = Color(0.95, 0.66, 0.16) if not opened else Color(0.30, 0.22, 0.10)
	cost_label.visible = not opened
	cost_label.text = "%dG" % cost
