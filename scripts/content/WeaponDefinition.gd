extends ContentDefinition
class_name WeaponDefinition

@export var runtime_scene: PackedScene
@export var runtime_script: Script
@export var level_descriptions: PackedStringArray = PackedStringArray()

func instantiate_runtime() -> Node:
	if runtime_scene != null:
		return runtime_scene.instantiate()
	if runtime_script != null:
		return runtime_script.new() as Node
	return null

func get_level_description(level: int) -> String:
	var safe_level := clampi(level, 1, max_level)
	if safe_level >= level_descriptions.size():
		return ""
	return level_descriptions[safe_level]

func get_validation_errors() -> Array[String]:
	var errors := super.get_validation_errors()
	if runtime_scene == null and runtime_script == null:
		errors.append("weapon '%s' has no runtime implementation" % content_id)
	if level_descriptions.size() <= max_level:
		errors.append("weapon '%s' must provide descriptions for levels 1..%d" % [content_id, max_level])
	else:
		for level in range(1, max_level + 1):
			if level_descriptions[level].strip_edges().is_empty():
				errors.append("weapon '%s' has an empty level-%d description" % [content_id, level])
	return errors
