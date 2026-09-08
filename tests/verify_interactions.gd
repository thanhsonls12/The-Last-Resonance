extends Node

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)


func _touch(input: GameplayInput, pressed: bool, position: Vector2, index := 0, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	event.canceled = canceled
	input._unhandled_input(event)


func _run() -> void:
	var root := get_tree().root
	_check(load("res://scenes/game/main.tscn") != null, "Gameplay scene must load with autoloads")
	var camera := EchoCameraController.new()
	root.add_child(camera)
	camera.setup()
	var input := GameplayInput.new()
	root.add_child(input)
	input.setup(camera)
	var arrow_found := false
	for event in InputMap.action_get_events("move_left"):
		if event is InputEventKey and event.physical_keycode == KEY_LEFT:
			arrow_found = true
	_check(arrow_found, "Arrow key must coexist with the configured WASD key")
	var counts := {"taps": 0, "steps": 0}
	input.tap_requested.connect(func(_position: Vector2): counts.taps += 1)
	input.step_requested.connect(func(_direction: Vector3i): counts.steps += 1)
	_touch(input, true, Vector2(100, 100))
	_touch(input, true, Vector2(200, 200), 1)
	_touch(input, false, Vector2(200, 200), 1)
	_touch(input, false, Vector2(100, 100))
	_check(counts.taps == 1 and counts.steps == 0, "Multi-touch must produce one tap")
	var mouse := InputEventMouseButton.new()
	mouse.device = -1
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = Vector2(100, 100)
	mouse.pressed = true
	input._unhandled_input(mouse)
	mouse.pressed = false
	input._unhandled_input(mouse)
	_check(counts.taps == 1, "Emulated mouse must not duplicate touch")
	_touch(input, true, Vector2(100, 100))
	_touch(input, false, Vector2(200, 100))
	_check(counts.steps == 1, "Swipe must produce one step")
	_touch(input, true, Vector2(100, 100))
	_touch(input, false, Vector2(100, 100), 0, true)
	_check(counts.taps == 1, "Canceled touch must not move")
	_touch(input, true, Vector2(100, 100))
	input.cancel_gesture()
	_touch(input, false, Vector2(100, 100))
	_check(counts.taps == 1, "Release after restart must not move")
	camera.focus_layer(1)
	camera.focus_layer(0, false)
	await get_tree().create_timer(0.5).timeout
	_check(camera.active_layer == 0 and is_zero_approx(camera.position.y), "Old layer tween must not override reset")
	_check(is_equal_approx(EchoCameraController.board_fov_for_aspect(16.0 / 9.0), 48.0), "Landscape board framing keeps the base FOV")
	_check(EchoCameraController.board_fov_for_aspect(0.6) > 48.0 and EchoCameraController.board_fov_for_aspect(0.6) <= 62.0, "Portrait board framing widens the FOV within a safe cap")
	var dialogue := DialogueBox.new()
	root.add_child(dialogue)
	var card := ChapterIntroCard.new()
	root.add_child(card)
	var story := StoryDirector.new()
	story.setup(dialogue, null, card, Callable())
	# Cancellation must return before an old intro accesses its board/VFX.
	story.play_chapter_start_sequence(1, null, Callable())
	story.reset_for_level()
	_check(not card.visible and not dialogue.visible, "Reset must hide the old chapter intro")
	dialogue.play_dialogue([{"speaker": "EVA", "text": "Test"}])
	story.reset_for_level()
	_check(not dialogue.visible and not dialogue._is_typing, "Reset must stop dialogue typing")
	input.free()
	var board := BoardView.new()
	root.add_child(board)
	var data := Levels.get_data(12)
	var logic := GameLogic.new()
	logic.load_level(data)
	board.chapter = 4
	board.build(logic, data.decorations)
	_check(board.palette_name == &"central_core", "Chapter 4 must select the Central Core palette")
	_check(board.energy_nodes.size() == 3, "Level 13 must render all energy nodes")
	for i in logic.energy_nodes.size():
		var node: Node3D = board.energy_nodes[logic.energy_nodes[i]]
		var number := node.get_node_or_null("NodeNumber") as Label3D
		_check(number != null and number.text == str(i + 1), "Energy nodes must show activation order")
	board.free()
	camera.free()
	dialogue.free()
	card.free()
	print("INTERACTIONS: %s" % ("ALL TESTS PASSED" if failures == 0 else "FAILED"))
	get_tree().quit(0 if failures == 0 else 1)
