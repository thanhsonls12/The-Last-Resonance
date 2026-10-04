extends Node

const MOTION = preload("res://src/view/module_motion.gd")
const CATALOG = preload("res://src/data/module_motion_catalog.gd")
const QUALITY = preload("res://src/data/render_quality.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func motions(node: Node, result: Array[Node]) -> void:
	for child in node.get_children():
		if child.name == "ModuleMotion":
			result.append(child)
		motions(child, result)


func count_class(node: Node, type: StringName) -> int:
	var count := 1 if node.is_class(type) else 0
	for child in node.get_children():
		count += count_class(child, type)
	return count


func _ready() -> void:
	var report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/MODULE_ANIMATIONS.json"))
	check(report.size() == 18, "all eighteen authored clips exist")
	for entry in report:
		var model := (load("res://" + str(entry.path)) as PackedScene).instantiate() as Node3D
		add_child(model)
		var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		check(player != null, str(entry.path) + " imports an AnimationPlayer")
		if player:
			var clip: StringName
			for candidate in player.get_animation_list():
				if candidate != &"RESET":
					clip = candidate
			check(not clip.is_empty(), str(entry.path) + " imported idle clip")
			if not clip.is_empty():
				player.play(clip)
				player.seek(0, true)
				var parts := model.find_children("Motion_*", "Node3D", true, false)
				var before := {}
				for part in parts:
					before[part] = (part as Node3D).transform
				var root_before := model.transform
				player.advance(.7)
				var changed := false
				for part in parts:
					if not (part as Node3D).transform.is_equal_approx(before[part]):
						changed = true
				check(changed, str(entry.path) + " geometry actually moves after advancing clip")
				check(model.transform.is_equal_approx(root_before), str(entry.path) + " module anchor stays fixed")
				check(count_class(model, &"CollisionObject3D") == 0, "animation adds no gameplay collision")
		model.free()

	var seen_types := {}
	var animated_instances := 0
	for index in range(15):
		var data: LevelData = Levels.get_data(index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var walls := logic.walls.duplicate()
		var floors := logic.floors.duplicate()
		var blocks := logic.blocks.duplicate()
		var board := BoardView.new()
		board.chapter = data.chapter
		board.power_level = data.power_level
		add_child(board)
		board.build(logic, data.decorations)
		check(board.decor_nodes.size() == data.decorations.size(), "all campaign scenery retained")
		for i in mini(board.decor_nodes.size(), data.decorations.size()):
			var model: Node3D = board.decor_nodes[i]
			var path := model.scene_file_path
			var expected := CATALOG.profile_for(path)
			var controller := model.get_node_or_null("ModuleMotion")
			seen_types[data.decorations[i].type] = expected
			check((controller != null) == (expected != &""), "dynamic scenery connected; structural scenery remains static")
			if controller:
				var anchor := model.transform
				controller._process(.5)
				check(model.transform.is_equal_approx(anchor), "effect does not move puzzle-cell anchor")
				if controller.animation_player:
					animated_instances += 1
		var controllers: Array[Node] = []
		motions(board, controllers)
		check(not controllers.is_empty(), "L%d receives live modules" % (index + 1))
		check(logic.walls == walls and logic.floors == floors and logic.blocks == blocks and logic.moves == 0, "presentation leaves puzzle state unchanged")
		check(count_class(board, &"CollisionObject3D") == 0, "campaign effects add no collision")
		if index == 13:
			for position in logic.energy_nodes:
				var controller: Node = board.energy_nodes[position].get_node("EnergyNodeModel/ModuleMotion")
				check(controller.signal_materials.size() > 0, "node lens shader is connected")
				if DisplayServer.get_name() != "headless":
					var lens := board.energy_nodes[position].find_child("NodeLens", true, false) as MeshInstance3D
					check(lens != null and lens.get_active_material(0) is ShaderMaterial, "rendered lens uses state shader")
				board.set_energy_progress(0)
				check(controller.signal_materials[0].get_shader_parameter("state") >= 0, "node follows floor progress")
			var hidden: Array[Node] = []
			motions(board.layer_roots[1], hidden)
			for controller in hidden:
				var clock: float = controller._clock
				controller._process(1)
				check(is_equal_approx(controller._clock, clock), "hidden floor freezes effect clock")
				check(not controller.trigger_burst(), "hidden floor cannot emit")
		board.free()
	check(seen_types.size() == 80, "all campaign scenery types including chapter surfaces reviewed")
	check(animated_instances > 0, "campaign uses Blender clips")
	check(MOTION._burst_owners.is_empty(), "changing boards cleans effect ownership")
	var plate := (load("res://assets/models/baked/Pressure-Plate.glb") as PackedScene).instantiate() as Node3D
	add_child(plate)
	var plate_motion := MOTION.attach(plate, plate.scene_file_path, null, 1)
	var compression := plate.find_child("Motion_PlateCompression", true, false) as Node3D
	check(compression != null, "plate imports compression rig")
	if compression:
		var rest := compression.transform
		plate_motion.set_pressed(true)
		plate_motion._process(.2)
		check(not compression.transform.is_equal_approx(rest), "occupied plate physically depresses")
		plate_motion.set_pressed(false)
		plate_motion._process(.2)
		check(compression.transform.is_equal_approx(rest), "release/Undo restores plate pose")
	plate.free()

	var hosts: Array[Node3D] = []
	var bursts: Array[Node] = []
	for i in range(4):
		var model := (load("res://assets/models/baked/Cable-Coil.glb") as PackedScene).instantiate() as Node3D
		model.position.x = i
		add_child(model)
		hosts.append(model)
		bursts.append(MOTION.attach(model, model.scene_file_path, null, 1))
	for i in range(4):
		check(bursts[i].trigger_burst() == (i < 3), "desktop simultaneous burst budget")
	hosts[0].hide()
	bursts[0]._process(.1)
	check(bursts[3].trigger_burst(), "hiding emitter releases slot")
	for host in hosts:
		host.free()
	check(MOTION._burst_owners.is_empty(), "freeing scene releases all burst slots")

	QUALITY.set_mobile_override(true)
	var mobile_hosts: Array[Node3D] = []
	for i in range(2):
		var model := (load("res://assets/models/baked/Cable-Coil.glb") as PackedScene).instantiate() as Node3D
		add_child(model)
		mobile_hosts.append(model)
		var controller := MOTION.attach(model, model.scene_file_path, null, 1)
		check(count_class(model, &"GPUParticles3D") == 0 and count_class(model, &"Light3D") == 0, "mobile spark uses lightweight meshes")
		check(controller.trigger_burst() == (i == 0), "mobile allows one ambient burst")
	for model in mobile_hosts:
		model.free()
	QUALITY.set_mobile_override(null)

	var pause_model := (load("res://assets/models/baked/Conveyor.glb") as PackedScene).instantiate() as Node3D
	add_child(pause_model)
	var pause_motion := MOTION.attach(pause_model, pause_model.scene_file_path, null, 2)
	await get_tree().process_frame
	var old_clock: float = pause_motion._clock
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await get_tree().process_frame
	await get_tree().process_frame
	check(is_equal_approx(pause_motion._clock, old_clock), "pause freezes module clock")
	get_tree().paused = false
	pause_model.free()
	print("Module motion checks: ", failures, " failures; ", seen_types.size(), " scenery types; ", animated_instances, " animated campaign instances")
	get_tree().quit(1 if failures else 0)
