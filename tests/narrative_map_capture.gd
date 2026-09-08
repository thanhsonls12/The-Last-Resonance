extends Node3D

## Visual QA of the real BoardView/camera; no main scene or progress writes.
const DIRECTIONS := {"U": Vector3i(0,0,-1), "D": Vector3i(0,0,1), "L": Vector3i(-1,0,0), "R": Vector3i(1,0,0)}
const QUALITY = preload("res://src/data/render_quality.gd")
const CAPTURE_ROOT := "res://.codex_qa/visual_polish"

func option(prefix: String, fallback: int) -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix).to_int()
	return fallback


func text_option(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			var value := arg.trim_prefix(prefix).strip_edges().to_upper()
			if not value.is_empty():
				return value.replace(" ", "_")
	return fallback

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Map capture requires a graphics display")
		get_tree().quit(1)
		return
	var number := option("--level=", 15)
	var floor := option("--floor=", 0)
	var steps := option("--steps=", 0)
	var label := text_option("--label=", "STATE")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_ROOT))
	var data := Levels.get_data(number - 1)
	var logic := GameLogic.new()
	logic.load_level(data)
	var played := 0
	for action in data.hint_route:
		if logic.active_floor == floor and played >= steps:
			break
		var result := logic.rotate_bridge() if action == "B" else logic.try_move(DIRECTIONS[action])
		assert(not result.is_empty())
		played += 1
	assert(logic.active_floor == floor)
	var board := BoardView.new()
	add_child(board)
	board.chapter = data.chapter
	board.power_level = data.power_level
	board.build(logic, data.decorations)
	var camera := EchoCameraController.new()
	add_child(camera)
	camera.setup()
	camera.focus_cells(logic.cells_on_floor(floor), floor, false)
	var profile := load("res://resources/visuals/chapter_%02d.tres" % data.chapter) as ChapterVisuals
	var lift := data.power_level
	var env := WorldEnvironment.new()
	add_child(env)
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = profile.background
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = profile.ambient
	env.environment.ambient_light_energy = lerpf(profile.ambient_range.x, profile.ambient_range.y, lift) * QUALITY.ambient_boost()
	var colors := [profile.key, profile.fill, profile.wash]
	var ranges := [profile.key_range, profile.fill_range, profile.wash_range]
	var angles := [Vector3(-54,-36,0), Vector3(38,142,0), Vector3(-22,148,0)]
	for i in range(3):
		var light := DirectionalLight3D.new()
		add_child(light)
		light.rotation_degrees = angles[i]
		light.light_color = colors[i]
		light.light_energy = lerpf(ranges[i].x, ranges[i].y, lift) * QUALITY.key_boost()
		light.shadow_enabled = i == 0 and QUALITY.shadows_enabled()
	for frame in range(24):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	var output := "%s/LEVEL_%02d_FLOOR_%02d_STEP_%03d_%s.png" % [CAPTURE_ROOT, number, floor + 1, played, label]
	var error := picture.save_png(output)
	print("Map capture: ", output, " result=", error)
	get_tree().quit(error)
