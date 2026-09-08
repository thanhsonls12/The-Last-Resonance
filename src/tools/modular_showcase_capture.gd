extends Node3D

func _ready() -> void:
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png("res://docs/MODULAR_KIT_PREVIEW.png")
		get_tree().quit(result)
