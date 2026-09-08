extends Control

const PROPS = preload("res://src/data/chapter_props.gd")

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("101820")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	margin.add_child(grid)
	for kind in PROPS.ASSETS:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var container := SubViewportContainer.new()
		container.stretch = true
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.add_child(container)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(240, 220)
		viewport.own_world_3d = true
		container.add_child(viewport)
		var world := Node3D.new()
		viewport.add_child(world)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color("1c2935")
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color("c5dcf0")
		env.environment.ambient_light_energy = 0.65
		world.add_child(env)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50, -35, 0)
		sun.light_energy = 1.3
		world.add_child(sun)
		var model := (load(PROPS.ASSETS[kind]) as PackedScene).instantiate() as Node3D
		model.scale = Vector3.ONE * 0.5
		world.add_child(model)
		var floor_mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2, 0.06, 2)
		floor_mesh.mesh = box
		floor_mesh.position.y = -0.035
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("344656")
		floor_mesh.material_override = material
		world.add_child(floor_mesh)
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 2.5
		camera.position = Vector3(2.8, 2.5, 4)
		camera.look_at(Vector3(0, 0.65, 0))
		var label := Label.new()
		label.text = str(kind).replace("_", " ")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		card.add_child(label)
	if "--capture" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png("res://docs/CHAPTER_PROPS_PREVIEW.png")
		get_tree().quit(error)
