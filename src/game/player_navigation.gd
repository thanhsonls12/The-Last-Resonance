class_name PlayerNavigation
extends RefCounted

## Pure navigation/planning for tap-to-move.
## Decides where the player can auto-walk and returns an execution plan.
## Does not mutate GameLogic and does not know about BoardView, HUD, audio,
## story, tweens, or session/busy state.

const KIND_STEP := &"step"
const KIND_WALK := &"walk"
const KIND_BLOCK_APPROACH := &"block_approach"
const KIND_ELEVATOR := &"elevator"

const CARDINAL_DIRECTIONS: Array[Vector3i] = [
	Vector3i.RIGHT,
	Vector3i.LEFT,
	Vector3i.BACK,
	Vector3i.FORWARD,
]


func plan_tap(logic: GameLogic, grid_target: Vector3i) -> Dictionary:
	if logic == null:
		return {}
	grid_target = Vector3i(grid_target.x, logic.player.y, grid_target.z)
	if not logic.floors.has(grid_target) or logic.walls.has(grid_target):
		return {}

	if logic.elevators.has(grid_target):
		return _plan_elevator(logic, grid_target)

	if logic.blocks.has(grid_target):
		var diff := grid_target - logic.player
		if is_cardinal_step(diff):
			return {
				"kind": KIND_STEP,
				"direction": diff,
				"target": grid_target,
			}
		var block_path := path_to_block_approach(logic, grid_target)
		if block_path.is_empty():
			return {}
		return {
			"kind": KIND_BLOCK_APPROACH,
			"path": block_path,
			"target": grid_target,
		}

	var path := path_to(logic, grid_target)
	if path.is_empty():
		return {}
	return {
		"kind": KIND_WALK,
		"path": path,
		"target": grid_target,
	}


func path_to(logic: GameLogic, target: Vector3i) -> Array:
	if logic == null:
		return []
	target = Vector3i(target.x, logic.player.y, target.z)
	if target == logic.player or auto_walk_blocked(logic, target):
		return []
	var came := {logic.player: null}
	var queue: Array = [logic.player]
	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		if current == target:
			break
		for direction in CARDINAL_DIRECTIONS:
			var next: Vector3i = current + direction
			if came.has(next) or auto_walk_blocked(logic, next):
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


func path_to_block_approach(logic: GameLogic, target: Vector3i) -> Array:
	return _shortest_neighbor_path(logic, target)


func path_to_elevator_approach(logic: GameLogic, target: Vector3i) -> Array:
	return _shortest_neighbor_path(logic, target)


func auto_walk_blocked(logic: GameLogic, cell: Vector3i) -> bool:
	if logic == null:
		return true
	# Elevators stay excluded from generic auto-walk. Entering an elevator must
	# be an explicit final step from an adjacent cell.
	return not logic.is_active_floor_cell(cell) or not logic.floors.has(cell) \
		or logic.walls.has(cell) or logic.blocks.has(cell) \
		or logic.elevators.has(cell) \
		or (logic.doors.has(cell) and not logic.door_open(cell)) \
		or (logic.bridges.has(cell) and not logic.bridge_open)


func is_cardinal_step(diff: Vector3i) -> bool:
	return diff.y == 0 and absi(diff.x) + absi(diff.z) == 1


func _plan_elevator(logic: GameLogic, target: Vector3i) -> Dictionary:
	if not logic.elevator_is_unlocked(target):
		return {}
	var diff := target - logic.player
	if is_cardinal_step(diff):
		return {
			"kind": KIND_STEP,
			"direction": diff,
			"target": target,
		}
	var path := path_to_elevator_approach(logic, target)
	if path.is_empty():
		return {}
	return {
		"kind": KIND_ELEVATOR,
		"path": path,
		"target": target,
	}


func _shortest_neighbor_path(logic: GameLogic, target: Vector3i) -> Array:
	var best_path: Array = []
	for direction in CARDINAL_DIRECTIONS:
		var neighbor := target + direction
		if auto_walk_blocked(logic, neighbor):
			continue
		var candidate := path_to(logic, neighbor)
		if candidate.is_empty():
			continue
		if best_path.is_empty() or candidate.size() < best_path.size():
			best_path = candidate
	return best_path
