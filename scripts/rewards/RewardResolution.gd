extends RefCounted
class_name RewardResolution

var _success: bool = false
var _kind: int = -1
var _content_id: StringName = &""
var _level: int = 0
var _display_name: String = ""
var _message: String = ""

var success: bool:
	get:
		return _success

var kind: int:
	get:
		return _kind

var content_id: StringName:
	get:
		return _content_id

var level: int:
	get:
		return _level

var display_name: String:
	get:
		return _display_name

var message: String:
	get:
		return _message

static func accepted(
	reward_kind: int = -1,
	reward_content_id: StringName = &"",
	resolved_level: int = 0,
	resolved_display_name: String = "",
	resolved_message: String = ""
) -> RewardResolution:
	var resolution := RewardResolution.new()
	resolution._success = true
	resolution._kind = reward_kind
	resolution._content_id = reward_content_id
	resolution._level = resolved_level
	resolution._display_name = resolved_display_name
	resolution._message = resolved_message
	return resolution

static func rejected(error_message: String) -> RewardResolution:
	var resolution := RewardResolution.new()
	resolution._success = false
	resolution._message = error_message
	return resolution

func to_legacy_dictionary() -> Dictionary:
	return {
		"success": _success,
		"kind": _legacy_kind_name(_kind),
		"content_id": String(_content_id),
		"level": _level,
		"display_name": _display_name,
		"message": _message,
	}

static func _legacy_kind_name(value: int) -> String:
	match value:
		RewardOption.Kind.WEAPON:
			return "weapon"
		RewardOption.Kind.PASSIVE:
			return "passive"
	return ""
