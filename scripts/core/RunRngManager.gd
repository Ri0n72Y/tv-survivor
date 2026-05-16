extends RefCounted
class_name RunRngManager

const STREAM_MAP_ROUTE := "map.route"
const STREAM_GRID_NODE := "grid.node"
const STREAM_EVENT_CONTENT := "event.content"
const STREAM_BATTLE_SPAWN := "battle.spawn"
const STREAM_BATTLE_AFFIX := "battle.affix"
const STREAM_CHEST_TYPE := "chest.type"
const STREAM_CHEST_REWARD := "chest.reward"
const STREAM_WEAPON_REWARD := "reward.weapon"
const STREAM_PASSIVE_REWARD := "reward.passive"
const STREAM_SHOP_REFRESH := "shop.refresh"
const STREAM_META_UNLOCK := "meta.unlock"
const STREAM_VISUAL := "visual.nondeterministic"

const DEFAULT_STREAMS: Array[String] = [
	STREAM_MAP_ROUTE,
	STREAM_GRID_NODE,
	STREAM_EVENT_CONTENT,
	STREAM_BATTLE_SPAWN,
	STREAM_BATTLE_AFFIX,
	STREAM_CHEST_TYPE,
	STREAM_CHEST_REWARD,
	STREAM_WEAPON_REWARD,
	STREAM_PASSIVE_REWARD,
	STREAM_SHOP_REFRESH,
	STREAM_META_UNLOCK,
]

var run_seed := 0
var streams: Dictionary = {}

func start_run(seed_value: int) -> void:
	run_seed = seed_value
	streams = {}

func get_stream(stream_name: String) -> RunRngStream:
	if not streams.has(stream_name):
		var stream := RunRngStream.new()
		stream.setup(stream_name, derive_stream_seed(run_seed, stream_name))
		streams[stream_name] = stream
	return streams[stream_name]

func randf(stream_name: String) -> float:
	return get_stream(stream_name).randf()

func randf_range(stream_name: String, from: float, to: float) -> float:
	return get_stream(stream_name).randf_range(from, to)

func randi_range(stream_name: String, from: int, to: int) -> int:
	return get_stream(stream_name).randi_range(from, to)

func chance(stream_name: String, probability: float) -> bool:
	return get_stream(stream_name).chance(probability)

func shuffle_array(stream_name: String, items: Array) -> void:
	get_stream(stream_name).shuffle_array(items)

func save_state() -> Dictionary:
	var stream_states := {}
	for stream_name in streams.keys():
		stream_states[stream_name] = (streams[stream_name] as RunRngStream).save_state()
	return {
		"run_seed": run_seed,
		"streams": stream_states,
	}

func restore_state(state_data: Dictionary) -> void:
	run_seed = int(state_data.get("run_seed", 0))
	streams = {}
	var stream_states: Dictionary = state_data.get("streams", {})
	for stream_name in stream_states.keys():
		var stream := RunRngStream.new()
		stream.restore(stream_states[stream_name])
		streams[stream_name] = stream

func create_visual_rng() -> RandomNumberGenerator:
	var visual_rng := RandomNumberGenerator.new()
	visual_rng.randomize()
	return visual_rng

static func derive_stream_seed(seed_value: int, stream_name: String) -> int:
	var hash := _stable_hash(stream_name)
	var mixed := int(seed_value) ^ int(hash) ^ 0x5bd1e995
	mixed = int((mixed * 1103515245 + 12345) & 0x7fffffff)
	return mixed

static func _stable_hash(text: String) -> int:
	var hash := 2166136261
	for i in range(text.length()):
		hash = int((hash ^ text.unicode_at(i)) * 16777619) & 0x7fffffff
	return hash
