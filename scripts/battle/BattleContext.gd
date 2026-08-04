extends RefCounted
class_name BattleContext

var _room_definition_id: String = ""
var _room_instance_id: String = ""
var _room_type: String = GridTypes.CELL_TASK
var _room_position: Vector2i = Vector2i(-1, -1)
var _initial_sync: float = 100.0

var room_definition_id: String:
	get:
		return _room_definition_id

var room_instance_id: String:
	get:
		return _room_instance_id

var room_type: String:
	get:
		return _room_type

var room_position: Vector2i:
	get:
		return _room_position

var initial_sync: float:
	get:
		return _initial_sync

static func create(
	battle_room_definition_id: String,
	battle_room_instance_id: String,
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float
) -> BattleContext:
	var context := BattleContext.new()
	context._room_type = _normalize_room_type(battle_room_type)
	context._room_definition_id = battle_room_definition_id.strip_edges()
	if context._room_definition_id.is_empty():
		context._room_definition_id = context._room_type
	context._room_instance_id = battle_room_instance_id.strip_edges()
	if context._room_instance_id.is_empty():
		context._room_instance_id = "%d:%d" % [position.x, position.y]
		push_warning("BattleContext received an empty room instance id; using position fallback.")
	context._room_position = position
	context._initial_sync = _nonnegative_float(sync_rate, 100.0)
	return context

func duplicate_value() -> BattleContext:
	return BattleContext.create(
		_room_definition_id,
		_room_instance_id,
		_room_type,
		_room_position,
		_initial_sync
	)

static func _normalize_room_type(value: String) -> String:
	var room_type := value.strip_edges()
	match room_type:
		GridTypes.CELL_TASK, GridTypes.CELL_SEARCH, GridTypes.CELL_ELITE, GridTypes.CELL_BOSS:
			return room_type
	push_warning("BattleContext received an invalid room type; using the task-room fallback.")
	return GridTypes.CELL_TASK

static func _nonnegative_float(value: float, fallback: float) -> float:
	if is_nan(value) or is_inf(value):
		return fallback
	return maxf(0.0, value)
