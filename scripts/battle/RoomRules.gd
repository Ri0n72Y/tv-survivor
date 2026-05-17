extends RefCounted
class_name RoomRules

const USES_SYNC := "uses_sync"
const SHOW_SIGNAL_AREA := "show_signal_area"
const SIGNAL_AFFECTS_SYNC := "signal_affects_sync"
const EDGE_IS_WALL := "edge_is_wall"

static func for_room_type(room_type: String) -> Dictionary:
	match room_type:
		GridTypes.CELL_ELITE, GridTypes.CELL_BOSS:
			return {
				USES_SYNC: true,
				SHOW_SIGNAL_AREA: false,
				SIGNAL_AFFECTS_SYNC: false,
				EDGE_IS_WALL: true,
			}
		GridTypes.CELL_TASK, GridTypes.CELL_SEARCH:
			return {
				USES_SYNC: true,
				SHOW_SIGNAL_AREA: true,
				SIGNAL_AFFECTS_SYNC: true,
				EDGE_IS_WALL: false,
			}
		_:
			return {
				USES_SYNC: true,
				SHOW_SIGNAL_AREA: true,
				SIGNAL_AFFECTS_SYNC: true,
				EDGE_IS_WALL: false,
			}

static func uses_sync(room_type: String) -> bool:
	return bool(for_room_type(room_type).get(USES_SYNC, true))
