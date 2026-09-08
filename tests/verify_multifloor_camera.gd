extends Node

const GAME_SCENE := preload("res://scenes/game/main.tscn")
const TARGET_LEVELS := [11, 12, 14]
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame


func projected_point_is_readable(camera: Camera3D, point: Vector3, viewport_size: Vector2, label: String) -> void:
	check(not camera.is_position_behind(point), "%s is in front of the camera" % label)
	var screen := camera.unproject_position(point)
	var margin := 12.0
	check(screen.x >= margin and screen.x <= viewport_size.x - margin and screen.y >= margin and screen.y <= viewport_size.y - margin, "%s stays inside the board frame" % label)


func landmark_positions(game: Node, layer: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	var logic = game.logic
	for position in logic.elevators.keys():
		if position.y == layer:
			result.append(position)
	for position in logic.slots.keys():
		if position.y == layer:
			result.append(position)
	for position in logic.energy_nodes:
		if position.y == layer:
			result.append(position)
	if result.is_empty():
		for position in logic.floors.keys():
			if position.y == layer:
				result.append(position)
				break
	return result


func check_level(game: Node, level_number: int) -> void:
	var logic = game.logic
	var camera_controller: EchoCameraController = game.camera_controller
	var board: BoardView = game.board_view
	check(logic != null and camera_controller != null and camera_controller.camera != null, "Level %02d runtime camera exists" % level_number)
	if logic == null or camera_controller == null or camera_controller.camera == null:
		return
	var layers := {}
	for position in logic.floors.keys():
		layers[position.y] = true
	check(layers.has(0) and layers.has(1), "Level %02d has both gameplay layers" % level_number)
	check(logic.sequential_floors, "Level %02d uses sequential floor progression" % level_number)
	var floor_zero_root := board.layer_roots.get(0) as Node3D
	var floor_one_root := board.layer_roots.get(1) as Node3D
	var floor_one_preview := board.floor_preview_roots.get(1) as Node3D
	check(floor_zero_root != null and floor_one_root != null, "Level %02d builds separate visual floor roots" % level_number)
	if floor_zero_root != null and floor_one_root != null:
		check(floor_zero_root.visible and not floor_one_root.visible, "Level %02d hides full floor 2 while floor 1 is active" % level_number)
	check(floor_one_preview != null and floor_one_preview.visible, "Level %02d leaves a small upper-floor structure visible" % level_number)
	var upper_loop_found := false
	for effect in game.vfx._loop_effects:
		if int(effect.get_meta("floor", -1)) == 1:
			upper_loop_found = true
			check(not effect.visible, "Level %02d hides upper-floor loop VFX" % level_number)
	var expects_upper_loop := false
	for position in logic.energy_nodes:
		if position.y == 1:
			expects_upper_loop = true
	for position in logic.portals.keys():
		if position.y == 1:
			expects_upper_loop = true
	if expects_upper_loop:
		check(upper_loop_found, "Level %02d tracks authored upper-floor loop VFX" % level_number)
	var min_x := 999999
	var max_x := -999999
	var min_z := 999999
	var max_z := -999999
	for position in logic.cells_on_floor(0).keys():
		min_x = mini(min_x, position.x)
		max_x = maxi(max_x, position.x)
		min_z = mini(min_z, position.z)
		max_z = maxi(max_z, position.z)
	var expected_center := Vector3((min_x + max_x) * 0.5 + 0.5, 0.0, (min_z + max_z) * 0.5 + 0.5)
	check(is_equal_approx(camera_controller.position.x, expected_center.x) and is_equal_approx(camera_controller.position.z, expected_center.z), "Level %02d camera centers the active floor" % level_number)
	var viewport_size := get_viewport().get_visible_rect().size
	for layer in [0, 1]:
		board.set_active_floor(layer)
		game.vfx.set_active_floor(layer)
		camera_controller.focus_cells(logic.cells_on_floor(layer), layer, false)
		await wait_frames(2)
		check(camera_controller.active_layer == layer and is_equal_approx(camera_controller.position.y, float(layer) * 1.15), "Level %02d camera focuses layer %d" % [level_number, layer])
		if floor_zero_root != null and floor_one_root != null:
			check(floor_zero_root.visible == (layer == 0) and floor_one_root.visible == (layer == 1), "Level %02d shows only active puzzle floor %d" % [level_number, layer + 1])
		if floor_one_preview != null:
			check(floor_one_preview.visible == (layer == 0), "Level %02d keeps preview only below floor 2" % level_number)
		for effect in game.vfx._loop_effects:
			if int(effect.get_meta("floor", -1)) == 1:
				check(effect.visible == (layer == 1), "Level %02d shows upper loop VFX only on floor 2" % level_number)
		for position in landmark_positions(game, layer):
			projected_point_is_readable(camera_controller.camera, board.world_position(position) + Vector3(0, 0.24, 0), viewport_size, "Level %02d layer %d landmark %s" % [level_number, layer, position])


func _ready() -> void:
	for level_number in TARGET_LEVELS:
		var game := GAME_SCENE.instantiate()
		add_child(game)
		await wait_frames(8)
		game.call("_load_level", level_number - 1)
		await wait_frames(8)
		await check_level(game, level_number)
		game.free()
	print("Multi-floor camera checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
