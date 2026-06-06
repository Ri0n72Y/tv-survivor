extends RefCounted
class_name BuffSystem

const BuffContainerScript = preload("res://scripts/battle/buffs/BuffContainer.gd")

var containers: Dictionary = {}

func reset() -> void:
	containers.clear()

func register_container(container: BuffContainer) -> void:
	if container == null or container.owner_id == "":
		return
	containers[container.owner_id] = container

func unregister_container(owner_id: String) -> void:
	containers.erase(owner_id)

func process(delta: float) -> Dictionary:
	var events := {
		"before_tick": [],
		"tick": [],
		"after_tick": [],
	}
	for owner_id in containers:
		var container := containers[owner_id] as BuffContainer
		var expired_ids: Array[String] = []
		for buff_id in container.buffs.keys():
			var instance := container.buffs[buff_id] as BuffInstance
			var advance_result := instance.advance(delta)
			var tick_count := int(advance_result.get("ticks", 0))
			for _i in range(tick_count):
				(events["before_tick"] as Array).append(_event(owner_id, buff_id, instance))
				(events["tick"] as Array).append(_event(owner_id, buff_id, instance))
				(events["after_tick"] as Array).append(_event(owner_id, buff_id, instance))
			if bool(advance_result.get("expired", false)):
				expired_ids.append(buff_id)
		for buff_id in expired_ids:
			container.remove_buff(buff_id)
	return events

func _event(owner_id: String, buff_id: String, instance: BuffInstance) -> Dictionary:
	return {
		"owner_id": owner_id,
		"buff_id": buff_id,
		"stacks": instance.stacks,
		"source_id": instance.source_id,
		"data": instance.data,
	}
