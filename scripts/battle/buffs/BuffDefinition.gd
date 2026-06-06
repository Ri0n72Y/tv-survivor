extends RefCounted
class_name BuffDefinition

var id := ""
var display_name := ""
var icon_path := ""
var tags: Array[String] = []
var max_stacks := 1
var tick_seconds := 1.0
var duration_seconds := -1.0

static func create(
	buff_id: String,
	buff_name: String,
	buff_max_stacks: int = 1,
	buff_tick_seconds: float = 1.0,
	buff_duration_seconds: float = -1.0,
	buff_tags: Array[String] = [],
	buff_icon_path: String = ""
) -> BuffDefinition:
	var definition := BuffDefinition.new()
	definition.id = buff_id
	definition.display_name = buff_name
	definition.max_stacks = maxi(1, buff_max_stacks)
	definition.tick_seconds = maxf(0.01, buff_tick_seconds)
	definition.duration_seconds = buff_duration_seconds
	definition.tags = buff_tags.duplicate()
	definition.icon_path = buff_icon_path
	return definition
