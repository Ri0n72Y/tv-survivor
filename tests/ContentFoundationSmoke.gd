extends Node

const Constants = preload("res://scripts/core/Constants.gd")

var failures: Array[String] = []
var run_state: Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	run_state = get_node_or_null("/root/RunState")
	if run_state == null:
		push_error("RunState autoload is unavailable. Check project.godot [autoload] configuration.")
		get_tree().quit(1)
		return

	_check_definition_catalogs()
	_check_build_state_rules()
	_check_build_attribute_aggregation()
	_check_reward_service()
	_check_battle_boundaries()
	_check_battle_result_application()
	await _check_scene_lifecycles()

	get_tree().paused = false
	await get_tree().process_frame
	await get_tree().process_frame

	if failures.is_empty():
		print("Content foundation smoke checks passed.")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	get_tree().quit(1)

func _check_definition_catalogs() -> void:
	var weapon_errors := WeaponDefinitions.reload_catalog()
	var passive_errors := PassiveDefinitions.reload_catalog()
	_expect(weapon_errors.is_empty(), "Weapon catalog must load without validation errors: " + str(weapon_errors))
	_expect(passive_errors.is_empty(), "Passive catalog must load without validation errors: " + str(passive_errors))

	var expected_weapon_ids := ["projectile", "aura", "shape", "beam"]
	var weapon_ids := WeaponDefinitions.get_ids()
	_expect(Array(weapon_ids) == expected_weapon_ids, "Weapon catalog order or membership changed: " + str(weapon_ids))
	_expect(weapon_ids.size() == _unique_count(weapon_ids), "Weapon catalog contains duplicate IDs.")
	for weapon_id in weapon_ids:
		var definition := WeaponDefinitions.get_definition(weapon_id)
		_expect(definition is WeaponDefinition, "Weapon '%s' must resolve to WeaponDefinition." % weapon_id)
		var max_level := WeaponDefinitions.get_max_level(weapon_id)
		_expect(max_level > 0, "Weapon '%s' must have a positive max level." % weapon_id)
		_expect(not WeaponDefinitions.get_display_name(weapon_id).is_empty(), "Weapon '%s' must have a display name." % weapon_id)
		_expect(not WeaponDefinitions.get_stats_text(weapon_id, 1).is_empty(), "Weapon '%s' must describe level 1." % weapon_id)
		_expect(not WeaponDefinitions.get_stats_text(weapon_id, max_level).is_empty(), "Weapon '%s' must describe its maximum level." % weapon_id)
		var runtime := WeaponDefinitions.instantiate_runtime(weapon_id)
		_expect(runtime != null, "Weapon '%s' must instantiate a runtime node." % weapon_id)
		if runtime != null:
			_expect(runtime.has_method("setup"), "Weapon '%s' runtime must implement setup()." % weapon_id)
			runtime.free()

	var expected_passive_ids := [
		"move_speed",
		"damage_bonus",
		"cooldown_bonus",
		"pickup_bonus",
		"sync_bonus",
		"gold_bonus",
	]
	var passive_ids := PassiveDefinitions.get_ids()
	_expect(Array(passive_ids) == expected_passive_ids, "Passive catalog order or membership changed: " + str(passive_ids))
	_expect(passive_ids.size() == _unique_count(passive_ids), "Passive catalog contains duplicate IDs.")
	for passive_id in passive_ids:
		var definition := PassiveDefinitions.get_definition(passive_id)
		_expect(definition is PassiveDefinition, "Passive '%s' must resolve to PassiveDefinition." % passive_id)
		var max_level := PassiveDefinitions.get_max_level(passive_id)
		_expect(max_level > 0, "Passive '%s' must have a positive max level." % passive_id)
		_expect(not PassiveDefinitions.get_display_name(passive_id).is_empty(), "Passive '%s' must have a display name." % passive_id)
		_expect(not PassiveDefinitions.get_stats_text(passive_id, 1).is_empty(), "Passive '%s' must describe level 1." % passive_id)
		_expect(not PassiveDefinitions.get_stats_text(passive_id, max_level).is_empty(), "Passive '%s' must describe its maximum level." % passive_id)
		for attribute_id in definition.attribute_ids:
			_expect(BuildAttributes.has(StringName(attribute_id)), "Passive '%s' references unknown attribute '%s'." % [passive_id, attribute_id])

func _check_build_state_rules() -> void:
	var build := BuildState.new()
	_expect(build.weapon_slots == Constants.BASE_WEAPON_SLOTS, "BuildState must use the configured base weapon-slot count.")
	_expect(build.main_weapon_id == Constants.BASE_WEAPON_ID, "BuildState must use the configured base weapon ID.")
	_expect(build.get_weapon_level(Constants.BASE_WEAPON_ID) == 1, "A new build must own its base weapon at level 1.")

	build.weapon_slots = 1
	_expect(not build.add_weapon("aura"), "Normal acquisition must respect weapon slot limits.")
	build.set_weapon_level("aura", 1)
	_expect(build.get_weapon_level("aura") == 1, "Explicit weapon setters must retain the intentional slot bypass.")

	var weapon_snapshot := build.weapons
	weapon_snapshot["projectile"] = 999
	weapon_snapshot["unknown_weapon"] = 2
	_expect(build.get_weapon_level("projectile") == 1, "Mutating a weapon snapshot must not mutate BuildState.")
	_expect(build.get_weapon_level("unknown_weapon") == 0, "Unknown weapon IDs must always read as level 0.")

	build.weapons = {"projectile": 999, "unknown_weapon": 2}
	_expect(build.get_weapon_level("projectile") == WeaponDefinitions.get_max_level("projectile"), "Whole weapon replacement must clamp levels.")
	_expect(build.get_weapon_count() == 1, "Unknown weapon IDs must not affect slot counts.")

	var passive_snapshot := build.passives
	passive_snapshot["damage_bonus"] = NAN
	_expect(build.get_passive_level("damage_bonus") == 0, "Mutating a passive snapshot must not mutate BuildState.")
	build.passives = {"damage_bonus": NAN, "unknown_passive": 3}
	_expect(build.get_passive_level("damage_bonus") == 0, "Non-finite restored passive levels must normalize to zero.")
	_expect(build.get_passive_count() == 0, "Unknown passive IDs must not affect slot counts.")

func _check_build_attribute_aggregation() -> void:
	var build := BuildState.new()
	_expect(is_equal_approx(build.get_damage_multiplier(), 1.0), "Base damage multiplier must remain 1.0.")
	_expect(is_equal_approx(build.get_cooldown_multiplier(), 1.0), "Base cooldown multiplier must remain 1.0.")
	_expect(is_equal_approx(build.get_move_speed_multiplier(), 1.0), "Base move-speed multiplier must remain 1.0.")
	_expect(is_equal_approx(build.get_pickup_radius_multiplier(), 1.0), "Base pickup multiplier must remain 1.0.")
	_expect(is_equal_approx(build.get_sync_max(), Constants.SYNC_MAX), "Base sync maximum must remain unchanged.")
	_expect(is_equal_approx(build.get_sync_regen_multiplier(), 1.0), "Base sync regeneration multiplier must remain 1.0.")
	_expect(is_equal_approx(build.get_gold_multiplier(), 1.0), "Base gold multiplier must remain 1.0.")

	build.set_passive_level("damage_bonus", 3)
	build.set_passive_level("cooldown_bonus", 3)
	build.set_passive_level("move_speed", 3)
	build.set_passive_level("pickup_bonus", 3)
	build.set_passive_level("sync_bonus", 3)
	build.set_passive_level("gold_bonus", 3)
	_expect(is_equal_approx(build.get_damage_multiplier(), 1.36), "Damage passive aggregation changed existing level-3 behavior.")
	_expect(is_equal_approx(build.get_cooldown_multiplier(), 0.76), "Cooldown passive aggregation changed existing level-3 behavior.")
	_expect(is_equal_approx(build.get_move_speed_multiplier(), 1.24), "Move-speed passive aggregation changed existing level-3 behavior.")
	_expect(is_equal_approx(build.get_pickup_radius_multiplier(), 1.75), "Pickup passive aggregation changed existing level-3 behavior.")
	_expect(is_equal_approx(build.get_sync_max(), 130.0), "Sync maximum aggregation changed existing level-3 behavior.")
	_expect(is_equal_approx(build.get_sync_regen_multiplier(), 1.6), "Sync regeneration aggregation changed existing level-3 behavior.")
	_expect(is_equal_approx(build.get_gold_multiplier(), 1.45), "Gold passive aggregation changed existing level-3 behavior.")

func _check_reward_service() -> void:
	var build := BuildState.new()
	build.gold = 20
	var projectile_option := RewardService.make_weapon_option("projectile", 2, "测试")
	_expect(projectile_option != null, "Typed weapon reward option must be created.")
	if projectile_option == null:
		return
	var typed_result := RewardService.purchase_option_and_apply(build, 5, projectile_option)
	_expect(typed_result.success, "A valid typed paid upgrade must succeed.")
	_expect(typed_result.kind == RewardOption.Kind.WEAPON, "Typed reward resolution must preserve reward kind.")
	_expect(typed_result.content_id == &"projectile", "Typed reward resolution must preserve content ID.")
	_expect(build.gold == 15, "A successful typed paid reward must deduct its cost exactly once.")
	_expect(build.get_weapon_level("projectile") == 2, "A successful typed reward must update the weapon level.")

	var duplicate_result := RewardService.purchase_option_and_apply(build, 5, projectile_option)
	_expect(not duplicate_result.success, "A duplicate or downgrade typed reward must be rejected.")
	_expect(build.gold == 15, "A rejected typed reward must not spend gold.")

	var oversized_option := RewardOption.create(
		&"weapon:projectile:999",
		RewardOption.Kind.WEAPON,
		&"projectile",
		999,
		1.0,
		PackedStringArray(["weapon", "projectile"]),
		"oversized"
	)
	var oversized_typed_result := RewardService.purchase_option_and_apply(build, 5, oversized_option)
	_expect(not oversized_typed_result.success, "Typed rewards above the registered maximum must be rejected.")
	_expect(build.gold == 15, "Rejected oversized typed rewards must not spend gold.")

	var legacy_reward := RewardService.make_passive_reward("damage_bonus", 1, "测试")
	var legacy_result := RewardService.purchase_and_apply(build, 5, legacy_reward)
	_expect(bool(legacy_result.get("success", false)), "The explicit legacy reward adapter must remain functional during scene migration.")
	_expect(String(legacy_result.get("kind", "")) == "passive", "Legacy reward result must preserve string kind names.")
	_expect(build.gold == 10, "A successful legacy-adapter reward must deduct its cost exactly once.")

	var malformed_reward := {
		"kind": "passive",
		"passive_id": "damage_bonus",
		"level": {},
	}
	var malformed_result := RewardService.purchase_and_apply(build, 5, malformed_reward)
	_expect(not bool(malformed_result.get("success", false)), "Malformed legacy reward levels must be rejected.")
	_expect(build.gold == 10, "Malformed legacy rewards must not spend gold.")

func _check_battle_boundaries() -> void:
	var context := BattleContext.create(
		"",
		"",
		" invalid_room ",
		Vector2i(2, 3),
		NAN
	)
	_expect(context.room_definition_id == GridTypes.CELL_TASK, "BattleContext must fall back to the task definition when identity is missing.")
	_expect(context.room_instance_id == "2:3", "BattleContext must derive a missing instance ID from position.")
	_expect(context.room_type == GridTypes.CELL_TASK, "BattleContext must normalize invalid room types to task.")
	_expect(context.initial_sync == 100.0, "BattleContext must replace non-finite sync with the default.")

	var source_effects: Array[BattleEffect] = [
		BattleEffect.set_next_sync(NAN),
		BattleEffect.result_message("测试结果"),
	]
	var result := BattleResult.failure(
		context.room_definition_id,
		context.room_instance_id,
		context.room_type,
		context.room_position,
		INF,
		-7,
		source_effects
	)
	var copied_effects := result.effects
	copied_effects.clear()
	_expect(result.is_failure(), "BattleResult must preserve the failure outcome.")
	_expect(result.final_sync == 0.0, "BattleResult must normalize non-finite final sync.")
	_expect(result.gold_collected == 0, "BattleResult must clamp negative collected gold to zero.")
	_expect(result.effects.size() == 2, "BattleResult must return defensive effect copies.")
	_expect(result.effects[0].number_value == 100.0, "BattleEffect must normalize non-finite sync values.")

func _check_battle_result_application() -> void:
	run_state.reset_run(12345)
	run_state.grid_data = [[{
		"type": GridTypes.CELL_TASK,
		"state": GridTypes.STATE_REVEALED,
		"cleared": false,
	}]]
	run_state.grid_size = 1
	run_state.player_grid_pos = Vector2i.ZERO
	run_state.previous_grid_pos = Vector2i.ZERO
	run_state.current_task_pos = Vector2i.ZERO
	run_state.current_room_cell = Vector2i.ZERO
	run_state.current_battle_room_type = GridTypes.CELL_TASK
	var effects: Array[BattleEffect] = [
		BattleEffect.clear_room(),
		BattleEffect.set_next_sync(70.0),
		BattleEffect.clear_transition(),
		BattleEffect.result_message("已应用"),
	]
	var result := BattleResult.success(
		GridTypes.CELL_TASK,
		"0:0",
		GridTypes.CELL_TASK,
		Vector2i.ZERO,
		25.0,
		0,
		effects
	)
	var message := BattleResultApplicator.apply(result)
	_expect(bool(run_state.grid_data[0][0].get("cleared", false)), "BattleResultApplicator must clear the result room.")
	_expect(run_state.completed_tasks == 1, "Clearing a task room must increment completed tasks once.")
	_expect(run_state.next_battle_initial_sync == 70.0, "BattleResultApplicator must apply the next-sync command.")
	_expect(run_state.current_task_pos == Vector2i(-1, -1), "BattleResultApplicator must clear transition state.")
	_expect(message == "已应用", "BattleResultApplicator must return the typed result message.")

func _check_scene_lifecycles() -> void:
	var main_scene_resource := load("res://scenes/main/Main.tscn") as PackedScene
	var grid_scene_resource := load("res://scenes/grid/GridScene.tscn") as PackedScene
	var battle_scene_resource := load("res://scenes/battle/BattleScene.tscn") as PackedScene
	_expect(main_scene_resource != null, "Main.tscn must load.")
	_expect(grid_scene_resource != null, "GridScene.tscn must load.")
	_expect(battle_scene_resource != null, "BattleScene.tscn must load.")

	if main_scene_resource != null:
		var main_scene := main_scene_resource.instantiate()
		get_tree().root.add_child(main_scene)
		await get_tree().process_frame
		_expect(main_scene.is_node_ready(), "Main.tscn must complete _ready().")
		main_scene.queue_free()
		await get_tree().process_frame

	run_state.reset_run(12345)
	if grid_scene_resource != null:
		var grid_scene := grid_scene_resource.instantiate() as GridScene
		_expect(grid_scene != null, "GridScene.tscn must instantiate GridScene.")
		if grid_scene != null:
			get_tree().root.add_child(grid_scene)
			await get_tree().process_frame
			_expect(grid_scene.is_node_ready(), "GridScene must complete _ready().")
			_expect(grid_scene.reward_overlay != null, "GridScene must initialize its reward overlay.")
			grid_scene.queue_free()
			await get_tree().process_frame

	run_state.reset_run(12345)
	if battle_scene_resource != null:
		var battle_scene := battle_scene_resource.instantiate() as BattleScene
		_expect(battle_scene != null, "BattleScene.tscn must instantiate BattleScene.")
		if battle_scene != null:
			battle_scene.configure(BattleContext.create(
				GridTypes.CELL_TASK,
				"0:0",
				GridTypes.CELL_TASK,
				Vector2i.ZERO,
				100.0
			))
			get_tree().root.add_child(battle_scene)
			await get_tree().process_frame
			_expect(battle_scene.is_node_ready(), "BattleScene must complete _ready().")
			_expect(battle_scene.battle_room_type == GridTypes.CELL_TASK, "BattleScene must preserve the configured task-room fallback.")
			_expect(battle_scene.player != null, "BattleScene must initialize the player.")
			_expect(battle_scene.spawner != null, "BattleScene must initialize the spawner.")
			_expect(battle_scene.hud != null, "BattleScene must initialize the HUD.")
			_expect(battle_scene.reward_overlay != null, "BattleScene must initialize its reward overlay.")
			_expect(battle_scene.weapon_manager.get_child_count() == 1, "The weapon catalog must instantiate exactly the owned base weapon at battle start.")
			battle_scene.queue_free()
			await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

static func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[value] = true
	return unique.size()