extends RefCounted
class_name RewardService

static func build_options(build_state: BuildState) -> Array[RewardOption]:
	var pool: Array[RewardOption] = []
	for weapon_id in WeaponDefinitions.get_ids():
		var weapon_level := build_state.get_weapon_level(weapon_id)
		var weapon_max_level := WeaponDefinitions.get_max_level(weapon_id)
		if weapon_level > 0 and weapon_level < weapon_max_level:
			pool.append(make_weapon_option(weapon_id, weapon_level + 1, "升级武器"))
		elif weapon_level <= 0 and build_state.get_weapon_count() < build_state.weapon_slots:
			pool.append(make_weapon_option(weapon_id, 1, "新武器"))
	for passive_id in PassiveDefinitions.get_ids():
		var passive_level := build_state.get_passive_level(passive_id)
		var passive_max_level := PassiveDefinitions.get_max_level(passive_id)
		if passive_level > 0 and passive_level < passive_max_level:
			pool.append(make_passive_option(passive_id, passive_level + 1, "升级被动"))
		elif passive_level <= 0 and build_state.get_passive_count() < build_state.passive_slots:
			pool.append(make_passive_option(passive_id, 1, "新被动"))
	return pool

static func build_pool(build_state: BuildState) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for option in build_options(build_state):
		pool.append(option.to_legacy_dictionary())
	return pool

static func draw_options(
	stream: RunRngStream,
	build_state: BuildState,
	count: int
) -> Array[RewardOption]:
	var entries: Array[Dictionary] = []
	for option in build_options(build_state):
		entries.append(option.to_pool_entry())
	var drawn := RandomPool.draw(stream, entries, {
		"count": mini(maxi(0, count), entries.size()),
		"allow_repeats": false,
	})
	var result: Array[RewardOption] = []
	for entry in drawn:
		var option := (entry as Dictionary).get("option") as RewardOption
		if option != null:
			result.append(option.duplicate_value())
	return result

static func make_weapon_option(weapon_id: String, level: int, prefix: String) -> RewardOption:
	if not WeaponDefinitions.has(weapon_id):
		return null
	return RewardOption.create(
		StringName("weapon:%s:%d" % [weapon_id, level]),
		RewardOption.Kind.WEAPON,
		StringName(weapon_id),
		level,
		1.0,
		PackedStringArray(["weapon", weapon_id]),
		"%s\n%s Lv.%d\n%s" % [
			prefix,
			WeaponDefinitions.get_display_name(weapon_id),
			level,
			WeaponDefinitions.get_stats_text(weapon_id, level),
		]
	)

static func make_passive_option(passive_id: String, level: int, prefix: String) -> RewardOption:
	if not PassiveDefinitions.has(passive_id):
		return null
	return RewardOption.create(
		StringName("passive:%s:%d" % [passive_id, level]),
		RewardOption.Kind.PASSIVE,
		StringName(passive_id),
		level,
		1.0,
		PackedStringArray(["passive", passive_id]),
		"%s\n%s Lv.%d\n%s" % [
			prefix,
			PassiveDefinitions.get_display_name(passive_id),
			level,
			PassiveDefinitions.get_stats_text(passive_id, level),
		]
	)

static func make_weapon_reward(weapon_id: String, level: int, prefix: String) -> Dictionary:
	var option := make_weapon_option(weapon_id, level, prefix)
	return option.to_legacy_dictionary() if option != null else {}

static func make_passive_reward(passive_id: String, level: int, prefix: String) -> Dictionary:
	var option := make_passive_option(passive_id, level, prefix)
	return option.to_legacy_dictionary() if option != null else {}

static func purchase_and_apply(
	build_state: BuildState,
	cost: int,
	choice: Dictionary,
	allow_slot_bypass: bool = false
) -> Dictionary:
	return purchase_option_and_apply(
		build_state,
		cost,
		RewardOption.from_legacy_dictionary(choice),
		allow_slot_bypass
	).to_legacy_dictionary()

static func validate_reward(
	build_state: BuildState,
	choice: Dictionary,
	allow_slot_bypass: bool = false
) -> Dictionary:
	return validate_option(
		build_state,
		RewardOption.from_legacy_dictionary(choice),
		allow_slot_bypass
	).to_legacy_dictionary()

static func apply_reward(
	build_state: BuildState,
	choice: Dictionary,
	allow_slot_bypass: bool = false
) -> Dictionary:
	return apply_option(
		build_state,
		RewardOption.from_legacy_dictionary(choice),
		allow_slot_bypass
	).to_legacy_dictionary()

static func purchase_option_and_apply(
	build_state: BuildState,
	cost: int,
	choice: RewardOption,
	allow_slot_bypass: bool = false
) -> RewardResolution:
	var validation := validate_option(build_state, choice, allow_slot_bypass)
	if not validation.success:
		return validation
	if cost < 0:
		return RewardResolution.rejected("奖励费用不能为负数。")
	if cost > 0 and not build_state.spend_gold(cost):
		return RewardResolution.rejected("金币不足。")
	var result := apply_option(build_state, choice, allow_slot_bypass)
	if not result.success and cost > 0:
		build_state.refund_gold(cost)
	return result

static func validate_option(
	build_state: BuildState,
	choice: RewardOption,
	allow_slot_bypass: bool = false
) -> RewardResolution:
	if choice == null:
		return RewardResolution.rejected("奖励不能为空。")
	var content_id := String(choice.content_id)
	match choice.kind:
		RewardOption.Kind.WEAPON:
			if not WeaponDefinitions.has(content_id):
				return RewardResolution.rejected("未知武器奖励。")
			var weapon_max_level := WeaponDefinitions.get_max_level(content_id)
			if choice.level <= 0 or choice.level > weapon_max_level:
				return RewardResolution.rejected("武器奖励等级无效。")
			var current_weapon_level := build_state.get_weapon_level(content_id)
			if current_weapon_level > 0 and choice.level <= current_weapon_level:
				return RewardResolution.rejected("武器奖励不能降低或重复当前等级。")
			if current_weapon_level <= 0 and not allow_slot_bypass and build_state.get_weapon_count() >= build_state.weapon_slots:
				return RewardResolution.rejected("武器槽位已满。")
		RewardOption.Kind.PASSIVE:
			if not PassiveDefinitions.has(content_id):
				return RewardResolution.rejected("未知被动奖励。")
			var passive_max_level := PassiveDefinitions.get_max_level(content_id)
			if choice.level <= 0 or choice.level > passive_max_level:
				return RewardResolution.rejected("被动奖励等级无效。")
			var current_passive_level := build_state.get_passive_level(content_id)
			if current_passive_level > 0 and choice.level <= current_passive_level:
				return RewardResolution.rejected("被动奖励不能降低或重复当前等级。")
			if current_passive_level <= 0 and not allow_slot_bypass and build_state.get_passive_count() >= build_state.passive_slots:
				return RewardResolution.rejected("被动槽位已满。")
		_:
			return RewardResolution.rejected("未知奖励类型。")
	return RewardResolution.accepted()

static func apply_option(
	build_state: BuildState,
	choice: RewardOption,
	allow_slot_bypass: bool = false
) -> RewardResolution:
	var validation := validate_option(build_state, choice, allow_slot_bypass)
	if not validation.success:
		return validation
	var content_id := String(choice.content_id)
	match choice.kind:
		RewardOption.Kind.WEAPON:
			if build_state.get_weapon_level(content_id) <= 0 and not allow_slot_bypass:
				if not build_state.add_weapon(content_id, choice.level):
					return RewardResolution.rejected("无法添加武器。")
			else:
				build_state.set_weapon_level(content_id, choice.level)
			return _success(choice, build_state.get_weapon_level(content_id), WeaponDefinitions.get_display_name(content_id))
		RewardOption.Kind.PASSIVE:
			if build_state.get_passive_level(content_id) <= 0 and not allow_slot_bypass:
				if not build_state.add_passive(content_id, choice.level):
					return RewardResolution.rejected("无法添加被动。")
			else:
				build_state.set_passive_level(content_id, choice.level)
			return _success(choice, build_state.get_passive_level(content_id), PassiveDefinitions.get_display_name(content_id))
	return RewardResolution.rejected("奖励应用失败。")

static func _success(choice: RewardOption, level: int, display_name: String) -> RewardResolution:
	return RewardResolution.accepted(
		choice.kind,
		choice.content_id,
		level,
		display_name,
		"%s 提升到 Lv.%d" % [display_name, level]
	)
