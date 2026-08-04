extends RefCounted
class_name WeaponDefinitions

const ROOT_PATH := "res://content/weapons"

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
		if not (resource is WeaponDefinition):
			_catalog_errors.append("Unexpected resource in weapon catalog: %s" % resource.resource_path)
			continue
		var definition := resource as WeaponDefinition
		var definition_errors := definition.get_validation_errors()
		for error in definition_errors:
			_catalog_errors.append("%s: %s" % [definition.resource_path, error])
		if not definition_errors.is_empty():
			continue
		var weapon_id := String(definition.content_id)
		if _definitions.has(weapon_id):
			_catalog_errors.append("Duplicate weapon id '%s'" % weapon_id)
			continue
		_definitions[weapon_id] = definition
		_ordered_ids.append(weapon_id)

	_ordered_ids.sort_custom(func(left: String, right: String) -> bool:
		var left_definition := _definitions[left] as WeaponDefinition
		var right_definition := _definitions[right] as WeaponDefinition
		if left_definition.sort_order == right_definition.sort_order:
			return left < right
		return left_definition.sort_order < right_definition.sort_order
	)
	for error in _catalog_errors:
		push_error(error)
	return get_catalog_errors()

static func has(weapon_id: String) -> bool:
	_ensure_loaded()
	return _definitions.has(weapon_id)

static func get_definition(weapon_id: String) -> WeaponDefinition:
	_ensure_loaded()
	return _definitions.get(weapon_id) as WeaponDefinition

static func get_max_level(weapon_id: String) -> int:
	var definition := get_definition(weapon_id)
	return definition.max_level if definition != null else 0

static func get_display_name(weapon_id: String) -> String:
	var definition := get_definition(weapon_id)
	return definition.display_name if definition != null else weapon_id

static func get_ids() -> Array[String]:
	_ensure_loaded()
	var result: Array[String] = []
	result.append_array(_ordered_ids)
	return result

static func get_stats_text(weapon_id: String, level: int) -> String:
	var definition := get_definition(weapon_id)
	return definition.get_level_description(level) if definition != null else ""

static func instantiate_runtime(weapon_id: String) -> Node:
	var definition := get_definition(weapon_id)
	return definition.instantiate_runtime() if definition != null else null

static func get_catalog_errors() -> Array[String]:
	var result: Array[String] = []
	result.append_array(_catalog_errors)
	return result

static func _ensure_loaded() -> void:
	if not _loaded:
		reload_catalog()
