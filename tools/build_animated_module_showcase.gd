extends SceneTree

var scene: Node3D


func own(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = scene


func _initialize() -> void:
	scene = Node3D.new()
	scene.name = "AnimatedModuleShowcase"
	scene.set_script(preload("res://src/tools/animated_module_preview.gd"))
	root.add_child(scene)
	var groups := [
		["Archive", Vector3(-7.8, 0, -5), ["Cable-Coil", "Broken-Robot", "Terminal", "Hologram-Projector"]],
		["Foundry", Vector3(1, 0, -5), ["Conveyor", "Foundry-Press", "Foundry-Furnace", "Foundry-Pipe-Valve"]],
		["Sanctuary", Vector3(-7.8, 0, 2), ["Sanctuary-Tree", "Plant-Cluster", "Sanctuary-Vine-Arch", "Sanctuary-Shrine"]],
		["Central Core", Vector3(1, 0, 2), ["Core-Reactor", "Core-Generator", "Core-Hologram-Dais", "Energy-Core"]],
	]
	var polish := "--polish-gallery" in OS.get_cmdline_user_args()
	if polish:
		groups = [
			["Core / Socket", Vector3(-7.8, 0, -5), ["Energy-Core", "Core-Pedestal", "Core-Generator", "Core-Hologram-Dais"]],
			["Foundry", Vector3(1, 0, -5), ["Foundry-Furnace", "Foundry-Press", "Machine-Unit", "Conveyor"]],
			["Archive / Sanctuary", Vector3(-7.8, 0, 2), ["Archive-Data-Vault", "Sanctuary-Shrine", "Sanctuary-Tree", "Plant-Cluster"]],
			["Landmarks", Vector3(1, 0, 2), ["Core-Reactor", "Narrative-judgement_engine", "Archive-Terminal", "Hologram-Projector"]],
		]
	for chapter_index in range(4):
		var group: Array = groups[chapter_index]
		var origin: Vector3 = group[1]
		for i in range(4):
			var name_text: String = group[2][i]
			var model := (load("res://assets/models/baked/" + name_text + ".glb") as PackedScene).instantiate() as Node3D
			model.position = origin + Vector3((i % 2) * 3.5, 0, (i / 2) * 2.7)
			model.scale = Vector3.ONE * .5
			model.set_meta("chapter", chapter_index + 1)
			own(model, scene)
			preload("res://src/data/chapter_material_profiles.gd").apply(model, chapter_index + 1)
			var platform := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(2.4, .14, 2.1)
			platform.mesh = box
			platform.material_override = MeshFactory.mat(Color("142331"))
			platform.position = model.position + Vector3(0, -.08, 0)
			own(platform, scene)
			var label := Label3D.new()
			label.text = name_text.replace("-", " ")
			label.font_size = 32
			label.pixel_size = .006
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.position = model.position + Vector3(0, -.03, 1.3)
			own(label, scene)
		var heading := Label3D.new()
		heading.text = group[0]
		heading.font_size = 48
		heading.pixel_size = .007
		heading.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		heading.no_depth_test = true
		heading.position = origin + Vector3(1.75, .1, -1.4)
		own(heading, scene)
	var plate := (load("res://assets/models/baked/Pressure-Plate.glb") as PackedScene).instantiate() as Node3D
	plate.position = Vector3(-1.6, 0, .2)
	plate.scale = Vector3.ONE * .5
	plate.set_meta("chapter", 2)
	own(plate, scene)
	var plate_label := Label3D.new()
	plate_label.text = "Pressure Plate\nPress / Release"
	plate_label.font_size = 32
	plate_label.pixel_size = .006
	plate_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plate_label.no_depth_test = true
	plate_label.position = plate.position + Vector3(0, 0, .8)
	own(plate_label, scene)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("0c1521")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("a2c6db")
	env.environment.ambient_light_energy = .42
	env.environment.glow_enabled = true
	own(env, scene)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = .8
	light.shadow_enabled = true
	own(light, scene)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.5
	camera.position = Vector3(13, 19, 20)
	own(camera, scene)
	camera.look_at_from_position(camera.position, Vector3(-1.8, .2, -.5))
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	var output := "res://scenes/editor/asset_polish_showcase.tscn" if polish else "res://scenes/editor/animated_module_showcase.tscn"
	assert(ResourceSaver.save(packed, output) == OK)
	print("Saved animated module showcase")
	quit()
