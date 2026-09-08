extends SceneTree

func _initialize() -> void:
	var scene := Node3D.new()
	scene.name = "NarrativeLandmarks"
	scene.set_script(preload("res://src/tools/narrative_gallery_capture.gd"))
	root.add_child(scene)
	var kinds := ["silence_reliquary", "elias_testament", "soul_archive", "eva_conduit", "judgement_engine"]
	var labels := ["11 · SILENCE", "12 · ELIAS", "13 · SOUL ARCHIVE", "14 · EVA", "15 · JUDGEMENT"]
	for i in kinds.size():
		var model := (load("res://assets/models/baked/Narrative-%s.glb" % kinds[i]) as PackedScene).instantiate() as Node3D
		scene.add_child(model)
		model.owner = scene
		model.name = kinds[i]
		model.scale = Vector3.ONE * .5
		model.position.x = (2 - i) * 1.5
		var label := Label3D.new()
		scene.add_child(label)
		label.owner = scene
		label.text = labels[i]
		label.font_size = 32
		label.pixel_size = .004
		label.position = model.position + Vector3(0, 0, -.85)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
	var env := WorldEnvironment.new()
	scene.add_child(env)
	env.owner = scene
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("17212a")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("cfdeec")
	env.environment.ambient_light_energy = .65
	var light := DirectionalLight3D.new()
	scene.add_child(light)
	light.owner = scene
	light.rotation_degrees = Vector3(-55, -25, 0)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.owner = scene
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.look_at_from_position(Vector3(0, 4, -6), Vector3(0, .15, 0))
	camera.current = true
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/editor/narrative_landmarks.tscn") == OK)
	print("Narrative landmark gallery saved")
	quit()
