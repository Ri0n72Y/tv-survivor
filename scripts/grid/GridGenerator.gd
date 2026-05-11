extends RefCounted
class_name GridGenerator

const Constants = preload("res://scripts/core/Constants.gd")
const GridTypeDefs = preload("res://scripts/grid/GridTypes.gd")
const START_POS := Vector2i(0, 5)

static func generate(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	for attempt in range(100):
		rng.seed = seed_value + attempt
		var grid := _new_empty_grid()
		_set_cell_type(grid, START_POS, GridTypeDefs.CELL_START)
		var available := _all_positions_except([START_POS])
		_shuffle_positions(available, rng)
		var task_positions := _take_positions(available, Constants.TASK_COUNT)
		for pos in task_positions:
			_set_cell_type(grid, pos, GridTypeDefs.CELL_TASK)
		var chest_positions := _take_positions(available, Constants.CHEST_COUNT)
		for pos in chest_positions:
			_set_cell_type(grid, pos, GridTypeDefs.CELL_CHEST)
		var obstacle_positions := _take_positions(available, Constants.OBSTACLE_COUNT)
		for pos in obstacle_positions:
			_set_cell_type(grid, pos, GridTypeDefs.CELL_BLOCKED)
		var target_positions: Array[Vector2i] = []
		target_positions.append_array(task_positions)
		target_positions.append_array(chest_positions)
		if _all_targets_reachable(grid, target_positions):
			_apply_initial_fog(grid)
			return grid
	return _generate_fallback(seed_value)

static func _new_empty_grid() -> Array:
	var grid: Array = []
	for y in range(Constants.GRID_SIZE):
		var row: Array = []
		for x in range(Constants.GRID_SIZE):
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

static func _generate_fallback(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var grid := _new_empty_grid()
	_set_cell_type(grid, START_POS, GridTypeDefs.CELL_START)
	var available := _all_positions_except([START_POS])
	_shuffle_positions(available, rng)
	for pos in _take_positions(available, Constants.TASK_COUNT):
		_set_cell_type(grid, pos, GridTypeDefs.CELL_TASK)
	for pos in _take_positions(available, Constants.CHEST_COUNT):
		_set_cell_type(grid, pos, GridTypeDefs.CELL_CHEST)
	_apply_initial_fog(grid)
	return grid

static func _set_cell_type(grid: Array, pos: Vector2i, cell_type: String) -> void:
	grid[pos.y][pos.x]["type"] = cell_type

static func _all_positions_except(excluded: Array) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for y in range(Constants.GRID_SIZE):
		for x in range(Constants.GRID_SIZE):
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

static func _all_targets_reachable(grid: Array, targets: Array[Vector2i]) -> bool:
	var reachable := _bfs_reachable(grid, START_POS)
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
		for neighbor: Vector2i in _neighbors(current):
			if visited.has(neighbor):
				continue
			if grid[neighbor.y][neighbor.x]["type"] == GridTypeDefs.CELL_BLOCKED:
				continue
			visited.append(neighbor)
			queue.append(neighbor)
	return visited

static func _neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var deltas: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for delta: Vector2i in deltas:
		var neighbor: Vector2i = pos + delta
		if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < Constants.GRID_SIZE and neighbor.y < Constants.GRID_SIZE:
			result.append(neighbor)
	return result

static func _apply_initial_fog(grid: Array) -> void:
	_reveal_at(grid, START_POS, true)
	for neighbor: Vector2i in _neighbors(START_POS):
		_reveal_at(grid, neighbor, false)

static func reveal_neighbors(grid: Array, pos: Vector2i) -> void:
	_reveal_at(grid, pos, true)
	for neighbor: Vector2i in _neighbors(pos):
		_reveal_at(grid, neighbor, false)

static func reveal_ring(grid: Array, pos: Vector2i) -> void:
	for y in range(pos.y - 1, pos.y + 2):
		for x in range(pos.x - 1, pos.x + 2):
			var neighbor := Vector2i(x, y)
			if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < Constants.GRID_SIZE and neighbor.y < Constants.GRID_SIZE:
				_reveal_at(grid, neighbor, neighbor == pos)

static func _reveal_at(grid: Array, pos: Vector2i, visited: bool) -> void:
	if visited:
		grid[pos.y][pos.x]["state"] = GridTypeDefs.STATE_VISITED
	elif grid[pos.y][pos.x]["state"] == GridTypeDefs.STATE_HIDDEN:
		grid[pos.y][pos.x]["state"] = GridTypeDefs.STATE_REVEALED
