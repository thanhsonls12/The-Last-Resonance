extends SceneTree


func _initialize() -> void:
	var failures := 0
	var main_script = load("res://src/game/main.gd")
	var game = main_script.new()
	var data := Levels.get_data(0)
	game.flow.load_level(0)
	game.hints.load_route(data.hint_route)
	game._build_hint_route_states(data)

	# Level 1 starts with R on the verified route, while L is a harmless walkable
	# detour. The hint should guide Kiro back to the route instead of pointing at
	# the final pedestal.
	var detour: Dictionary = game.logic.try_move(Vector3i.LEFT)
	game._record_hint_action("L")
	game._sync_hint_cursor_to_logic()
	if detour.is_empty() or not game.hints.desynced:
		print("FAIL: harmless off-route walk was not detected as hint desync")
		failures += 1

	var recovery: Array = game._hint_recovery_path()
	if recovery.is_empty() or recovery[0] != Vector3i.RIGHT:
		print("FAIL: hint recovery did not point back to the verified route")
		failures += 1
	else:
		game.logic.try_move(recovery[0])
		game._record_hint_action("R")
		game._sync_hint_cursor_to_logic()
		if game.hints.desynced or game.hints.cursor != 0:
			print("FAIL: hint route did not resync after returning to the canonical state")
			failures += 1

	game.hints.load_route("RRRRRR")
	game.hints.advance_stage()
	if game.hints.reveal_current_stage() != 1:
		print("FAIL: hint level 1 did not charge one new action")
		failures += 1
	game.hints.advance_stage()
	if game.hints.reveal_current_stage() != 0:
		print("FAIL: hint level 2 charged the same action twice")
		failures += 1
	game.hints.advance_stage()
	if game.hints.reveal_current_stage() != 4 or game.hints.get_hint_penalty() != 5:
		print("FAIL: hint level 3 did not charge only new preview actions")
		failures += 1
	game.hints.dismiss()
	game.hints.advance_stage()
	if game.hints.reveal_current_stage() != 0:
		print("FAIL: reopening a revealed hint charged twice")
		failures += 1
	game.hints.undo_action()
	if game.hints.get_hint_penalty() != 5:
		print("FAIL: undo refunded revealed information")
		failures += 1
	game.hints.mark_desynced()
	if game.hints.reveal_current_stage() != 0:
		print("FAIL: desynced recovery hint was charged")
		failures += 1

	game.free()
	print("Hint recovery: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
