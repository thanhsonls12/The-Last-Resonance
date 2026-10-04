extends SceneTree

const NAVIGATION = preload("res://src/game/player_navigation.gd")

func _initialize() -> void:
	var failures := 0
	var navigation = NAVIGATION.new()
	var logic := GameLogic.new()
	logic.load_map("Navigation", [
		"#######",
		"#@    #",
		"#  $  #",
		"#     #",
		"#######",
	])

	var walk_plan := navigation.plan_tap(logic, Vector3i(5, 0, 1))
	if walk_plan.get("kind", &"") != NAVIGATION.KIND_WALK:
		print("FAIL: empty walkable tile did not produce a walk plan")
		failures += 1
	elif (walk_plan.get("path", []) as Array).size() != 4:
		print("FAIL: walk plan did not use the shortest path")
		failures += 1

	var wall_plan := navigation.plan_tap(logic, Vector3i(0, 0, 1))
	if not wall_plan.is_empty():
		print("FAIL: wall tap produced a navigation plan")
		failures += 1

	var block_plan := navigation.plan_tap(logic, Vector3i(3, 0, 2))
	if block_plan.get("kind", &"") != NAVIGATION.KIND_BLOCK_APPROACH:
		print("FAIL: distant Core tap did not produce an approach plan")
		failures += 1
	elif (block_plan.get("path", []) as Array).is_empty():
		print("FAIL: distant Core approach plan has no path")
		failures += 1

	logic.load_map("Adjacent Core", [
		"#####",
		"#   #",
		"#@$ #",
		"#   #",
		"#####",
	])
	var push_plan := navigation.plan_tap(logic, Vector3i(2, 0, 2))
	if push_plan.get("kind", &"") != NAVIGATION.KIND_STEP \
			or push_plan.get("direction", Vector3i.ZERO) != Vector3i.RIGHT:
		print("FAIL: adjacent Core tap did not produce a direct step/push intent")
		failures += 1

	logic.load_maps("Elevator", [
		"#####\n#@  #\n# e #\n#####",
		"#####\n#   #\n# e #\n#####",
	])
	var elevator := Vector3i(2, 0, 2)
	var elevator_plan := navigation.plan_tap(logic, elevator)
	if elevator_plan.get("kind", &"") != NAVIGATION.KIND_ELEVATOR:
		print("FAIL: reachable elevator did not produce an explicit elevator plan")
		failures += 1
	else:
		var approach: Array = elevator_plan.get("path", [])
		if approach.is_empty():
			print("FAIL: elevator plan did not stop at an adjacent approach cell")
			failures += 1

	print("Player navigation: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
