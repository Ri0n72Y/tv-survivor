extends RefCounted
class_name RandomPool

static func draw(stream: RunRngStream, items: Array, options: Dictionary = {}) -> Array:
	var count := int(options.get("count", 1))
	var allow_repeats := bool(options.get("allow_repeats", false))
	var weight_key := String(options.get("weight_key", "weight"))
	var id_key := String(options.get("id_key", "id"))
	var drawn_ids: Array = options.get("drawn_ids", [])
	var unlocked_ids: Array = options.get("unlocked_ids", [])
	var required_tags: Array = options.get("required_tags", [])
	var blocked_tags: Array = options.get("blocked_tags", [])
	var candidates := _filter_items(items, id_key, drawn_ids, unlocked_ids, required_tags, blocked_tags)
	var result: Array = []
	for _i in range(count):
		if candidates.is_empty():
			break
		var selected := _draw_one_weighted(stream, candidates, weight_key)
		result.append(selected)
		if not allow_repeats:
			candidates.erase(selected)
	return result

static func draw_one(stream: RunRngStream, items: Array, options: Dictionary = {}) -> Dictionary:
	var selected := draw(stream, items, options)
	if selected.is_empty():
		return {}
	return selected[0]

static func _filter_items(
	items: Array,
	id_key: String,
	drawn_ids: Array,
	unlocked_ids: Array,
	required_tags: Array,
	blocked_tags: Array
) -> Array:
	var result: Array = []
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var dict := item as Dictionary
		var item_id := String(dict.get(id_key, dict.get("id", "")))
		if not drawn_ids.is_empty() and drawn_ids.has(item_id):
			continue
		if not unlocked_ids.is_empty() and not unlocked_ids.has(item_id):
			continue
		var tags: Array = dict.get("tags", [])
		if not _has_all_tags(tags, required_tags):
			continue
		if _has_any_tag(tags, blocked_tags):
			continue
		result.append(dict)
	return result

static func _draw_one_weighted(stream: RunRngStream, items: Array, weight_key: String) -> Dictionary:
	var total_weight := 0.0
	for item in items:
		total_weight += maxf(0.0, float((item as Dictionary).get(weight_key, 1.0)))
	if total_weight <= 0.0:
		return items[stream.randi_range(0, items.size() - 1)]
	var roll := stream.randf_range(0.0, total_weight)
	var cursor := 0.0
	for item in items:
		cursor += maxf(0.0, float((item as Dictionary).get(weight_key, 1.0)))
		if roll <= cursor:
			return item
	return items[items.size() - 1]

static func _has_all_tags(tags: Array, required_tags: Array) -> bool:
	for tag in required_tags:
		if not tags.has(tag):
			return false
	return true

static func _has_any_tag(tags: Array, blocked_tags: Array) -> bool:
	for tag in blocked_tags:
		if tags.has(tag):
			return true
	return false
