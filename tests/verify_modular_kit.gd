extends SceneTree

const KIT = preload("res://src/data/modular_props.gd")
const PROPS = preload("res://src/data/chapter_props.gd")
const PIPE_PORTS := {
	"kit_pipe_straight": [Vector3(-.5, .22, 0), Vector3(.5, .22, 0)],
	"kit_pipe_elbow": [Vector3(-.5, .22, 0), Vector3(0, .22, .5)],
	"kit_pipe_tee": [Vector3(-.5, .22, 0), Vector3(.5, .22, 0), Vector3(0, .22, .5)],
	"kit_pipe_end": [Vector3(-.5, .22, 0)],
}
const LOW_WALLS := {
	"kit_wall_low_straight": Vector3(0.97, 0.38, 0.20),
	"kit_wall_low_corner": Vector3(0.93, 0.38, 0.89),
	"kit_wall_low_end": Vector3(0.52, 0.38, 0.25),
}
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func vector(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])

func collect_scene_paths(node: Node, paths: Dictionary) -> void:
	if not node.scene_file_path.is_empty():
		paths[node.scene_file_path] = true
	for child in node.get_children():
		collect_scene_paths(child, paths)

func _initialize() -> void:
	var library := load("res://resources/mesh_libraries/echo_mesh_library.tres") as MeshLibrary
	var bounds_report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/MODULAR_KIT_BOUNDS.json"))
	check(bounds_report.size() == KIT.ASSETS.size(), "all measured modules")
	var grid := GridMap.new()
	grid.mesh_library = library
	grid.cell_size = Vector3.ONE
	var index := 0
	for entry in bounds_report:
		var kind: String = entry.type
		var instance := (load(KIT.ASSETS[kind]) as PackedScene).instantiate() as Node3D
		var mesh := ArrayMesh.new()
		PROPS.append_meshes(instance, Transform3D.IDENTITY, mesh)
		var bounds := mesh.get_aabb()
		check((bounds.position * .5).distance_to(vector(entry.bounds_min)) < .001, kind + " minimum bounds")
		check((bounds.end * .5).distance_to(vector(entry.bounds_max)) < .001, kind + " maximum bounds")
		check(bounds.size.x <= 2.02 and bounds.size.z <= 2.02, kind + " stays within grid footprint")
		if LOW_WALLS.has(kind):
			var expected: Vector3 = LOW_WALLS[kind]
			check(bounds.size.x * .5 <= expected.x + .001, kind + " low-wall width")
			check(bounds.size.z * .5 <= expected.z + .001, kind + " low-wall depth")
			check(bounds.size.y * .5 <= .39, kind + " stays below .4 game-unit height")
		var id := library.find_item_by_name("Kit_" + kind.trim_prefix("kit_"))
		check(id >= 0, kind + " editor item")
		if id >= 0:
			check(library.get_item_mesh(id).get_aabb().is_equal_approx(bounds), kind + " editor geometry")
			check(library.get_item_mesh(id).get_surface_count() == mesh.get_surface_count(), kind + " complete assembly")
			check(library.get_item_shapes(id).is_empty(), kind + " no unintended collision")
			for turn in range(4):
				grid.set_cell_item(Vector3i(index * 2, 0, turn * 2), id,
					grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, turn * PI / 2)))
		if PIPE_PORTS.has(kind):
			for port in PIPE_PORTS[kind]:
				var normal := Vector3(port.x, 0, port.z).normalized()
				var points: Array[Vector3] = []
				for surface in mesh.get_surface_count():
					var arrays := mesh.surface_get_arrays(surface)
					for vertex in arrays[Mesh.ARRAY_VERTEX]:
						var game_vertex: Vector3 = vertex * .5
						if absf((game_vertex - port).dot(normal)) < .0005:
							if not points.has(game_vertex):
								points.append(game_vertex)
				check(points.size() >= 12, kind + " connector has full cross-section")
				var center := Vector3.ZERO
				for p in points:
					center += p
					check(absf(p.distance_to(port) - .10) < .001, kind + " connector radius .10")
				if not points.is_empty():
					check((center / points.size()).distance_to(port) < .001, kind + " connector center")
		instance.free()
		index += 1
	var level := GridMapLevelSync.export_gridmap_to_level_data(grid)
	check(level.decorations.size() == KIT.ASSETS.size() * 4, "all modules in four orientations export")
	for deco in level.decorations:
		check(KIT.ASSETS.has(deco.type), "runtime type known")
		check(level.map[deco.grid_position.z][deco.grid_position.x] == " ", "modular overlay does not add walls")
	GridMapLevelSync.import_level_data_to_gridmap(level, grid)
	var roundtrip := GridMapLevelSync.export_gridmap_to_level_data(grid)
	check(roundtrip.decorations.size() == level.decorations.size(), "round trip count")
	var expected_by_cell := {}
	for deco in level.decorations:
		expected_by_cell[deco.grid_position] = deco
	for deco in roundtrip.decorations:
		check(expected_by_cell.has(deco.grid_position), "round trip position")
		if expected_by_cell.has(deco.grid_position):
			var expected: Dictionary = expected_by_cell[deco.grid_position]
			check(deco.type == expected.type, "round trip type")
			check(absf(angle_difference(deg_to_rad(expected.yaw), deg_to_rad(deco.yaw))) < .0001, "round trip rotation")
	grid.free()
	# Independent connection examples: straight-to-elbow, elbow-to-rotated-straight,
	# and a rail turning from the north edge to the east edge of a cell.
	for turn in range(4):
		var rotation := Basis(Vector3.UP, turn * PI / 2)
		check((rotation * Vector3(.5, .22, 0)).is_equal_approx(rotation * (Vector3(1, 0, 0) + PIPE_PORTS.kit_pipe_elbow[0])), "pipe joins straight to elbow")
		var elbow_end: Vector3 = Vector3(1, 0, 0) + PIPE_PORTS.kit_pipe_elbow[1]
		var continuation := Vector3(1, 0, 1) + Basis(Vector3.UP, -PI / 2) * PIPE_PORTS.kit_pipe_straight[0]
		check((rotation * elbow_end).is_equal_approx(rotation * continuation), "pipe turns on grid")
		var rail_corner_end := Vector3(1.43, .64, .5)
		var rail_next := Vector3(1, 0, 1) + Basis(Vector3.UP, -PI / 2) * Vector3(-.5, .64, -.43)
		check((rotation * rail_corner_end).is_equal_approx(rotation * rail_next), "rail turns on grid")
	var ids := {}
	for id in library.get_item_list():
		ids[id] = library.get_item_name(id)
	KIT.add_to_library(library)
	check(library.get_item_list().size() == ids.size(), "reinstall does not duplicate items")
	for id in ids:
		check(library.get_item_name(id) == ids[id], "reinstall preserves IDs")
	var showcase := (load("res://scenes/editor/modular_map_showcase.tscn") as PackedScene).instantiate()
	var used_assets := {}
	collect_scene_paths(showcase, used_assets)
	for path in KIT.ASSETS.values():
		check(used_assets.has(path), "assembled showcase includes " + str(path))
	showcase.free()
	print("Modular kit checks: ", failures, " failures")
	quit(1 if failures else 0)
