extends RefCounted
class_name BuildState

const Constants = preload("res://scripts/core/Constants.gd")

var gold: int = 0
var total_score: int = 0
var weapon_slots: int = Constants.BASE_WEAPON_SLOTS
var passive_slots: int = Constants.BASE_PASSIVE_SLOTS

var _main_weapon_id: String = Constants.BASE_WEAPON_ID
var _weapons: Dictionary = {Constants.BASE_WEAPON_ID: 1}
var _passives: Dictionary = {}

var main_weapon_id: String:
	get:
		return _main_weapon_id
	set(value):
		set_main_weapon_id(value)

var weapons: Dictionary:
	get:
		return get_weapons_snapshot()
	set(value):
		replace_weapons(value)

var passives: Dictionary:
	get:
		return get_passives_snapshot()
	set(value):
		replace_passives(value)

func reset() -> void:
	gold = 0
	total_score = 0
	weapon_slots = Constants.BASE_WEAPON_SLOTS
	passive_slots = Constants.BASE_PASSIVE_SLOTS
	_main_weapon_id = Constants.BASE_WEAPON_ID
	_weapons = {Constants.BASE_WEAPON_ID: 1}
	_passives = {}

func get_weapon_level(weapon_id: String) -> int:
	if not WeaponDefinitions.has(weapon_id):
		return 0
	return clampi(
		_parse_level(_weapons.get(weapon_id, 0)),
		0,
		WeaponDefinitions.get_max_level(weapon_id)
	)

func set_weapon_level(weapon_id: String, level: int) -> void:
	if not WeaponDefinitions.has(weapon_id):
		return
	var resolved_level := clampi(level, 0, WeaponDefinitions.get_max_level(weapon_id))
	if resolved_level == 0:
		_weapons.erase(weapon_id)
		return
	_weapons[weapon_id] = resolved_level

func add_weapon(weapon_id: String, initial_level: int = 1) -> bool:
	if not WeaponDefinitions.has(weapon_id):
		return false
	if get_weapon_level(weapon_id) > 0:
		return false
	if get_weapon_count() >= weapon_slots:
		return false
	set_weapon_level(weapon_id, initial_level)
	return get_weapon_level(weapon_id) > 0

func set_main_weapon_id(weapon_id: String) -> bool:
	if not WeaponDefinitions.has(weapon_id):
		return false
	if get_weapon_level(weapon_id) <= 0:
		return false
	_main_weapon_id = weapon_id
	return true

func replace_weapons(source: Dictionary) -> void:
	var normalized: Dictionary = {}
	for weapon_id in WeaponDefinitions.get_ids():
		var resolved_level := clampi(
			_parse_level(source.get(weapon_id, 0)),
			0,
			WeaponDefinitions.get_max_level(weapon_id)
		)
		if resolved_level > 0:
			normalized[weapon_id] = resolved_level

	if normalized.is_empty():
		_main_weapon_id = Constants.BASE_WEAPON_ID
		_weapons = {Constants.BASE_WEAPON_ID: 1}
		return

	_weapons = normalized
	_repair_main_weapon()

func get_weapon_count() -> int:
	var count := 0
	for weapon_id in WeaponDefinitions.get_ids():
		if get_weapon_level(weapon_id) > 0:
			count += 1
	return count

func get_total_weapon_level() -> int:
	var total := 0
	for weapon_id in WeaponDefinitions.get_ids():
		total += get_weapon_level(weapon_id)
	return total

func get_passive_count() -> int:
	var count := 0
	for passive_id in PassiveDefinitions.get_ids():
		if get_passive_level(passive_id) > 0:
			count += 1
	return count

func get_total_passive_level() -> int:
	var total := 0
	for passive_id in PassiveDefinitions.get_ids():
		total += get_passive_level(passive_id)
	return total

func get_total_upgrade_level() -> int:
	return get_total_weapon_level() + get_total_passive_level()

func get_player_difficulty_level() -> int:
	var total_level := get_total_upgrade_level()
	if total_level <= 1:
		return 0
	return int(floor(log(float(total_level)) / log(Constants.PLAYER_LEVEL_DIFFICULTY_LOG_BASE)))

func get_passive_level(passive_id: String) -> int:
	if not PassiveDefinitions.has(passive_id):
		return 0
	return clampi(
		_parse_level(_passives.get(passive_id, 0)),
		0,
		PassiveDefinitions.get_max_level(passive_id)
	)

func set_passive_level(passive_id: String, level: int) -> void:
	if not PassiveDefinitions.has(passive_id):
		return
	var resolved_level := clampi(level, 0, PassiveDefinitions.get_max_level(passive_id))
	if resolved_level == 0:
		_passives.erase(passive_id)
		return
	_passives[passive_id] = resolved_level

func add_passive(passive_id: String, initial_level: int = 1) -> bool:
	if not PassiveDefinitions.has(passive_id):
		return false
	if get_passive_level(passive_id) > 0:
		return false
	if get_passive_count() >= passive_slots:
		return false
	set_passive_level(passive_id, initial_level)
	return get_passive_level(passive_id) > 0

func replace_passives(source: Dictionary) -> void:
	var normalized: Dictionary = {}
	for passive_id in PassiveDefinitions.get_ids():
		var resolved_level := clampi(
			_parse_level(source.get(passive_id, 0)),
			0,
			PassiveDefinitions.get_max_level(passive_id)
		)
		if resolved_level > 0:
			normalized[passive_id] = resolved_level
	_passives = normalized

func spend_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount:
		return false
	gold -= amount
	return true

func refund_gold(amount: int) -> void:
	if amount > 0:
		gold += amount

func add_gold(base_amount: int) -> int:
	var gained := apply_gold_gain(base_amount)
	if gained == 0:
		return 0
	gold += gained
	total_score += gained
	return gained

func get_attribute_value(attribute_id: StringName) -> float:
	return BuildAttributes.evaluate(get_passives_snapshot(), attribute_id)

func get_damage_multiplier() -> float:
	return get_attribute_value(BuildAttributes.DAMAGE_MULTIPLIER)

func get_cooldown_multiplier() -> float:
	return get_attribute_value(BuildAttributes.COOLDOWN_MULTIPLIER)

func get_move_speed_multiplier() -> float:
	return get_attribute_value(BuildAttributes.MOVE_SPEED_MULTIPLIER)

func get_pickup_radius_multiplier() -> float:
	return get_attribute_value(BuildAttributes.PICKUP_RADIUS_MULTIPLIER)

func get_sync_max() -> float:
	return get_attribute_value(BuildAttributes.SYNC_MAX)

func get_sync_regen_multiplier() -> float:
	return get_attribute_value(BuildAttributes.SYNC_REGEN_MULTIPLIER)

func get_gold_multiplier() -> float:
	return get_attribute_value(BuildAttributes.GOLD_MULTIPLIER)

func apply_gold_gain(base_points: int) -> int:
	if base_points <= 0:
		return 0
	return maxi(1, int(round(float(base_points) * get_gold_multiplier())))

func get_weapons_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for weapon_id in WeaponDefinitions.get_ids():
		var level := get_weapon_level(weapon_id)
		if level > 0:
			snapshot[weapon_id] = level
	return snapshot

func get_passives_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for passive_id in PassiveDefinitions.get_ids():
		var level := get_passive_level(passive_id)
		if level > 0:
			snapshot[passive_id] = level
	return snapshot

func get_snapshot() -> Dictionary:
	return {
		"gold": gold,
		"total_score": total_score,
		"weapon_slots": weapon_slots,
		"passive_slots": passive_slots,
		"main_weapon_id": _main_weapon_id,
		"weapons": get_weapons_snapshot(),
		"passives": get_passives_snapshot(),
	}

func _repair_main_weapon() -> void:
	if get_weapon_level(_main_weapon_id) > 0:
		return
	for weapon_id in WeaponDefinitions.get_ids():
		if get_weapon_level(weapon_id) > 0:
			_main_weapon_id = weapon_id
			return
	_main_weapon_id = Constants.BASE_WEAPON_ID
	_weapons = {Constants.BASE_WEAPON_ID: 1}

static func _parse_level(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			var number := float(value)
			if is_nan(number) or is_inf(number):
				return 0
			return int(number)
		TYPE_STRING, TYPE_STRING_NAME:
			var text := String(value).strip_edges()
			return int(text) if text.is_valid_int() else 0
		_:
			return 0
