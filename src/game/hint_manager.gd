class_name HintManager
extends RefCounted

## Manager for the 3-tier in-game hint system.
## Owns route/checkpoints, cursor, desync recovery, stage, and hint usage count.
## The puzzle solution stays offline/pre-verified. Recovery delegates walk-only
## pathfinding to a caller-provided callable so HintManager does not own input
## or player movement execution.

signal hint_changed

var route: String = ""
var cursor: int = 0
var stage: int = 0
var desynced: bool = false
var hint_penalty: int = 0

var _recorded_actions: Array[String] = []
var _revealed_action_ids: Dictionary = {}
var _route_states: Array[Dictionary] = []


func reset() -> void:
	route = ""
	cursor = 0
	stage = 0
	desynced = false
	hint_penalty = 0
	_recorded_actions.clear()
	_revealed_action_ids.clear()
	_route_states.clear()
	hint_changed.emit()


func load_route(new_route: String) -> void:
	route = new_route if new_route != null else ""
	cursor = 0
	stage = 0
	desynced = false
	hint_penalty = 0
	_recorded_actions.clear()
	_revealed_action_ids.clear()
	_route_states.clear()
	hint_changed.emit()


func load_level(data: LevelData) -> void:
	load_route(data.hint_route if data != null else "")
	_build_route_states(data)


func is_available() -> bool:
	return not route.is_empty()


func advance_stage() -> int:
	if route.is_empty():
		return 0
	if stage >= 3:
		stage = 0
	else:
		stage += 1
	hint_changed.emit()
	return stage


func dismiss() -> void:
	stage = 0
	hint_changed.emit()


func record_action(action: String) -> void:
	if action.is_empty() or route.is_empty():
		return
	_recorded_actions.append(action)
	_rebuild_progress()
	hint_changed.emit()


func undo_action() -> void:
	if not _recorded_actions.is_empty():
		_recorded_actions.pop_back()
	_rebuild_progress()
	hint_changed.emit()


func resync_to(new_cursor: int) -> void:
	if route.is_empty():
		return
	var clamped_cursor := clampi(new_cursor, 0, route.length())
	if cursor == clamped_cursor and not desynced:
		return
	cursor = clamped_cursor
	desynced = false
	_recorded_actions.clear()
	for i in cursor:
		_recorded_actions.append(route[i])
	hint_changed.emit()


func mark_desynced() -> void:
	if desynced:
		return
	desynced = true
	hint_changed.emit()


func get_display() -> Dictionary:
	# Returns: { stage, text, target, desynced }
	if stage <= 0 or route.is_empty():
		return {"stage": 0, "text": "", "target": Vector3i.ZERO, "desynced": false}

	if desynced or cursor >= route.length():
		return {
			"stage": stage,
			"text": _get_fallback_text(),
			"target": Vector3i.ZERO, # caller resolves fallback cell
			"desynced": desynced
		}

	var action: String = route[cursor]
	return {
		"stage": stage,
		"text": _get_stage_text(action),
		"target": Vector3i.ZERO, # caller resolves from action
		"desynced": false
	}


func get_current_action() -> String:
	if desynced or cursor >= route.length() or stage <= 0:
		return ""
	return route[cursor]


func get_preview(max_steps: int = 5) -> String:
	if route.is_empty() or cursor >= route.length():
		return ""
	var end := mini(route.length(), cursor + max_steps)
	var preview := ""
	for i in range(cursor, end):
		if i > cursor:
			preview += " • "
		preview += _action_symbol(route[i])
	return preview


func reveal_current_stage() -> int:
	if desynced or stage <= 0 or cursor >= route.length():
		return 0
	var end := cursor + 1
	if stage >= 3:
		end = mini(route.length(), cursor + 5)
	var charged := 0
	for action_id in range(cursor, end):
		if _revealed_action_ids.has(action_id):
			continue
		_revealed_action_ids[action_id] = true
		charged += 1
	hint_penalty += charged
	return charged


func get_hint_penalty() -> int:
	return hint_penalty


func get_hints_used() -> int:
	return hint_penalty


func sync_to_logic(logic: GameLogic) -> void:
	if logic == null or _route_states.is_empty() or not is_available():
		return
	var exact_checkpoint := -1
	for i in _route_states.size():
		if _state_matches(logic, _route_states[i], true):
			exact_checkpoint = i
	if exact_checkpoint >= 0:
		resync_to(exact_checkpoint)
	else:
		mark_desynced()


func recovery_path(logic: GameLogic, pathfinder: Callable) -> Array:
	if logic == null or not pathfinder.is_valid():
		return []
	var best_path: Array = []
	for checkpoint in _route_states:
		if not _state_matches(logic, checkpoint, false):
			continue
		var target: Vector3i = checkpoint.get("player", logic.player)
		if target == logic.player:
			continue
		var path: Array = pathfinder.call(target)
		if path.is_empty():
			continue
		if best_path.is_empty() or path.size() < best_path.size():
			best_path = path
	return best_path


func target_for_current_action(logic: GameLogic) -> Vector3i:
	if logic == null:
		return Vector3i.ZERO
	var action := get_current_action()
	if action == "B":
		var controls: Array = logic.bridge_controls.keys()
		if controls.is_empty():
			controls = logic.bridges.keys()
		return _nearest_cell(controls, logic.player)
	var direction := direction_for_action(action)
	if direction == Vector3i.ZERO:
		return logic.player
	var candidate := logic.player + direction
	if logic.floors.has(candidate) and not logic.walls.has(candidate):
		return candidate
	return logic.player


func recovery_text(path: Array) -> String:
	var action := action_for_direction(path[0]) if not path.is_empty() else ""
	match stage:
		1:
			return "GỢI Ý 1/3 — Bạn đã đi lệch. Hãy quay lại đường gợi ý qua ô đang phát sáng."
		2:
			return "GỢI Ý 2/3 — Bước phục hồi: %s." % _action_text(action)
		_:
			return "GỢI Ý 3/3 — Đường trở lại: %s" % _path_preview(path)


func fallback_cell(logic: GameLogic) -> Vector3i:
	if logic == null:
		return Vector3i.ZERO
	var floor := logic.active_floor
	var floor_nodes := logic.energy_nodes_on_floor(floor)
	var floor_progress := logic.energy_progress_for_floor(floor)
	if floor_progress < floor_nodes.size():
		return floor_nodes[floor_progress]
	if logic.sequential_floors and logic.is_floor_completed(floor):
		for elevator in logic.elevators.keys():
			if elevator.y == floor and logic.elevator_is_unlocked(elevator):
				return elevator
	if not logic.bridge_open and not logic.bridge_controls.is_empty():
		var controls: Array = []
		for control in logic.bridge_controls.keys():
			if control.y == floor:
				controls.append(control)
		if not controls.is_empty():
			return _nearest_cell(controls, logic.player)
	for slot in logic.slots.keys():
		if slot.y == floor and not logic.blocks.has(slot):
			return slot
	for plate in logic.plates.keys():
		if plate.y == floor and logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
			return plate
	return logic.player


func fallback_text(logic: GameLogic) -> String:
	if logic == null:
		return "Tiếp tục di chuyển và quan sát các ô sáng."
	if logic.sequential_floors:
		var floor := logic.active_floor
		var floor_nodes := logic.energy_nodes_on_floor(floor)
		var floor_progress := logic.energy_progress_for_floor(floor)
		if floor_progress < floor_nodes.size():
			return "Đưa Core tới nút năng lượng %d/%d được đánh dấu trước khi về chân đế." % [floor_progress + 1, floor_nodes.size()]
		if logic.is_floor_completed(floor) and floor < logic.floor_count() - 1:
			return "Thang máy đã mở. Hãy bước vào vòng sáng để lên tầng tiếp theo."
		for slot in logic.slots.keys():
			if slot.y == floor and not logic.blocks.has(slot):
				return "Đưa một Lumina Core vào ô đích được đánh dấu."
		for plate in logic.plates.keys():
			if plate.y == floor and logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
				return "Đặt Core lên bàn áp lực được đánh dấu để mở khóa."
		return "Tiếp tục di chuyển và quan sát các ô sáng."
	if logic.energy_progress < logic.energy_nodes.size():
		return "Đưa Core tới nút năng lượng %d/%d được đánh dấu trước khi về chân đế." % [logic.energy_progress + 1, logic.energy_nodes.size()]
	if not logic.bridge_open and not logic.bridge_controls.is_empty():
		return "Mở cầu ở bảng điều khiển được đánh dấu."
	for slot in logic.slots.keys():
		if not logic.blocks.has(slot):
			return "Đưa một Lumina Core vào ô đích được đánh dấu."
	for plate in logic.plates.keys():
		if logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
			return "Đặt Core lên bàn áp lực được đánh dấu để mở khóa."
	return "Tiếp tục di chuyển và quan sát các ô sáng."


func direction_for_action(action: String) -> Vector3i:
	match action:
		"U": return Vector3i(0, 0, -1)
		"D": return Vector3i(0, 0, 1)
		"L": return Vector3i(-1, 0, 0)
		"R": return Vector3i(1, 0, 0)
	return Vector3i.ZERO


func action_for_direction(direction: Vector3i) -> String:
	if direction == Vector3i(0, 0, -1):
		return "U"
	if direction == Vector3i(0, 0, 1):
		return "D"
	if direction == Vector3i(-1, 0, 0):
		return "L"
	if direction == Vector3i(1, 0, 0):
		return "R"
	return ""


func _rebuild_progress() -> void:
	cursor = 0
	desynced = false
	for action in _recorded_actions:
		if desynced:
			break
		if cursor >= route.length() or route[cursor] != action:
			desynced = true
			break
		cursor += 1


func _build_route_states(data: LevelData) -> void:
	_route_states.clear()
	if data == null or data.hint_route.is_empty():
		return
	var simulation := GameLogic.new()
	simulation.load_level(data)
	_route_states.append(_capture_state(simulation))
	for action in data.hint_route:
		var result: Dictionary
		if action == "B":
			result = simulation.rotate_bridge()
		else:
			var direction := direction_for_action(action)
			if direction == Vector3i.ZERO:
				_route_states.clear()
				return
			result = simulation.try_move(direction)
		if result.is_empty():
			_route_states.clear()
			return
		_route_states.append(_capture_state(simulation))


func _capture_state(source: GameLogic) -> Dictionary:
	return {
		"player": source.player,
		"blocks": source.blocks.duplicate(),
		"bridge_open": source.bridge_open,
		"energy_progress": source.energy_progress,
		"active_floor": source.active_floor,
		"completed_floors": source.completed_floors.duplicate(),
		"energy_progress_by_floor": source.energy_progress_by_floor.duplicate(),
		"won": source.won,
	}


func _state_matches(logic: GameLogic, checkpoint: Dictionary, include_player: bool) -> bool:
	if include_player and logic.player != checkpoint.get("player", Vector3i.ZERO):
		return false
	if not _same_key_set(logic.blocks, checkpoint.get("blocks", {})):
		return false
	if logic.bridge_open != bool(checkpoint.get("bridge_open", true)):
		return false
	if logic.energy_progress != int(checkpoint.get("energy_progress", 0)):
		return false
	if logic.active_floor != int(checkpoint.get("active_floor", 0)):
		return false
	if not _same_key_set(logic.completed_floors, checkpoint.get("completed_floors", {})):
		return false
	if logic.energy_progress_by_floor != checkpoint.get("energy_progress_by_floor", {}):
		return false
	return logic.won == bool(checkpoint.get("won", false))


func _same_key_set(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for key in left.keys():
		if not right.has(key):
			return false
	return true


func _nearest_cell(cells: Array, origin: Vector3i) -> Vector3i:
	if cells.is_empty():
		return origin
	var best: Vector3i = cells[0]
	var best_distance := absi(best.x - origin.x) + absi(best.y - origin.y) + absi(best.z - origin.z)
	for raw_cell in cells:
		var cell: Vector3i = raw_cell
		var distance := absi(cell.x - origin.x) + absi(cell.y - origin.y) + absi(cell.z - origin.z)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best


func _path_preview(path: Array, max_steps := 5) -> String:
	var preview := ""
	var count := mini(path.size(), max_steps)
	for i in count:
		if i > 0:
			preview += " • "
		match action_for_direction(path[i]):
			"U": preview += "↑"
			"D": preview += "↓"
			"L": preview += "←"
			"R": preview += "→"
			_: preview += "•"
	return preview


func _get_stage_text(action: String) -> String:
	match stage:
		1:
			return "GỢI Ý 1/3 — Hãy hướng tới ô đang phát sáng."
		2:
			return "GỢI Ý 2/3 — Bước kế tiếp theo lưới: %s." % _action_text(action)
		_:
			return "GỢI Ý 3/3 — Chuỗi kế tiếp: %s" % get_preview()
	return ""


func _action_symbol(action: String) -> String:
	match action:
		"U": return "↑"
		"D": return "↓"
		"L": return "←"
		"R": return "→"
		"B": return "CẦU"
	return "•"


func _action_text(action: String) -> String:
	match action:
		"U": return "↑ Lên"
		"D": return "↓ Xuống"
		"L": return "← Trái"
		"R": return "→ Phải"
		"B": return "xoay cầu tại bảng điều khiển"
	return "tiếp tục"


func _get_fallback_text() -> String:
	if desynced:
		return "Đường gợi ý đã lệch khỏi nước đi hiện tại."
	return "Tiếp tục di chuyển và quan sát các ô sáng."
