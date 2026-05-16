extends RefCounted
class_name RunRngStream

var stream_name := ""
var stream_seed := 0
var draw_count := 0
var rng := RandomNumberGenerator.new()

func setup(name: String, seed_value: int) -> void:
	stream_name = name
	stream_seed = seed_value
	draw_count = 0
	rng.seed = stream_seed

func restore(state_data: Dictionary) -> void:
	stream_name = String(state_data.get("name", ""))
	stream_seed = int(state_data.get("seed", 0))
	draw_count = int(state_data.get("draw_count", 0))
	rng.seed = stream_seed
	rng.state = int(state_data.get("state", rng.state))

func save_state() -> Dictionary:
	return {
		"name": stream_name,
		"seed": stream_seed,
		"state": rng.state,
		"draw_count": draw_count,
	}

func randf() -> float:
	draw_count += 1
	return rng.randf()

func randf_range(from: float, to: float) -> float:
	draw_count += 1
	return rng.randf_range(from, to)

func randi_range(from: int, to: int) -> int:
	draw_count += 1
	return rng.randi_range(from, to)

func chance(probability: float) -> bool:
	return randf() < clampf(probability, 0.0, 1.0)

func shuffle_array(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
