extends RefCounted
class_name BattleResultApplicator

static func apply(result: BattleResult) -> String:
	var effects := result.effects
	for effect in effects:
		_apply_effect(result, effect)
	return _result_message(result, effects)

static func _apply_effect(result: BattleResult, effect: BattleEffect) -> void:
	match effect.type:
		BattleEffect.Type.CLEAR_ROOM:
			_clear_room(result)
		BattleEffect.Type.REVEAL_RING:
			_reveal_room_radius(result.room_position)
		BattleEffect.Type.SET_NEXT_SYNC:
			RunState.next_battle_initial_sync = effect.number_value
		BattleEffect.Type.ROLLBACK_POSITION:
			RunState.player_grid_pos = RunState.previous_grid_pos
		BattleEffect.Type.REVEAL_NEIGHBORS:
			_reveal_neighbors(RunState.player_grid_pos)
		BattleEffect.Type.CLEAR_TRANSITION:
			RunState.current_task_pos = Vector2i(-1, -1)
			RunState.current_room_cell = Vector2i.ZERO
			RunState.current_battle_room_type = ""
		BattleEffect.Type.RESULT_MESSAGE:
			pass

static func _clear_room(result: BattleResult) -> void:
	if not _is_inside(result.room_position):
		return
	var cell: Dictionary = RunState.grid_data[result.room_position.y][result.room_position.x]
	if bool(cell.get("cleared", false)):
		return
	cell["cleared"] = true
	if String(cell.get("type", GridTypes.CELL_EMPTY)) == GridTypes.CELL_TASK:
		RunState.completed_tasks += 1

static func _reveal_room_radius(pos: Vector2i) -> void:
	if not _is_inside(pos):
		return
	var connections: Array = RunState.grid_data[pos.y][pos.x].get("connections", [])
	if not connections.is_empty():
		GridGenerator.reveal_connected_radius(RunState.grid_data, pos, 1)
	else:
		GridGenerator.reveal_ring(RunState.grid_data, pos)

static func _reveal_neighbors(pos: Vector2i) -> void:
	if not _is_inside(pos):
		return
	var connections: Array = RunState.grid_data[pos.y][pos.x].get("connections", [])
	if not connections.is_empty():
		GridGenerator.reveal_neighbors_tree(RunState.grid_data, pos)
	else:
		GridGenerator.reveal_neighbors(RunState.grid_data, pos)

static func _result_message(result: BattleResult, effects: Array[BattleEffect]) -> String:
	for effect in effects:
		if effect.type == BattleEffect.Type.RESULT_MESSAGE and not effect.text_value.is_empty():
			return effect.text_value
	if result.is_failure():
		return "战斗失败，返回上一个格子。"
	return "战斗成功，房间已清理。"

static func _is_inside(pos: Vector2i) -> bool:
	return (
		pos.x >= 0
		and pos.y >= 0
		and pos.y < RunState.grid_data.size()
		and pos.x < RunState.grid_data[pos.y].size()
	)
