extends Node

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	for index in range(15):
		var data := Levels.get_data(index)
		var raw := GameLogic.new()
		if data.maps.is_empty():
			raw.load_map(data.title, data.map)
		else:
			raw.load_maps(data.title, data.maps)
		var logic := GameLogic.new()
		logic.load_level(data)
		if index == 8:
			var pool: Dictionary = data.decorations.filter(func(deco): return deco.type == "sanctuary_pool")[0]
			check(pool.type in GameLogic.DECORATION_WALL_TYPES, "L9 pool frame is solid scenery, not a flat water tile")
			check(raw.walls.has(pool.grid_position), "L9 pool frame stays off the puzzle route")
			check(logic.portals.size() == 2, "L9 retains both real teleporters")
		var board := BoardView.new()
		board.chapter = data.chapter
		add_child(board)
		board.build(logic, data.decorations)
		for i in data.decorations.size():
			var deco: Dictionary = data.decorations[i]
			if deco.type not in GameLogic.DECORATION_WALL_TYPES:
				continue
			var cell: Vector3i = deco.grid_position
			if deco.type not in ["bridge_console", "reactor_switch"]:
				check(raw.walls.has(cell), "L%d %s does not consume a puzzle route" % [index+1, deco.type])
			check(logic.walls.has(cell), "Solid scenery blocks direct movement and pathfinding")
			var model: Node3D = board.decor_nodes[i]
			if index == 8 and deco.type == "sanctuary_pool":
				check(model.scene_file_path.ends_with("Sanctuary-Pool.glb"), "L9 uses the authored basin instead of Portal")
				var water_surfaces := 0
				for part in model.find_children("*", "MeshInstance3D", true, false):
					for surface in part.mesh.get_surface_count():
						var material: Material = part.get_active_material(surface)
						if material is ShaderMaterial and material.shader == load(BoardDecorations.WATER_SHADER_PATH):
							water_surfaces += 1
							check(is_zero_approx(material.get_shader_parameter("is_ice_mode")), "Pool water is liquid")
				check(water_surfaces == 1, "Only water gets the shader; stone and energy orb keep their materials")
			for child in model.find_children("*", "MeshInstance3D", true, false):
				var mesh := child as MeshInstance3D
				if not mesh.mesh:
					continue
				var bounds: AABB = (model.get_parent().global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb()
				check(bounds.position.x >= cell.x-.441 and bounds.end.x <= cell.x+.441 and bounds.position.z >= cell.z-.441 and bounds.end.z <= cell.z+.441, "L%d %s/%s stays inside blocked cell: %s" % [index+1, deco.type, mesh.name, bounds])
		board.free()
	print("Scenery clearance checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
