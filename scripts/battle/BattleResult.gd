extends RefCounted
class_name BattleResult

enum Outcome {
	SUCCESS,
	FAILURE,
}

var _outcome: Outcome = Outcome.FAILURE
var _room_definition_id: String = ""
var _room_instance_id: String = ""
var _room_type: String = GridTypes.CELL_TASK
var _room_position: Vector2i = Vector2i(-1, -1)
var _final_sync: float = 0.0
var _gold_collected: int = 0
var _effects: Array[BattleEffect] = []

var outcome: Outcome:
	get:
		return _outcome

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

var final_sync: float:
	get:
		return _final_sync

var gold_collected: int:
	get:
		return _gold_collected

var effects: Array[BattleEffect]:
	get:
		return _duplicate_effects(_effects)

func is_success() -> bool:
	return _outcome == Outcome.SUCCESS

func is_failure() -> bool:
	return _outcome == Outcome.FAILURE

static func success(
	battle_room_definition_id: String,
	battle_room_instance_id: String,
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float,
	collected_gold: int = 0,
	result_effects: Array[BattleEffect] = []
) -> BattleResult:
	return _create(
		Outcome.SUCCESS,
		battle_room_definition_id,
		battle_room_instance_id,
		battle_room_type,
		position,
		sync_rate,
		collected_gold,
		result_effects
	)

static func failure(
	battle_room_definition_id: String,
	battle_room_instance_id: String,
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float,
	collected_gold: int = 0,
	result_effects: Array[BattleEffect] = []
) -> BattleResult:
	return _create(
		Outcome.FAILURE,
		battle_room_definition_id,
		battle_room_instance_id,
		battle_room_type,
		position,
		sync_rate,
		collected_gold,
		result_effects
	)

static func _create(
	result_outcome: Outcome,
	battle_room_definition_id: String,
	battle_room_instance_id: String,
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float,
	collected_gold: int,
	result_effects: Array[BattleEffect]
) -> BattleResult:
	var result := BattleResult.new()
	result._outcome = result_outcome
	result._room_type = _normalize_room_type(battle_room_type)
	result._room_definition_id = battle_room_definition_id.strip_edges()
	if result._room_definition_id.is_empty():
		result._room_definition_id = result._room_type
	result._room_instance_id = battle_room_instance_id.strip_edges()
	if result._room_instance_id.is_empty():
		result._room_instance_id = "%d:%d" % [position.x, position.y]
		push_warning("BattleResult received an empty room instance id; using position fallback.")
	result._room_position = position
	result._final_sync = _nonnegative_float(sync_rate, 0.0)
	result._gold_collected = maxi(0, collected_gold)
	result._effects = _duplicate_effects(result_effects)
	return result

func duplicate_value() -> BattleResult:
	return _create(
		_outcome,
		_room_definition_id,
		_room_instance_id,
		_room_type,
		_room_position,
		_final_sync,
		_gold_collected,
		_effects
	)

static func _duplicate_effects(source: Array[BattleEffect]) -> Array[BattleEffect]:
	var duplicated: Array[BattleEffect] = []
	for effect in source:
		if effect != null:
			duplicated.append(effect.duplicate_value())
	return duplicated

static func _normalize_room_type(value: String) -> String:
	var room_type := value.strip_edges()
	match room_type:
		GridTypes.CELL_TASK, GridTypes.CELL_SEARCH, GridTypes.CELL_ELITE, GridTypes.CELL_BOSS:
			return room_type
	push_warning("BattleResult received an invalid room type; using the task-room fallback.")
	return GridTypes.CELL_TASK

static func _nonnegative_float(value: float, fallback: float) -> float:
	if is_nan(value) or is_inf(value):
		return fallback
	return maxf(0.0, value)
