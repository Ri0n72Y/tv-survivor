extends Control
## MiniMap — Isaac-style top-right minimap for grid exploration mode.
## Only displays revealed/visited tree nodes. Skips blocked filler and hidden cells.

func refresh(grid_data: Array, player_pos: Vector2i) -> void:
	if grid_data.is_empty():
		return
	queue_redraw()

func _draw() -> void:
	var grid_data: Array = RunState.grid_data
	if grid_data.is_empty():
		return

	var grid_height: int = grid_data.size() as int
	var grid_width: int = int(grid_data[0].size())

	if grid_width <= 0 or grid_height <= 0:
		return

	# Collect visible (in-tree, non-blocked, non-hidden) positions and their bounding box
	var visible: Array[Vector2i] = []
	var min_x: int = 99999
	var min_y: int = 99999
	var max_x: int = -1
	var max_y: int = -1

	for y in range(grid_height):
		for x in range(grid_width):
			var cell: Dictionary = grid_data[y][x]
			var cell_type := String(cell.get("type", GridTypes.CELL_EMPTY))
			if cell_type == GridTypes.CELL_BLOCKED:
				continue
			var state := String(cell.get("state", GridTypes.STATE_HIDDEN))
			if state == GridTypes.STATE_HIDDEN:
				continue
			visible.append(Vector2i(x, y))
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if visible.is_empty():
		return

	# Calculate cell size to fit into our panel based on visible bounding box
	var panel_size := size
	var span_x := max_x - min_x + 1
	var span_y := max_y - min_y + 1

	var cell_size_x: float = floor(panel_size.x / float(span_x))
	var cell_size_y: float = floor(panel_size.y / float(span_y))
	var cell_size: float = minf(cell_size_x, cell_size_y)
	cell_size = maxf(cell_size, 2.0)

	var offset_x: float = (panel_size.x - float(span_x) * cell_size) * 0.5
	var offset_y: float = (panel_size.y - float(span_y) * cell_size) * 0.5

	# Draw background
	draw_rect(Rect2(Vector2.ZERO, panel_size), Color(0.04, 0.04, 0.06, 0.82), true)

	var player_pos := RunState.player_grid_pos

	# Draw connections (only between visible nodes where both ends are visible)
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: Dictionary = grid_data[y][x]
			var cell_type := String(cell.get("type", GridTypes.CELL_EMPTY))
			if cell_type == GridTypes.CELL_BLOCKED:
				continue
			var state := String(cell.get("state", GridTypes.STATE_HIDDEN))
			if state == GridTypes.STATE_HIDDEN:
				continue
			var conns: Array = cell.get("connections", [])
			for conn in conns:
				var cx := int(conn.x)
				var cy := int(conn.y)
				if cy < y or (cy == y and cx < x):
					continue
				if cy < 0 or cy >= grid_height or cx < 0 or cx >= grid_width:
					continue
				var ntype := String(grid_data[cy][cx].get("type", GridTypes.CELL_EMPTY))
				if ntype == GridTypes.CELL_BLOCKED:
					continue
				var nstate := String(grid_data[cy][cx].get("state", GridTypes.STATE_HIDDEN))
				if nstate == GridTypes.STATE_HIDDEN:
					continue
				var from_rect := _cell_rect(x - min_x, y - min_y, cell_size, offset_x, offset_y)
				var to_rect := _cell_rect(cx - min_x, cy - min_y, cell_size, offset_x, offset_y)
				draw_line(from_rect.get_center(), to_rect.get_center(), GridTypes.MINIMAP_COLORS["connection"], 1.0)

	# Draw cells (only visible)
	for vpos in visible:
		var x: int = vpos.x
		var y: int = vpos.y
		var cell: Dictionary = grid_data[y][x]
		var cell_type := String(cell.get("type", GridTypes.CELL_EMPTY))
		var state := String(cell.get("state", GridTypes.STATE_HIDDEN))

		var color: Color = GridTypes.MINIMAP_COLORS.get(cell_type, GridTypes.MINIMAP_COLORS["revealed"])
		if state == GridTypes.STATE_VISITED and cell_type == GridTypes.CELL_EMPTY:
			color = GridTypes.MINIMAP_COLORS["visited"]

		var rect := _cell_rect(x - min_x, y - min_y, cell_size, offset_x, offset_y)
		draw_rect(rect, color, true)

		if Vector2i(x, y) == player_pos:
			draw_rect(rect, GridTypes.MINIMAP_COLORS["current"], true)
			draw_rect(rect, Color.WHITE, false, 1.0)

func _cell_rect(x: int, y: int, cell_size: float, offset_x: float, offset_y: float) -> Rect2:
	var margin: float = maxf(1.0, cell_size * 0.15)
	return Rect2(
		offset_x + float(x) * cell_size + margin,
		offset_y + float(y) * cell_size + margin,
		cell_size - margin * 2.0,
		cell_size - margin * 2.0
	)
