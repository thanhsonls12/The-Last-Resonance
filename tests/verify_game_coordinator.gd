extends SceneTree


func _initialize() -> void:
	var failures := 0
	var coordinator := GameCoordinator.new()

	var first_session := coordinator.new_session()
	var operation := coordinator.begin_operation()
	if operation != first_session or not coordinator.busy or not coordinator.guard(operation):
		print("FAIL: begin_operation did not bind busy work to the current session")
		failures += 1

	var second_session := coordinator.new_session()
	if second_session == first_session or coordinator.guard(operation):
		print("FAIL: new_session did not invalidate stale async work")
		failures += 1
	if coordinator.end_operation(operation):
		print("FAIL: stale operation was allowed to end the current session")
		failures += 1

	coordinator.set_busy(false)
	var current_operation := coordinator.begin_operation()
	if not coordinator.end_operation(current_operation) or coordinator.busy:
		print("FAIL: current operation did not release busy state")
		failures += 1

	print("Game coordinator: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
