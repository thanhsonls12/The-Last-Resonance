class_name BoardGameplayObjects
extends RefCounted

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
const MAP_EXPANSION = preload("res://src/data/map_expansion.gd")

const COLOR_GOAL := Color(0.12, 0.95, 1.0)
const COLOR_PLATE := Color(1.0, 0.78, 0.12)
const COLOR_DOOR := Color(0.95, 0.18, 0.18)
const COLOR_ELEVATOR := Color(0.15, 0.95, 0.75)
const COLOR_BLOCK_EDGE := Color(0.90, 0.45, 1.0)
const BAKED := "res://assets/models/baked/"
const PEDESTAL_PATH := BAKED + "Core-Pedestal.glb"
const ENERGY_CORE_PATH := BAKED + "Energy-Core.glb"
const PLATE_PATH := BAKED + "Pressure-Plate.glb"
const DOOR_PATH := BAKED + "Door.glb"
const BRIDGE_PATH := BAKED + "Bridge.glb"
const ELEVATOR_PATH := BAKED + "Elevator.glb"
const ENERGY_CABLE_PATH := "res://assets/models/gameplay/Interaction/Energy-Cable.glb"
const ENERGY_CABLE_SHADER_PATH := "res://assets/shaders/energy_cable_flow.gdshader"
const FRAGMENT_MODEL_PATH := "res://assets/models/gameplay/Core/Memory-Fragment.glb"
const FRAGMENT_SHADER_PATH := "res://assets/shaders/resonance_fragment.gdshader"
const FLOOR_TOP_Y := 0.154
const BLOCK_ROOT_HEIGHT := 0.45

var block_nodes: Dictionary = {}
var plate_nodes: Dictionary = {}
var plate_status_materials: Dictionary = {}
var plate_status_lights: Dictionary = {}
var plate_motion_nodes: Dictionary = {}
var door_nodes: Dictionary = {}
var door_status_lights: Dictionary = {}
var door_status_materials: Dictionary = {}
var lock_cable_materials: Dictionary = {}
var lock_cable_material: StandardMaterial3D
var lock_routes: Dictionary = {}
var portal_nodes: Dictionary = {}
var elevator_nodes: Dictionary = {}
var elevator_status_materials: Dictionary = {}
var bridge_nodes: Dictionary = {}
var bridge_rail_nodes: Dictionary = {}
var bridge_rail_tweens: Dictionary = {}
var energy_nodes: Dictionary = {}
var energy_cable_materials: Array[ShaderMaterial] = []
var fragment_node: Node3D

var _elevator_cabin: Node3D


func reset() -> void:
	block_nodes.clear()
	plate_nodes.clear()
	plate_status_materials.clear()
	plate_status_lights.clear()
	plate_motion_nodes.clear()
	door_nodes.clear()
	door_status_lights.clear()
	door_status_materials.clear()
	lock_cable_materials.clear()
	lock_routes.clear()
	lock_cable_material = null
	portal_nodes.clear()
	elevator_nodes.clear()
	elevator_status_materials.clear()
	bridge_nodes.clear()
	for tween in bridge_rail_tweens.values():
		if tween and tween.is_valid():
			tween.kill()
	bridge_rail_nodes.clear()
	bridge_rail_tweens.clear()
	energy_nodes.clear()
	energy_cable_materials.clear()
	fragment_node = null
	if is_instance_valid(_elevator_cabin):
		_elevator_cabin.queue_free()
	_elevator_cabin = null


func build(
		root: Node3D,
		logic: GameLogic,
		chapter: int,
		materials: Dictionary,
		colors: Dictionary,
		spawn: Callable,
		world_position: Callable,
		floor_surface_y: Callable,
		layer_parent: Callable) -> void:
	if root == null or logic == null:
		return
	for position in logic.slots.keys():
		var slot_root := Node3D.new()
		slot_root.position = world_position.call(position) + Vector3(0, 0.07, 0)
		var parent := layer_parent.call(position) as Node3D
		parent.add_child(slot_root)
		var pedestal: Node3D = spawn.call(parent, PEDESTAL_PATH, world_position.call(position), floor_surface_y.call(position), 1.0, false)
		if pedestal == null:
			MeshFactory.cylinder(slot_root, Vector3.ZERO, 0.30, 0.025, materials["slot"])
		MeshFactory.torus(slot_root, Vector3(0, 0.035, 0), 0.26, 0.36, materials["slot_ring"])
		if RENDER_QUALITY.local_lights_enabled():
			var slot_light := OmniLight3D.new()
			slot_light.light_color = colors["goal"]
			slot_light.light_energy = 0.55
			slot_light.omni_range = 1.35
			slot_light.omni_attenuation = 1.6
			slot_light.position = Vector3(0, 0.2, 0)
			slot_root.add_child(slot_light)

	for position in logic.plates.keys():
		var plate_root := Node3D.new()
		plate_root.position = world_position.call(position) + Vector3(0, 0.07, 0)
		var parent := layer_parent.call(position) as Node3D
		parent.add_child(plate_root)
		plate_nodes[position] = plate_root
		var plate: Node3D = spawn.call(parent, PLATE_PATH, world_position.call(position), floor_surface_y.call(position), 1.0, false)
		if plate:
			plate_motion_nodes[position] = plate.get_node_or_null("ModuleMotion")
		else:
			MeshFactory.cylinder(plate_root, Vector3.ZERO, 0.34, 0.035, materials["plate"])
		var status_material := (materials["plate_ring"] as StandardMaterial3D).duplicate() as StandardMaterial3D
		MeshFactory.torus(plate_root, Vector3(0, 0.045, 0), 0.25, 0.34, status_material)
		plate_status_materials[position] = status_material
		if RENDER_QUALITY.local_lights_enabled():
			var plate_light := OmniLight3D.new()
			plate_light.light_color = colors["plate"]
			plate_light.light_energy = 0.45
			plate_light.omni_range = 1.35
			plate_light.position = Vector3(0, 0.16, 0)
			plate_root.add_child(plate_light)
			plate_status_lights[position] = plate_light

	for position in logic.portals.keys():
		var portal_root := Node3D.new()
		portal_root.position = world_position.call(position) + Vector3(0, 0.075, 0)
		(layer_parent.call(position) as Node3D).add_child(portal_root)
		MeshFactory.cylinder(portal_root, Vector3.ZERO, 0.31, 0.025, materials["portal"])
		MeshFactory.torus(portal_root, Vector3(0, 0.035, 0), 0.23, 0.31, materials["portal_ring"])
		portal_nodes[position] = portal_root

	for position in logic.elevators.keys():
		var elevator_root := Node3D.new()
		elevator_root.position = world_position.call(position) + Vector3(0, 0.075, 0)
		elevator_root.rotation_degrees.y = _get_elevator_yaw(logic, position)
		(layer_parent.call(position) as Node3D).add_child(elevator_root)
		var status_material := (materials["elevator_ring"] as StandardMaterial3D).duplicate() as StandardMaterial3D
		_add_elevator_model(elevator_root, -.095, status_material)
		MeshFactory.torus(elevator_root, Vector3(0, 0.06, 0), 0.25, 0.34, status_material)
		elevator_nodes[position] = elevator_root
		elevator_status_materials[position] = status_material

	for position in logic.bridges.keys():
		var bridge_root := Node3D.new()
		bridge_root.position = world_position.call(position) + Vector3(0, 0.08, 0)
		(layer_parent.call(position) as Node3D).add_child(bridge_root)
		var bridge_model: Node3D = spawn.call(bridge_root, BRIDGE_PATH, Vector3.ZERO, -.18, 1.0, false, false)
		bridge_model.name = "BridgeModel"
		bridge_model.rotation_degrees.y = 90
		var rail_root := Node3D.new()
		rail_root.name = "Rails"
		bridge_root.add_child(rail_root)
		for part in bridge_model.find_children("Bridge_Rail*", "MeshInstance3D", true, false):
			part.reparent(rail_root, true)
			if String(part.name).contains("Glow"):
				(part as MeshInstance3D).material_override = materials["bridge_ring"]
		bridge_nodes[position] = bridge_root
		bridge_rail_nodes[position] = rail_root

	for position in logic.energy_nodes:
		var energy_root := Node3D.new()
		energy_root.position = Vector3(position.x, float(floor_surface_y.call(position)), position.z)
		(layer_parent.call(position) as Node3D).add_child(energy_root)
		var housing: Node3D = spawn.call(energy_root, MAP_EXPANSION.ENERGY_NODE_PATH, Vector3.ZERO, 0.0, 1.0, false, false)
		if housing:
			housing.name = "EnergyNodeModel"
			var lens := housing.find_child("NodeLens", true, false) as MeshInstance3D
			if lens:
				lens.material_override = materials["energy"]
		MeshFactory.torus(energy_root, Vector3(0, 0.102, 0), 0.21, 0.30, materials["energy_ring"])
		energy_nodes[position] = energy_root
		if chapter == 4:
			var number := Label3D.new()
			number.name = "NodeNumber"
			number.text = str(logic.energy_nodes.find(position) + 1)
			number.font_size = 64
			number.pixel_size = 0.008
			number.position.y = 0.48
			number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			energy_root.add_child(number)
	_build_energy_cables(logic, spawn, world_position, layer_parent)

	for position in logic.doors.keys():
		var door_edge := (materials["door_edge"] as StandardMaterial3D).duplicate() as StandardMaterial3D
		door_status_materials[position] = door_edge
		var door_yaw := _get_door_yaw(logic, position)
		var door_root := _build_door(
			layer_parent.call(position) as Node3D,
			door_position(position, logic.door_open(position), world_position),
			materials["door"],
			door_edge,
			spawn,
			door_position(position, false, world_position),
			door_yaw)
		door_nodes[position] = door_root
		if RENDER_QUALITY.local_lights_enabled():
			var status_light := OmniLight3D.new()
			status_light.light_color = colors["door_edge"]
			status_light.light_energy = 0.55
			status_light.omni_range = 1.35
			status_light.omni_attenuation = 1.6
			status_light.position = Vector3(0, 0.35, 0)
			door_root.add_child(status_light)
			door_status_lights[position] = status_light
	build_lock_cables(root, logic, layer_parent, world_position)

	for position in logic.blocks.keys():
		block_nodes[position] = _build_block(
			layer_parent.call(position) as Node3D,
			world_position.call(position) + Vector3(0, BLOCK_ROOT_HEIGHT, 0),
			materials["block"],
			materials["block_edge"],
			spawn,
			world_position)


func door_position(cell: Vector3i, open: bool, world_position: Callable) -> Vector3:
	return world_position.call(cell) + Vector3(0, -0.58 if open else 0.58, 0)


func place_memory_fragment(
		cell: Vector3i,
		spawn: Callable,
		world_position: Callable,
		layer_parent: Callable) -> void:
	if fragment_node != null and is_instance_valid(fragment_node):
		fragment_node.queue_free()
	var position: Vector3 = world_position.call(cell) + Vector3(0, 0.42, 0)
	fragment_node = spawn.call(layer_parent.call(cell), FRAGMENT_MODEL_PATH, position, position.y, 1.15, false, false)
	if fragment_node == null:
		return
	var shader := load(FRAGMENT_SHADER_PATH) as Shader
	if shader:
		var material := ShaderMaterial.new()
		material.shader = shader
		_apply_material(fragment_node, material)


func collect_memory_fragment() -> Vector3:
	if fragment_node == null or not is_instance_valid(fragment_node):
		return Vector3.ZERO
	var position := fragment_node.global_position
	fragment_node.queue_free()
	fragment_node = null
	return position


func _build_block(
		parent: Node3D,
		position: Vector3,
		base_material: Material,
		accent_material: Material,
		spawn: Callable,
		world_position: Callable) -> Node3D:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	var model_local_y := FLOOR_TOP_Y - float((world_position.call(Vector3i.ZERO) as Vector3).y) - BLOCK_ROOT_HEIGHT
	var core: Node3D = spawn.call(root, ENERGY_CORE_PATH, Vector3.ZERO, model_local_y, 1.0, false)
	if core != null:
		core.name = "EnergyCoreModel"
	else:
		MeshFactory.box(root, Vector3.ZERO, Vector3(0.80, 0.80, 0.80), base_material)
		MeshFactory.box(root, Vector3(0, 0.415, 0), Vector3(0.56, 0.035, 0.56), accent_material)
		MeshFactory.box(root, Vector3(0, -0.415, 0), Vector3(0.56, 0.035, 0.56), accent_material)
		MeshFactory.box(root, Vector3(0, 0, -0.405), Vector3(0.60, 0.035, 0.025), accent_material)
		MeshFactory.box(root, Vector3(0, 0, 0.405), Vector3(0.60, 0.035, 0.025), accent_material)
	MeshFactory.torus(root, Vector3(0, -0.405, 0), 0.34, 0.43, accent_material)
	if RENDER_QUALITY.local_lights_enabled():
		var core_light := OmniLight3D.new()
		core_light.light_color = COLOR_BLOCK_EDGE
		core_light.light_energy = 0.45
		core_light.omni_range = 1.15
		core_light.omni_attenuation = 1.6
		core_light.position = Vector3(0, 0.1, 0)
		root.add_child(core_light)
	return root


func _build_door(parent: Node3D, position: Vector3, base_material: Material, accent_material: Material, spawn: Callable, closed_position: Vector3, yaw: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = position
	root.rotation_degrees.y = yaw
	parent.add_child(root)
	var model: Node3D = spawn.call(root, DOOR_PATH, Vector3.ZERO, -.575, 1.0, false, false)
	model.name = "DoorModel"
	var frame := Node3D.new()
	frame.name = "DoorFrame"
	frame.position = closed_position + Vector3(0, -.575, 0)
	frame.rotation_degrees.y = yaw
	frame.scale = Vector3.ONE * .5
	parent.add_child(frame)
	for part in model.find_children("Door_*", "MeshInstance3D", true, false):
		var part_name := String(part.name)
		if part_name.contains("StonePillar") or part_name.contains("MetalInset") or part_name.contains("Top"):
			part.reparent(frame, false)
		if part_name.contains("Glow") or part_name.contains("PanelLine") or part_name.contains("LockCore"):
			(part as MeshInstance3D).material_override = accent_material
	return root


func _add_elevator_model(parent: Node3D, offset_y: float, status_material: Material) -> Node3D:
	var model := (load(ELEVATOR_PATH) as PackedScene).instantiate() as Node3D
	model.name = "ElevatorModel"
	model.scale = Vector3.ONE * .5
	model.position.y = offset_y
	parent.add_child(model)
	for part in model.find_children("Elevator_*", "MeshInstance3D", true, false):
		if String(part.name).contains("Glow") or String(part.name).contains("Arrow"):
			(part as MeshInstance3D).material_override = status_material
	return model


func _build_energy_cables(
		logic: GameLogic,
		spawn: Callable,
		world_position: Callable,
		layer_parent: Callable) -> void:
	if logic.energy_nodes.size() < 2:
		return
	var shader := load(ENERGY_CABLE_SHADER_PATH) as Shader
	var by_floor := {}
	for cell in logic.energy_nodes:
		if not by_floor.has(cell.y):
			by_floor[cell.y] = []
		by_floor[cell.y].append(cell)
	for floor in by_floor.keys():
		var floor_nodes: Array = by_floor[floor]
		for index in range(floor_nodes.size() - 1):
			var start_cell: Vector3i = floor_nodes[index]
			var end_cell: Vector3i = floor_nodes[index + 1]
			var start: Vector3 = world_position.call(start_cell) + Vector3(0, 0.18, 0)
			var finish: Vector3 = world_position.call(end_cell) + Vector3(0, 0.18, 0)
			var midpoint := (start + finish) * 0.5
			var cable: Node3D = spawn.call(layer_parent.call(start_cell), ENERGY_CABLE_PATH, midpoint, midpoint.y, 0.85, false, false)
			if cable == null:
				continue
			var delta := finish - start
			if delta.length_squared() > 0.001:
				cable.look_at(finish, Vector3.UP)
				var span := maxf(delta.length() / 2.0, 0.35)
				cable.scale = Vector3(0.35, 0.35, 0.5 * span)
			if shader:
				var material := ShaderMaterial.new()
				material.shader = shader
				material.set_shader_parameter("is_active", false)
				material.set_shader_parameter("activity_progress", 0.0)
				_apply_material(cable, material)
				energy_cable_materials.append(material)


func _apply_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material(child, material)


func set_elevator_state(logic: GameLogic, visible_floor: int, animated := false) -> void:
	if logic == null:
		return
	for raw_position in elevator_nodes.keys():
		var position: Vector3i = raw_position
		var unlocked: bool = logic.elevator_is_unlocked(position)
		var material := elevator_status_materials.get(position) as StandardMaterial3D
		var active: bool = not logic.sequential_floors or position.y == visible_floor
		var color := COLOR_ELEVATOR if unlocked else COLOR_DOOR
		if material != null:
			material.albedo_color = color
			material.emission = color
			material.emission_enabled = true
			material.emission_energy_multiplier = 1.9 if unlocked else 0.85
		var root := elevator_nodes[position] as Node3D
		if animated and root != null and active:
			var pulse := root.create_tween()
			pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			pulse.tween_property(root, "scale", Vector3.ONE * 1.10, 0.16)
			pulse.tween_property(root, "scale", Vector3.ONE, 0.26)


func play_elevator_ride(
		root: Node3D,
		entry: Vector3i,
		destination: Vector3i,
		duration: float,
		world_position: Callable) -> void:
	if root == null or not world_position.is_valid():
		return
	if is_instance_valid(_elevator_cabin):
		_elevator_cabin.queue_free()
	_elevator_cabin = Node3D.new()
	_elevator_cabin.name = "ElevatorCabin"
	_elevator_cabin.position = world_position.call(entry) + Vector3(0, 0.04, 0)
	if elevator_nodes.has(entry):
		_elevator_cabin.rotation_degrees.y = (elevator_nodes[entry] as Node3D).rotation_degrees.y
	root.add_child(_elevator_cabin)
	var cabin_material := MeshFactory.transparent_mat(Color(COLOR_ELEVATOR.r, COLOR_ELEVATOR.g, COLOR_ELEVATOR.b, 0.20), 1.8)
	_add_elevator_model(_elevator_cabin, -.06, cabin_material)
	MeshFactory.torus(_elevator_cabin, Vector3(0, 0.03, 0), 0.32, 0.42, cabin_material)
	MeshFactory.torus(_elevator_cabin, Vector3(0, 0.82, 0), 0.32, 0.42, cabin_material)
	for raw_root in [elevator_nodes.get(entry), elevator_nodes.get(destination)]:
		var elevator_root := raw_root as Node3D
		if elevator_root == null:
			continue
		elevator_root.get_node("ElevatorModel").hide()
		var tween := elevator_root.create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(elevator_root, "scale", Vector3.ONE * 1.16, duration * 0.24)
		tween.tween_property(elevator_root, "scale", Vector3.ONE, duration * 0.36)
	var cabin_tween := _elevator_cabin.create_tween()
	cabin_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	cabin_tween.tween_interval(duration * 0.32)
	cabin_tween.tween_property(_elevator_cabin, "position", world_position.call(destination) + Vector3(0, 0.04, 0), duration * 0.68)
	cabin_tween.tween_callback(func() -> void:
		for station in [elevator_nodes.get(entry), elevator_nodes.get(destination)]:
			if is_instance_valid(station):
				station.get_node("ElevatorModel").show()
		if is_instance_valid(_elevator_cabin):
			_elevator_cabin.queue_free())


func build_lock_cables(root: Node3D, logic: GameLogic, layer_parent: Callable, world_position: Callable) -> void:
	if logic == null or logic.plates.is_empty() or logic.doors.is_empty() or lock_cable_material == null:
		return
	for door in logic.doors.keys():
		var group: String = logic.doors[door]
		if not lock_cable_materials.has(group):
			lock_cable_materials[group] = lock_cable_material.duplicate() as StandardMaterial3D
	for group in lock_cable_materials.keys():
		var group_doors := logic.doors_in_group(group)
		var group_plates := logic.plates_in_group(group)
		if group_doors.is_empty() or group_plates.is_empty():
			continue
		var material: StandardMaterial3D = lock_cable_materials[group]
		var door_sum := Vector3i.ZERO
		for door_position in group_doors:
			door_sum += door_position
		var hub := Vector3i(
			roundi(float(door_sum.x) / float(group_doors.size())),
			roundi(float(door_sum.y) / float(group_doors.size())),
			roundi(float(door_sum.z) / float(group_doors.size())))
		var plate_paths := {}
		for plate_position in group_plates:
			plate_paths[plate_position] = _build_lock_trace(root, plate_position, hub, material, layer_parent, world_position)
			lock_routes[plate_position] = []
		for door_position in group_doors:
			var door_path := _build_lock_trace(root, hub, door_position, material, layer_parent, world_position)
			for plate_position in group_plates:
				var route: Array[Vector3] = plate_paths[plate_position].duplicate()
				route.append_array(door_path.slice(1))
				lock_routes[plate_position].append(route)


func set_lock_state(logic: GameLogic, visible_floor: int) -> void:
	set_elevator_state(logic, visible_floor)
	if logic == null or logic.plates.is_empty():
		return
	for plate_position in logic.plates.keys():
		var active := logic.blocks.has(plate_position)
		var motion: Node = plate_motion_nodes.get(plate_position)
		if motion:
			motion.set_pressed(active)
		var hold_required := bool(logic.plate_hold_required.get(plate_position, true))
		var plate_color := COLOR_GOAL if active else (COLOR_PLATE if hold_required else Color(1.0, 0.50, 0.12))
		_set_status_material(
			plate_status_materials.get(plate_position) as StandardMaterial3D,
			plate_color,
			3.2 if active else (1.7 if hold_required else 2.2))
		var plate_light := plate_status_lights.get(plate_position) as OmniLight3D
		if plate_light:
			plate_light.light_color = plate_color
			plate_light.light_energy = 0.70 if active else (0.30 if hold_required else 0.45)
	for door_position in logic.doors.keys():
		var group: String = logic.doors[door_position]
		var open := logic.door_open(door_position)
		var group_active := _active_plates_in_group(logic, group)
		var status_color := COLOR_GOAL if open else (COLOR_PLATE if group_active > 0 else COLOR_DOOR)
		_set_status_material(door_status_materials.get(door_position) as StandardMaterial3D, status_color, 3.2 if open else 2.0)
		_set_status_material(
			lock_cable_materials.get(group) as StandardMaterial3D,
			status_color,
			2.6 if open else (1.4 if group_active > 0 else 0.55))
		var light := door_status_lights.get(door_position) as OmniLight3D
		if light:
			light.light_color = status_color
			light.light_energy = 0.85 if open else (0.65 if group_active > 0 else 0.45)


func set_bridge_rails_retracted(
		root: Node3D,
		cell: Vector3i,
		direction: Vector3i,
		retracted: bool,
		animated := true,
		reduced_motion := false) -> void:
	if not bridge_rail_nodes.has(cell):
		return
	var rail: Node3D = bridge_rail_nodes[cell]
	if bridge_rail_tweens.has(cell):
		var old_tween := bridge_rail_tweens[cell] as Tween
		if old_tween and old_tween.is_valid():
			old_tween.kill()
		bridge_rail_tweens.erase(cell)
	var target_y := -0.20 if retracted else 0.0
	var target_rotation_y := 90.0 if abs(direction.x) > abs(direction.z) else 0.0
	if not animated or reduced_motion or root == null:
		rail.position.y = target_y
		rail.rotation_degrees.y = target_rotation_y
		return
	var tween := root.create_tween().set_parallel(true)
	bridge_rail_tweens[cell] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rail, "position:y", target_y, 0.15)
	tween.tween_property(rail, "rotation_degrees:y", target_rotation_y, 0.15)
	tween.finished.connect(func() -> void:
		if bridge_rail_tweens.get(cell) == tween:
			bridge_rail_tweens.erase(cell))


func reset_bridge_rails(root: Node3D, animated := false, reduced_motion := false) -> void:
	for cell in bridge_rail_nodes.keys():
		set_bridge_rails_retracted(root, cell, Vector3i(0, 0, 1), false, animated, reduced_motion)


func set_bridges_open(root: Node3D, open: bool, animated := false, reduced_motion := false) -> void:
	reset_bridge_rails(root, false, reduced_motion)
	for bridge_node in bridge_nodes.values():
		bridge_node.visible = true
		var target_rotation := Vector3.ZERO if open else Vector3(-82.0, 0.0, 0.0)
		var target_scale := Vector3.ONE if open else Vector3(1.0, 0.86, 1.0)
		if not animated or reduced_motion or root == null:
			bridge_node.rotation_degrees = target_rotation
			bridge_node.scale = target_scale
			continue
		var tween := root.create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(bridge_node, "rotation_degrees", target_rotation, 0.48)
		tween.tween_property(bridge_node, "scale", target_scale, 0.48)


func set_energy_progress(logic: GameLogic, progress: int) -> void:
	for position in energy_nodes.keys():
		var energy_node: Node3D = energy_nodes[position]
		var floor_progress := progress
		var node_index := logic.energy_nodes.find(position) if logic != null else 0
		if logic != null and logic.sequential_floors:
			floor_progress = logic.energy_progress_for_floor(position.y)
			node_index = logic.energy_nodes_on_floor(position.y).find(position)
		energy_node.scale = Vector3.ONE if node_index < floor_progress else Vector3.ONE * 0.78
		var motion := energy_node.get_node_or_null("EnergyNodeModel/ModuleMotion")
		if motion:
			motion.set_state(2 if node_index < floor_progress else (1 if node_index == floor_progress else 0))
		var number := energy_node.get_node_or_null("NodeNumber") as Label3D
		if number:
			number.modulate = Color(0.25, 1.0, 0.65) if node_index < floor_progress else (Color(1.0, 0.82, 0.25) if node_index == floor_progress else Color(0.42, 0.50, 0.60))
	var total := energy_nodes.size()
	var ratio := 0.0 if total <= 0 else clampf(float(progress) / float(total), 0.0, 1.0)
	for material in energy_cable_materials:
		if material:
			material.set_shader_parameter("is_active", progress > 0)
			material.set_shader_parameter("activity_progress", ratio)


func _build_lock_trace(
		root: Node3D,
		from: Vector3i,
		to: Vector3i,
		material: StandardMaterial3D,
		layer_parent: Callable,
		world_position: Callable) -> Array[Vector3]:
	var parent: Node3D = layer_parent.call(from) as Node3D if from.y == to.y else root
	if parent == null:
		return []
	var start: Vector3 = world_position.call(from) + Vector3(0, 0.145, 0)
	var finish: Vector3 = world_position.call(to) + Vector3(0, 0.145, 0)
	var corner := Vector3(finish.x, start.y, start.z)
	if not is_equal_approx(start.x, corner.x):
		MeshFactory.box(parent, (start + corner) * 0.5, Vector3(absf(corner.x - start.x) + 0.08, 0.025, 0.075), material)
	if not is_equal_approx(corner.z, finish.z):
		MeshFactory.box(parent, (corner + finish) * 0.5, Vector3(0.075, 0.025, absf(finish.z - corner.z) + 0.08), material)
	MeshFactory.sphere(parent, world_position.call(to) + Vector3(0, 0.16, 0), 0.055, material)
	return [start, corner, finish]


func _active_plates_in_group(logic: GameLogic, group: String) -> int:
	var active := 0
	for plate_position in logic.plates_in_group(group):
		if logic.blocks.has(plate_position):
			active += 1
	return active


func _set_status_material(material: StandardMaterial3D, color: Color, energy: float) -> void:
	if material == null:
		return
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy * .72


func _get_elevator_yaw(logic: GameLogic, pos: Vector3i) -> float:
	var orthogonal_dirs: Array[Vector3i] = [
		Vector3i(-1, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(0, 0, -1),
		Vector3i(0, 0, 1),
	]
	var open_dirs: Array[Vector3i] = []
	for dir in orthogonal_dirs:
		var neighbor: Vector3i = pos + dir
		if logic.floors.has(neighbor) and not logic.walls.has(neighbor):
			open_dirs.append(dir)
	if open_dirs.is_empty():
		return 0.0

	var targets: Array[Vector3i] = []
	for slot in logic.slots.keys():
		if slot.y == pos.y:
			targets.append(slot)
	for plate in logic.plates.keys():
		if plate.y == pos.y:
			targets.append(plate)
	for block in logic.blocks.keys():
		if block.y == pos.y:
			targets.append(block)

	var target_center := Vector2.ZERO
	if not targets.is_empty():
		for t in targets:
			target_center += Vector2(t.x, t.z)
		target_center /= float(targets.size())
	else:
		var floor_cells: Array[Vector3i] = []
		for cell in logic.cells_on_floor(pos.y).keys():
			floor_cells.append(cell)
		if not floor_cells.is_empty():
			for cell in floor_cells:
				target_center += Vector2(cell.x, cell.z)
			target_center /= float(floor_cells.size())
		else:
			target_center = Vector2(pos.x, pos.z)

	var to_target := (target_center - Vector2(pos.x, pos.z)).normalized()

	var best_dir: Vector3i = open_dirs[0]
	var best_score: float = -999.0
	for dir in open_dirs:
		var dir_2d := Vector2(dir.x, dir.z).normalized()
		var score := dir_2d.dot(to_target)
		if score > best_score:
			best_score = score
			best_dir = dir

	return rad_to_deg(atan2(-float(best_dir.x), -float(best_dir.z)))


func _get_door_yaw(logic: GameLogic, pos: Vector3i) -> float:
	var north_wall := logic.walls.has(pos + Vector3i(0, 0, -1))
	var south_wall := logic.walls.has(pos + Vector3i(0, 0, 1))
	if north_wall or south_wall:
		return 90.0
	return 0.0
