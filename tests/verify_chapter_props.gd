extends SceneTree

const PROPS = preload("res://src/data/chapter_props.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var library := load("res://resources/mesh_libraries/echo_mesh_library.tres") as MeshLibrary
	var identity_report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/CHAPTER_IDENTITY_PROPS_BOUNDS.json"))
	var identity_by_type := {}
	for entry in identity_report:
		identity_by_type[str(entry.type)] = entry
		check(PROPS.ASSETS.has(str(entry.type)), str(entry.type) + " identity report entry is registered in chapter catalog")
	var grid := GridMap.new()
	grid.mesh_library = library
	grid.cell_size = Vector3.ONE
	var index := 0
	for kind in PROPS.ASSETS:
		var instance := (load(PROPS.ASSETS[kind]) as PackedScene).instantiate() as Node3D
		var mesh := ArrayMesh.new()
		PROPS.append_meshes(instance, Transform3D.IDENTITY, mesh)
		var bounds := mesh.get_aabb()
		check(absf(bounds.position.y) < 0.002, str(kind) + " grounded pivot")
		check(absf(bounds.get_center().x) < 0.002 and absf(bounds.get_center().z) < 0.002, str(kind) + " centered pivot")
		check(bounds.size.x < 4 and bounds.size.z < 4, str(kind) + " no distant roster parts")
		if identity_by_type.has(kind):
			var entry: Dictionary = identity_by_type[kind]
			var game_size := bounds.size * 0.5
			check(game_size.x <= 1.0 and game_size.z <= 1.0, str(kind) + " identity prop stays within 1x1 footprint")
			check(game_size.y <= 0.45, str(kind) + " identity prop stays below 0.45 game-unit height")
			check(int(entry.triangles) <= 120, str(kind) + " identity prop triangle budget")
		var id := library.find_item_by_name("Prop_" + str(kind))
		check(id >= 0, str(kind) + " editor item exists")
		if id >= 0:
			check(library.get_item_mesh(id).get_surface_count() == mesh.get_surface_count(), str(kind) + " all surfaces retained")
			check(library.get_item_mesh(id).get_aabb().is_equal_approx(bounds), str(kind) + " editor geometry matches GLB")
			grid.set_cell_item(Vector3i(index * 2, 0, 0), id, grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, PI / 2)))
		instance.free()
		index += 1
	var level := GridMapLevelSync.export_gridmap_to_level_data(grid)
	check(level.decorations.size() == PROPS.ASSETS.size(), "all chapter props export to LevelData")
	check(identity_report.size() == 8, "all 8 phase-B identity props measured")
	for deco in level.decorations:
		check(PROPS.ASSETS.has(deco.type), "runtime decoration mapping")
		check(is_equal_approx(float(deco.yaw), 90.0), "export yaw")
		check(level.map[deco.grid_position.z][deco.grid_position.x] == "#", "scenery anchor is not walkable")
	GridMapLevelSync.import_level_data_to_gridmap(level, grid)
	var roundtrip := GridMapLevelSync.export_gridmap_to_level_data(grid)
	check(roundtrip.decorations == level.decorations, "decoration position/type/yaw round trip")
	grid.free()
	print("Chapter props checks: ", failures, " failures")
	quit(1 if failures else 0)
