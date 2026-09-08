extends Node3D

const GAME_SCENE := preload("res://scenes/game/main.tscn")
const CAPTURE_ROOT := "res://.codex_qa/visual_polish"


func _level_number() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			return maxi(1, arg.trim_prefix("--level=").to_int())
	return 1


func _floor_number() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			return maxi(1, arg.trim_prefix("--floor=").to_int())
	return 1


func _capture_label() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			var value := arg.trim_prefix("--label=").strip_edges().to_upper()
			if not value.is_empty():
				return value.replace(" ", "_")
	return "START"


func _int_option(prefix: String, fallback := 0) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix).to_int()
	return fallback


func _decoration_cell(game: Node, kind: String) -> Variant:
	var data: LevelData = Levels.get_data(_level_number() - 1)
	if data == null:
		return null
	for deco in data.decorations:
		if deco is Dictionary and str(deco.get("type", "")) == kind:
			var cell: Variant = deco.get("grid_position", null)
			if cell is Vector3i:
				return cell
	return null


func _hide_story_overlay(game: Node) -> void:
	for property in [&"chapter_intro_card", &"dialogue_box"]:
		var node: Node = game.get(property)
		if node is CanvasItem:
			(node as CanvasItem).hide()


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT))
	var game := GAME_SCENE.instantiate()
	add_child(game)
	# Let the actual gameplay scene build its board, camera and chapter lighting.
	for _frame in 18:
		await get_tree().process_frame
	_hide_story_overlay(game)
	var requested_floor := _floor_number() - 1
	if requested_floor > 0 and requested_floor < game.logic.floor_count():
		game.board_view.set_active_floor(requested_floor, false)
		game.vfx.set_active_floor(requested_floor)
		game.camera_controller.focus_cells(game.logic.cells_on_floor(requested_floor), requested_floor, false)
		# This QA override jumps floors without simulating the elevator, so Kiro would
		# otherwise remain at the Floor 1 transform and pollute the composition shot.
		game.board_view.player_node.visible = false
		for _frame in 3:
			await get_tree().process_frame
	var eva_stage := clampi(_int_option("--eva-stage=", 0), 0, 4)
	if eva_stage > 0 and _level_number() == 14:
		var eva_cell: Variant = _decoration_cell(game, "eva_conduit")
		if eva_cell is Vector3i:
			# Use the same projection-position helper as runtime story beats. The QA
			# viewer sits by the fourth Energy Node so the shot represents the live
			# Floor 2 confession composition without replaying dialogue UI.
			var viewer := Vector3i(6, 1, 2)
			var fixture_world: Vector3 = game.board_view.world_position(eva_cell)
			var viewer_world: Vector3 = game.board_view.world_position(viewer)
			var projection: Vector3 = game.story._hologram_projection_position(fixture_world, viewer_world)
			game.board_view.set_eva_hologram_stage(eva_stage, projection, viewer_world)
			for _frame in 3:
				await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var label := _capture_label()
	var output := "%s/LEVEL_%02d_FLOOR_01_%s.png" % [CAPTURE_ROOT, _level_number(), label]
	if requested_floor > 0:
		output = "%s/LEVEL_%02d_FLOOR_%02d_%s.png" % [CAPTURE_ROOT, _level_number(), requested_floor + 1, label]
	var error := image.save_png(output)
	print("Asset pilot capture: ", output, " (", image.get_width(), "x", image.get_height(), ")")
	# Let the real renderer consume the captured frame before the QA scene exits.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().quit(error)
