extends Node

const PROPS = preload("res://src/data/chapter_props.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	var report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/ASSET_POLISH_BOUNDS.json"))
	check(report.size() == 9, "nine polished models")
	for entry in report:
		var model := (load("res://" + str(entry.path)) as PackedScene).instantiate() as Node3D
		var mesh := ArrayMesh.new()
		PROPS.append_meshes(model, Transform3D.IDENTITY, mesh)
		var bounds := mesh.get_aabb()
		var low: Array = entry.bounds_min
		var high: Array = entry.bounds_max
		check(bounds.position.x * .5 >= float(low[0]) - .002 and bounds.end.x * .5 <= float(high[0]) + .002, "footprint width retained")
		check(bounds.position.z * .5 >= float(low[2]) - .002 and bounds.end.z * .5 <= float(high[2]) + .002, "footprint depth retained")
		check(int(entry.triangles) <= 2000, "polished model triangle budget")
		model.free()
	for index in range(15):
		var data: LevelData = Levels.get_data(index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var board := BoardView.new()
		board.chapter = data.chapter
		add_child(board)
		board.build(logic, data.decorations)
		var signs := board.find_children("SectorSign", "Node3D", true, false)
		check(signs.size() == logic.floor_count(), "one sector sign per floor")
		for i in range(data.decorations.size()):
			var kind: String = data.decorations[i].type
			if kind in ["plant", "sanctuary_tree", "debris", "rubble", "archive_access_panel_broken"]:
				check(board.decor_nodes[i].has_meta("asset_variation"), "active scenery receives variation")
		check(board.decor_nodes.size() == data.decorations.size(), "dressing retains existing instances")
		check(logic.moves == 0, "polish does not execute gameplay moves")
		board.free()
	print("Asset polish checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
