extends RefCounted
class_name SyncController

const Constants = preload("res://scripts/core/Constants.gd")

var sync_rate: float = Constants.SYNC_MAX
var time_since_damage: float = 999.0
var control_state: String = BattleTypes.CONTROLLED
var signal_text: String = BattleTypes.SIGNAL_STABLE

func setup(initial_sync: float) -> void:
	sync_rate = clampf(initial_sync, 0.0, RunState.get_sync_max())
	time_since_damage = 999.0
	control_state = BattleTypes.CONTROLLED
	signal_text = BattleTypes.SIGNAL_STABLE

func apply_damage(amount: float) -> void:
	sync_rate = maxf(0.0, sync_rate - amount)
	time_since_damage = 0.0

func update(delta: float, distance: float) -> void:
	time_since_damage += delta
	if distance >= Constants.SIGNAL_RADIUS:
		control_state = BattleTypes.DISCONNECTED
	if control_state == BattleTypes.DISCONNECTED:
		signal_text = BattleTypes.SIGNAL_DISCONNECTED
		return
	var stable_radius := Constants.SIGNAL_RADIUS * Constants.SIGNAL_STABLE_RATIO
	var weak_radius := Constants.SIGNAL_RADIUS * Constants.SIGNAL_WEAK_RATIO
	if distance < stable_radius:
		signal_text = BattleTypes.SIGNAL_STABLE
		if time_since_damage >= Constants.SYNC_REGEN_DELAY:
			sync_rate = minf(RunState.get_sync_max(), sync_rate + Constants.SYNC_REGEN_PER_SECOND * RunState.get_sync_regen_multiplier() * delta)
	elif distance < weak_radius:
		signal_text = BattleTypes.SIGNAL_DECLINING
		sync_rate = maxf(0.0, sync_rate - Constants.SYNC_EDGE_DRAIN_PER_SECOND * delta)
	else:
		signal_text = BattleTypes.SIGNAL_WEAK

func recover_from_disconnect() -> void:
	control_state = BattleTypes.CONTROLLED
	sync_rate = maxf(sync_rate, Constants.SYNC_MIN_RECOVER_AFTER_DISCONNECT)
	sync_rate = minf(sync_rate, RunState.get_sync_max())
