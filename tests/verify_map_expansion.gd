extends Node

const EXPANSION = preload("res://src/data/map_expansion.gd")
const PROPS = preload("res://src/data/chapter_props.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func vec(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])


func _ready() -> void:
	var report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/MAP_EXPANSION_BOUNDS.json"))
	check(report.size() == 13, "thirteen measured models")
	var library := load("res://resources/mesh_libraries/echo_mesh_library.tres") as MeshLibrary
	var grid := GridMap.new()
	grid.mesh_library = library
	grid.cell_size = Vector3.ONE
	var seen := {}
	for entry in report:
		var kind: String = entry.type
		seen[kind] = true
		var path: String = EXPANSION.ENERGY_NODE_PATH if kind == "energy_node" else EXPANSION.ASSETS[kind]
		var instance := (load(path) as PackedScene).instantiate() as Node3D
		var mesh := ArrayMesh.new()
		PROPS.append_meshes(instance, Transform3D.IDENTITY, mesh)
		var bounds := mesh.get_aabb()
		check((bounds.position * .5).distance_to(vec(entry.bounds_min)) < .001, kind + " minimum bounds survive export/import")
		check((bounds.end * .5).distance_to(vec(entry.bounds_max)) < .001, kind + " maximum bounds survive export/import")
		check(bounds.size.x * .5 <= 1.01 and bounds.size.z * .5 <= 1.01, kind + " one-cell footprint")
		check(entry.triangles <= 1500, kind + " triangle budget")
		if kind.ends_with("floor_variant"):
			check(bounds.position.y >= 0 and bounds.end.y * .5 <= .05, kind + " thin overlay above floor plane")
		if kind.ends_with("wall_variant"):
			check(bounds.end.y * .5 <= .4, kind + " low wall silhouette")
		if kind in ["elevator_support_column", "elevator_support_brace"]:
			check(is_equal_approx(bounds.size.y * .5, 1.14), kind + " floor spacing with .01 deck clearance")
		if kind == "energy_node":
			check(instance.find_child("NodeLens", true, false) is MeshInstance3D, "energy lens remains addressable")
		else:
			var id := library.find_item_by_name("Expansion_" + kind)
			check(id >= 0, kind + " editor item")
			if id >= 0:
				check(library.get_item_shapes(id).is_empty(), kind + " no implicit physics")
				check(library.get_item_mesh(id).get_surface_count() == mesh.get_surface_count(), kind + " complete editor assembly")
				for turn in range(4):
					grid.set_cell_item(Vector3i(seen.size() * 2, 0, turn * 2), id,
						grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, turn * PI / 2)))
		instance.free()
	for kind in EXPANSION.ASSETS:
		check(seen.has(kind), str(kind) + " measured")
	var level := GridMapLevelSync.export_gridmap_to_level_data(grid)
	check(level.decorations.size() == 48, "twelve scenery modules export in four orientations")
	for deco in level.decorations:
		var expected := "#" if EXPANSION.blocks_anchor(deco.type) else " "
		check(level.map[deco.grid_position.z][deco.grid_position.x] == expected, "wall/support anchors blocked; overlays remain walkable")
	GridMapLevelSync.import_level_data_to_gridmap(level, grid)
	var roundtrip := GridMapLevelSync.export_gridmap_to_level_data(grid)
	check(roundtrip.decorations.size() == level.decorations.size(), "editor round trip count")
	var expected_by_cell := {}
	for deco in level.decorations:
		expected_by_cell[deco.grid_position] = deco
	for deco in roundtrip.decorations:
		check(expected_by_cell.has(deco.grid_position), "editor round trip position")
		if expected_by_cell.has(deco.grid_position):
			var original: Dictionary = expected_by_cell[deco.grid_position]
			check(deco.type == original.type, "editor round trip type")
			check(absf(angle_difference(deg_to_rad(deco.yaw), deg_to_rad(original.yaw))) < .0001, "editor round trip yaw")
	grid.free()

	var board := BoardView.new()
	add_child(board)
	var decorations: Array = []
	for layer in range(2):
		var x := 0
		for kind in EXPANSION.ASSETS:
			decorations.append({"type": kind, "grid_position": Vector3i(x, layer, 2),
				"yaw": 90.0, "offset_x": .1, "offset_y": .12, "scale": .8})
			x += 1
	board._build_decorations(decorations)
	check(board.decor_nodes.size() == 24, "all scenery spawns at both elevations")
	for i in mini(board.decor_nodes.size(), decorations.size()):
		var item: Node3D = board.decor_nodes[i]
		var cell: Vector3i = decorations[i].grid_position
		check(item.position.is_equal_approx(Vector3(cell.x + .1, BoardView.FLOOR_TOP_Y + cell.y * 1.15 + .12, 2)), "floor elevation and offsets applied once")
		check(item.scale.is_equal_approx(Vector3.ONE * .4), "authored grid scale")
		check(is_equal_approx(item.rotation.y, PI / 2), "runtime yaw")
	board.free()

	for index in [12, 13, 14]:
		var data: LevelData = Levels.get_data(index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var campaign_board := BoardView.new()
		campaign_board.chapter = data.chapter
		add_child(campaign_board)
		campaign_board.build(logic, data.decorations)
		check(campaign_board.energy_nodes.size() == logic.energy_nodes.size(), "campaign Energy Node count unchanged")
		for position in logic.energy_nodes:
			var node: Node3D = campaign_board.energy_nodes[position]
			var housing := node.get_node_or_null("EnergyNodeModel") as Node3D
			check(housing != null and housing.scene_file_path == EXPANSION.ENERGY_NODE_PATH, "campaign uses new GLB")
			check(is_equal_approx(node.position.y, BoardView.FLOOR_TOP_Y + position.y * 1.15), "Energy Node sits on its floor")
			if housing:
				var lens := housing.find_child("NodeLens", true, false) as MeshInstance3D
				check(lens != null and lens.get_active_material(0) != null, "live energy material reaches lens")
			check(node.get_node_or_null("NodeNumber") is Label3D, "sequence number retained")
		if not logic.sequential_floors:
			campaign_board.set_energy_progress(1)
			var first: Node3D = campaign_board.energy_nodes[logic.energy_nodes[0]]
			check(first.scale.is_equal_approx(Vector3.ONE), "completed node feedback retained")
			campaign_board.set_energy_progress(0)
			check(first.scale.is_equal_approx(Vector3.ONE * .78), "reset node feedback retained")
		campaign_board.free()
	print("Map expansion checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
