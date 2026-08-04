extends Resource
class_name ContentDefinition

@export var content_id: StringName = &""
@export var display_name: String = ""
@export_range(1, 99, 1) var max_level: int = 1
@export var sort_order: int = 0
@export var tags: PackedStringArray = PackedStringArray()

func get_validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if String(content_id).strip_edges().is_empty():
		errors.append("content_id cannot be empty")
	if display_name.strip_edges().is_empty():
		errors.append("display_name cannot be empty for '%s'" % content_id)
	if max_level <= 0:
		errors.append("max_level must be positive for '%s'" % content_id)
	return errors

func has_tag(tag: StringName) -> bool:
	return tags.has(String(tag))
