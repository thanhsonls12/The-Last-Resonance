extends SceneTree

const ACTIONS = preload("res://src/game/action_execution.gd")


func _initialize() -> void:
	var failures := 0
	var actions = ACTIONS.new()

	var logic := GameLogic.new()
	logic.load_map("Push", [
		"######",
		"#@$ .#",
		"######",
	])
	var plan := actions.step(logic, Vector3i.RIGHT)
	if plan.get("kind", &"") != ACTIONS.KIND_MOVE:
		print("FAIL: valid step did not produce a move plan")
		failures += 1
	var block: Dictionary = plan.get("block_transition", {})
	if block.get("from", Vector3i.ZERO) != Vector3i(2, 0, 1) \
			or block.get("to", Vector3i.ZERO) != Vector3i(3, 0, 1):
		print("FAIL: push transition was not normalized")
		failures += 1
	if logic.player != Vector3i(2, 0, 1) or not logic.blocks.has(Vector3i(3, 0, 1)):
		print("FAIL: action execution did not commit GameLogic state")
		failures += 1

	var blocked := actions.step(logic, Vector3i.FORWARD)
	if not blocked.is_empty():
		print("FAIL: blocked step produced a presentation plan")
		failures += 1

	logic.load_maps("Elevator", [
		"#####\n#@  #\n# e #\n#####",
		"#####\n#   #\n# e #\n#####",
	])
	logic.sequential_floors = true
	logic.completed_floors[0] = true
	logic.player = Vector3i(1, 0, 2)
	var elevator_plan := actions.step(logic, Vector3i.RIGHT)
	if not bool(elevator_plan.get("floor_transition", false)):
		print("FAIL: unlocked elevator step did not expose a floor transition")
		failures += 1
	elif elevator_plan.get("elevator_entry", Vector3i.ZERO) != Vector3i(2, 0, 2) \
			or elevator_plan.get("player_to", Vector3i.ZERO) != Vector3i(2, 1, 2):
		print("FAIL: elevator transition endpoints were not normalized")
		failures += 1

	logic.load_map("Bridge", [
		"#####",
		"#@  #",
		"#   #",
		"#####",
	])
	logic.bridges[Vector3i(2, 0, 1)] = true
	logic.bridge_controls[Vector3i(2, 0, 1)] = true
	var bridge_plan := actions.rotate_bridge(logic)
	if bridge_plan.get("kind", &"") != ACTIONS.KIND_BRIDGE:
		print("FAIL: bridge action did not produce a bridge plan")
		failures += 1
	elif bridge_plan.get("bridge_open", false) != logic.bridge_open:
		print("FAIL: bridge plan does not reflect committed state")
		failures += 1

	print("Action execution: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
