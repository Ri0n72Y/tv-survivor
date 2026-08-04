extends RefCounted
class_name BuildAttributes

const DAMAGE_MULTIPLIER: StringName = &"damage_multiplier"
const COOLDOWN_MULTIPLIER: StringName = &"cooldown_multiplier"
const MOVE_SPEED_MULTIPLIER: StringName = &"move_speed_multiplier"
const PICKUP_RADIUS_MULTIPLIER: StringName = &"pickup_radius_multiplier"
const SYNC_MAX: StringName = &"sync_max"
const SYNC_REGEN_MULTIPLIER: StringName = &"sync_regen_multiplier"
const GOLD_MULTIPLIER: StringName = &"gold_multiplier"

const _BASE_VALUES := {
	DAMAGE_MULTIPLIER: 1.0,
	COOLDOWN_MULTIPLIER: 1.0,
	MOVE_SPEED_MULTIPLIER: 1.0,
	PICKUP_RADIUS_MULTIPLIER: 1.0,
	SYNC_MAX: 100.0,
	SYNC_REGEN_MULTIPLIER: 1.0,
	GOLD_MULTIPLIER: 1.0,
}

const _MIN_VALUES := {
	COOLDOWN_MULTIPLIER: 0.5,
}

static func has(attribute_id: StringName) -> bool:
	return _BASE_VALUES.has(attribute_id)

static func get_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for attribute_id in _BASE_VALUES.keys():
		ids.append(StringName(attribute_id))
	return ids

static func get_base_value(attribute_id: StringName) -> float:
	return float(_BASE_VALUES.get(attribute_id, 0.0))

static func evaluate(passive_levels: Dictionary, attribute_id: StringName) -> float:
	if not has(attribute_id):
		return 0.0
	var value := get_base_value(attribute_id)
	for passive_id in PassiveDefinitions.get_ids():
		var level := maxi(0, int(passive_levels.get(passive_id, 0)))
		if level <= 0:
			continue
		var definition := PassiveDefinitions.get_definition(passive_id)
		if definition == null:
			continue
		value += float(level) * definition.get_add_per_level(attribute_id)
	return _clamp_value(attribute_id, value)

static func _clamp_value(attribute_id: StringName, value: float) -> float:
	if _MIN_VALUES.has(attribute_id):
		value = maxf(value, float(_MIN_VALUES[attribute_id]))
	return value
