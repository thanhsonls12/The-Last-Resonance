class_name EnvironmentDynamics
extends RefCounted

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
const WATER_SHADER_PATH := "res://assets/shaders/ice_water_sanctuary.gdshader"

const COLOR_ARCHIVE_CYAN := Color(0.10, 0.82, 1.0)
const COLOR_FOUNDRY_ORANGE := Color(1.0, 0.32, 0.055)
const COLOR_CORE_CYAN := Color(0.72, 0.94, 1.0)
const COLOR_CORE_TEAL := Color(0.30, 0.78, 0.88)

var profiles: Array[StringName] = []
var nodes: Array[Dictionary] = []
var materials: Array[Dictionary] = []
var water_materials: Array[ShaderMaterial] = []
var elapsed_time := 0.0


func reset() -> void:
	profiles.clear()
	nodes.clear()
	materials.clear()
	water_materials.clear()
	elapsed_time = 0.0


func register(
		node: Node3D,
		deco: Dictionary,
		center: Vector3,
		yaw: float,
		cell: Vector3i,
		layer_parent: Node3D) -> void:
	var profile := StringName(str(deco.get("dynamic_profile", "")))
	if profile == &"":
		return
	profiles.append(profile)
	var phase := float(deco.get("dynamic_phase", _phase(cell)))
	match profile:
		&"archive_terminal":
			var speed := float(deco.get("dynamic_speed", 4.2))
			var amplitude := float(deco.get("dynamic_amplitude", 0.62))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_indicator(
				layer_parent, center, yaw,
				Vector3(0, 0.44, -0.30), Vector3(0.34, 0.025, 0.018),
				COLOR_ARCHIVE_CYAN, 0.72 * intensity, profile, phase, speed, amplitude, &"flicker")
		&"archive_panel":
			var speed := float(deco.get("dynamic_speed", 2.4))
			var amplitude := float(deco.get("dynamic_amplitude", 0.48))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_indicator(
				layer_parent, center, yaw,
				Vector3(0, 0.25, -0.17), Vector3(0.24, 0.020, 0.016),
				COLOR_ARCHIVE_CYAN, 0.44 * intensity, profile, phase, speed, amplitude, &"flicker")
		&"foundry_conveyor":
			nodes.append({
				"node": node,
				"base_position": node.position,
				"base_rotation": node.rotation,
				"mode": &"vibrate",
				"axis": Vector3(1, 0, 0),
				"amplitude": float(deco.get("dynamic_amplitude", 0.007)),
				"speed": float(deco.get("dynamic_speed", 7.2)),
				"phase": phase,
			})
		&"foundry_furnace", &"foundry_machine_heat":
			var speed := float(deco.get("dynamic_speed", 1.75))
			var amplitude := float(deco.get("dynamic_amplitude", 0.72))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_indicator(
				layer_parent, center, yaw,
				Vector3(0, 0.43, -0.35), Vector3(0.34, 0.050, 0.020),
				COLOR_FOUNDRY_ORANGE, 0.82 * intensity, profile, phase, speed, amplitude)
			_make_indicator(
				layer_parent, center, yaw,
				Vector3(0, 0.66, -0.30), Vector3(0.22, 0.030, 0.018),
				Color(1.0, 0.58, 0.12), 0.55 * intensity, profile, phase + 0.65, speed, amplitude * 0.81)
		&"sanctuary_sway":
			nodes.append({
				"node": node,
				"base_position": node.position,
				"base_rotation": node.rotation,
				"mode": &"sway",
				"axis": Vector3(0.55, 0.0, 1.0).normalized(),
				"amplitude": deg_to_rad(float(deco.get("dynamic_amplitude", 1.35))),
				"speed": float(deco.get("dynamic_speed", 0.72)),
				"phase": phase,
			})
		&"sanctuary_water":
			_configure_water(node, deco)
		&"core_cabinet_pulse":
			var speed := float(deco.get("dynamic_speed", 1.18))
			var amplitude := float(deco.get("dynamic_amplitude", 0.52))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_indicator(
				layer_parent, center, yaw,
				Vector3(0, 0.31, -0.265), Vector3(0.46, 0.018, 0.014),
				COLOR_CORE_TEAL, 0.48 * intensity, profile, phase, speed, amplitude)
		&"core_trim_pulse":
			var speed := float(deco.get("dynamic_speed", 1.18))
			var amplitude := float(deco.get("dynamic_amplitude", 0.68))
			var intensity := float(deco.get("dynamic_intensity", 1.0))
			_make_indicator(
				layer_parent, center, yaw,
				Vector3(0, 0.15, -0.12), Vector3(0.62, 0.018, 0.014),
				COLOR_CORE_CYAN, 0.62 * intensity, profile, phase, speed, amplitude)


func process(delta: float) -> void:
	elapsed_time += delta
	update()


func update() -> void:
	var motion_scale := RENDER_QUALITY.environment_motion_scale()
	for info in nodes:
		var node: Node3D = info["node"]
		if not is_instance_valid(node):
			continue
		var phase := float(info["phase"])
		var speed := float(info["speed"])
		var amount := sin(elapsed_time * speed + phase) * float(info["amplitude"]) * motion_scale
		var base_position: Vector3 = info["base_position"]
		var base_rotation: Vector3 = info["base_rotation"]
		var axis: Vector3 = info["axis"]
		match StringName(info["mode"]):
			&"vibrate":
				node.position = base_position + axis * amount
				node.rotation = base_rotation
			&"sway":
				node.position = base_position
				node.rotation = base_rotation + axis * amount
	for info in materials:
		var material: StandardMaterial3D = info["material"]
		if not is_instance_valid(material):
			continue
		var phase := float(info["phase"])
		var speed := float(info["speed"])
		var wave := 0.5 + 0.5 * sin(elapsed_time * speed + phase)
		if StringName(info["mode"]) == &"flicker":
			var drop := 0.18 if fmod(elapsed_time + phase, 3.15) < 0.07 else 1.0
			wave = clampf((0.34 + wave * 0.66) * drop, 0.08, 1.0)
		var emission_scale := RENDER_QUALITY.environment_emission_scale()
		material.emission_energy_multiplier = float(info["base"]) \
			* (1.0 + wave * float(info["amplitude"])) * emission_scale


func _phase(cell: Vector3i) -> float:
	return fmod(float(cell.x * 17 + cell.y * 29 + cell.z * 41), 31.0) * 0.37


func _make_indicator(
		parent: Node3D,
		center: Vector3,
		yaw: float,
		local_position: Vector3,
		size: Vector3,
		color: Color,
		base_emission: float,
		profile: StringName,
		phase: float,
		speed: float,
		amplitude: float,
		mode: StringName = &"pulse") -> void:
	if parent == null:
		return
	var root := Node3D.new()
	root.name = "EnvironmentDynamic_%s" % str(profile)
	root.position = center
	root.rotation_degrees.y = yaw
	parent.add_child(root)
	var material := MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.72), base_emission)
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var strip := MeshFactory.box(root, local_position, size, material)
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	materials.append({
		"material": material,
		"profile": profile,
		"base": base_emission,
		"phase": phase,
		"speed": speed,
		"amplitude": amplitude,
		"mode": mode,
	})


func _configure_water(node: Node, deco: Dictionary) -> void:
	var speed := float(deco.get("dynamic_speed", 0.58))
	var amplitude := float(deco.get("dynamic_amplitude", 0.012))
	if RENDER_QUALITY.is_mobile():
		amplitude *= 0.72
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				var active := mesh_instance.get_active_material(surface)
				if active is ShaderMaterial and (active as ShaderMaterial).shader == load(WATER_SHADER_PATH):
					var material := active as ShaderMaterial
					material.set_shader_parameter("wave_speed", speed)
					material.set_shader_parameter("wave_amplitude", amplitude)
					if not water_materials.has(material):
						water_materials.append(material)
	for child in node.get_children():
		_configure_water(child, deco)
