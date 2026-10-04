extends SceneTree

const EXPANSION = preload("res://src/data/map_expansion.gd")
var scene: Node3D


func own(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = scene


func model(kind: String, position: Vector3, yaw := 0.0) -> void:
	var path: String = EXPANSION.ENERGY_NODE_PATH if kind == "energy_node" else EXPANSION.ASSETS[kind]
	var instance := (load(path) as PackedScene).instantiate() as Node3D
	instance.name = kind
	instance.position = position
	instance.rotation_degrees.y = yaw
	instance.scale = Vector3.ONE * .5
	own(instance, scene)


func cube(position: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .75
	instance.material_override = mat
	instance.position = position
	own(instance, scene)


func label(text: String, position: Vector3) -> void:
	var node := Label3D.new()
	node.text = text
	node.font_size = 48
	node.pixel_size = .004
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.no_depth_test = true
	node.position = position
	own(node, scene)


func _initialize() -> void:
	scene = Node3D.new()
	scene.name = "MapExpansionShowcase"
	scene.set_script(preload("res://src/tools/map_expansion_capture.gd"))
	root.add_child(scene)
	var origins := [Vector3(-3.2, 0, -2.2), Vector3(.7, 0, -2.2), Vector3(-3.2, 0, 1.7), Vector3(.7, 0, 1.7)]
	var chapters := ["archive", "foundry", "sanctuary", "core"]
	for i in range(4):
		var chapter: String = chapters[i]
		var origin: Vector3 = origins[i]
		cube(origin + Vector3(1, -.075, 1), Vector3(3.1, .15, 3.1), Color("152331"))
		for x in range(3):
			for z in range(3):
				model(chapter + "_floor_variant", origin + Vector3(x, 0, z), 90.0 if (x + z) % 2 else 0.0)
			model(chapter + "_wall_variant", origin + Vector3(x, .028, -.40))
		label(chapter.capitalize(), origin + Vector3(1, 0, 2.8))
	model("energy_node", Vector3(1.7, .035, 2.7))
	for x in [5.0, 6.0]:
		for z in [-1.8, -.8]:
			model("elevator_support_column", Vector3(x, 0, z))
	model("elevator_support_brace", Vector3(5.5, 0, -.8))
	cube(Vector3(5.5, 1.05, -1.3), Vector3(2, .20, 2), Color("172d40"))
	for x in [5.0, 6.0]:
		model("elevator_deck_fascia", Vector3(x, 1.15, -.8), 180)
	model("elevator_threshold", Vector3(5.5, 1.15, -.5), 180)
	label("Elevator / 1.15", Vector3(5.5, 0, .5))
	model("energy_node", Vector3(5.5, 0, 2.6))
	label("Energy Node", Vector3(5.5, 0, 3.4))
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("101b28")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c4def0")
	env.environment.ambient_light_energy = .6
	own(env, scene)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = .9
	light.shadow_enabled = true
	own(light, scene)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.8
	camera.position = Vector3(13, 15, 18)
	own(camera, scene)
	camera.look_at_from_position(camera.position, Vector3(1.5, 0, 1.1))
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/editor/map_expansion_showcase.tscn") == OK)
	print("Saved map expansion showcase")
	quit()
