extends Node

const GAME_SCENE := preload("res://scenes/game/main.tscn")
const EXPECTED := {
	2: ["kit_floor_edge", "kit_rail_straight", "kit_floor_corner"],
	6: ["kit_pipe_straight", "kit_pipe_elbow", "foundry_furnace"],
	11: ["kit_water_edge", "kit_water_corner", "kit_water_tile"],
	14: ["kit_floor_edge", "kit_rail_straight", "core_wall"],
}
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func requested_level() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			return arg.trim_prefix("--level=").to_int()
	return 2


func normalized(value: String) -> String:
	return value.to_lower().replace("-", "_")


func detail_surface_count(root: Node) -> int:
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh:
			var mesh_instance := node as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D and (material as StandardMaterial3D).detail_enabled:
					count += 1
		for child in node.get_children():
			stack.append(child)
	return count


func _ready() -> void:
	var level_number := requested_level()
	var game := GAME_SCENE.instantiate()
	add_child(game)
	# main.gd builds the actual BoardView and loads the requested LevelData in _ready.
	for _frame in 8:
		await get_tree().process_frame
	check(game.board_view != null, "gameplay BoardView exists")
	check(game.camera_controller != null and game.camera_controller.camera != null, "gameplay camera exists")
	if game.board_view != null:
		var expected: Array = EXPECTED.get(level_number, [])
		var found := {}
		for node in game.board_view.decor_nodes:
			var filename := normalized(str(node.scene_file_path).get_file().get_basename())
			for kind in expected:
				var expected_filename := normalized(str(kind).trim_prefix("kit_"))
				if filename.contains(expected_filename):
					found[kind] = true
		check(found.size() == expected.size(), "all pilot models spawn in gameplay: " + str(found.keys()))
		if level_number == 11 or level_number == 14:
			var high_nodes := 0
			for decor_node in game.board_view.decor_nodes:
				if decor_node.position.y > BoardView.FLOOR_TOP_Y + 1.0:
					high_nodes += 1
			check(high_nodes > 0, "multi-floor pilot has decoration above floor one")
		var decoration_detail := 0
		for decor_node in game.board_view.decor_nodes:
			decoration_detail += detail_surface_count(decor_node)
		var all_detail := detail_surface_count(game.board_view)
		check(decoration_detail > 0, "pilot decorations receive chapter weathering")
		check(all_detail == decoration_detail, "weathering stays scoped to decoration nodes")
		print("Asset pilot runtime level %02d: %d failures, decorations=%d, detail_surfaces=%d" % [level_number, failures, game.board_view.decor_nodes.size(), decoration_detail])
	game.free()
	get_tree().quit(1 if failures else 0)
