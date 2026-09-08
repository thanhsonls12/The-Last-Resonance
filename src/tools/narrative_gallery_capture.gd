extends Node3D

func _ready() -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	if DisplayServer.get_name() == "headless":
		printerr("Narrative gallery capture requires a graphics display")
		get_tree().quit(1)
		return
	for frame in range(18):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	var result := picture.save_png("res://docs/NARRATIVE_LANDMARK_PREVIEW.png")
	print("Narrative gallery capture: ", result)
	get_tree().quit(result)
