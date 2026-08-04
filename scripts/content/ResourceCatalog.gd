extends RefCounted
class_name ResourceCatalog

const SUPPORTED_EXTENSIONS: Array[String] = ["tres", "res"]

static func load_resources_recursive(root_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	_append_directory(root_path.trim_suffix("/"), resources)
	return resources

static func _append_directory(directory_path: String, resources: Array[Resource]) -> void:
	var entries: PackedStringArray = ResourceLoader.list_directory(directory_path)
	entries.sort()
	for raw_entry in entries:
		var entry := String(raw_entry)
		if entry.ends_with("/"):
			_append_directory(directory_path.path_join(entry.trim_suffix("/")), resources)
			continue
		if not SUPPORTED_EXTENSIONS.has(entry.get_extension().to_lower()):
			continue
		var resource_path := directory_path.path_join(entry)
		var resource := ResourceLoader.load(resource_path)
		if resource == null:
			push_error("Failed to load catalog resource: %s" % resource_path)
			continue
		resources.append(resource)
