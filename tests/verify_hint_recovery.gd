extends SceneTree


func _initialize() -> void:
	var failures := 0
	var data := Levels.get_data(0)
	var logic := GameLogic.new()
	logic.load_level(data)
	var hints := HintManager.new()
	hints.load_level(data)

	# Level 1 starts with R on the verified route, while L is a harmless walkable
	# detour. The hint should guide Kiro back to the route instead of pointing at
	# the final pedestal.
	var detour: Dictionary = logic.try_move(Vector3i.LEFT)
	hints.record_action("L")
	hints.sync_to_logic(logic)
	if detour.is_empty() or not hints.desynced:
		print("FAIL: harmless off-route walk was not detected as hint desync")
		failures += 1

	var recovery: Array = hints.recovery_path(
		logic,
		func(target: Vector3i) -> Array: return _path_to(logic, target))
	if recovery.is_empty() or recovery[0] != Vector3i.RIGHT:
		print("FAIL: hint recovery did not point back to the verified route")
		failures += 1
	else:
		logic.try_move(recovery[0])
		hints.record_action("R")
		hints.sync_to_logic(logic)
		if hints.desynced or hints.cursor != 0:
			print("FAIL: hint route did not resync after returning to the canonical state")
			failures += 1

	hints.load_route("RRRRRR")
	hints.advance_stage()
	if hints.reveal_current_stage() != 1:
		print("FAIL: hint level 1 did not charge one new action")
		failures += 1
	hints.advance_stage()
	if hints.reveal_current_stage() != 0:
		print("FAIL: hint level 2 charged the same action twice")
		failures += 1
	hints.advance_stage()
	if hints.reveal_current_stage() != 4 or hints.get_hint_penalty() != 5:
		print("FAIL: hint level 3 did not charge only new preview actions")
		failures += 1
	hints.dismiss()
	hints.advance_stage()
	if hints.reveal_current_stage() != 0:
		print("FAIL: reopening a revealed hint charged twice")
		failures += 1
	hints.undo_action()
	if hints.get_hint_penalty() != 5:
		print("FAIL: undo refunded revealed information")
		failures += 1
	hints.mark_desynced()
	if hints.reveal_current_stage() != 0:
		print("FAIL: desynced recovery hint was charged")
		failures += 1

	print("Hint recovery: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)


func _path_to(logic: GameLogic, target: Vector3i) -> Array:
	if target == logic.player or _blocked(logic, target):
		return []
	var came := {logic.player: null}
	var queue: Array = [logic.player]
	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		if current == target:
			break
		for direction in [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.BACK, Vector3i.FORWARD]:
			var next: Vector3i = current + direction
			if came.has(next) or _blocked(logic, next):
				continue
			came[next] = current
			queue.append(next)
	if not came.has(target):
		return []
	var path: Array = []
	var node := target
	while came[node] != null:
		var previous: Vector3i = came[node]
		path.push_front(node - previous)
		node = previous
	return path


func _blocked(logic: GameLogic, cell: Vector3i) -> bool:
	return not logic.is_active_floor_cell(cell) or not logic.floors.has(cell) \
		or logic.walls.has(cell) or logic.blocks.has(cell) \
		or logic.elevators.has(cell) \
		or (logic.doors.has(cell) and not logic.door_open(cell)) \
		or (logic.bridges.has(cell) and not logic.bridge_open)
