extends Node

const KIT = preload("res://src/data/modular_props.gd")
const PROPS = preload("res://src/data/chapter_props.gd")
const REPRESENTATIVE_LEVELS := [1, 5, 10, 13]
const IDENTITY_BY_LEVEL := {
	1: ["archive_access_panel_broken", "archive_storage_tray_low"],
	5: ["foundry_pipe_support", "foundry_maintenance_box"],
	10: ["sanctuary_bank_root", "sanctuary_broken_plinth_low"],
	13: ["core_data_cabinet_low", "core_light_trim"],
}
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _ready() -> void:
	var board := BoardView.new()
	add_child(board)
	var decorations: Array = []
	for layer in range(2):
		var x := 0
		for kind in KIT.ASSETS:
			decorations.append({"type": kind, "grid_position": Vector3i(x, layer, 2),
				"yaw": 90.0, "offset_x": .1, "offset_y": .12, "scale": .8})
			x += 1
	board._build_decorations(decorations)
	check(board.decor_nodes.size() == KIT.ASSETS.size() * 2, "all modules spawn on both floors")
	for i in mini(board.decor_nodes.size(), decorations.size()):
		var item: Node3D = board.decor_nodes[i]
		var cell: Vector3i = decorations[i].grid_position
		var floor_height := board.world_position(cell).y - board.world_position(Vector3i.ZERO).y
		check(item.position.is_equal_approx(Vector3(cell.x + .1, BoardView.FLOOR_TOP_Y + floor_height + .12, 2)), "decoration position respects floor and offsets")
		check(item.scale.is_equal_approx(Vector3.ONE * .4), "runtime scale matches kit convention")
		check(is_equal_approx(item.rotation.y, PI / 2), "runtime yaw")
	board.free()

	# A2 campaign integration: low walls replace only the visual wall at an
	# already-blocked cell. The puzzle wall must remain authoritative.
	for level_index in REPRESENTATIVE_LEVELS:
		var data: LevelData = Levels.get_data(level_index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var expected := []
		for deco in data.decorations:
			if deco is Dictionary and str(deco.get("type", "")).begins_with("kit_wall_low_"):
				expected.append(deco)
		check(not expected.is_empty(), "representative Level %d contains an A2 low wall" % (level_index + 1))
		var campaign_board := BoardView.new()
		add_child(campaign_board)
		campaign_board.chapter = data.chapter
		campaign_board.power_level = data.power_level
		campaign_board.build(logic, data.decorations)
		for deco in expected:
			var cell: Vector3i = deco.grid_position
			var kind := str(deco.type)
			check(logic.walls.has(cell), "Level %d %s keeps its puzzle wall" % [level_index + 1, kind])
			var path: String = KIT.ASSETS[kind]
			var found := false
			for node in campaign_board.decor_nodes:
				if is_instance_valid(node) and node.scene_file_path == path:
					found = true
					break
			check(found, "Level %d spawns %s in BoardView" % [level_index + 1, kind])
		var identity_expected: Array = IDENTITY_BY_LEVEL[level_index]
		var identity_found := []
		for deco in data.decorations:
			if deco is Dictionary and identity_expected.has(str(deco.get("type", ""))):
				identity_found.append(deco)
		check(identity_found.size() == identity_expected.size(), "representative Level %d contains both phase-B identity props" % (level_index + 1))
		for deco in identity_found:
			var cell: Vector3i = deco.grid_position
			var kind := str(deco.type)
			check(logic.walls.has(cell), "Level %d %s stays on an authoritative puzzle wall" % [level_index + 1, kind])
			var path: String = PROPS.ASSETS[kind]
			var spawned := false
			for node in campaign_board.decor_nodes:
				if is_instance_valid(node) and node.scene_file_path == path:
					spawned = true
					break
			check(spawned, "Level %d spawns phase-B %s in BoardView" % [level_index + 1, kind])
		campaign_board.free()
	print("Modular runtime checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
