extends SceneTree

const KIT = preload("res://src/data/modular_props.gd")
const PROPS = preload("res://src/data/chapter_props.gd")
const MATERIAL_PROFILES = preload("res://src/data/chapter_material_profiles.gd")
var scene: Node3D


func own(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = scene


func cube(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	item.material_override = mat
	item.position = pos
	own(item, parent)


func model(parent: Node3D, kind: String, pos: Vector3, yaw := 0.0) -> void:
	var path: String = KIT.ASSETS.get(kind, PROPS.ASSETS.get(kind, ""))
	if path.is_empty():
		path = "res://assets/models/baked/" + kind + ".glb"
	var instance := (load(path) as PackedScene).instantiate() as Node3D
	instance.name = kind
	instance.position = pos
	instance.rotation_degrees.y = yaw
	instance.scale = Vector3.ONE * 0.5
	own(instance, parent)


func room(name_text: String, origin: Vector3, color: Color) -> Node3D:
	var room_node := Node3D.new()
	room_node.name = name_text
	room_node.position = origin
	own(room_node, scene)
	for z in range(5):
		for x in range(5):
			cube(room_node, Vector3(x, -.22, z), Vector3(.985, .44, .985), color)
	# A continuous fascia with explicit NE/SE/SW/NW corner pieces.
	for i in range(1, 4):
		model(room_node, "kit_floor_edge", Vector3(i, 0, 0))
		model(room_node, "kit_floor_edge", Vector3(4, 0, i), -90)
		model(room_node, "kit_floor_edge", Vector3(i, 0, 4), 180)
		model(room_node, "kit_floor_edge", Vector3(0, 0, i), 90)
	model(room_node, "kit_floor_corner", Vector3(4, 0, 0))
	model(room_node, "kit_floor_corner", Vector3(4, 0, 4), -90)
	model(room_node, "kit_floor_corner", Vector3(0, 0, 4), 180)
	model(room_node, "kit_floor_corner", Vector3(0, 0, 0), 90)
	model(room_node, "kit_floor_inner_corner", Vector3(2, 0, 2))
	for x in range(1, 4):
		model(room_node, "kit_rail_straight", Vector3(x, 0, 0))
	model(room_node, "kit_rail_corner", Vector3(4, 0, 0))
	model(room_node, "kit_rail_end", Vector3(0, 0, 0), 180)
	model(room_node, "kit_rail_end_reverse", Vector3(2, 0, 0))
	# The rotated end sits on the north rail's plane, not across the cell.
	room_node.get_child(room_node.get_child_count() - 1).position.z = -.86
	model(room_node, "kit_rail_straight", Vector3(4, 0, 1), -90)
	model(room_node, "kit_rail_end", Vector3(4, 0, 2), -90)
	# A2 low-wall family: straight, corner and end. These sit on blocked
	# architectural cells in campaign maps; the showcase keeps them isolated so
	# their connectors and silhouette can be inspected from the gameplay camera.
	model(room_node, "kit_wall_low_straight", Vector3(1, 0, 4))
	model(room_node, "kit_wall_low_corner", Vector3(2, 0, 4))
	model(room_node, "kit_wall_low_end", Vector3(3, 0, 4))
	var label := Label3D.new()
	label.text = name_text.replace("_", " ")
	label.font_size = 58
	label.pixel_size = .006
	label.position = Vector3(2, .1, 5.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	own(label, room_node)
	return room_node


func _initialize() -> void:
	scene = Node3D.new()
	scene.name = "ModularMapShowcase"
	scene.set_script(preload("res://src/tools/modular_showcase_capture.gd"))
	root.add_child(scene)
	var archive := room("I_Archive", Vector3(-6, 0, -6), Color("253646"))
	model(archive, "Archive-Bookshelf", Vector3(1, 0, .7))
	model(archive, "Archive-Terminal", Vector3(3, 0, 1))
	model(archive, "Archive-Holo-Projector", Vector3(2, 0, 3))
	model(archive, "archive_access_panel_broken", Vector3(.7, 0, 2.2), 90)
	model(archive, "archive_storage_tray_low", Vector3(3.3, 0, 3.2))
	model(archive, "kit_floor_end", Vector3(2, 0, 4), 180)
	model(archive, "kit_floor_end_reverse", Vector3(3, 0, 4), 180)
	MATERIAL_PROFILES.apply(archive, 1)
	var foundry := room("II_Foundry", Vector3(1, 0, -6), Color("45382e"))
	model(foundry, "foundry_furnace", Vector3(1, 0, .8))
	model(foundry, "foundry_press", Vector3(3, 0, .8))
	model(foundry, "kit_pipe_end", Vector3(0, 0, 3), 180)
	model(foundry, "kit_pipe_straight", Vector3(1, 0, 3))
	model(foundry, "kit_pipe_tee", Vector3(2, 0, 3))
	model(foundry, "kit_pipe_elbow", Vector3(3, 0, 3))
	model(foundry, "kit_pipe_end", Vector3(2, 0, 4), -90)
	model(foundry, "kit_pipe_end", Vector3(3, 0, 4), -90)
	model(foundry, "foundry_pipe_support", Vector3(1.1, 0, 2.2), 90)
	model(foundry, "foundry_maintenance_box", Vector3(3.5, 0, 3.7), 180)
	MATERIAL_PROFILES.apply(foundry, 2)
	var sanctuary := room("III_Sanctuary", Vector3(-6, 0, 1), Color("2c4640"))
	# L-shaped 4x3 basin, with a filled NE tile and a connected concave bank.
	for z in range(3):
		for x in range(4):
			if x == 3 and z == 0:
				cube(sanctuary, Vector3(x + 1, .11, z + 1), Vector3(1, .22, 1), Color("536f70"))
				continue
			var kind := "kit_water_tile"
			var yaw := 0.0
			if x == 0 and z == 0:
				kind = "kit_water_corner"
				yaw = 90
			elif x == 3 and z == 0:
				kind = "kit_water_corner"
			elif x == 3 and z == 2:
				kind = "kit_water_corner"
				yaw = -90
			elif x == 0 and z == 2:
				kind = "kit_water_corner"
				yaw = 180
			elif z == 0 or z == 2 or x == 0 or x == 3:
				kind = "kit_water_edge"
				yaw = 180 if z == 2 else (90 if x == 0 else (-90 if x == 3 else 0))
			if (x == 2 and z == 0) or (x == 3 and z == 1):
				kind = "kit_water_corner"
				yaw = 0
			elif x == 2 and z == 1:
				kind = "kit_water_inner_corner"
			model(sanctuary, kind, Vector3(x + 1, 0, z + 1), yaw)
	model(sanctuary, "sanctuary_tree", Vector3(.25, 0, .8))
	model(sanctuary, "sanctuary_shrine", Vector3(3, 0, .15))
	model(sanctuary, "sanctuary_bank_root", Vector3(.8, 0, 3.8), -90)
	model(sanctuary, "sanctuary_broken_plinth_low", Vector3(3.7, 0, 3.7))
	MATERIAL_PROFILES.apply(sanctuary, 3)
	var core := room("IV_Central_Core", Vector3(1, 0, 1), Color("253c50"))
	model(core, "core_reactor", Vector3(2, 0, 1.2))
	model(core, "core_generator", Vector3(.6, 0, 2.7))
	model(core, "core_hologram_dais", Vector3(3.3, 0, 2.7))
	model(core, "core_wall", Vector3(1, 0, .15))
	model(core, "core_data_cabinet_low", Vector3(.8, 0, 3.8))
	model(core, "core_light_trim", Vector3(3.4, 0, 3.8))
	MATERIAL_PROFILES.apply(core, 4)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("101b28")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c4def0")
	env.environment.ambient_light_energy = .5
	own(env, scene)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = .9
	light.shadow_enabled = true
	own(light, scene)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.8
	camera.position = Vector3(10, 17, 20)
	own(camera, scene)
	camera.look_at_from_position(camera.position, Vector3(-.5, 0, -.2))
	var packed := PackedScene.new()
	assert(packed.pack(scene) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/editor/modular_map_showcase.tscn") == OK)
	print("Saved four-chapter modular showcase")
	quit()
