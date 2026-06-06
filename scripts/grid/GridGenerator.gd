extends RefCounted
class_name GridGenerator

const Constants = preload("res://scripts/core/Constants.gd")
const GridTypeDefs = preload("res://scripts/grid/GridTypes.gd")
const RunRngManagerScript = preload("res://scripts/core/RunRngManager.gd")

const DEFAULT_MAP_PATH := "res://data/maps/default_grid.json"
const START_POS := Vector2i(0, 5)

# ──────────────────────────────────────────
#  Public entry
# ──────────────────────────────────────────

static func generate(seed_value: int, config_path: String = DEFAULT_MAP_PATH, rng_manager: RunRngManager = null) -> Array:
	var config := load_map_config(config_path)
	var mode := String(config.get("mode", "tree"))

	if mode == "tree":
		return generate_tree(seed_value, config, rng_manager)

	if mode == "random":
		return generate_random(seed_value, _random_config(config), rng_manager)

	var grid := generate_from_config(config)
	if not grid.is_empty():
		return grid
	return generate_random(seed_value, _random_config(config), rng_manager)

# ──────────────────────────────────────────
#  Tree-generation (mode = "tree")
# ──────────────────────────────────────────

static func generate_tree(seed_value: int, config: Dictionary, rng_manager: RunRngManager = null) -> Array:
	var gen_cfg := _tree_generation_config(config)
	var max_width: int = int(gen_cfg["max_width"])
	var max_height: int = int(gen_cfg["max_height"])
	var min_rooms: int = int(gen_cfg["min_rooms"])
	var max_rooms: int = int(gen_cfg["max_rooms"])

	var start_pos := _read_vector2i(config.get("start", [0, max_height - 1]), Vector2i(0, max_height - 1))
	var map_stream := _stream_for(seed_value, rng_manager, RunRngManagerScript.STREAM_MAP_ROUTE)
	var node_stream := _stream_for(seed_value, rng_manager, RunRngManagerScript.STREAM_GRID_NODE)

	var max_attempts := int(config.get("max_attempts", 200))
	for _attempt in range(max_attempts):
		var tree := _grow_tree(Vector2i(start_pos.x, start_pos.y), max_width, max_height, min_rooms, max_rooms, node_stream)
		if tree.is_empty():
			continue

		var grid := _tree_to_grid(tree, max_width, max_height)
		# Ensure start is explicitly typed
		_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)
		var assigned := _assign_room_types(grid, tree, start_pos, gen_cfg, map_stream)
		if not assigned:
			continue

		if not _verify_tree_constraints(grid, start_pos, gen_cfg):
			continue

		_apply_initial_fog_tree(grid, start_pos)
		return grid

	# Final fallback
	return _tree_fallback(seed_value, gen_cfg, start_pos, rng_manager)

# ───── tree config parse ─────

static func _tree_generation_config(config: Dictionary) -> Dictionary:
	var gen_value = config.get("generation", {})
	var gen_cfg: Dictionary = {}
	if typeof(gen_value) == TYPE_DICTIONARY:
		gen_cfg = (gen_value as Dictionary).duplicate()
	else:
		gen_cfg = {}

	gen_cfg["max_width"] = int(gen_cfg.get("max_width", Constants.TREE_MAX_WIDTH))
	gen_cfg["max_height"] = int(gen_cfg.get("max_height", Constants.TREE_MAX_HEIGHT))
	gen_cfg["min_rooms"] = int(gen_cfg.get("min_rooms", Constants.TREE_MIN_ROOMS))
	gen_cfg["max_rooms"] = int(gen_cfg.get("max_rooms", Constants.TREE_MAX_ROOMS))
	gen_cfg["search_min"] = int(gen_cfg.get("search_min", Constants.TREE_SEARCH_MIN))
	gen_cfg["search_max"] = int(gen_cfg.get("search_max", Constants.TREE_SEARCH_MAX))
	gen_cfg["elite_min"] = int(gen_cfg.get("elite_min", Constants.TREE_ELITE_MIN))
	gen_cfg["elite_max"] = int(gen_cfg.get("elite_max", Constants.TREE_ELITE_MAX))
	gen_cfg["boss_count"] = int(gen_cfg.get("boss_count", Constants.TREE_BOSS_COUNT))
	gen_cfg["chest_count"] = int(gen_cfg.get("chest_count", Constants.TREE_CHEST_COUNT))
	gen_cfg["ensure_reward_before_elite"] = bool(gen_cfg.get("ensure_reward_before_elite", Constants.TREE_ENSURE_REWARD_BEFORE_ELITE))
	return gen_cfg

# ───── tree growth ─────

static func _grow_tree(root: Vector2i, max_width: int, max_height: int, min_rooms: int, max_rooms: int, rng: RunRngStream) -> Dictionary:
	var nodes: Dictionary = {}
	var frontier: Array[Vector2i] = []
	nodes[_pos_key(root.x, root.y)] = _make_node(root.x, root.y)
	frontier.append(root)

	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	while not frontier.is_empty() and nodes.size() < max_rooms:
		_shuffle_positions(frontier, rng)
		var parent: Vector2i = frontier.pop_front()
		_shuffle_array_static(directions, rng)

		for dir in directions:
			if nodes.size() >= max_rooms:
				break
			var nx: int = parent.x + dir.x
			var ny: int = parent.y + dir.y
			if nx < 0 or ny < 0 or nx >= max_width or ny >= max_height:
				continue
			var key := _pos_key(nx, ny)
			if nodes.has(key):
				continue
			var child := _make_node(nx, ny)
			nodes[key] = child
			_connect_bidirectional(nodes, parent.x, parent.y, nx, ny)
			frontier.append(Vector2i(nx, ny))

	if nodes.size() < min_rooms:
		return {}
	return nodes

static func _make_node(x: int, y: int) -> Dictionary:
	return {
		"x": x,
		"y": y,
		"connections": [],
		"type": GridTypeDefs.CELL_EMPTY,
	}

static func _connect_bidirectional(nodes: Dictionary, ax: int, ay: int, bx: int, by: int) -> void:
	_append_connection(nodes, ax, ay, bx, by)
	_append_connection(nodes, bx, by, ax, ay)

static func _append_connection(nodes: Dictionary, x: int, y: int, tx: int, ty: int) -> void:
	var key := _pos_key(x, y)
	if nodes.has(key):
		var conns: Array = nodes[key]["connections"]
		var target := Vector2i(tx, ty)
		if not conns.has(target):
			conns.append(target)

static func _pos_key(x: int, y: int) -> String:
	return "%d_%d" % [x, y]

static func _shuffle_array_static(arr: Array, rng: RunRngStream) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

# ───── tree → grid ─────

static func _tree_to_grid(tree: Dictionary, max_width: int, max_height: int) -> Array:
	var grid := _new_empty_grid_rect(max_width, max_height)
	for key in tree.keys():
		var node: Dictionary = tree[key]
		var x := int(node["x"])
		var y := int(node["y"])
		grid[y][x]["x"] = x
		grid[y][x]["y"] = y
		grid[y][x]["type"] = String(node["type"])
		grid[y][x]["connections"] = node["connections"].duplicate()
		grid[y][x]["_in_tree"] = true
	# Set remaining cells as blocked
	for y in range(max_height):
		for x in range(max_width):
			if not bool(grid[y][x].get("_in_tree", false)):
				grid[y][x]["type"] = GridTypeDefs.CELL_BLOCKED
				grid[y][x]["state"] = GridTypeDefs.STATE_HIDDEN
			else:
				grid[y][x].erase("_in_tree")
	return grid

# ───── room-type assignment ─────

static func _assign_room_types(grid: Array, tree: Dictionary, start_pos: Vector2i, gen_cfg: Dictionary, rng: RunRngStream) -> bool:
	var max_attempts := int(gen_cfg.get("max_attempts", 200))
	for _attempt in range(max_attempts):
		_reset_tree_types(grid, tree)

		var node_list: Array = _tree_node_list(tree)
		_shuffle_array_static(node_list, rng)

		# Exclude start
		node_list = node_list.filter(func(n): return Vector2i(n.x, n.y) != start_pos)

		# 1. Boss: pick furthest leaf
		var boss_pos := _pick_boss_leaf(tree, start_pos)
		_set_cell_type(grid, boss_pos, GridTypeDefs.CELL_BOSS)

		# 2. Search rooms
		var search_count: int = rng.randi_range(int(gen_cfg["search_min"]), int(gen_cfg["search_max"]))
		var search_candidates := node_list.filter(func(n):
			var p = Vector2i(n.x, n.y)
			return p != boss_pos and p != start_pos
		)
		_shuffle_array_static(search_candidates, rng)
		for i in range(mini(search_count, search_candidates.size())):
			var pos := Vector2i(search_candidates[i].x, search_candidates[i].y)
			_set_cell_type(grid, pos, GridTypeDefs.CELL_SEARCH)

		# 3. Chest
		var chest_count: int = int(gen_cfg["chest_count"])
		var chest_candidates := node_list.filter(func(n):
			var p = Vector2i(n.x, n.y)
			return p != boss_pos and p != start_pos and String(grid[p.y][p.x]["type"]) == GridTypeDefs.CELL_EMPTY
		)
		_shuffle_array_static(chest_candidates, rng)
		for i in range(mini(chest_count, chest_candidates.size())):
			var pos := Vector2i(chest_candidates[i].x, chest_candidates[i].y)
			_set_cell_type(grid, pos, GridTypeDefs.CELL_CHEST)

		# 4. Elite rooms
		var elite_count: int = rng.randi_range(int(gen_cfg["elite_min"]), int(gen_cfg["elite_max"]))
		var elite_candidates := node_list.filter(func(n):
			var p = Vector2i(n.x, n.y)
			return p != boss_pos and p != start_pos and String(grid[p.y][p.x]["type"]) == GridTypeDefs.CELL_EMPTY
		)
		_shuffle_array_static(elite_candidates, rng)
		var elite_positions: Array[Vector2i] = []
		for i in range(mini(elite_count, elite_candidates.size())):
			var pos := Vector2i(elite_candidates[i].x, elite_candidates[i].y)
			elite_positions.append(pos)
			_set_cell_type(grid, pos, GridTypeDefs.CELL_ELITE)

		# 5. Verify elite reward constraint
		if gen_cfg["ensure_reward_before_elite"]:
			if not _check_elite_reward_constraint(grid, start_pos):
				continue

		return true
	return false

static func _reset_tree_types(grid: Array, tree: Dictionary) -> void:
	for key in tree.keys():
		var node: Dictionary = tree[key]
		var x: int = int(node["x"])
		var y: int = int(node["y"])
		var current_type := String(grid[y][x].get("type", ""))
		if current_type == GridTypeDefs.CELL_START:
			continue
		node["type"] = GridTypeDefs.CELL_EMPTY
		grid[y][x]["type"] = GridTypeDefs.CELL_EMPTY

static func _tree_node_list(tree: Dictionary) -> Array:
	return tree.values()

# ───── boss placement ─────

static func _pick_boss_leaf(tree: Dictionary, start_pos: Vector2i) -> Vector2i:
	var distances := _compute_distances_from(tree, start_pos)
	var leaves: Array[Vector2i] = []
	for key in tree.keys():
		var node: Dictionary = tree[key]
		var pos := Vector2i(node["x"], node["y"])
		if pos == start_pos:
			continue
		if node["connections"].size() <= 1:
			leaves.append(pos)
	if leaves.is_empty():
		# Fallback: pick any node except start
		for key in tree.keys():
			var node: Dictionary = tree[key]
			var pos := Vector2i(node["x"], node["y"])
			if pos != start_pos:
				return pos
		return start_pos

	# Sort by distance descending, pick from farthest
	leaves.sort_custom(func(a, b):
		return int(distances.get(a, 0) as int) > int(distances.get(b, 0) as int)
	)
	return leaves[0]

static func _compute_distances_from(tree: Dictionary, start: Vector2i) -> Dictionary:
	var dist: Dictionary = {}
	var queue: Array[Vector2i] = []
	dist[start] = 0
	queue.append(start)
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front() as Vector2i
		var key := _pos_key(current.x, current.y)
		var node: Dictionary = tree.get(key, {}) as Dictionary
		for conn in node.get("connections", []):
			var neighbor := Vector2i(conn.x, conn.y)
			if not dist.has(neighbor):
				dist[neighbor] = int(dist.get(current, 0) as int) + 1
				queue.append(neighbor)
	return dist

# ───── elite reward constraint ─────

static func _check_elite_reward_constraint(grid: Array, start_pos: Vector2i) -> bool:
	var elite_positions: Array[Vector2i] = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if String(grid[y][x]["type"]) == GridTypeDefs.CELL_ELITE:
				elite_positions.append(Vector2i(x, y))

	for elite_pos in elite_positions:
		var path := _find_unique_path(grid, start_pos, elite_pos)
		if path.is_empty():
			continue
		var has_reward := _has_reward_before_elite(grid, path, elite_pos)
		if not has_reward:
			return false
	return true

static func _has_reward_before_elite(grid: Array, path: Array[Vector2i], elite_pos: Vector2i) -> bool:
	for room_pos in path:
		if room_pos == elite_pos:
			break
		var cell_type := String(grid[room_pos.y][room_pos.x]["type"])
		if cell_type == GridTypeDefs.CELL_CHEST or cell_type == GridTypeDefs.CELL_SEARCH:
			return true
	return false

static func _find_unique_path(grid: Array, start_pos: Vector2i, target_pos: Vector2i) -> Array[Vector2i]:
	# BFS to find unique path in a tree (always unique if acyclic)
	var parent: Dictionary = {}
	var queue: Array[Vector2i] = []
	var visited: Array[Vector2i] = []
	queue.append(start_pos)
	visited.append(start_pos)
	parent[start_pos] = Vector2i(-1, -1)

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front() as Vector2i
		if current == target_pos:
			# Reconstruct path
			var path: Array[Vector2i] = []
			var step := target_pos
			while step != Vector2i(-1, -1):
				path.push_front(step)
				step = parent.get(step, Vector2i(-1, -1))
			return path

		var cell: Dictionary = grid[current.y][current.x]
		for conn in cell.get("connections", []):
			var neighbor := Vector2i(conn.x, conn.y)
			if visited.has(neighbor):
				continue
			var cell_type := String(grid[neighbor.y][neighbor.x]["type"])
			if cell_type == GridTypeDefs.CELL_BLOCKED:
				continue
			visited.append(neighbor)
			parent[neighbor] = current
			queue.append(neighbor)

	return []

# ───── tree verification ─────

static func _verify_tree_constraints(grid: Array, start_pos: Vector2i, gen_cfg: Dictionary) -> bool:
	# Count rooms
	var type_counts := _count_tree_room_types(grid)
	var wanted_boss: int = int(gen_cfg["boss_count"])
	var wanted_search_min: int = int(gen_cfg["search_min"])
	var wanted_search_max: int = int(gen_cfg["search_max"])
	var wanted_elite_min: int = int(gen_cfg["elite_min"])
	var wanted_elite_max: int = int(gen_cfg["elite_max"])
	var wanted_chest: int = int(gen_cfg["chest_count"])

	if type_counts.get(GridTypeDefs.CELL_BOSS, 0) != wanted_boss:
		return false
	var search_n: int = int(type_counts.get(GridTypeDefs.CELL_SEARCH, 0))
	if search_n < wanted_search_min or search_n > wanted_search_max:
		return false
	var elite_n: int = int(type_counts.get(GridTypeDefs.CELL_ELITE, 0))
	if elite_n < wanted_elite_min or elite_n > wanted_elite_max:
		return false
	if type_counts.get(GridTypeDefs.CELL_CHEST, 0) != wanted_chest:
		return false
	if type_counts.get(GridTypeDefs.CELL_TASK, 0) > 0:
		return false

	# All target rooms reachable from start
	var targets := _tree_target_positions(grid)
	if not _all_targets_reachable(grid, start_pos, targets):
		return false

	return true

static func _count_tree_room_types(grid: Array) -> Dictionary:
	var counts: Dictionary = {}
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell_type := String(grid[y][x]["type"])
			counts[cell_type] = int(int(counts.get(cell_type, 0))) + 1
	return counts

static func _tree_target_positions(grid: Array) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell_type := String(grid[y][x].get("type", GridTypeDefs.CELL_EMPTY))
			if cell_type != GridTypeDefs.CELL_EMPTY and cell_type != GridTypeDefs.CELL_BLOCKED and cell_type != GridTypeDefs.CELL_START:
				targets.append(Vector2i(x, y))
	return targets

# ───── tree fallback ─────

static func _tree_fallback(seed_value: int, gen_cfg: Dictionary, start_pos: Vector2i, rng_manager: RunRngManager) -> Array:
	var max_width: int = int(gen_cfg["max_width"])
	var max_height: int = int(gen_cfg["max_height"])
	var grid := _new_empty_grid_rect(max_width, max_height)
	_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)

	# Build a simple line/path from start to boss
	var boss_x := clampi(start_pos.x + 2, 0, max_width - 1)
	var boss_y := start_pos.y
	_set_cell_type(grid, Vector2i(boss_x, boss_y), GridTypeDefs.CELL_BOSS)
	_add_connection(grid, start_pos, Vector2i(boss_x, boss_y))

	# Add a search and chest along way
	var mid_pos := Vector2i(clampi(start_pos.x + 1, 0, max_width - 1), start_pos.y)
	grid[mid_pos.y][mid_pos.x]["type"] = GridTypeDefs.CELL_SEARCH
	_add_connection(grid, start_pos, mid_pos)
	_add_connection(grid, mid_pos, Vector2i(boss_x, boss_y))

	var chest_pos := Vector2i(mid_pos.x, clampi(mid_pos.y - 1, 0, max_height - 1))
	if chest_pos != mid_pos and chest_pos != start_pos:
		_set_cell_type(grid, chest_pos, GridTypeDefs.CELL_CHEST)
		_add_connection(grid, mid_pos, chest_pos)

	_apply_initial_fog_tree(grid, start_pos)
	return grid

static func _add_connection(grid: Array, a: Vector2i, b: Vector2i) -> void:
	var ca: Array = grid[a.y][a.x].get("connections", [])
	if not ca.has(b):
		ca.append(b)
		grid[a.y][a.x]["connections"] = ca
	var cb: Array = grid[b.y][b.x].get("connections", [])
	if not cb.has(a):
		cb.append(a)
		grid[b.y][b.x]["connections"] = cb

# ───── tree fog ─────

static func _apply_initial_fog_tree(grid: Array, start_pos: Vector2i) -> void:
	_reveal_at(grid, start_pos, true)
	var cell: Dictionary = grid[start_pos.y][start_pos.x]
	for conn in cell.get("connections", []):
		var neighbor := Vector2i(conn.x, conn.y)
		_reveal_at(grid, neighbor, false)

static func reveal_neighbors_tree(grid: Array, pos: Vector2i) -> void:
	_reveal_at(grid, pos, true)
	var cell: Dictionary = grid[pos.y][pos.x]
	for conn in cell.get("connections", []):
		var neighbor := Vector2i(conn.x, conn.y)
		var state := String(grid[neighbor.y][neighbor.x]["state"])
		if state == GridTypeDefs.STATE_HIDDEN:
			_reveal_at(grid, neighbor, false)

# ──────────────────────────────────────────
#  Static map (mode = "static")
# ──────────────────────────────────────────

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

# ──────────────────────────────────────────
#  Legacy random (mode = "random")
# ──────────────────────────────────────────

static func generate_random(seed_value: int, config: Dictionary = {}, rng_manager: RunRngManager = null) -> Array:
	var size := maxi(1, int(config.get("size", Constants.GRID_SIZE)))
	var start_pos := _read_vector2i(config.get("start", [START_POS.x, START_POS.y]), START_POS)
	if not _is_inside(start_pos, size):
		start_pos = Vector2i(0, size - 1)
	var max_attempts := int(config.get("max_attempts", 100))
	var task_count := int(config.get("task_count", Constants.TASK_COUNT))
	var search_count := int(config.get("search_count", Constants.SEARCH_ROOM_COUNT))
	var chest_count := int(config.get("chest_count", Constants.CHEST_COUNT))
	var elite_count := int(config.get("elite_count", Constants.ELITE_ROOM_COUNT))
	var boss_count := int(config.get("boss_count", Constants.BOSS_ROOM_COUNT))
	var obstacle_count := int(config.get("obstacle_count", Constants.OBSTACLE_COUNT))

	var map_stream := _stream_for(seed_value, rng_manager, RunRngManagerScript.STREAM_MAP_ROUTE)
	for attempt in range(max_attempts):
		var grid := _new_empty_grid(size)
		_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)
		var available := _all_positions_except(size, [start_pos])
		_shuffle_positions(available, map_stream)

		var target_positions: Array[Vector2i] = []
		target_positions.append_array(_place_random_cells(grid, available, task_count, GridTypeDefs.CELL_TASK))
		target_positions.append_array(_place_random_cells(grid, available, search_count, GridTypeDefs.CELL_SEARCH))
		target_positions.append_array(_place_random_cells(grid, available, chest_count, GridTypeDefs.CELL_CHEST))
		target_positions.append_array(_place_random_cells(grid, available, elite_count, GridTypeDefs.CELL_ELITE))
		target_positions.append_array(_place_random_cells(grid, available, boss_count, GridTypeDefs.CELL_BOSS))
		_place_random_cells(grid, available, obstacle_count, GridTypeDefs.CELL_BLOCKED)

		if _all_targets_reachable(grid, start_pos, target_positions):
			_apply_initial_fog(grid, start_pos)
			return grid

	return _generate_random_fallback(seed_value, size, start_pos, task_count, search_count, chest_count, elite_count, boss_count, rng_manager)

# ──────────────────────────────────────────
#  Shared helpers
# ──────────────────────────────────────────

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
				"connections": [],
			})
		grid.append(row)
	return grid

static func _new_empty_grid_rect(width: int, height: int) -> Array:
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append({
				"x": x,
				"y": y,
				"type": GridTypeDefs.CELL_EMPTY,
				"state": GridTypeDefs.STATE_HIDDEN,
				"opened": false,
				"cleared": false,
				"connections": [],
			})
		grid.append(row)
	return grid

static func _generate_random_fallback(
	seed_value: int,
	size: int,
	start_pos: Vector2i,
	task_count: int,
	search_count: int,
	chest_count: int,
	elite_count: int,
	boss_count: int,
	rng_manager: RunRngManager = null
) -> Array:
	var map_stream := _stream_for(seed_value, rng_manager, RunRngManagerScript.STREAM_MAP_ROUTE)
	var grid := _new_empty_grid(size)
	_set_cell_type(grid, start_pos, GridTypeDefs.CELL_START)
	var available := _all_positions_except(size, [start_pos])
	_shuffle_positions(available, map_stream)
	_place_random_cells(grid, available, task_count, GridTypeDefs.CELL_TASK)
	_place_random_cells(grid, available, search_count, GridTypeDefs.CELL_SEARCH)
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

static func _shuffle_positions(positions: Array[Vector2i], rng: RunRngStream) -> void:
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
		# Use connections if available, otherwise fall back to 4-neighbor
		var connections: Array = grid[current.y][current.x].get("connections", [])
		if not connections.is_empty():
			for conn in connections:
				var neighbor := Vector2i(conn.x, conn.y)
				if visited.has(neighbor):
					continue
				if _is_inside(neighbor, grid.size()):
					var cell_type := String(grid[neighbor.y][neighbor.x]["type"])
					if cell_type == GridTypeDefs.CELL_BLOCKED:
						continue
					visited.append(neighbor)
					queue.append(neighbor)
		else:
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
	# Use connections if available
	var connections: Array = grid[pos.y][pos.x].get("connections", [])
	if not connections.is_empty():
		for conn in connections:
			var neighbor := Vector2i(conn.x, conn.y)
			var state := String(grid[neighbor.y][neighbor.x]["state"])
			if state == GridTypeDefs.STATE_HIDDEN:
				_reveal_at(grid, neighbor, false)
	else:
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
		"R":
			return GridTypeDefs.CELL_SEARCH
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

static func _stream_for(seed_value: int, rng_manager: RunRngManager, stream_name: String) -> RunRngStream:
	if rng_manager != null:
		return rng_manager.get_stream(stream_name)
	var temp_manager := RunRngManagerScript.new()
	temp_manager.start_run(seed_value)
	return temp_manager.get_stream(stream_name)
