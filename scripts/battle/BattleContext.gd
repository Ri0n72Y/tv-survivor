extends RefCounted
class_name BattleContext

var room_type: String = ""
var room_position: Vector2i = Vector2i(-1, -1)
var initial_sync: float = 100.0
var difficulty_level: int = 0
var run_seed: int = 0
var modifiers: Array[String] = []

static func create(
	battle_room_type: String,
	position: Vector2i,
	sync_rate: float,
	player_difficulty: int,
	seed: int
) -> BattleContext:
	var context := BattleContext.new()
	context.room_type = battle_room_type
	context.room_position = position
	context.initial_sync = sync_rate
	context.difficulty_level = player_difficulty
	context.run_seed = seed
	return context
