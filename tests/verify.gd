extends SceneTree

## Routes come from tools/validate_levels.py, which solves the same .tres
## resources the game loads. Each string is the shortest route it found.
const ROUTES: Array[String] = [
	"RUULLLLDDRDL",
	"RRRUULLRRRRLDDRRUULLLDDLLLUU",
	"LLUUUULLDRLLDRRRRRUULDULDDRURDDLDR",
	"DRRUURRDLDLLLUURRDRDLRURUURRDLULLDLDDRURUDLLURURDRRUL",
	"DLLUUULLLDDRRLLUURRRDDLLUDRDDLUULUURDLDRRDRRURRRUULDDDLLL",
	"LUULUULLDDUURRDDLRRDDLLULUULUURRDLULDRRRDDLDLUUDRRUULLRRRRRDDLLLLDLUUURUL",
	"DDLDLLLLLUURUURURDLLDDLDDRRRRRURUULULLLRRRURBLDDRDDLDLLLUURDLDRUUURULULDDDD",
	"LLLLLBRDDLDDLLUULUURRRRRDDDDLUUUUUDLLLLDDRULUUURRRRRLDDLLLDLUUDRRRRRDDDDRRUUUULLLLLLDLU",
	"URURUULLDLLULLDDDDUUUURRDRRURRDDLDLDDDRRRURUUU",
	"RLUUUUURRRURRDLLLRRRRURRDDLDDRDDLLLLULUURR",
	"LLUULLDRURRDDLUUURULLRRRRLLLLDDDDLLURRDRUUULLDRDDLLURRRLUUURR",
	"RLUUUUURRRRURRRRDDLDDRDDLLLLULUURRLLDDRDRRRRUULUURUULLLLLLLDRLLDRRRRRUULLDDURURDDDLDR",
	"DDRULURRRURDDRDLLLLULDLDRDRULURRRLUURRDD",
	"LUURRDRRDRURRUULLLLLLLDRRRRR",
	"URBRRDRRRUUULLLLDDRDRUUDLLUURRDDDRRUUULLLRDDRLLLUUUULURRRLLDDDDDLLUURLDDRRUUUURUL",
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
		if not _verify_undo_restart(i):
			passed = false
	if not _verify_save_recovery() or not _verify_session_guard():
		passed = false
	if not _verify_score_rules():
		passed = false
	if not _verify_optional_plate():
		passed = false
	if not _verify_chapter_two_progress_migration():
		passed = false
	if Levels.is_chapter_final(4) or not Levels.is_chapter_final(3):
		print("FAIL: Content boundary is being treated as a completed chapter")
		passed = false
	if Levels.is_chapter_final(6):
		print("FAIL: Level 7 is not the Chapter II finale (Level 8 is)")
		passed = false
	if not Levels.is_chapter_final(11) or Levels.is_campaign_final(11):
		print("FAIL: Level 12 must end Chapter III without ending the campaign")
		passed = false
	if not Levels.is_chapter_final(14) or not Levels.is_campaign_final(14):
		print("FAIL: Level 15 must end Chapter IV and the campaign")
		passed = false
	if Levels.is_campaign_final(13):
		print("FAIL: Level 14 must not end the campaign")
		passed = false
	if not _verify_current_level_clamp():
		passed = false
	if Levels.reconciled_unlocked({"11": {"completed": true}}, 12) != 13:
		print("FAIL: Chapter III completion must unlock Level 13")
		passed = false
	if Levels.is_campaign_final(12) or Levels.is_chapter_final(12):
		print("FAIL: Level 13 must not end the chapter or campaign")
		passed = false
	if Levels.reconciled_unlocked({"12": {"completed": true}}, 13) != 14:
		print("FAIL: Level 13 completion must unlock Level 14")
		passed = false
	if Levels.reconciled_unlocked({"13": {"completed": true}}, 14) != 15:
		print("FAIL: Level 14 completion must unlock Level 15")
		passed = false
	if not _verify_level_13_energy():
		passed = false
	if not _verify_level_12_climax():
		passed = false
	if not _verify_chapter_four_content():
		passed = false
	if not _verify_narrative_progression():
		passed = false

	print("===================================")
	print("RESULT: %s" % ("ALL TESTS PASSED" if passed else "TESTS FAILED"))
	quit(0 if passed else 1)


func _verify_score_rules() -> bool:
	var expected := {
		1: [13, 16],
		2: [13, 16],
		3: [14, 19],
		4: [16, 22],
		5: [16, 22],
	}
	for difficulty in expected.keys():
		var limits := ScoreRules.thresholds(11, difficulty)
		if [limits.three_star_max, limits.two_star_max] != expected[difficulty]:
			print("FAIL: score thresholds for difficulty %d" % difficulty)
			return false
	var data := LevelData.new()
	data.par_moves = 30
	data.difficulty = 3
	var perfect := ScoreRules.evaluate_run(30, 0, data)
	var assisted := ScoreRules.evaluate_run(32, 6, data)
	if perfect.stars != 3 or not perfect.perfect:
		print("FAIL: perfect score semantics")
		return false
	if assisted.stars != 3 or assisted.perfect or assisted.score_moves != 38:
		print("FAIL: hint penalty score semantics")
		return false
	data.three_star_moves_override = 36
	data.two_star_moves_override = 44
	var overridden := ScoreRules.thresholds(30, 3, data.three_star_moves_override, data.two_star_moves_override)
	if overridden != {"three_star_max": 36, "two_star_max": 44}:
		print("FAIL: per-level score threshold overrides")
		return false
	print("Score rules: PASS")
	return true


func _verify_level_13_energy() -> bool:
	var data := Levels.get_data(12)
	var logic := GameLogic.new()
	logic.load_level(data)
	if logic.blocks.size() != 1 or logic.energy_nodes.size() != 3 or not data.maps.is_empty():
		print("FAIL: Level 13 must teach three sequential nodes with one Core on one floor")
		return false
	# Trying to skip node 1 must reject the push without consuming a move.
	logic.player = Vector3i(3, 0, 4)
	logic.blocks = {Vector3i(4, 0, 4): true}
	var before := logic._snapshot()
	if not logic.try_move(Vector3i.RIGHT).is_empty() or logic._snapshot() != before:
		print("FAIL: Level 13 permits out-of-order node activation")
		return false
	logic.blocks = {logic.slots.keys()[0]: true}
	if logic._check_won():
		print("FAIL: Level 13 can finish before all nodes are activated")
		return false
	return true


func _verify_narrative_progression() -> bool:
	for index in range(12):
		var early := GameLogic.new()
		early.load_level(Levels.get_data(index))
		if not early.energy_nodes.is_empty():
			print("FAIL: Energy Nodes must first appear at the L13 soul reveal")
			return false
	var finale := Levels.get_data(14)
	if finale.map == Levels.get_data(7).map or finale.hint_route == Levels.get_data(7).hint_route:
		print("FAIL: Judgement must not repeat the Foundry finale")
		return false
	var logic := GameLogic.new()
	logic.load_level(finale)
	var opened_door := false
	var crossed_bridge := false
	var advances := 0
	for action in finale.hint_route:
		var result := logic.rotate_bridge() if action == "B" else logic.try_move(DIRECTIONS[action])
		if result.is_empty():
			return false
		opened_door = opened_door or not (result.get("doors_changed", []) as Array).is_empty()
		crossed_bridge = crossed_bridge or logic.bridges.has(logic.player)
		if bool(result.get("energy_advanced", false)):
			advances += 1
	if not logic.won or not opened_door or not crossed_bridge or advances != 4:
		print("FAIL: Finale route must use the supply gate, bridge and all four Energy Nodes")
		return false
	return true


func _verify_level_12_climax() -> bool:
	var data := Levels.get_data(11)
	var logic := GameLogic.new()
	logic.load_level(data)
	if not logic.sequential_floors or logic.floor_count() != 2 \
			or logic.blocks.size() != 5 \
			or logic.portal_links.size() != 2 \
			or logic.elevator_links.size() != 2 \
			or logic.plates.size() != 2 \
			or logic.doors.size() != 2 \
			or not logic.energy_nodes.is_empty():
		print("FAIL: Level 12 must combine Portal, two sequential floors and Plate/Door without Energy Nodes")
		return false
	var used_portal := false
	var used_elevator := false
	var changed_door := false
	for action in data.hint_route:
		var result := logic.try_move(DIRECTIONS[action])
		if result.is_empty():
			print("FAIL: Level 12 verified route became invalid")
			return false
		used_portal = used_portal or bool(result.get("teleported", false))
		used_elevator = used_elevator or bool(result.get("floor_transition", false))
		changed_door = changed_door or not (result.get("doors_changed", []) as Array).is_empty()
	if not logic.won or not used_portal or not used_elevator or not changed_door:
		print("FAIL: Level 12 optimal route must actually use Portal, Door/Plate and Elevator")
		return false
	return true


func _verify_chapter_four_content() -> bool:
	var eva_data := Levels.get_data(13)
	var eva_logic := GameLogic.new()
	eva_logic.load_level(eva_data)
	if eva_data.chapter != 4 or eva_logic.blocks.size() != 2 \
			or eva_logic.energy_nodes.size() != 4 \
			or eva_logic.portal_links.size() != 2 \
			or eva_logic.elevator_links.size() != 2:
		print("FAIL: Level 14 must combine two Cores, four nodes, Portal and Elevator")
		return false

	var final_data := Levels.get_data(14)
	var final_logic := GameLogic.new()
	final_logic.load_level(final_data)
	if final_data.chapter != 4 or final_logic.blocks.size() != 3 \
			or final_logic.energy_nodes.size() != 4 \
			or not final_logic.has_bridges() \
			or final_logic.bridge_controls.is_empty():
		print("FAIL: Level 15 must combine three Cores, four nodes and a local bridge")
		return false
	return true


func _verify_undo_restart(index: int) -> bool:
	var data := Levels.get_data(index)
	var logic := GameLogic.new()
	logic.load_level(data)
	var initial := logic._snapshot()
	for action in data.hint_route:
		var before := logic._snapshot()
		var result := logic.rotate_bridge() if action == "B" else logic.try_move(DIRECTIONS[action])
		if result.is_empty():
			return false
		var after := logic._snapshot()
		var won := logic.won
		if not logic.undo() or logic._snapshot() != before or logic.won:
			print("FAIL: Undo changed puzzle state in Level %d" % (index + 1))
			return false
		if action == "B":
			logic.rotate_bridge()
		else:
			logic.try_move(DIRECTIONS[action])
		if logic._snapshot() != after or logic.won != won:
			print("FAIL: Replay after Undo differs in Level %d" % (index + 1))
			return false
	logic.load_level(data)
	if logic._snapshot() != initial or not logic.history.is_empty() or logic.won:
		print("FAIL: Restart did not reset Level %d" % (index + 1))
		return false
	return true


func _verify_session_guard() -> bool:
	var coordinator := GameCoordinator.new()
	var stale := coordinator.begin_operation()
	coordinator.new_session()
	var active := coordinator.begin_operation()
	if coordinator.end_operation(stale) or not coordinator.busy or coordinator.guard(stale):
		print("FAIL: Stale operation can unlock a new session")
		return false
	return coordinator.end_operation(active) and not coordinator.busy


func _verify_save_recovery() -> bool:
	var store = preload("res://src/core/progress_store.gd")
	# Isolated fixture: never touch the player's progress.json.
	var path := "user://verify_progress_%s.json" % Time.get_ticks_usec()
	var first := {"version": 2, "unlocked": 4, "levels": {"3": {"completed": true}}}
	var second := {"version": 2, "unlocked": 8, "levels": {}}
	var passed: bool = store.write_progress(path, first) == OK
	passed = (store.write_progress(path, second) == OK) and passed
	passed = (int(store.load_progress(path).get("unlocked", 0)) == 8) and passed
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	passed = (int(store.load_progress(path).get("unlocked", 0)) == 4) and passed
	# A corrupt primary must not overwrite the last good backup on next save.
	passed = (store.write_progress(path, second) == OK) and passed
	passed = (int(store.read_valid(path + ".bak").get("unlocked", 0)) == 4) and passed
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"unlocked": 4, "levels": {"0": "invalid record"}}')
	file.close()
	passed = (int(store.load_progress(path).get("unlocked", 0)) == 4) and passed
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	print("Save recovery: %s" % ("PASS" if passed else "FAIL"))
	return passed


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
	if i in [10, 11, 13] and not _verify_multi_floor_level(i + 1, data, logic):
		return false
	if not _verify_landmark(i, data, landmarks):
		return false
	if logic.has_bridges() and logic.bridge_controls.is_empty():
		print("FAIL: Level %d has a bridge but no local bridge_switch" % (i + 1))
		return false
	if logic.has_bridges() and logic.bridge_control_available():
		print("FAIL: Level %d starts inside bridge-switch range; local interaction is not tested" % (i + 1))
		return false
	if data.difficulty < 1 or data.difficulty > 5:
		print("FAIL: Level %d difficulty=%d is outside the 1-5 chapter scale" % [
			i + 1, data.difficulty
		])
		return false

	if i >= ROUTES.size():
		print("FAIL: Level %d has no verification route" % (i + 1))
		return false

	var route := ROUTES[i]
	if data.hint_route.is_empty():
		print("FAIL: Level %d has no offline hint route" % (i + 1))
		return false
	if data.hint_route != route:
		print("FAIL: Level %d hint_route differs from its verification route" % (i + 1))
		return false
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


func _verify_multi_floor_level(level_number: int, data: LevelData, logic: GameLogic) -> bool:
	if data.maps.size() != 2:
		print("FAIL: Level %d must contain exactly two map layers" % level_number)
		return false
	if not data.sequential_floors or not logic.sequential_floors:
		print("FAIL: Level %d must use sequential floor progression" % level_number)
		return false
	if logic.elevators.size() != 2 or logic.elevator_links.size() != 2:
		print("FAIL: Level %d must contain one valid Elevator pair" % level_number)
		return false
	var elevator_positions: Array = logic.elevators.keys()
	var first: Vector3i = elevator_positions[0]
	var second: Vector3i = elevator_positions[1]
	if first.x != second.x or first.z != second.z or first.y == second.y:
		print("FAIL: Level %d Elevator endpoints must share their X/Z column" % level_number)
		return false
	if logic.elevators.has(logic.player):
		print("FAIL: Level %d player may not spawn on the Elevator" % level_number)
		return false
	for block in logic.blocks.keys():
		if logic.elevators.has(block):
			print("FAIL: Level %d Core may not spawn on the Elevator" % level_number)
			return false
	var lower_elevator: Vector3i = first if first.y == 0 else second
	if logic.elevator_is_unlocked(lower_elevator):
		print("FAIL: Level %d starts with its elevator unlocked" % level_number)
		return false
	var approach := Vector3i.ZERO
	for direction in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		var candidate: Vector3i = lower_elevator - direction
		if logic.floors.has(candidate) and not logic.walls.has(candidate) and not logic.blocks.has(candidate):
			approach = candidate
			break
	if approach == Vector3i.ZERO:
		print("FAIL: Level %d has no clear approach to its lower elevator" % level_number)
		return false
	logic.player = approach
	var before_attempt := logic._snapshot()
	if not logic.try_move(lower_elevator - approach).is_empty() or logic._snapshot() != before_attempt:
		print("FAIL: Level %d allows an early elevator ride" % level_number)
		return false
	logic.load_level(data)
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


func _verify_current_level_clamp() -> bool:
	var unlocked := 4
	var stored := 9
	var clamped := clampi(stored, 0, maxi(0, unlocked - 1))
	if clamped != 3:
		print("FAIL: current_level must clamp to unlocked-1 (got %d)" % clamped)
		return false
	print("Save cursor: current_level clamps to last unlocked index (PASS)")
	return true


func _verify_chapter_two_progress_migration() -> bool:
	var migrated := Levels.reconciled_unlocked({"3": {"completed": true}}, 4)
	if migrated != 5:
		print("FAIL: Chapter I completion did not migrate to unlock Level 5")
		return false
	print("Progress migration: completed Level 4 unlocks Level 5 (PASS)")
	return true


func _replay_route(logic: GameLogic, route: String, level_number: int) -> bool:
	var portal_crossed := false
	var elevator_crossings := 0
	var block_floor_changes := 0
	for step_index in route.length():
		var step: String = route[step_index]
		if step == "B":
			if logic.rotate_bridge().is_empty():
				print("FAIL: Level %d route cannot rotate bridge at step %d" % [
					level_number, step_index + 1
				])
				return false
			continue
		if not DIRECTIONS.has(step):
			print("FAIL: Level %d route has invalid step '%s'" % [level_number, step])
			return false
		var result := logic.try_move(DIRECTIONS[step])
		if result.is_empty():
			print("FAIL: Level %d route blocked at step %d ('%s')" % [
				level_number, step_index + 1, step
			])
			return false
		portal_crossed = portal_crossed or bool(result.get("teleported", false))
		if bool(result.get("pushed", false)) and result["pushed_from"].y != result["pushed_to"].y:
			block_floor_changes += 1
		if bool(result.get("elevated", false)):
			elevator_crossings += 1
			if logic.sequential_floors and (not bool(result.get("floor_transition", false)) \
					or result["player_to"].y <= result["player_from"].y \
					or not logic.is_floor_completed(result["player_from"].y)):
				print("FAIL: Level %d bypassed sequential elevator progression" % level_number)
				return false
	if not logic.won:
		print("FAIL: Level %d route ended without winning" % level_number)
		return false
	if level_number in [9, 10, 12] and not portal_crossed:
		print("FAIL: Level %d verification route never crosses its Portal" % level_number)
		return false
	if level_number == 11 and elevator_crossings < 1:
		print("FAIL: Level 11 verification route never uses its Elevator")
		return false
	if level_number in [11, 12, 14] and elevator_crossings != 1:
		print("FAIL: Level %d must use its Elevator exactly once" % level_number)
		return false
	if level_number in [11, 12, 14] and block_floor_changes > 0:
		print("FAIL: Level %d moved a Core between sequential floors" % level_number)
		return false
	return true
