extends Node3D

const MOTION = preload("res://src/view/module_motion.gd")
var controllers: Array[Node3D] = []
var _demo_clock := 0.0


func _process(delta: float) -> void:
	_demo_clock += delta
	for controller in controllers:
		if controller.profile == &"plate":
			var phase := fmod(_demo_clock, 3.0)
			controller.set_pressed(phase > .8 and phase < 2.0)


func _ready() -> void:
	for child in get_children():
		if child is Node3D and not child.scene_file_path.is_empty():
			var motion := MOTION.attach(child, child.scene_file_path, null, int(child.get_meta("chapter", 1)))
			if motion:
				controllers.append(motion)
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().create_timer(1.5).timeout
		for controller in controllers:
			if controller.profile == &"spark":
				controller.trigger_burst()
		await get_tree().create_timer(.12).timeout
		await RenderingServer.frame_post_draw
		var output := "res://docs/ASSET_POLISH_PREVIEW.png" if "--polish-gallery" in OS.get_cmdline_user_args() else "res://docs/ANIMATED_MODULE_PREVIEW.png"
		get_viewport().get_texture().get_image().save_png(output)
		get_tree().quit()
	elif "--record" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex_qa/module_motion_frames"))
		for frame in range(60):
			await get_tree().create_timer(.13).timeout
			if frame in [4, 32]:
				for controller in controllers:
					if controller.profile == &"spark":
						controller.trigger_burst()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.codex_qa/module_motion_frames/frame_%03d.png" % frame)
		get_tree().quit()
