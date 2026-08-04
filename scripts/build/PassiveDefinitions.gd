extends RefCounted
class_name PassiveDefinitions

const ROOT_PATH := "res://content/passives"

static var _loaded := false
static var _definitions: Dictionary = {}
static var _ordered_ids: Array[String] = []
static var _catalog_errors: Array[String] = []

static func reload_catalog() -> Array[String]:
	_loaded = true
	_definitions.clear()
	_ordered_ids.clear()
	_catalog_errors.clear()

	for resource in ResourceCatalog.load_resources_recursive(ROOT_PATH):
		if not (resource is PassiveDefinition):
			_catalog_errors.append("Unexpected resource in passive catalog: %s" % resource.resource_path)
			continue
		var definition := resource as PassiveDefinition
		var definition_errors := definition.get_validation_errors()
		for error in definition_errors:
			_catalog_errors.append("%s: %s" % [definition.resource_path, error])
		if not definition_errors.is_empty():
			continue
		var passive_id := String(definition.content_id)
		if _definitions.has(passive_id):
			_catalog_errors.append("Duplicate passive id '%s'" % passive_id)
			continue
		var has_attribute_errors := false
		for attribute_id in definition.attribute_ids:
			if not BuildAttributes.has(StringName(attribute_id)):
				_catalog_errors.append("%s: passive '%s' references unknown attribute '%s'" % [definition.resource_path, passive_id, attribute_id])
				has_attribute_errors = true
		if has_attribute_errors:
			continue
		_definitions[passive_id] = definition
		_ordered_ids.append(passive_id)

	_ordered_ids.sort_custom(func(left: String, right: String) -> bool:
		var left_definition := _definitions[left] as PassiveDefinition
		var right_definition := _definitions[right] as PassiveDefinition
		if left_definition.sort_order == right_definition.sort_order:
			return left < right
		return left_definition.sort_order < right_definition.sort_order
	)
	for error in _catalog_errors:
		push_error(error)
	return get_catalog_errors()

static func has(passive_id: String) -> bool:
	_ensure_loaded()
	return _definitions.has(passive_id)

static func get_definition(passive_id: String) -> PassiveDefinition:
	_ensure_loaded()
	return _definitions.get(passive_id) as PassiveDefinition

static func get_max_level(passive_id: String) -> int:
	var definition := get_definition(passive_id)
	return definition.max_level if definition != null else 0

static func get_display_name(passive_id: String) -> String:
	var definition := get_definition(passive_id)
	return definition.display_name if definition != null else passive_id

static func get_per_level(passive_id: String) -> float:
	var definition := get_definition(passive_id)
	if definition == null or definition.add_per_level.is_empty():
		return 0.0
	return float(definition.add_per_level[0])

static func get_sync_max_per_level() -> float:
	return get_modifier_per_level("sync_bonus", &"sync_max")

static func get_sync_regen_per_level() -> float:
	return get_modifier_per_level("sync_bonus", &"sync_regen_multiplier")

static func get_modifier_per_level(passive_id: String, attribute_id: StringName) -> float:
	var definition := get_definition(passive_id)
	return definition.get_add_per_level(attribute_id) if definition != null else 0.0

static func get_ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	result.append_array(_ordered_ids)
	return result

static func get_stats_text(passive_id: String, level: int) -> String:
	var definition := get_definition(passive_id)
	return definition.get_level_description(level) if definition != null else ""

static func get_catalog_errors() -> Array[String]:
	var result: Array[String] = []
	result.append_array(_catalog_errors)
	return result

static func _ensure_loaded() -> void:
	if not _loaded:
		reload_catalog()
