extends Node

const SURFACES = preload("res://src/data/map_expansion.gd")
const PROPS = preload("res://src/data/chapter_props.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func collect_base_tiles(node: Node, tiles: Array[Node3D]) -> void:
	if node is Node3D and node.scene_file_path == BoardView.FLOOR_TILE_PATH:
		tiles.append(node)
	for child in node.get_children():
		collect_base_tiles(child, tiles)


func _ready() -> void:
	for path in SURFACES.FLOOR_SKINS.values():
		var model := (load(path) as PackedScene).instantiate() as Node3D
		var mesh := ArrayMesh.new()
		PROPS.append_meshes(model, Transform3D.IDENTITY, mesh)
		var bounds := mesh.get_aabb()
		check(bounds.size.x <= 2.001 and bounds.size.z <= 2.001, "complete floor stays inside cell")
		check(bounds.position.y >= -.001 and bounds.end.y * .5 < .15, "panel height fits old floor envelope")
		check(mesh.get_surface_count() <= 4, "consolidated material budget")
		model.free()
	for index in range(15):
		var data: LevelData = Levels.get_data(index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var walls := logic.walls.duplicate()
		var blocks := logic.blocks.duplicate()
		var board := BoardView.new()
		board.chapter = data.chapter
		board.power_level = data.power_level
		add_child(board)
		board.build(logic, data.decorations)
		var old_tiles: Array[Node3D] = []
		collect_base_tiles(board, old_tiles)
		var floors_by_layer := {}
		var walls_by_layer := {}
		for i in data.decorations.size():
			var deco: Dictionary = data.decorations[i]
			if str(deco.get("surface_pass", "")) != "chapter_surface":
				continue
			var cell: Vector3i = deco.grid_position
			var node: Node3D = board.decor_nodes[i]
			if bool(deco.get("surface_skin", false)):
				floors_by_layer[cell.y] = int(floors_by_layer.get(cell.y, 0)) + 1
				check(not logic.walls.has(cell), "floor skin remains walkable")
				check(node.scene_file_path == SURFACES.FLOOR_SKINS[deco.type], "campaign uses full floor skin")
				check(node.position.is_equal_approx(board.world_position(cell)), "floor foundation anchored at original tile height")
				for old in old_tiles:
					check(not old.position.is_equal_approx(node.position), "no old tile drawn under replacement")
			else:
				walls_by_layer[cell.y] = int(walls_by_layer.get(cell.y, 0)) + 1
				check(logic.walls.has(cell), "chapter wall remains blocked")
				check(node.scene_file_path == SURFACES.ASSETS[deco.type], "chapter wall GLB is used")
		for floor in range(logic.floor_count()):
			check(int(floors_by_layer.get(floor, 0)) >= 5, "every campaign floor receives chapter panels")
			check(int(walls_by_layer.get(floor, 0)) >= 1, "every campaign floor receives chapter walls")
		check(logic.walls == walls and logic.blocks == blocks and logic.moves == 0, "surface pass does not alter puzzle state")
		board.free()
	print("Campaign surface checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
