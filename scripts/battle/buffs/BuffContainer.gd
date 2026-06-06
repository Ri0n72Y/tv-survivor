extends RefCounted
class_name BuffContainer

var owner_id := ""
var buffs: Dictionary = {}

func setup(container_owner_id: String) -> void:
	owner_id = container_owner_id
	clear()

func clear() -> void:
	buffs.clear()

func apply_buff(definition: BuffDefinition, stacks: int = 1, source_id: String = "") -> BuffInstance:
	if definition == null or definition.id == "":
		return null
	if buffs.has(definition.id):
		var existing := buffs[definition.id] as BuffInstance
		existing.add_stacks(stacks)
		return existing
	var instance := BuffInstance.new()
	instance.setup(definition, stacks, source_id)
	buffs[definition.id] = instance
	return instance

func ensure_buff(definition: BuffDefinition, initial_stacks: int = 0, source_id: String = "") -> BuffInstance:
	if definition == null or definition.id == "":
		return null
	if buffs.has(definition.id):
		return buffs[definition.id] as BuffInstance
	var instance := BuffInstance.new()
	instance.setup(definition, initial_stacks, source_id)
	buffs[definition.id] = instance
	return instance

func remove_buff(buff_id: String) -> void:
	buffs.erase(buff_id)

func has_buff(buff_id: String) -> bool:
	return buffs.has(buff_id)

func get_buff(buff_id: String) -> BuffInstance:
	if not buffs.has(buff_id):
		return null
	return buffs[buff_id] as BuffInstance

func get_buff_stacks(buff_id: String) -> int:
	var instance := get_buff(buff_id)
	if instance == null:
		return 0
	return instance.stacks

func set_buff_stacks(buff_id: String, stacks: int) -> void:
	var instance := get_buff(buff_id)
	if instance == null:
		return
	instance.set_stacks(stacks)

func get_display_buffs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for buff_id in buffs:
		var instance := buffs[buff_id] as BuffInstance
		result.append(instance.to_display_data())
	return result
