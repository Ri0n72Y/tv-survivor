extends RefCounted
class_name GridTypes

const CELL_START := "start"
const CELL_EMPTY := "empty"
const CELL_CHEST := "chest"
const CELL_TASK := "task"
const CELL_SEARCH := "search"
const CELL_ELITE := "elite"
const CELL_BOSS := "boss"
const CELL_BLOCKED := "blocked"

const STATE_HIDDEN := "hidden"
const STATE_REVEALED := "revealed"
const STATE_VISITED := "visited"
const STATE_CLEARED := "cleared"

# Minimap colours (lightweight palette)
const MINIMAP_COLORS := {
	CELL_START: Color(0.16, 0.62, 0.22),
	CELL_EMPTY: Color(0.25, 0.26, 0.28),
	CELL_CHEST: Color(0.92, 0.66, 0.12),
	CELL_SEARCH: Color(0.40, 0.55, 0.80),
	CELL_ELITE: Color(0.72, 0.18, 0.40),
	CELL_BOSS: Color(0.95, 0.30, 0.08),
	"current": Color(1.0, 0.95, 0.36),
	"visited": Color(0.20, 0.28, 0.36),
	"revealed": Color(0.35, 0.36, 0.38),
	"hidden": Color(0.08, 0.08, 0.10),
	"connection": Color(0.28, 0.30, 0.34),
}

# Battle room types that trigger combat
const BATTLE_ROOMS := [CELL_TASK, CELL_SEARCH, CELL_ELITE, CELL_BOSS]

# Tree-generation battle rooms (excludes task)
const TREE_BATTLE_ROOMS := [CELL_SEARCH, CELL_ELITE, CELL_BOSS]
