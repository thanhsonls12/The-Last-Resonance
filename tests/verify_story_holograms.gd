extends Node

var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: " + message)


func _decoration_cell(data: LevelData, kind: String) -> Vector3i:
	for deco in data.decorations:
		if deco is Dictionary and str(deco.get("type", "")) == kind:
			var value: Variant = deco.get("grid_position", null)
			if value is Vector3i:
				return value
	return Vector3i.ZERO


func _build_board(level_index: int) -> Dictionary:
	var data: LevelData = Levels.get_data(level_index)
	var logic := GameLogic.new()
	logic.load_level(data)
	var board := BoardView.new()
	add_child(board)
	board.chapter = data.chapter
	board.power_level = data.power_level
	board.build(logic, data.decorations)
	return {"data": data, "logic": logic, "board": board}


func _run() -> void:
	var fixtures := {}
	for kind in ["silence_reliquary", "elias_testament", "soul_archive", "eva_conduit", "judgement_engine"]:
		var path: String = BoardView.DECOR_ASSETS[kind].path
		_check(not fixtures.has(path), "Story fixtures have distinct geometry: " + kind)
		fixtures[path] = true
		var fixture := (load(path) as PackedScene).instantiate() as Node3D
		var mesh := ArrayMesh.new()
		preload("res://src/data/chapter_props.gd").append_meshes(fixture, Transform3D.IDENTITY, mesh)
		var bounds := mesh.get_aabb()
		_check(absf(bounds.position.y) < .002, kind + " grounded pivot")
		_check(bounds.size.x * .5 <= .83 and bounds.size.z * .5 <= .83, kind + " bounded footprint")
		_check(bounds.size.y * .5 <= .6, kind + " low silhouette")
		fixture.free()
	# Level 12: the projector exists from load, Elias does not. His body is a
	# narrative reveal, not scenery that is visible before the testament unlocks.
	var l12 := _build_board(11)
	var board12: BoardView = l12["board"]
	var data12: LevelData = l12["data"]
	_check(board12.get_node_or_null("EliasHologram") == null, "Level 12 must not show Elias before the testament beat")
	var elias_cell := _decoration_cell(data12, "elias_testament")
	var elias := board12.spawn_elias_hologram(board12.world_position(elias_cell), board12.world_position((l12["logic"] as GameLogic).player))
	await get_tree().create_timer(0.5).timeout
	_check(elias != null and is_instance_valid(elias) and elias.visible, "Level 12 can reveal the Elias full-body hologram")
	board12.dismiss_elias_hologram(true)
	board12.free()

	# Level 14: each Energy Node strengthens the same live EVA signal.
	var l14 := _build_board(13)
	var board14: BoardView = l14["board"]
	var data14: LevelData = l14["data"]
	var logic14: GameLogic = l14["logic"]
	var eva_cell := _decoration_cell(data14, "eva_conduit")
	var eva1 := board14.set_eva_hologram_stage(1, board14.world_position(eva_cell), board14.world_position(logic14.player))
	await get_tree().create_timer(0.55).timeout
	var stage1_scale := eva1.scale.x if eva1 != null else 0.0
	var stage1_glitch := float(board14._eva_hologram_material.get_shader_parameter("glitch_strength")) if board14._eva_hologram_material != null else -1.0
	var eva4 := board14.set_eva_hologram_stage(4, board14.world_position(eva_cell), board14.world_position(logic14.player))
	await get_tree().create_timer(0.4).timeout
	var stage4_glitch := float(board14._eva_hologram_material.get_shader_parameter("glitch_strength")) if board14._eva_hologram_material != null else -1.0
	_check(eva1 == eva4 and eva4 != null, "Level 14 strengthens one persistent EVA signal instead of spawning unrelated copies")
	_check(eva4 != null and eva4.scale.x > stage1_scale, "Level 14 EVA grows from weak signal to full hologram")
	_check(stage1_glitch > stage4_glitch and is_equal_approx(stage4_glitch, 0.06), "Level 14 EVA becomes less glitchy as Energy Nodes stabilize her")
	board14.free()

	# Level 15: the final judgement may show both witnesses at the same time.
	var l15 := _build_board(14)
	var board15: BoardView = l15["board"]
	var data15: LevelData = l15["data"]
	var logic15: GameLogic = l15["logic"]
	var judgement := _decoration_cell(data15, "judgement_engine")
	var center := board15.world_position(judgement)
	var player_world := board15.world_position(logic15.player)
	var eva_final := board15.spawn_eva_hologram(center + Vector3(-0.85, 0, 0), player_world, 4)
	var elias_final := board15.spawn_elias_hologram(center + Vector3(0.85, 0, 0), player_world)
	await get_tree().create_timer(0.5).timeout
	_check(eva_final != null and elias_final != null and eva_final.visible and elias_final.visible, "Level 15 can present EVA and Elias together before Kiro decides")
	board15.free()

	print("STORY HOLOGRAMS: %s" % ("ALL TESTS PASSED" if failures == 0 else "FAILED"))
	get_tree().quit(0 if failures == 0 else 1)
