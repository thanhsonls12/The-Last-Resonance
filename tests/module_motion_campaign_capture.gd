extends Node3D

const GAME_SCENE = preload("res://scenes/game/main.tscn")


func _ready() -> void:
	var game := GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().create_timer(1.8).timeout
	var floor := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--floor="):
			floor = arg.trim_prefix("--floor=").to_int() - 1
	if floor > 0:
		game.board_view.set_active_floor(floor, false)
		game.vfx.set_active_floor(floor)
		game.camera_controller.focus_cells(game.logic.cells_on_floor(floor), floor, false)
		game.board_view.player_node.hide()
	var motions: Array = game.board_view.find_children("ModuleMotion", "Node3D", true, false)
	for motion in motions:
		if motion.profile == &"spark":
			motion.trigger_burst()
	await get_tree().create_timer(.1).timeout
	game.chapter_intro_card.hide()
	game.dialogue_box.hide()
	await RenderingServer.frame_post_draw
	var output := "res://.codex_qa/MOTION_LEVEL_%02d_FLOOR_%02d.png" % [game.level_index + 1, floor + 1]
	var result := get_viewport().get_texture().get_image().save_png(output)
	print("Motion campaign capture: ", output)
	get_tree().quit(result)
