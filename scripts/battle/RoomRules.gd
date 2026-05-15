extends RefCounted
class_name RoomRules

const USES_SYNC := "uses_sync"
const SHOW_SIGNAL_AREA := "show_signal_area"
const EDGE_IS_WALL := "edge_is_wall"

static func for_room_type(room_type: String) -> Dictionary:
	match room_type:
		GridTypes.CELL_ELITE, GridTypes.CELL_BOSS:
			return {
				USES_SYNC: false,
				SHOW_SIGNAL_AREA: false,
				EDGE_IS_WALL: true,
			}
		_:
			return {
				USES_SYNC: true,
				SHOW_SIGNAL_AREA: true,
				EDGE_IS_WALL: false,
			}

static func uses_sync(room_type: String) -> bool:
	return bool(for_room_type(room_type).get(USES_SYNC, true))
