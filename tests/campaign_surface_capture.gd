extends Node3D

const GAME_SCENE = preload("res://scenes/game/main.tscn")


func _ready() -> void:
	var original_level := GameState.current_level
	var original_unlocked := GameState.unlocked
	GameState.unlocked = 15
	var selected: Array[int] = []
	var powered := "--powered" in OS.get_cmdline_user_args()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--levels="):
			for number in argument.trim_prefix("--levels=").split(","):
				selected.append(number.to_int() - 1)
	var capture_directory := "res://.codex_qa/campaign_powered" if powered else "res://.codex_qa/campaign_surfaces"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_directory))
	for index in range(15):
		if not selected.is_empty() and not selected.has(index):
			continue
		GameState.current_level = index
		var game := GAME_SCENE.instantiate()
		add_child(game)
		await get_tree().create_timer(1.1).timeout
		if powered:
			game.board_view.set_sector_powered(true, true)
			game.scene_environment.power_up(Levels.get_data(index).chapter)
			await get_tree().create_timer(1.1).timeout
		var floors: int = game.logic.floor_count()
		for floor in range(floors):
			if floor > 0:
				game.board_view.set_active_floor(floor, false)
				game.vfx.set_active_floor(floor)
				game.camera_controller.focus_cells(game.logic.cells_on_floor(floor), floor, false)
				game.board_view.player_node.hide()
				await get_tree().create_timer(.1).timeout
			game.chapter_intro_card.hide()
			game.dialogue_box.hide()
			await RenderingServer.frame_post_draw
			var path := "%s/L%02d_F%d.png" % [capture_directory, index + 1, floor + 1]
			get_viewport().get_texture().get_image().save_png(path)
			print("Captured ", path)
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	GameState.current_level = original_level
	GameState.unlocked = original_unlocked
	get_tree().quit()
