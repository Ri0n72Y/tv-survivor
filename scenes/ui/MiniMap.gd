extends Control
## MiniMap — Isaac-style top-right minimap for grid exploration mode.

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

	# Calculate cell size to fit in our rect
	var panel_size := size
	var cell_size_x: float = floor(panel_size.x / float(grid_width))
	var cell_size_y: float = floor(panel_size.y / float(grid_height))
	var cell_size: float = minf(cell_size_x, cell_size_y)
	if cell_size < 2.0:
		cell_size = 2.0

	var offset_x := (panel_size.x - float(grid_width) * cell_size) * 0.5
	var offset_y := (panel_size.y - float(grid_height) * cell_size) * 0.5

	# Draw background
	draw_rect(Rect2(Vector2.ZERO, panel_size), Color(0.04, 0.04, 0.06, 0.82), true)

	var player_pos := RunState.player_grid_pos

	# Draw connections first (underneath cells)
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: Dictionary = grid_data[y][x]
			var state := String(cell.get("state", GridTypes.STATE_HIDDEN))
			if state == GridTypes.STATE_HIDDEN:
				continue
			var conns: Array = cell.get("connections", [])
			for conn in conns:
				var cx := int(conn.x)
				var cy := int(conn.y)
				if cy < y or (cy == y and cx < x):
					# Only draw once per pair
					continue
				if cy < 0 or cy >= grid_height or cx < 0 or cx >= grid_width:
					continue
				var conn_state := String(grid_data[cy][cx].get("state", GridTypes.STATE_HIDDEN))
				if conn_state == GridTypes.STATE_HIDDEN:
					continue
				var from_rect := _cell_rect(x, y, cell_size, offset_x, offset_y)
				var to_rect := _cell_rect(cx, cy, cell_size, offset_x, offset_y)
				draw_line(from_rect.get_center(), to_rect.get_center(), GridTypes.MINIMAP_COLORS["connection"], 1.0)

	# Draw cells
	for y in range(grid_height):
		for x in range(grid_width):
			var cell: Dictionary = grid_data[y][x]
			var cell_type := String(cell.get("type", GridTypes.CELL_EMPTY))
			var state := String(cell.get("state", GridTypes.STATE_HIDDEN))

			if state == GridTypes.STATE_HIDDEN:
				# Draw as hidden dot
				var rect := _cell_rect(x, y, cell_size, offset_x, offset_y)
				draw_rect(rect, GridTypes.MINIMAP_COLORS["hidden"], true)
				continue

			var color: Color = GridTypes.MINIMAP_COLORS.get(cell_type, GridTypes.MINIMAP_COLORS["revealed"])
			if state == GridTypes.STATE_VISITED and cell_type == GridTypes.CELL_EMPTY:
				color = GridTypes.MINIMAP_COLORS["visited"]

			var rect := _cell_rect(x, y, cell_size, offset_x, offset_y)
			draw_rect(rect, color, true)

			# Player position highlight
			if Vector2i(x, y) == player_pos:
				draw_rect(rect, GridTypes.MINIMAP_COLORS["current"], true)
				# White border
				draw_rect(rect, Color.WHITE, false, 1.0)

func _cell_rect(x: int, y: int, cell_size: float, offset_x: float, offset_y: float) -> Rect2:
	var margin := maxf(1.0, cell_size * 0.15)
	return Rect2(
		offset_x + float(x) * cell_size + margin,
		offset_y + float(y) * cell_size + margin,
		cell_size - margin * 2.0,
		cell_size - margin * 2.0
	)

func _get_color_for_type(cell_type: String) -> Color:
	return GridTypes.MINIMAP_COLORS.get(cell_type, Color.GRAY)
