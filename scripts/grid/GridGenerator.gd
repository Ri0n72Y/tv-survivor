extends RefCounted
class_name GridGenerator

const Constants = preload("res://scripts/core/Constants.gd")
const GridTypeDefs = preload("res://scripts/grid/GridTypes.gd")

const DEFAULT_MAP_PATH := "res://data/maps/default_grid.json"
const START_POS := Vector2i(0, 5)

static func generate(seed_value: int, config_path: String = DEFAULT_MAP_PATH) -> Array:
	var config := load_map_config(config_path)
	if String(config.get("mode", "static")) == "random":
		return generate_random(seed_value, _random_config(config))

	var grid := generate_from_config(config)
	if not grid.is_empty():
		return grid
	return generate_random(seed_value, _random_config(config))

static func load_map_config(config_path: String) -> Dictionary:
	if not FileAccess.file_exists(config_path):
		push_warning("Grid map config not found: %s" % config_path)
		return {}

	var file := FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		push_warning("Grid map config cannot be opened: %s" % config_path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Grid map config is not a JSON object: %s" % config_path)
		return {}
	return parsed as Dictionary

static func generate_from_config(config: Dictionary) -> Array:
	var rows_value = config.get("rows", [])
	if typeof(rows_value) != TYPE_ARRAY:
		push_warning("Grid map config rows must be an array.")
		return []
	var rows: Array = rows_value
	if rows.is_empty():
		return []

	var size := int(config.get("size", rows.size()))
	if size <= 0 or rows.size() != size:
		push_warning("Grid map config has invalid size or row count.")
		return []

	var grid := _new_empty_grid(size)
	var start_pos := _read_vector2i(config.get("start", [START_POS.x, START_POS.y]), START_POS)
	if not _is_inside(start_pos, size):
		push_warning("Grid map config start position is outside the map.")
		return []
	var start_count := 0

	for y in range(size):
		var row := String(rows[y])
		if row.length() != size:
			push_warning("Grid map config row %d has invalid width." % y)
			return []
		for x in range(size):
			var symbol := row.substr(x, 1)
			var cell_type := _cell_type_from_symbol(symbol)
			if cell_type == "":
				push_warning("Grid map config has unknown cell symbol '%s' at %d,%d." % [symbol, x, y])
				return []
			_set_cell_type(grid, Vector2i(x, y), cell_type)
			if cell_type == GridTypeDefs.CELL_START:
				start_pos = Vector2i(x, y)
				start_count += 1

	if start_count == 0:
		_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)
	elif start_count > 1:
		push_warning("Grid map config must contain only one start cell.")
		return []

	var targets := _target_positions(grid, start_pos)
	if not _all_targets_reachable(grid, start_pos, targets):
		push_warning("Grid map config has unreachable target cells.")
		return []

	_apply_initial_fog(grid, start_pos)
	return grid

static func generate_random(seed_value: int, config: Dictionary = {}) -> Array:
	var size := maxi(1, int(config.get("size", Constants.GRID_SIZE)))
	var start_pos := _read_vector2i(config.get("start", [START_POS.x, START_POS.y]), START_POS)
	if not _is_inside(start_pos, size):
		start_pos = Vector2i(0, size - 1)
	var max_attempts := int(config.get("max_attempts", 100))
	var task_count := int(config.get("task_count", Constants.TASK_COUNT))
	var chest_count := int(config.get("chest_count", Constants.CHEST_COUNT))
	var elite_count := int(config.get("elite_count", Constants.ELITE_ROOM_COUNT))
	var boss_count := int(config.get("boss_count", Constants.BOSS_ROOM_COUNT))
	var obstacle_count := int(config.get("obstacle_count", Constants.OBSTACLE_COUNT))

	var rng := RandomNumberGenerator.new()
	for attempt in range(max_attempts):
		rng.seed = seed_value + attempt
		var grid := _new_empty_grid(size)
		_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)
		var available := _all_positions_except(size, [start_pos])
		_shuffle_positions(available, rng)

		var target_positions: Array[Vector2i] = []
		target_positions.append_array(_place_random_cells(grid, available, task_count, GridTypeDefs.CELL_TASK))
		target_positions.append_array(_place_random_cells(grid, available, chest_count, GridTypeDefs.CELL_CHEST))
		target_positions.append_array(_place_random_cells(grid, available, elite_count, GridTypeDefs.CELL_ELITE))
		target_positions.append_array(_place_random_cells(grid, available, boss_count, GridTypeDefs.CELL_BOSS))
		_place_random_cells(grid, available, obstacle_count, GridTypeDefs.CELL_BLOCKED)

		if _all_targets_reachable(grid, start_pos, target_positions):
			_apply_initial_fog(grid, start_pos)
			return grid

	return _generate_random_fallback(seed_value, size, start_pos, task_count, chest_count, elite_count, boss_count)

static func _random_config(config: Dictionary) -> Dictionary:
	var random_value = config.get("random", {})
	var random_config: Dictionary = {}
	if typeof(random_value) == TYPE_DICTIONARY:
		random_config = (random_value as Dictionary).duplicate()
	if not random_config.has("size") and config.has("size"):
		random_config["size"] = config["size"]
	if not random_config.has("start") and config.has("start"):
		random_config["start"] = config["start"]
	return random_config

static func _new_empty_grid(size: int) -> Array:
	var grid: Array = []
	for y in range(size):
		var row: Array = []
		for x in range(size):
			row.append({
				"x": x,
				"y": y,
				"type": GridTypeDefs.CELL_EMPTY,
				"state": GridTypeDefs.STATE_HIDDEN,
				"opened": false,
				"cleared": false,
			})
		grid.append(row)
	return grid

static func _generate_random_fallback(
	seed_value: int,
	size: int,
	start_pos: Vector2i,
	task_count: int,
	chest_count: int,
	elite_count: int,
	boss_count: int
) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var grid := _new_empty_grid(size)
	_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)
	var available := _all_positions_except(size, [start_pos])
	_shuffle_positions(available, rng)
	_place_random_cells(grid, available, task_count, GridTypeDefs.CELL_TASK)
	_place_random_cells(grid, available, chest_count, GridTypeDefs.CELL_CHEST)
	_place_random_cells(grid, available, elite_count, GridTypeDefs.CELL_ELITE)
	_place_random_cells(grid, available, boss_count, GridTypeDefs.CELL_BOSS)
	_apply_initial_fog(grid, start_pos)
	return grid

static func _place_random_cells(grid: Array, available: Array[Vector2i], count: int, cell_type: String) -> Array[Vector2i]:
	var positions := _take_positions(available, count)
	for pos in positions:
		_set_cell_type(grid, pos, cell_type)
	return positions

static func _set_cell_type(grid: Array, pos: Vector2i, cell_type: String) -> void:
	grid[pos.y][pos.x]["type"] = cell_type

static func _all_positions_except(size: int, excluded: Array) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(size):
		for x in range(size):
			var pos := Vector2i(x, y)
			if not excluded.has(pos):
				positions.append(pos)
	return positions

static func _shuffle_positions(positions: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(positions.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := positions[i]
		positions[i] = positions[j]
		positions[j] = tmp

static func _take_positions(positions: Array[Vector2i], count: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for _i in range(min(count, positions.size())):
		result.append(positions.pop_back())
	return result

static func _target_positions(grid: Array, start_pos: Vector2i) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var pos := Vector2i(x, y)
			if pos == start_pos:
				continue
			var cell_type := String(grid[y][x].get("type", GridTypeDefs.CELL_EMPTY))
			if cell_type != GridTypeDefs.CELL_EMPTY and cell_type != GridTypeDefs.CELL_BLOCKED:
				targets.append(pos)
	return targets

static func _all_targets_reachable(grid: Array, start_pos: Vector2i, targets: Array[Vector2i]) -> bool:
	var reachable := _bfs_reachable(grid, start_pos)
	for target in targets:
		if not reachable.has(target):
			return false
	return true

static func _bfs_reachable(grid: Array, start: Vector2i) -> Array[Vector2i]:
	var visited: Array[Vector2i] = []
	var queue: Array[Vector2i] = []
	visited.append(start)
	queue.append(start)
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		for neighbor: Vector2i in _neighbors(current, grid.size()):
			if visited.has(neighbor):
				continue
			if grid[neighbor.y][neighbor.x]["type"] == GridTypeDefs.CELL_BLOCKED:
				continue
			visited.append(neighbor)
			queue.append(neighbor)
	return visited

static func _neighbors(pos: Vector2i, size: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var deltas: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for delta: Vector2i in deltas:
		var neighbor: Vector2i = pos + delta
		if _is_inside(neighbor, size):
			result.append(neighbor)
	return result

static func _apply_initial_fog(grid: Array, start_pos: Vector2i) -> void:
	_reveal_at(grid, start_pos, true)
	for neighbor: Vector2i in _neighbors(start_pos, grid.size()):
		_reveal_at(grid, neighbor, false)

static func reveal_neighbors(grid: Array, pos: Vector2i) -> void:
	_reveal_at(grid, pos, true)
	for neighbor: Vector2i in _neighbors(pos, grid.size()):
		_reveal_at(grid, neighbor, false)

static func reveal_ring(grid: Array, pos: Vector2i) -> void:
	var size := grid.size()
	for y in range(pos.y - 1, pos.y + 2):
		for x in range(pos.x - 1, pos.x + 2):
			var neighbor := Vector2i(x, y)
			if _is_inside(neighbor, size):
				_reveal_at(grid, neighbor, neighbor == pos)

static func _reveal_at(grid: Array, pos: Vector2i, visited: bool) -> void:
	if visited:
		grid[pos.y][pos.x]["state"] = GridTypeDefs.STATE_VISITED
	elif grid[pos.y][pos.x]["state"] == GridTypeDefs.STATE_HIDDEN:
		grid[pos.y][pos.x]["state"] = GridTypeDefs.STATE_REVEALED

static func _cell_type_from_symbol(symbol: String) -> String:
	match symbol:
		"S":
			return GridTypeDefs.CELL_START
		".":
			return GridTypeDefs.CELL_EMPTY
		"C":
			return GridTypeDefs.CELL_CHEST
		"T":
			return GridTypeDefs.CELL_TASK
		"E":
			return GridTypeDefs.CELL_ELITE
		"B":
			return GridTypeDefs.CELL_BOSS
		"#":
			return GridTypeDefs.CELL_BLOCKED
	return ""

static func _read_vector2i(value, fallback: Vector2i) -> Vector2i:
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return fallback

static func _is_inside(pos: Vector2i, size: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < size and pos.y < size
