extends Node

const QUALITY = preload("res://src/data/render_quality.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	var reduced_before := GameState.reduced_motion
	GameState.reduced_motion = false
	for mobile in [false, true]:
		QUALITY.set_mobile_override(mobile)
		var data := Levels.get_data(6)
		var logic := GameLogic.new()
		logic.load_level(data)
		var board := BoardView.new()
		board.chapter = data.chapter
		add_child(board)
		board.build(logic, data.decorations)
		board.set_process(false)
		var original := board.player_node.position
		board.play_step_weight(true, .2)
		board._actors._weight_tween.custom_step(.07)
		check(board.player_node.rotation.x < -.02, "Push produces a restrained effort pose")
		board._actors._weight_tween.custom_step(.3)
		check(is_zero_approx(board.player_node.rotation.x), "Step pose settles without accumulating tilt")
		check(board.player_node.position == original, "Weight feedback does not change movement endpoints")
		var cell: Vector3i = logic.plates.keys()[0]
		var route: Array = board._gameplay_objects.lock_routes[cell][0]
		check(route[0].distance_to(board.world_position(cell)) < .2, "Energy starts at the triggering plate")
		for i in range(1, route.size()):
			var delta: Vector3 = route[i] - route[i - 1]
			check(is_zero_approx(delta.x) or is_zero_approx(delta.z), "Packet follows actual right-angle cable geometry")
		for i in range(5):
			board.send_lock_pulse(cell, true)
		check(board.map_response.pulses.size() == (2 if mobile else 3), "Energy packet budget stays bounded")
		for packet in board.map_response.pulses:
			check(packet.get_parent() == board.layer_roots[cell.y], "Packets inherit source floor visibility")
		board.set_sector_powered(true)
		var distinct_delays := {}
		for info in board._lighting._power_materials:
			distinct_delays[info.delay] = true
		check(distinct_delays.size() > 1, "Power restoration has a spatial startup sequence")
		board.set_sector_powered(false, true)
		check(board._lighting._transition_tweens.is_empty(), "Reset cancels pending power transitions")
		GameState.reduced_motion = true
		board.map_response._process(.1)
		board.play_step_weight(true, .2)
		board.send_lock_pulse(cell, true)
		check(board.map_response.pulses.is_empty(), "Reduced Motion cancels and suppresses energy packets")
		check(is_zero_approx(board.player_node.rotation.x), "Reduced Motion keeps character pose stable")
		GameState.reduced_motion = false
		board.free()
	var exterior := preload("res://src/view/sector_exterior.gd").new()
	add_child(exterior)
	QUALITY.set_mobile_override(false)
	exterior.build({"min_x": 0, "max_x": 8, "min_z": 0, "max_z": 6}, 3)
	exterior.react_to_step(Vector3(0, .04, 3))
	check(exterior._next_ripple == 1, "Border steps create a water ripple")
	exterior.react_to_step(Vector3(4, .04, 3))
	check(exterior._next_ripple == 1, "Interior steps do not create distant splashes")
	exterior.free()
	GameState.reduced_motion = reduced_before
	QUALITY.set_mobile_override(null)
	print("Map response checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
