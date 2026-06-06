extends RefCounted
class_name BuffInstance

var definition: BuffDefinition
var stacks := 0
var tick_elapsed := 0.0
var remaining_seconds := -1.0
var source_id := ""
var data: Dictionary = {}

func setup(buff_definition: BuffDefinition, initial_stacks: int = 1, buff_source_id: String = "") -> void:
	definition = buff_definition
	source_id = buff_source_id
	stacks = clampi(initial_stacks, 0, definition.max_stacks)
	tick_elapsed = 0.0
	remaining_seconds = definition.duration_seconds

func add_stacks(amount: int = 1) -> void:
	if definition == null:
		return
	stacks = clampi(stacks + amount, 0, definition.max_stacks)
	if definition.duration_seconds > 0.0:
		remaining_seconds = definition.duration_seconds

func set_stacks(next_stacks: int) -> void:
	if definition == null:
		stacks = max(0, next_stacks)
		return
	stacks = clampi(next_stacks, 0, definition.max_stacks)

func advance(delta: float) -> Dictionary:
	var result := {
		"ticks": 0,
		"expired": false,
	}
	if definition == null:
		result["expired"] = true
		return result
	if definition.duration_seconds > 0.0:
		remaining_seconds -= delta
		if remaining_seconds <= 0.0:
			result["expired"] = true
	tick_elapsed += delta
	while tick_elapsed >= definition.tick_seconds:
		tick_elapsed -= definition.tick_seconds
		result["ticks"] = int(result["ticks"]) + 1
	return result

func to_display_data() -> Dictionary:
	if definition == null:
		return {}
	return {
		"id": definition.id,
		"name": definition.display_name,
		"icon_path": definition.icon_path,
		"stacks": stacks,
		"remaining_seconds": remaining_seconds,
		"tags": definition.tags.duplicate(),
	}
