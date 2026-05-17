extends Node2D

signal battle_finished(success: bool, final_sync_rate: float)
signal restart_requested

const Constants = preload("res://scripts/core/Constants.gd")
const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")
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
const WEAPON_IDS: Array[String] = ["projectile", "aura", "shape", "beam"]

var signal_center := Vector2(640, 360)
var player: PlayerAvatar
var hud: Node
var sync_controller := SyncController.new()
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

func _ready() -> void:
	RunState.ensure_rng_started()
	RunState.begin_battle()
	battle_room_type = RunState.current_battle_room_type if RunState.current_battle_room_type != "" else GridTypes.CELL_TASK
	room_rules = RoomRules.for_room_type(battle_room_type)
	_build_scene()
	sync_controller.setup(RunState.next_battle_initial_sync)
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
		# Debug-only escape hatch for fast editor iteration; not part of formal win/loss flow.
		_finish(false)
		return
	battle_elapsed += delta
	if _signal_affects_sync():
		_update_sync(delta)
	else:
		sync_controller.time_since_damage += delta
		sync_controller.control_state = BattleTypes.CONTROLLED
		sync_controller.signal_text = BattleTypes.SIGNAL_STABLE
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
	sync_controller.update(delta, distance)
	player.controlled = sync_controller.control_state == BattleTypes.CONTROLLED
	if sync_controller.control_state == BattleTypes.DISCONNECTED and distance <= Constants.SIGNAL_RADIUS * Constants.SIGNAL_WEAK_RATIO:
		sync_controller.recover_from_disconnect()
		player.controlled = true

func _update_hud() -> void:
	var elite_ratio := -1.0
	for enemy in enemies:
		if is_instance_valid(enemy) and (enemy is EliteEnemy or enemy is BossEnemy):
			elite_ratio = enemy.get_hp_ratio()
			break
	var phase_text := _get_phase_text()
	if hud.has_method("update_hud"):
		hud.update_hud(sync_controller.sync_rate, sync_controller.signal_text, phase_text, RunState.weapons, elite_ratio, RunState.gold, _uses_sync(), battle_room_type, _get_objective_text(), room_status_text)

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
	if _build_reward_pool().is_empty():
		room_status_text = "没有可用奖励。"
		return
	var cost := chest.cost
	if RunState.gold < cost:
		room_status_text = "金币不足：打开战斗宝箱需要 %d 金币。" % cost
		return
	RunState.gold -= cost
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
	if is_elite or is_boss:
		RunState.total_score += Constants.SCORE_ELITE_KILL
	else:
		RunState.total_score += Constants.SCORE_SMALL_KILL
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
	var earned := RunState.apply_gold_gain(points)
	RunState.gold += earned
	RunState.total_score += earned

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
	if player_hit_invulnerability_left > 0.0:
		return
	player_hit_invulnerability_left = player_hit_invulnerability_seconds
	if player != null and player.has_method("play_hit_feedback"):
		player.play_hit_feedback(player_hit_invulnerability_seconds)
	if _uses_sync():
		sync_controller.apply_damage(amount)
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
	var choices := _build_reward_pool()
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

func _build_reward_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for weapon_id in WEAPON_IDS:
		var weapon_level := RunState.get_weapon_level(weapon_id)
		if weapon_level > 0 and weapon_level < 3:
			pool.append(_weapon_reward(weapon_id, weapon_level + 1, "升级武器"))
		elif weapon_level <= 0 and RunState.get_weapon_count() < RunState.weapon_slots:
			pool.append(_weapon_reward(weapon_id, 1, "新武器"))
	for passive_id in RunState.PASSIVE_IDS:
		var passive_level := RunState.get_passive_level(passive_id)
		if passive_level > 0 and passive_level < 3:
			pool.append(_passive_reward(passive_id, passive_level + 1, "升级被动"))
		elif passive_level <= 0 and RunState.get_passive_count() < RunState.passive_slots:
			pool.append(_passive_reward(passive_id, 1, "新被动"))
	return pool

func _weapon_reward(weapon_id: String, level: int, prefix: String) -> Dictionary:
	return {
		"id": "weapon:%s:%d" % [weapon_id, level],
		"kind": "weapon",
		"weapon_id": weapon_id,
		"level": level,
		"weight": 1.0,
		"tags": ["weapon", weapon_id],
		"label": "%s\n%s Lv.%d" % [prefix, _weapon_display_name(weapon_id), level],
	}

func _passive_reward(passive_id: String, level: int, prefix: String) -> Dictionary:
	return {
		"id": "passive:%s:%d" % [passive_id, level],
		"kind": "passive",
		"passive_id": passive_id,
		"level": level,
		"weight": 1.0,
		"tags": ["passive", passive_id],
		"label": "%s\n%s Lv.%d\n%s" % [prefix, _passive_display_name(passive_id), level, _passive_stats_text(passive_id, level)],
	}

func _choose_reward(choice: Dictionary) -> void:
	match String(choice.get("kind", "")):
		"weapon":
			var weapon_id := String(choice.get("weapon_id", "projectile"))
			RunState.weapons[weapon_id] = clampi(int(choice.get("level", 1)), 1, 3)
			weapon_manager.refresh_weapons()
			room_status_text = "%s 提升到 Lv.%d。" % [_weapon_display_name(weapon_id), RunState.get_weapon_level(weapon_id)]
		"passive":
			var passive_id := String(choice.get("passive_id", "move_speed"))
			RunState.set_passive_level(passive_id, int(choice.get("level", 1)))
			sync_controller.sync_rate = minf(sync_controller.sync_rate, RunState.get_sync_max())
			room_status_text = "%s 提升到 Lv.%d。" % [_passive_display_name(passive_id), RunState.get_passive_level(passive_id)]
	reward_overlay.hide_overlay()
	get_tree().paused = false
	pending_reward_chest = null
	if pending_finish_after_reward:
		pending_finish_after_reward = false
		_finish(true)

func _upgradable_existing_weapons() -> Array[String]:
	var result: Array[String] = []
	for weapon_id in WEAPON_IDS:
		if RunState.get_weapon_level(weapon_id) > 0 and RunState.get_weapon_level(weapon_id) < 3:
			result.append(weapon_id)
	return result

func _available_new_weapons() -> Array[String]:
	var result: Array[String] = []
	if RunState.get_weapon_count() >= RunState.weapon_slots:
		return result
	for weapon_id in WEAPON_IDS:
		if RunState.get_weapon_level(weapon_id) <= 0:
			result.append(weapon_id)
	return result

func _weapon_display_name(weapon_id: String) -> String:
	match weapon_id:
		"aura":
			return "光环"
		"projectile":
			return "基础弹"
		"shape":
			return "固定形状"
		"beam":
			return "射线"
	return weapon_id

func _passive_display_name(passive_id: String) -> String:
	match passive_id:
		"move_speed":
			return "移动速度"
		"damage_bonus":
			return "全武器伤害"
		"cooldown_bonus":
			return "冷却缩短"
		"pickup_bonus":
			return "金币吸附"
		"sync_bonus":
			return "同步强化"
		"gold_bonus":
			return "金币收益"
	return passive_id

func _passive_stats_text(passive_id: String, level: int) -> String:
	match passive_id:
		"move_speed":
			return "移动速度 +%d%%" % int(level * 8)
		"damage_bonus":
			return "全武器伤害 +%d%%" % int(level * 12)
		"cooldown_bonus":
			return "武器冷却 -%d%%" % int(level * 8)
		"pickup_bonus":
			return "金币吸附范围 +%d%%" % int(level * 25)
		"sync_bonus":
			return "同步上限 +%d，恢复 +%d%%" % [level * 10, level * 20]
		"gold_bonus":
			return "金币收益 +%d%%" % int(level * 15)
	return ""

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
	spawner.stop()
	var final_sync_rate := sync_controller.sync_rate if _uses_sync() else RunState.next_battle_initial_sync
	battle_finished.emit(success, final_sync_rate)
