extends Node2D
class_name BattleScene

signal battle_result_finished(result: BattleResult)
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")
const BuffContainerScript = preload("res://scripts/battle/buffs/BuffContainer.gd")
const BuffDefinitionScript = preload("res://scripts/battle/buffs/BuffDefinition.gd")
const BuffSystemScript = preload("res://scripts/battle/buffs/BuffSystem.gd")
const SIGNAL_AREA_SCENE := preload("res://scenes/battle/SignalArea.tscn")
const PLAYER_SCENE := preload("res://scenes/battle/PlayerAvatar.tscn")
const HUD_SCENE := preload("res://scenes/ui/BattleHud.tscn")
const REWARD_OVERLAY_SCENE := preload("res://scenes/ui/RewardOverlay.tscn")
const WEAPON_MANAGER_SCENE := preload("res://scenes/weapons/WeaponManager.tscn")
const COLLECTIBLE_DROP_SCENE := preload("res://scenes/battle/CollectibleDrop.tscn")
const ARENA_BOUNDARY_SCENE := preload("res://scenes/battle/ArenaBoundary.tscn")
const BATTLE_ALTAR_SCENE := preload("res://scenes/battle/BattleAltar.tscn")
const BATTLE_CHEST_SCENE := preload("res://scenes/battle/BattleChest.tscn")
const EXTRACTION_POINT_SCENE := preload("res://scenes/battle/ExtractionPoint.tscn")
const ELITE_ENEMY_SCENE := preload("res://scenes/enemies/EliteEnemy.tscn")
const PLAYER_BUFF_OWNER_ID := "player"
const BUFF_SIGNAL_LOSS := "signal_loss"
const BUFF_SYNC_STABLE := "sync_stable"

var battle_context: BattleContext
var battle_gold_collected: int = 0

var signal_center := Vector2(640, 360)
var player: PlayerAvatar
var hud: Node
var sync_controller := SyncController.new()
var buff_system := BuffSystemScript.new()
var player_buffs := BuffContainerScript.new()
var signal_loss_buff: BuffDefinition
var sync_stable_buff: BuffDefinition
var spawner: EnemySpawner
var weapon_manager: WeaponManager
var enemies: Array = []
var drops: Array = []
var battle_chests: Array[BattleChest] = []
var altar: BattleAltar
var extraction_point: ExtractionPoint
var reward_overlay: RewardOverlay

var task_time_left := Constants.TASK_DURATION
var extraction_time_left := Constants.EXTRACTION_COUNTDOWN
var extraction_active := false
var battle_elapsed := 0.0
var finished := false
var difficulty_stage := 0
var elite_escalation_bonus := 0
var battle_room_type := GridTypes.CELL_TASK
var room_rules: Dictionary = {}

var search_challenge_active := false
var search_challenge_completed := false
var search_challenge_time_left := Constants.ALTAR_CHALLENGE_DURATION
var search_extraction_active := false
var search_extraction_hold := 0.0
var search_chest_spawn_timer := 0.0
var search_chests_spawned := 0
var search_altar_available := false
var search_altar_hold := 0.0
var search_elite_spawned := false
var room_status_text := ""
var pending_reward_chest: BattleChest
var pending_finish_after_reward := false
var player_hit_invulnerability_seconds := Constants.PLAYER_HIT_INVULNERABILITY_SECONDS
var player_hit_invulnerability_left := 0.0

func configure(context: BattleContext) -> void:
	battle_context = context.duplicate_value() if context != null else null

func _ready() -> void:
	RunState.ensure_rng_started()
	if battle_context == null:
		battle_context = RunState.create_battle_context()
	battle_room_type = battle_context.room_type
	room_rules = RoomRules.for_room_type(battle_room_type)
	_setup_buffs()
	_build_scene()
	sync_controller.setup(battle_context.initial_sync)
	_update_difficulty()
	spawner.start()
	_update_hud()

func _process(delta: float) -> void:
	if finished:
		return
	player_hit_invulnerability_left = maxf(0.0, player_hit_invulnerability_left - delta)
	if reward_overlay != null and reward_overlay.visible:
		return
	if Input.is_key_pressed(KEY_R):
		restart_requested.emit()
		return
	if Input.is_key_pressed(KEY_ESCAPE):
		# Debug-only escape hatch for fast editor iteration; not part of formal gameplay.
		_finish(false)
		return
	battle_elapsed += delta
	if _signal_affects_sync():
		_update_sync(delta)
	else:
		sync_controller.control_state = BattleTypes.CONTROLLED
		sync_controller.signal_text = BattleTypes.SIGNAL_STABLE
		_update_sync_buffs(0.0)
		_process_buff_events(buff_system.process(delta))
		player.controlled = true
	match battle_room_type:
		GridTypes.CELL_SEARCH:
			_update_search_room(delta)
		GridTypes.CELL_ELITE:
			_update_elite_room(delta)
		GridTypes.CELL_BOSS:
			_update_boss_room()
		_:
			_update_task_room(delta)
	_update_difficulty()
	_update_hud()
	if _uses_sync() and sync_controller.sync_rate <= 0.0:
		_finish(false)

func _setup_buffs() -> void:
	buff_system.reset()
	player_buffs.setup(PLAYER_BUFF_OWNER_ID)
	buff_system.register_container(player_buffs)
	signal_loss_buff = BuffDefinitionScript.create(
		BUFF_SIGNAL_LOSS,
		"信号弱",
		5,
		Constants.BUFF_TICK_SECONDS,
		-1.0,
		["debuff", "signal", "sync"]
	)
	sync_stable_buff = BuffDefinitionScript.create(
		BUFF_SYNC_STABLE,
		"同步稳定",
		1,
		Constants.BUFF_TICK_SECONDS,
		-1.0,
		["buff", "signal", "sync", "regen"]
	)

func _build_scene() -> void:
	if bool(room_rules.get(RoomRules.SHOW_SIGNAL_AREA, true)):
		var signal_area := SIGNAL_AREA_SCENE.instantiate()
		signal_area.global_position = signal_center
		add_child(signal_area)
	if bool(room_rules.get(RoomRules.EDGE_IS_WALL, false)):
		var boundary := ARENA_BOUNDARY_SCENE.instantiate()
		add_child(boundary)
		boundary.setup_circle(signal_center, Constants.ARENA_BOUNDARY_RADIUS)
	player = PLAYER_SCENE.instantiate()
	player.global_position = signal_center
	player.signal_center = signal_center
	player.arena_bounds_enabled = bool(room_rules.get(RoomRules.EDGE_IS_WALL, false))
	player.arena_center = signal_center
	player.arena_radius = Constants.ARENA_BOUNDARY_RADIUS
	player.arena_bounds_shape = "circle" if player.arena_bounds_enabled else "rect"
	add_child(player)
	spawner = EnemySpawner.new()
	add_child(spawner)
	spawner.setup(player, self, signal_center, Constants.SIGNAL_RADIUS)
	spawner.set_room_type(battle_room_type)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	weapon_manager = WEAPON_MANAGER_SCENE.instantiate()
	add_child(weapon_manager)
	weapon_manager.setup(player, Callable(self, "get_enemies"))
	if battle_room_type == GridTypes.CELL_SEARCH:
		_build_search_objects()
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	_build_reward_overlay()

func _build_search_objects() -> void:
	altar = BATTLE_ALTAR_SCENE.instantiate()
	add_child(altar)
	altar.setup(signal_center)
	extraction_point = EXTRACTION_POINT_SCENE.instantiate()
	add_child(extraction_point)
	extraction_point.setup(signal_center, Constants.EXTRACTION_RADIUS)
	room_status_text = "探索房：宝箱每 10 秒出现，刷完 3 个后祭坛出现。"

func _build_reward_overlay() -> void:
	reward_overlay = REWARD_OVERLAY_SCENE.instantiate()
	add_child(reward_overlay)
	reward_overlay.reward_selected.connect(_choose_reward)

func _update_task_room(delta: float) -> void:
	if extraction_active:
		extraction_time_left = maxf(0.0, extraction_time_left - delta)
		room_status_text = "撤离中：%.1f" % extraction_time_left
		if extraction_time_left <= 0.0:
			_finish(true)
		return
	task_time_left = maxf(0.0, task_time_left - delta)
	if task_time_left <= 0.0:
		_start_extraction()

func _update_elite_room(delta: float) -> void:
	task_time_left = maxf(0.0, task_time_left - delta)
	if task_time_left <= 0.0:
		elite_escalation_bonus += 1
		task_time_left = Constants.TASK_DURATION
		spawner.set_spawn_intensity(1.0 + float(elite_escalation_bonus) * 0.35)
		room_status_text = "精英房难度提升：+%d" % elite_escalation_bonus

func _update_boss_room() -> void:
	room_status_text = "Boss 房不限时：击杀 Boss。"

func _update_search_room(delta: float) -> void:
	if search_challenge_active:
		search_challenge_time_left = maxf(0.0, search_challenge_time_left - delta)
		room_status_text = "祭坛挑战中：%.1f" % search_challenge_time_left
		if search_challenge_time_left <= 0.0:
			_complete_search_challenge()
		_update_auto_chest_trigger()
	elif search_extraction_active:
		var in_point := player.global_position.distance_to(altar.global_position) <= Constants.BATTLE_INTERACT_RADIUS
		if in_point:
			search_extraction_hold = minf(Constants.EXTRACTION_COUNTDOWN, search_extraction_hold + delta)
			room_status_text = "撤离中：%.1f" % (Constants.EXTRACTION_COUNTDOWN - search_extraction_hold)
		else:
			search_extraction_hold = maxf(0.0, search_extraction_hold - delta)
			room_status_text = "撤离已开放：回到祭坛圈内继续读条。"
		altar.set_hold_ratio(search_extraction_hold / Constants.EXTRACTION_COUNTDOWN)
		extraction_point.set_hold_ratio(search_extraction_hold / Constants.EXTRACTION_COUNTDOWN)
		if search_extraction_hold >= Constants.EXTRACTION_COUNTDOWN:
			_finish(true)
	elif search_altar_available:
		_update_altar_activation(delta)
		_update_auto_chest_trigger()
	else:
		_update_chest_spawns(delta)
		_update_auto_chest_trigger()

func _update_chest_spawns(delta: float) -> void:
	if search_chests_spawned >= Constants.BATTLE_CHEST_COUNT_MAX:
		_make_altar_available()
		return
	search_chest_spawn_timer += delta
	var remaining := maxf(0.0, Constants.BATTLE_CHEST_REFRESH_SECONDS - search_chest_spawn_timer)
	room_status_text = "下一宝箱：%.1f；已刷新 %d/%d。" % [remaining, search_chests_spawned, Constants.BATTLE_CHEST_COUNT_MAX]
	if search_chest_spawn_timer >= Constants.BATTLE_CHEST_REFRESH_SECONDS:
		search_chest_spawn_timer = 0.0
		_spawn_search_chest()
		if search_chests_spawned >= Constants.BATTLE_CHEST_COUNT_MAX:
			_make_altar_available()

func _spawn_search_chest() -> void:
	var positions: Array[Vector2] = [
		signal_center + Vector2(-130, -70),
		signal_center + Vector2(130, -70),
		signal_center + Vector2(-120, 95),
		signal_center + Vector2(120, 95),
	]
	var index := search_chests_spawned % positions.size()
	var chest := BATTLE_CHEST_SCENE.instantiate()
	add_child(chest)
	chest.setup(positions[index], _get_search_chest_cost())
	battle_chests.append(chest)
	search_chests_spawned += 1
	room_status_text = "战斗宝箱出现：靠近自动打开。"

func _get_search_chest_cost() -> int:
	return Constants.NORMAL_CHEST_COST

func _make_altar_available() -> void:
	if search_altar_available:
		return
	search_altar_available = true
	search_altar_hold = 0.0
	altar.set_available(true)
	room_status_text = "祭坛出现：在中心圈内停留 3 秒激活。"

func _update_altar_activation(delta: float) -> void:
	var in_altar := player.global_position.distance_to(altar.global_position) <= Constants.BATTLE_INTERACT_RADIUS
	if in_altar:
		search_altar_hold = minf(Constants.ALTAR_HOLD_SECONDS, search_altar_hold + delta)
		room_status_text = "祭坛激活中：%.1f" % (Constants.ALTAR_HOLD_SECONDS - search_altar_hold)
	else:
		search_altar_hold = maxf(0.0, search_altar_hold - delta)
		room_status_text = "祭坛出现：在中心圈内继续读条激活。"
	altar.set_hold_ratio(search_altar_hold / Constants.ALTAR_HOLD_SECONDS)
	if search_altar_hold >= Constants.ALTAR_HOLD_SECONDS:
		_activate_altar()

func _update_auto_chest_trigger() -> void:
	if reward_overlay.visible:
		return
	for chest in battle_chests:
		if is_instance_valid(chest) and not chest.opened and player.global_position.distance_to(chest.global_position) <= Constants.BATTLE_INTERACT_RADIUS:
			_try_open_battle_chest(chest)
			return

func _update_difficulty() -> void:
	var next_stage := int(floor(battle_elapsed / Constants.DIFFICULTY_STEP_SECONDS))
	if battle_room_type == GridTypes.CELL_ELITE:
		next_stage += elite_escalation_bonus
	if search_challenge_active:
		next_stage += 2
	if next_stage != difficulty_stage:
		difficulty_stage = next_stage
	spawner.set_difficulty(difficulty_stage, RunState.get_total_upgrade_level())

func _get_player_total_level() -> int:
	return RunState.get_total_upgrade_level()

func _update_sync(delta: float) -> void:
	var distance := player.global_position.distance_to(signal_center)
	var was_disconnected := sync_controller.control_state == BattleTypes.DISCONNECTED
	sync_controller.update(delta, distance)
	if not was_disconnected and sync_controller.control_state == BattleTypes.DISCONNECTED:
		_apply_player_damage(Constants.SYNC_BOUNDARY_HIT_DAMAGE, false)
		_add_signal_loss_stack()
	_update_sync_buffs(distance)
	_process_buff_events(buff_system.process(delta))
	player.controlled = sync_controller.control_state == BattleTypes.CONTROLLED

func _is_signal_loss_zone(distance: float) -> bool:
	return distance >= Constants.SIGNAL_RADIUS * Constants.SIGNAL_WEAK_RATIO

func _update_sync_buffs(distance: float) -> void:
	_update_signal_loss_buff(distance)
	_update_sync_stable_buff()

func _update_signal_loss_buff(distance: float) -> void:
	if _is_signal_loss_zone(distance) or player_buffs.has_buff(BUFF_SIGNAL_LOSS):
		var instance := player_buffs.ensure_buff(signal_loss_buff)
		if instance != null:
			instance.data["in_signal_loss_zone"] = _is_signal_loss_zone(distance)

func _update_sync_stable_buff() -> void:
	if not _uses_sync() or sync_controller.signal_text != BattleTypes.SIGNAL_STABLE or player_buffs.has_buff(BUFF_SIGNAL_LOSS):
		player_buffs.remove_buff(BUFF_SYNC_STABLE)
		return
	var instance := player_buffs.ensure_buff(sync_stable_buff, 1)
	if instance != null and not instance.data.has("stable_seconds"):
		instance.data["stable_seconds"] = 0.0

func _process_buff_events(events: Dictionary) -> void:
	for event in events.get("before_tick", []):
		if _is_player_signal_loss_event(event):
			if bool(event.get("data", {}).get("in_signal_loss_zone", false)):
				_add_signal_loss_stack()
			else:
				player_buffs.set_buff_stacks(BUFF_SIGNAL_LOSS, 0)
		elif _is_player_sync_stable_event(event):
			var instance := player_buffs.get_buff(BUFF_SYNC_STABLE)
			if instance != null:
				instance.data["stable_seconds"] = float(instance.data.get("stable_seconds", 0.0)) + Constants.BUFF_TICK_SECONDS
	for event in events.get("tick", []):
		if _is_player_signal_loss_event(event):
			var damage := RunState.get_sync_max() * Constants.SIGNAL_LOSS_DAMAGE_PER_STACK_RATIO * float(player_buffs.get_buff_stacks(BUFF_SIGNAL_LOSS))
			if damage > 0.0:
				sync_controller.apply_damage(damage)
				player_buffs.remove_buff(BUFF_SYNC_STABLE)
		elif _is_player_sync_stable_event(event):
			var instance := player_buffs.get_buff(BUFF_SYNC_STABLE)
			if instance != null and float(instance.data.get("stable_seconds", 0.0)) >= Constants.SYNC_REGEN_DELAY:
				var recovery := Constants.SYNC_REGEN_PER_SECOND * RunState.get_sync_regen_multiplier() * Constants.BUFF_TICK_SECONDS
				sync_controller.recover_sync(recovery)
	for event in events.get("after_tick", []):
		if _is_player_signal_loss_event(event) and player_buffs.get_buff_stacks(BUFF_SIGNAL_LOSS) <= 0:
			player_buffs.remove_buff(BUFF_SIGNAL_LOSS)

func _is_player_signal_loss_event(event: Dictionary) -> bool:
	return str(event.get("owner_id", "")) == PLAYER_BUFF_OWNER_ID and str(event.get("buff_id", "")) == BUFF_SIGNAL_LOSS

func _is_player_sync_stable_event(event: Dictionary) -> bool:
	return str(event.get("owner_id", "")) == PLAYER_BUFF_OWNER_ID and str(event.get("buff_id", "")) == BUFF_SYNC_STABLE

func _add_signal_loss_stack() -> void:
	player_buffs.apply_buff(signal_loss_buff, 1)

func _update_hud() -> void:
	var elite_ratio := -1.0
	for enemy in enemies:
		if is_instance_valid(enemy) and (enemy is EliteEnemy or enemy is BossEnemy):
			elite_ratio = enemy.get_hp_ratio()
			break
	var phase_text := _get_phase_text()
	if hud.has_method("update_hud"):
		hud.update_hud(
			sync_controller.sync_rate,
			sync_controller.signal_text,
			phase_text,
			RunState.get_build_snapshot(),
			elite_ratio,
			RunState.gold,
			_uses_sync(),
			battle_room_type,
			_get_objective_text(),
			room_status_text,
			player_buffs.get_display_buffs()
		)

func _get_phase_text() -> String:
	if battle_room_type == GridTypes.CELL_BOSS:
		return "Boss 房：不限时"
	if battle_room_type == GridTypes.CELL_SEARCH:
		if search_challenge_active:
			return "挑战剩余：%.1f  难度阶段：%d" % [search_challenge_time_left, difficulty_stage]
		if search_extraction_active:
			return "撤离点：已激活"
		return "探索中  难度阶段：%d" % difficulty_stage
	if extraction_active:
		return "撤离中：%.1f" % extraction_time_left
	var room_label := "任务"
	if battle_room_type == GridTypes.CELL_ELITE:
		room_label = "精英房"
	return "%s剩余：%.1f  难度阶段：%d（总等级：%d）" % [room_label, task_time_left, difficulty_stage, _get_player_total_level()]

func _get_objective_text() -> String:
	match battle_room_type:
		GridTypes.CELL_SEARCH:
			if search_extraction_active:
				return "目标：在祭坛圈内停留 3 秒返回阵列"
			if search_challenge_active:
				return "目标：坚持 20 秒或击杀精英"
			if search_altar_available:
				return "目标：在祭坛圈内停留 3 秒激活"
			return "目标：等待宝箱刷新，靠近自动开箱"
		GridTypes.CELL_ELITE:
			return "目标：击杀精英；超时会提高难度"
		GridTypes.CELL_BOSS:
			return "目标：击杀 Boss；不限时"
		_:
			return "目标：存活 30 秒并完成撤离"

func _try_open_battle_chest(chest: BattleChest) -> void:
	if RunState.build_reward_pool().is_empty():
		room_status_text = "没有可用奖励。"
		return
	if not RunState.spend_gold(chest.cost):
		room_status_text = "金币不足：打开战斗宝箱需要 %d 金币。" % chest.cost
		return
	chest.mark_opened()
	pending_reward_chest = chest
	_show_reward_choices("战斗宝箱", false)

func _activate_altar() -> void:
	if search_challenge_active or search_challenge_completed:
		return
	altar.set_activated(true)
	altar.set_hold_ratio(0.0)
	search_challenge_active = true
	search_challenge_completed = false
	search_challenge_time_left = Constants.ALTAR_CHALLENGE_DURATION
	spawner.set_spawn_intensity(2.0)
	_spawn_search_elite()
	room_status_text = "祭坛挑战已激活。"

func _complete_search_challenge() -> void:
	if search_challenge_completed:
		return
	search_challenge_active = false
	search_challenge_completed = true
	search_extraction_active = true
	search_extraction_hold = 0.0
	spawner.set_spawn_intensity(1.0)
	if altar != null:
		altar.set_completed(true)
	if extraction_point != null:
		extraction_point.set_active(true)
	room_status_text = "祭坛挑战完成：回到祭坛圈内撤离。"

func _spawn_search_elite() -> void:
	if search_elite_spawned:
		return
	search_elite_spawned = true
	var enemy := ELITE_ENEMY_SCENE.instantiate()
	enemy.global_position = signal_center + Vector2(0, -180)
	add_child(enemy)
	enemy.setup(player)
	if enemy.has_method("configure_spawn_tier"):
		enemy.configure_spawn_tier(2)
	_on_enemy_spawned(enemy)

func _on_enemy_spawned(enemy: Node) -> void:
	enemies.append(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.damaged_player.connect(_on_player_damaged)

func _on_enemy_died(enemy: Node) -> void:
	var is_boss := enemy is BossEnemy
	var is_elite := enemy is EliteEnemy
	RunState.total_score += Constants.SCORE_ELITE_KILL if is_elite or is_boss else Constants.SCORE_SMALL_KILL
	var drop_points := Constants.SCORE_SMALL_DROP
	if is_boss:
		drop_points = Constants.BOSS_GOLD
	elif is_elite:
		drop_points = Constants.SCORE_ELITE_DROP
	if enemy.has_method("get_drop_points"):
		drop_points = enemy.get_drop_points(drop_points)
	_spawn_drop(enemy.global_position, drop_points)
	enemies.erase(enemy)
	if is_boss:
		_collect_all_drops()
		_finish(true)
		return
	if is_elite:
		_collect_all_drops()
		if battle_room_type == GridTypes.CELL_ELITE:
			spawner.stop()
			pending_finish_after_reward = true
			_show_reward_choices("精英宝箱", true)
		elif battle_room_type == GridTypes.CELL_SEARCH and search_challenge_active:
			_complete_search_challenge()
		elif battle_room_type == GridTypes.CELL_TASK:
			_start_extraction()

func _spawn_drop(drop_position: Vector2, points: int) -> void:
	var drop := COLLECTIBLE_DROP_SCENE.instantiate()
	drop.global_position = drop_position
	add_child(drop)
	drop.setup(points, player)
	drop.collected.connect(_on_drop_collected)
	drops.append(drop)

func _on_drop_collected(drop: Node, points: int) -> void:
	drops.erase(drop)
	var earned := RunState.add_gold(points)
	battle_gold_collected += earned

func _collect_all_drops() -> void:
	for drop in drops.duplicate():
		if is_instance_valid(drop) and drop.has_method("collect"):
			drop.collect()

func _start_extraction() -> void:
	if extraction_active:
		return
	extraction_active = true
	extraction_time_left = Constants.EXTRACTION_COUNTDOWN
	room_status_text = "撤离中：%.1f" % extraction_time_left
	spawner.stop()

func _on_player_damaged(amount: float) -> void:
	_apply_player_damage(amount, true)

func _apply_player_damage(amount: float, respect_invulnerability: bool) -> void:
	if player_hit_invulnerability_left > 0.0 and respect_invulnerability:
		return
	player_hit_invulnerability_left = player_hit_invulnerability_seconds
	if player != null and player.has_method("play_hit_feedback"):
		player.play_hit_feedback(player_hit_invulnerability_seconds)
	if _uses_sync():
		sync_controller.apply_damage(amount)
		player_buffs.remove_buff(BUFF_SYNC_STABLE)
	if hud != null and hud.has_method("play_damage_feedback"):
		hud.play_damage_feedback(amount)

func _show_reward_choices(title: String, free_reward: bool) -> void:
	var choices := _roll_reward_choices()
	if choices.is_empty():
		room_status_text = "没有可用奖励。"
		if pending_finish_after_reward:
			pending_finish_after_reward = false
			_finish(true)
		return
	get_tree().paused = true
	var status := "免费奖励" if free_reward else "已消耗 %d 金币" % _get_pending_reward_cost()
	reward_overlay.show_choices(title, status, choices)

func _get_pending_reward_cost() -> int:
	if pending_reward_chest != null and is_instance_valid(pending_reward_chest):
		return pending_reward_chest.cost
	return Constants.NORMAL_CHEST_COST

func _roll_reward_choices() -> Array[Dictionary]:
	var choices := RunState.build_reward_pool()
	var stream_name := RunRngManagerScript.STREAM_CHEST_REWARD
	if pending_finish_after_reward:
		stream_name = RunRngManagerScript.STREAM_WEAPON_REWARD
	var drawn := RandomPool.draw(RunState.rng_stream(stream_name), choices, {
		"count": mini(3, choices.size()),
		"allow_repeats": false,
	})
	var result: Array[Dictionary] = []
	for choice in drawn:
		result.append(choice as Dictionary)
	return result

func _choose_reward(choice: Dictionary) -> void:
	var is_free_reward := pending_finish_after_reward
	var result := RunState.apply_reward(choice)
	if bool(result.get("success", false)):
		weapon_manager.refresh_weapons()
		sync_controller.sync_rate = minf(sync_controller.sync_rate, RunState.get_sync_max())
		room_status_text = "%s。" % String(result.get("message", "获得奖励"))
	else:
		room_status_text = String(result.get("message", "奖励应用失败。"))
	reward_overlay.hide_overlay()
	get_tree().paused = false
	pending_reward_chest = null
	if is_free_reward:
		pending_finish_after_reward = false
		_finish(true)

func get_enemies() -> Array:
	enemies = enemies.filter(func(enemy: Node) -> bool: return is_instance_valid(enemy))
	return enemies

func _uses_sync() -> bool:
	return bool(room_rules.get(RoomRules.USES_SYNC, true))

func _signal_affects_sync() -> bool:
	return _uses_sync() and bool(room_rules.get(RoomRules.SIGNAL_AFFECTS_SYNC, true))

func _finish(success: bool) -> void:
	if finished:
		return
	finished = true
	if reward_overlay != null:
		reward_overlay.hide_overlay()
	get_tree().paused = false
	if spawner != null:
		spawner.stop()
	var final_sync := sync_controller.sync_rate if _uses_sync() else battle_context.initial_sync
	var effects := _build_result_effects(success, final_sync)
	var result: BattleResult
	if success:
		result = BattleResult.success(
			battle_context.room_definition_id,
			battle_context.room_instance_id,
			battle_context.room_type,
			battle_context.room_position,
			final_sync,
			battle_gold_collected,
			effects
		)
	else:
		result = BattleResult.failure(
			battle_context.room_definition_id,
			battle_context.room_instance_id,
			battle_context.room_type,
			battle_context.room_position,
			final_sync,
			battle_gold_collected,
			effects
		)
	battle_result_finished.emit(result)

func _build_result_effects(success: bool, final_sync: float) -> Array[BattleEffect]:
	var effects: Array[BattleEffect] = []
	var next_sync := 100.0
	var message := ""
	if success:
		effects.append(BattleEffect.clear_room())
		if _uses_sync() and final_sync >= 80.0:
			effects.append(BattleEffect.reveal_ring())
		if _uses_sync() and final_sync < 30.0:
			next_sync = 70.0
		message = "战斗成功，同步率 %.0f" % final_sync if _uses_sync() else "战斗成功，竞技场已清理。"
	else:
		effects.append(BattleEffect.rollback_position())
		message = "战斗失败，返回上一个格子。"
	effects.append(BattleEffect.set_next_sync(next_sync))
	effects.append(BattleEffect.reveal_neighbors())
	effects.append(BattleEffect.clear_transition())
	effects.append(BattleEffect.result_message(message))
	return effects
