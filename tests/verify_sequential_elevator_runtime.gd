extends Node

const GAME_SCENE := preload("res://scenes/game/main.tscn")
const LEVEL_INDEX := 10
const DIRECTIONS := {
	"U": Vector3i(0, 0, -1),
	"D": Vector3i(0, 0, 1),
	"L": Vector3i(-1, 0, 0),
	"R": Vector3i(1, 0, 0),
}

var failures := 0


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame


func _ready() -> void:
	var game := GAME_SCENE.instantiate()
	add_child(game)
	await _wait_frames(8)
	game.call("_load_level", LEVEL_INDEX)
	await _wait_frames(8)

	var data: LevelData = Levels.get_data(LEVEL_INDEX)
	var transition := {}
	for action in data.hint_route:
		transition = game.logic.try_move(DIRECTIONS[action])
		_check(not transition.is_empty(), "Level 11 route reaches its elevator")
		if transition.is_empty():
			break
		if bool(transition.get("floor_transition", false)):
			break

	_check(bool(transition.get("floor_transition", false)), "Level 11 produces a floor-transition result")
	if bool(transition.get("floor_transition", false)):
		var entry: Vector3i = transition["elevator_entry"]
		game.board_view.player_node.position = game.board_view.player_target(entry, game.logic.blocks)
		await game._play_elevator_transition(entry, game.logic.player, game.coordinator.play_id)
		await _wait_frames(2)
		_check(game.logic.active_floor == 1, "Elevator commits floor 2 as the active floor")
		_check(game.board_view.layer_roots[1].visible and not game.board_view.layer_roots[0].visible, "Runtime elevator swaps visible puzzle floors")
		_check(game.camera_controller.active_layer == 1, "Runtime elevator moves the camera focus to floor 2")
		_check(is_equal_approx(game.board_view.player_node.position.y, game.board_view.player_target(game.logic.player, game.logic.blocks).y), "Kiro arrives on the upper elevator tile")
		var floor_two_root := game.board_view.layer_roots[1] as Node3D
		_check(floor_two_root.get_child_count() > 0 and floor_two_root.is_visible_in_tree(), "Floor 2 has visible rendered content after the elevator ride")
		for block in game.logic.blocks.keys():
			if block.y == 1:
				_check(game.board_view.block_nodes.has(block) and game.board_view.block_nodes[block].is_visible_in_tree(), "Floor 2 Core is visible after the elevator ride")
				var core_root := game.board_view.block_nodes[block] as Node3D
				var core_model := core_root.get_node_or_null("EnergyCoreModel") as Node3D
				_check(core_model != null, "Floor 2 Core keeps its authored model")
				if core_model != null:
					_check(is_equal_approx(core_model.global_position.y, game.board_view._floor_surface_y(block)), "Floor 2 Core model sits on the upper floor instead of below it")
		# Let one-shot elevator VFX timers finish before freeing their captured nodes.
		await get_tree().create_timer(1.0).timeout

	game.free()
	await _verify_tap_to_elevator()
	print("SEQUENTIAL ELEVATOR RUNTIME: ", "ALL TESTS PASSED" if failures == 0 else "FAILED")
	get_tree().quit(0 if failures == 0 else 1)


func _verify_tap_to_elevator() -> void:
	var game := GAME_SCENE.instantiate()
	add_child(game)
	await _wait_frames(8)
	game.call("_load_level", LEVEL_INDEX)
	await _wait_frames(8)

	# Replay only until floor 1 is completed. This leaves Kiro several cells away
	# from the unlocked elevator, matching the real tap-to-move use case.
	var data: LevelData = Levels.get_data(LEVEL_INDEX)
	var floor_completed := false
	for action in data.hint_route:
		var result: Dictionary = game.logic.try_move(DIRECTIONS[action])
		_check(not result.is_empty(), "Level 11 setup route remains valid before elevator tap")
		if result.is_empty():
			break
		if bool(result.get("floor_completed", false)):
			floor_completed = true
			break
	_check(floor_completed, "Level 11 floor 1 can unlock the elevator before tapping it")
	game.call("_snap_visuals")
	await _wait_frames(2)

	var elevator := Vector3i.ZERO
	var found_elevator := false
	for position in game.logic.elevators.keys():
		if position.y == game.logic.active_floor and game.logic.elevator_is_unlocked(position):
			elevator = position
			found_elevator = true
			break
	_check(found_elevator, "Level 11 exposes an unlocked floor-1 elevator to tap")
	if found_elevator:
		# Skip narrative blocking in this input regression test; the story event has
		# its own coverage and normally waits for the player to dismiss dialogue.
		game.story._story_event_flags["level_11_silence_protocol"] = true
		var old_reduced_motion: bool = GameState.reduced_motion
		GameState.reduced_motion = true
		var tap_world: Vector3 = game.board_view.world_position(elevator) + Vector3(0, 0.04, 0)
		var tap_screen: Vector2 = game.camera_controller.camera.unproject_position(tap_world)
		game.call("_handle_tap", tap_screen)
		await get_tree().create_timer(1.25).timeout
		_check(game.logic.active_floor == 1, "Tapping the unlocked Level 11 elevator moves Kiro to floor 2")
		_check(game.camera_controller.active_layer == 1, "Elevator tap also moves camera focus to floor 2")
		GameState.reduced_motion = old_reduced_motion

	game.free()
