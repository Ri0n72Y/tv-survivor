extends RefCounted
class_name RewardOption

enum Kind {
	WEAPON,
	PASSIVE,
}

var _id: StringName = &""
var _kind: int = -1
var _content_id: StringName = &""
var _level: int = 0
var _weight: float = 1.0
var _tags: PackedStringArray = PackedStringArray()
var _label: String = ""

var id: StringName:
	get:
		return _id

var kind: int:
	get:
		return _kind

var content_id: StringName:
	get:
		return _content_id

var level: int:
	get:
		return _level

var weight: float:
	get:
		return _weight

var tags: PackedStringArray:
	get:
		return PackedStringArray(_tags)

var label: String:
	get:
		return _label

static func create(
	reward_id: StringName,
	reward_kind: int,
	reward_content_id: StringName,
	target_level: int,
	reward_weight: float,
	reward_tags: PackedStringArray,
	reward_label: String
) -> RewardOption:
	var option := RewardOption.new()
	option._id = reward_id
	option._kind = reward_kind
	option._content_id = reward_content_id
	option._level = target_level
	option._weight = 0.0 if is_nan(reward_weight) or is_inf(reward_weight) else maxf(0.0, reward_weight)
	option._tags = PackedStringArray(reward_tags)
	option._label = reward_label
	return option

static func from_legacy_dictionary(choice: Dictionary) -> RewardOption:
	var kind_text := String(choice.get("kind", ""))
	var resolved_kind := -1
	var content_value: Variant = choice.get("content_id", "")
	match kind_text:
		"weapon":
			resolved_kind = Kind.WEAPON
			content_value = choice.get("weapon_id", content_value)
		"passive":
			resolved_kind = Kind.PASSIVE
			content_value = choice.get("passive_id", content_value)
	var resolved_tags := _parse_tags(choice.get("tags", []))
	return RewardOption.create(
		StringName(String(choice.get("id", ""))),
		resolved_kind,
		StringName(String(content_value)),
		_parse_level(choice.get("level", 0)),
		_safe_weight(choice.get("weight", 1.0)),
		resolved_tags,
		String(choice.get("label", "奖励"))
	)

func duplicate_value() -> RewardOption:
	return RewardOption.create(_id, _kind, _content_id, _level, _weight, _tags, _label)

func to_pool_entry() -> Dictionary:
	return {
		"id": String(_id),
		"weight": _weight,
		"tags": Array(_tags),
		"option": self,
	}

func to_legacy_dictionary() -> Dictionary:
	var result := {
		"id": String(_id),
		"kind": _kind_name(_kind),
		"level": _level,
		"weight": _weight,
		"tags": Array(_tags),
		"label": _label,
	}
	match _kind:
		Kind.WEAPON:
			result["weapon_id"] = String(_content_id)
		Kind.PASSIVE:
			result["passive_id"] = String(_content_id)
		_:
			result["content_id"] = String(_content_id)
	return result

static func _kind_name(value: int) -> String:
	match value:
		Kind.WEAPON:
			return "weapon"
		Kind.PASSIVE:
			return "passive"
	return ""

static func _parse_tags(value: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	match typeof(value):
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY:
			for tag in value:
				result.append(String(tag))
	return result

static func _parse_level(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			var number := float(value)
			return 0 if is_nan(number) or is_inf(number) else int(number)
		TYPE_STRING, TYPE_STRING_NAME:
			var text := String(value).strip_edges()
			return int(text) if text.is_valid_int() else 0
	return 0

static func _safe_weight(value: Variant) -> float:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0.0
	var number := float(value)
	return 0.0 if is_nan(number) or is_inf(number) else maxf(0.0, number)
