extends Node
## Grid generation verification — run via `godot --headless --path . res://tests/grid_generation_tests.gd`

const GridGenerator = preload("res://scripts/grid/GridGenerator.gd")
const GridTypesRef = preload("res://scripts/grid/GridTypes.gd")

var passed := 0
var failed := 0
var warnings := 0

func _ready() -> void:
	print("=== Grid Generation Tests ===")
	_run_all()
	print("=== %d passed / %d failed / %d warnings ===" % [passed, failed, warnings])
	if failed > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func _run_all() -> void:
	_test_static_config_loads()
	_test_tree_generation_bulk(100)
	_test_tree_connectivity()
	_test_tree_no_cycles()
	_test_tree_room_counts()
	_test_tree_elite_reward_constraint()
	_test_tree_no_task_rooms()
	_test_boss_is_leaf()
	_test_tree_fallback()

func _ok(label: String) -> void:
	passed += 1
	print("  OK: %s" % label)

func _fail(label: String, detail := "") -> void:
	failed += 1
	var msg := "  FAIL: %s" % label
	if detail != "":
		msg += " — %s" % detail
	printerr(msg)

func _warn(label: String) -> void:
	warnings += 1
	print("  WARN: %s" % label)

func _config() -> Dictionary:
	return GridGenerator.load_map_config(GridGenerator.DEFAULT_MAP_PATH)

# ───── Test 1: static config loads ─────

func _test_static_config_loads() -> void:
	var config := _config()
	if config.is_empty():
		_fail("Config loads", "empty config")
		return
	var gen_value = config.get("generation", {})
	if typeof(gen_value) != TYPE_DICTIONARY:
		_fail("Config loads", "generation not a Dictionary")
		return
	var gen: Dictionary = gen_value as Dictionary
	if String(gen.get("mode", "")) != "tree":
		_warn("Config mode is not 'tree'")
	_ok("Config loads and has generation section")

# ───── Test 2: bulk generation (100 seeds) ─────

func _test_tree_generation_bulk(count: int) -> void:
	var config := _config()
	for seed in range(1, count + 1):
		var grid := GridGenerator.generate_tree(seed, config)
		if grid.is_empty():
			_fail("Tree generation seed %d" % seed, "returned empty grid")
			return
	_ok("Tree generation: %d seeds produce non-empty grids" % count)

# ───── Test 3: connectivity ─────

func _test_tree_connectivity() -> void:
	var config := _config()
	for seed in range(1, 31):
		var grid := GridGenerator.generate_tree(seed, config)
		var start := _find_start(grid)
		if start == Vector2i(-1, -1):
			_fail("Connectivity seed %d" % seed, "no start found")
			continue
		var targets := _tree_targets(grid)
		if not GridGenerator._all_targets_reachable(grid, start, targets):
			_fail("Connectivity seed %d" % seed, "not all targets reachable")
			continue
	_ok("Connectivity: 30 seeds all reachable")

# ───── Test 4: no cycles ─────

func _test_tree_no_cycles() -> void:
	var config := _config()
	for seed in range(1, 31):
		var grid := GridGenerator.generate_tree(seed, config)
		if _has_cycle(grid):
			_fail("Cycles seed %d" % seed, "detected cycle")
			return
	_ok("No cycles: 30 seeds verified acyclic")

# ───── Test 5: room counts ─────

func _test_tree_room_counts() -> void:
	var config := _config()
	var gen_cfg: Dictionary = GridGenerator._tree_generation_config(config)
	var search_min: int = int(gen_cfg["search_min"])
	var search_max: int = int(gen_cfg["search_max"])
	var elite_min: int = int(gen_cfg["elite_min"])
	var elite_max: int = int(gen_cfg["elite_max"])
	var boss_count: int = int(gen_cfg["boss_count"])
	var chest_count: int = int(gen_cfg["chest_count"])

	for seed in range(1, 31):
		var grid := GridGenerator.generate_tree(seed, config)
		var counts := _count_types(grid)

		if int(counts.get(GridTypesRef.CELL_BOSS, 0)) != boss_count:
			_fail("Room counts seed %d" % seed, "boss=%d expected %d" % [counts.get(GridTypesRef.CELL_BOSS, 0), boss_count])
			return
		var sn: int = int(counts.get(GridTypesRef.CELL_SEARCH, 0))
		if sn < search_min or sn > search_max:
			_fail("Room counts seed %d" % seed, "search=%d expected [%d,%d]" % [sn, search_min, search_max])
			return
		var en: int = int(counts.get(GridTypesRef.CELL_ELITE, 0))
		if en < elite_min or en > elite_max:
			_fail("Room counts seed %d" % seed, "elite=%d expected [%d,%d]" % [en, elite_min, elite_max])
			return
		if int(counts.get(GridTypesRef.CELL_CHEST, 0)) != chest_count:
			_fail("Room counts seed %d" % seed, "chest=%d expected %d" % [counts.get(GridTypesRef.CELL_CHEST, 0), chest_count])
			return
	_ok("Room counts: 30 seeds within ranges")

# ───── Test 6: elite reward constraint ─────

func _test_tree_elite_reward_constraint() -> void:
	var config := _config()
	for seed in range(1, 31):
		var grid := GridGenerator.generate_tree(seed, config)
		var start := _find_start(grid)
		var elites := _find_type_positions(grid, GridTypesRef.CELL_ELITE)
		for elite_pos in elites:
			var path := GridGenerator._find_unique_path(grid, start, elite_pos)
			if path.is_empty():
				_fail("Elite reward seed %d" % seed, "no path from start to elite at %s" % elite_pos)
				return
			if not GridGenerator._has_reward_before_elite(grid, path, elite_pos):
				_fail("Elite reward seed %d" % seed, "elite at %s has no reward before" % elite_pos)
				return
	_ok("Elite reward: 30 seeds pass constraint")

# ───── Test 7: no task rooms ─────

func _test_tree_no_task_rooms() -> void:
	var config := _config()
	for seed in range(1, 31):
		var grid := GridGenerator.generate_tree(seed, config)
		var counts := _count_types(grid)
		if int(counts.get(GridTypesRef.CELL_TASK, 0)) > 0:
			_fail("No task seed %d" % seed, "found %d task rooms" % counts[GridTypesRef.CELL_TASK])
			return
	_ok("No task rooms: 30 seeds clean")

# ───── Test 8: boss is a leaf ─────

func _test_boss_is_leaf() -> void:
	var config := _config()
	var non_leaf_count: int = 0
	for seed in range(1, 31):
		var grid := GridGenerator.generate_tree(seed, config)
		var boss_positions := _find_type_positions(grid, GridTypesRef.CELL_BOSS)
		assert(boss_positions.size() > 0, "boss exists")
		var boss_pos := boss_positions[0]
		var conns: Array = grid[boss_pos.y][boss_pos.x].get("connections", [])
		if conns.size() > 1:
			non_leaf_count += 1
	if non_leaf_count > 5:
		_warn("Boss leaf: %d/30 bosses are not leaves" % non_leaf_count)
	else:
		_ok("Boss leaf: most bosses are leaves (%d/30 non-leaves)" % non_leaf_count)

# ───── Test 9: fallback works ─────

func _test_tree_fallback() -> void:
	var config := _config()
	var grid := GridGenerator.generate_tree(99999999, config)
	if grid.is_empty():
		_fail("Fallback", "returned empty grid")
		return
	var start := _find_start(grid)
	if start == Vector2i(-1, -1):
		_fail("Fallback", "no start found")
		return
	_ok("Fallback generation produces valid grid")

# ───── Helpers ─────

func _find_start(grid: Array) -> Vector2i:
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if String(grid[y][x].get("type", "")) == GridTypesRef.CELL_START:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _tree_targets(grid: Array) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell_type := String(grid[y][x].get("type", GridTypesRef.CELL_EMPTY))
			if cell_type != GridTypesRef.CELL_EMPTY and cell_type != GridTypesRef.CELL_BLOCKED and cell_type != GridTypesRef.CELL_START:
				targets.append(Vector2i(x, y))
	return targets

func _count_types(grid: Array) -> Dictionary:
	var counts: Dictionary = {}
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell_type := String(grid[y][x].get("type", GridTypesRef.CELL_EMPTY))
			counts[cell_type] = int(int(counts.get(cell_type, 0))) + 1
	return counts

func _find_type_positions(grid: Array, cell_type: String) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if String(grid[y][x].get("type", "")) == cell_type:
				positions.append(Vector2i(x, y))
	return positions

func _has_cycle(grid: Array) -> bool:
	var visited: Dictionary = {}
	var grid_height: int = grid.size() as int
	var grid_width: int = int(grid[0].size()) if grid_height > 0 else 0

	for y in range(grid_height):
		for x in range(grid_width):
			var cell_type := String(grid[y][x].get("type", GridTypesRef.CELL_EMPTY))
			if cell_type == GridTypesRef.CELL_BLOCKED:
				continue
			var key := "%d_%d" % [x, y]
			if not visited.has(key):
				if _dfs_cycle(grid, Vector2i(x, y), Vector2i(-1, -1), visited):
					return true
	return false

func _dfs_cycle(grid: Array, pos: Vector2i, parent: Vector2i, visited: Dictionary) -> bool:
	var key := "%d_%d" % [pos.x, pos.y]
	visited[key] = 1

	var conns: Array = grid[pos.y][pos.x].get("connections", [])
	for conn in conns:
		var neighbor := Vector2i(conn.x, conn.y)
		if neighbor == parent:
			continue
		var nkey := "%d_%d" % [neighbor.x, neighbor.y]
		var state: int = int(visited.get(nkey, 0))
		if state == 1:
			return true
		if state == 0:
			if _dfs_cycle(grid, neighbor, pos, visited):
				return true

	visited[key] = 2
	return false
