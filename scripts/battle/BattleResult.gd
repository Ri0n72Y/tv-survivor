extends RefCounted
class_name BattleResult

enum Outcome {
	SUCCESS,
	FAILURE,
	RETREAT,
}

var outcome: Outcome = Outcome.FAILURE
var room_type: String = ""
var room_position: Vector2i = Vector2i(-1, -1)
var final_sync: float = 0.0
var gold_gained: int = 0
var effects: Array[Dictionary] = []

func is_success() -> bool:
	return outcome == Outcome.SUCCESS

static func success(
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float
) -> BattleResult:
	var result := BattleResult.new()
	result.outcome = Outcome.SUCCESS
	result.room_type = battle_room_type
	result.room_position = position
	result.final_sync = sync_rate
	return result

static func failure(
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float
) -> BattleResult:
	var result := BattleResult.new()
	result.outcome = Outcome.FAILURE
	result.room_type = battle_room_type
	result.room_position = position
	result.final_sync = sync_rate
	return result
