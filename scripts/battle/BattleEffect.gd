extends RefCounted
class_name BattleEffect

enum Type {
	CLEAR_ROOM,
	REVEAL_RING,
	SET_NEXT_SYNC,
	ROLLBACK_POSITION,
	REVEAL_NEIGHBORS,
	CLEAR_TRANSITION,
	RESULT_MESSAGE,
}

var _type: Type = Type.CLEAR_TRANSITION
var _number_value: float = 0.0
var _text_value: String = ""

var type: Type:
	get:
		return _type

var number_value: float:
	get:
		return _number_value

var text_value: String:
	get:
		return _text_value

static func clear_room() -> BattleEffect:
	return _create(Type.CLEAR_ROOM)

static func reveal_ring() -> BattleEffect:
	return _create(Type.REVEAL_RING)

static func set_next_sync(value: float) -> BattleEffect:
	var safe_value := 100.0 if is_nan(value) or is_inf(value) else maxf(0.0, value)
	return _create(Type.SET_NEXT_SYNC, safe_value)

static func rollback_position() -> BattleEffect:
	return _create(Type.ROLLBACK_POSITION)

static func reveal_neighbors() -> BattleEffect:
	return _create(Type.REVEAL_NEIGHBORS)

static func clear_transition() -> BattleEffect:
	return _create(Type.CLEAR_TRANSITION)

static func result_message(value: String) -> BattleEffect:
	return _create(Type.RESULT_MESSAGE, 0.0, value.strip_edges())

static func _create(
	effect_type: Type,
	number: float = 0.0,
	text: String = ""
) -> BattleEffect:
	var effect := BattleEffect.new()
	effect._type = effect_type
	effect._number_value = number
	effect._text_value = text
	return effect

func duplicate_value() -> BattleEffect:
	return _create(_type, _number_value, _text_value)
