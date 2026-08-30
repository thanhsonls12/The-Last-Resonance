extends SceneTree

## Routes come from tools/validate_levels.py, which solves the same .tres
## resources the game loads. Each string is the shortest route it found.
const ROUTES: Array[String] = [
	"RRDRUU",
	"RRURULLDLUUDLLLDRRDRUU",
	"ULURRRRRDDLLDDDLLLLDRRRRRRR",
	"RRRUDDDLLLDRRLLLLULUUUUUDRRRRRDRUU",
]

## Engine check for a plate a Core may leave once it has done its job.
const OPTIONAL_PLATE_MAP: Array[String] = [
	"#########",
	"# $  K .#",
	"# @     #",
	"#  $    #",
	"#  k    #",
	"#     . #",
	"#########",
]
const OPTIONAL_PLATE_ROUTE := "LURRDDUURRRLLLDDDLDRRR"

const DIRECTIONS := {
	"U": Vector3i(0, 0, -1),
	"D": Vector3i(0, 0, 1),
	"L": Vector3i(-1, 0, 0),
	"R": Vector3i(1, 0, 0),
}


func _initialize() -> void:
	var passed := true
	if Levels.ALL.is_empty():
		print("FAIL: Level catalogue is empty")
		quit(1)
		return

	print("=== THE LAST RESONANCE LEVEL VERIFIER ===")
	var landmarks := {}
	for i in Levels.ALL.size():
		if not _verify_level(i, landmarks):
			passed = false
	if not _verify_optional_plate():
		passed = false

	print("===================================")
	print("RESULT: %s" % ("ALL TESTS PASSED" if passed else "TESTS FAILED"))
	quit(0 if passed else 1)


func _verify_level(i: int, landmarks: Dictionary) -> bool:
	var data := Levels.get_data(i)
	if data == null:
		print("FAIL: Cannot load Level %d" % (i + 1))
		return false

	var logic := GameLogic.new()
	logic.load_level(data)

	if logic.player == Vector3i.ZERO and not logic.floors.has(Vector3i.ZERO):
		print("FAIL: Level %d has no player spawn" % (i + 1))
		return false

	var required := logic.required_target_count()
	if logic.blocks.size() != required or logic.blocks.is_empty():
		print("FAIL: Level %d core/target mismatch (Cores: %d, needs: %d)" % [
			i + 1, logic.blocks.size(), required
		])
		return false

	if not _verify_door_groups(i, logic):
		return false
	if not _verify_landmark(i, data, landmarks):
		return false

	if i >= ROUTES.size():
		print("FAIL: Level %d has no verification route" % (i + 1))
		return false

	var route := ROUTES[i]
	if route.length() > data.par_moves:
		print("FAIL: Level %d par_moves=%d but the verified route needs %d moves" % [
			i + 1, data.par_moves, route.length()
		])
		return false
	if not _replay_route(logic, route, i + 1):
		return false
	if route.length() < data.par_moves:
		print("FAIL: Level %d par_moves=%d is stale; route solves in %d moves" % [
			i + 1, data.par_moves, route.length()
		])
		return false
	print("Level %d ['%s']: SOLVABLE in %d moves (PASS)" % [
		i + 1, data.title, route.length()
	])
	return true


func _verify_door_groups(level_number: int, logic: GameLogic) -> bool:
	# A door whose group has no plate can never open, which soft-locks the map.
	for door in logic.doors.keys():
		var group: String = logic.doors[door]
		if logic.plates_in_group(group).is_empty():
			print("FAIL: Level %d door at %s has no plate in group '%s'" % [
				level_number, door, group
			])
			return false
	return true


func _verify_landmark(level_number: int, data: LevelData, landmarks: Dictionary) -> bool:
	if data.landmark.is_empty():
		print("FAIL: Level %d declares no landmark" % level_number)
		return false
	if landmarks.has(data.landmark):
		print("FAIL: Level %d reuses landmark '%s' from Level %d" % [
			level_number, data.landmark, int(landmarks[data.landmark]) + 1
		])
		return false
	var found := false
	for deco in data.decorations:
		if deco is Dictionary and str(deco.get("type", "")) == data.landmark:
			found = true
			break
	if not found:
		print("FAIL: Level %d has no '%s' decoration to back its landmark" % [
			level_number, data.landmark
		])
		return false
	landmarks[data.landmark] = level_number - 1
	return true


func _verify_optional_plate() -> bool:
	var data := LevelData.new()
	data.title = "Optional plate"
	data.map.assign(OPTIONAL_PLATE_MAP)
	data.entities = [{
		"type": "plate",
		"grid_position": Vector3i(3, 0, 4),
		"hold_required": false,
	}]
	var logic := GameLogic.new()
	logic.load_level(data)
	var plate := Vector3i(3, 0, 4)
	var door := Vector3i(5, 0, 1)
	if logic.required_target_count() != logic.slots.size():
		print("FAIL: optional plate still counts as a target")
		return false
	if logic.door_open(door):
		print("FAIL: door with an empty plate reports open")
		return false
	if not _replay_route(logic, OPTIONAL_PLATE_ROUTE, 0):
		print("FAIL: optional plate route does not finish the map")
		return false
	if logic.blocks.has(plate):
		print("FAIL: optional plate route ends with a Core still on the plate")
		return false
	print("Optional plate: Core opens the door, leaves the plate, map still wins (PASS)")
	return true


func _replay_route(logic: GameLogic, route: String, level_number: int) -> bool:
	for step_index in route.length():
		var step: String = route[step_index]
		if not DIRECTIONS.has(step):
			print("FAIL: Level %d route has invalid step '%s'" % [level_number, step])
			return false
		if logic.try_move(DIRECTIONS[step]).is_empty():
			print("FAIL: Level %d route blocked at step %d ('%s')" % [
				level_number, step_index + 1, step
			])
			return false
	if not logic.won:
		print("FAIL: Level %d route ended without winning" % level_number)
		return false
	return true
