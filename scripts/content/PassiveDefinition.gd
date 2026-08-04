extends ContentDefinition
class_name PassiveDefinition

@export var attribute_ids: PackedStringArray = PackedStringArray()
@export var add_per_level: PackedFloat32Array = PackedFloat32Array()
@export var level_descriptions: PackedStringArray = PackedStringArray()

func get_add_per_level(attribute_id: StringName) -> float:
	var target := String(attribute_id)
	for index in range(attribute_ids.size()):
		if attribute_ids[index] == target:
			return float(add_per_level[index])
	return 0.0

func get_level_description(level: int) -> String:
	var safe_level := clampi(level, 1, max_level)
	if safe_level >= level_descriptions.size():
		return ""
	return level_descriptions[safe_level]

func get_validation_errors() -> Array[String]:
	var errors := super.get_validation_errors()
	if attribute_ids.size() != add_per_level.size():
		errors.append("passive '%s' has mismatched attribute/value arrays" % content_id)
	for attribute_id in attribute_ids:
		if String(attribute_id).strip_edges().is_empty():
			errors.append("passive '%s' contains an empty attribute id" % content_id)
	if level_descriptions.size() <= max_level:
		errors.append("passive '%s' must provide descriptions for levels 1..%d" % [content_id, max_level])
	else:
		for level in range(1, max_level + 1):
			if level_descriptions[level].strip_edges().is_empty():
				errors.append("passive '%s' has an empty level-%d description" % [content_id, level])
	return errors
