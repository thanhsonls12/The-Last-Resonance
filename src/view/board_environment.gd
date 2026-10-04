class_name BoardEnvironment
extends RefCounted

## Builds presentation-only sector architecture around the puzzle board.
## This component owns the shell/background geometry and atmospheric accents;
## it does not inspect or mutate puzzle state beyond reading floor bounds.

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")

const COLOR_ARCHIVE_STEEL := Color(0.035, 0.055, 0.085)
const COLOR_ARCHIVE_PANEL := Color(0.055, 0.085, 0.13)
const COLOR_ARCHIVE_CYAN := Color(0.10, 0.82, 1.0)
const COLOR_ARCHIVE_AMBER := Color(1.0, 0.30, 0.08)
const COLOR_FOUNDRY_STEEL := Color(0.075, 0.045, 0.032)
const COLOR_FOUNDRY_PANEL := Color(0.15, 0.07, 0.025)
const COLOR_CORE_STEEL := Color(0.018, 0.028, 0.050)
const COLOR_CORE_PANEL := Color(0.035, 0.075, 0.120)
const COLOR_CORE_RECESS := Color(0.006, 0.014, 0.026)
const COLOR_CORE_CYAN := Color(0.72, 0.94, 1.0)
const COLOR_CORE_AMBER := Color(1.0, 0.64, 0.22)

var _root: Node3D
var _lighting: RefCounted
var _chapter := 1


func build(
		root: Node3D,
		logic: GameLogic,
		bounds: Dictionary,
		chapter: int,
		lighting: RefCounted) -> void:
	if root == null or logic == null or logic.floors.is_empty() or bounds.is_empty():
		return
	_root = root
	_lighting = lighting
	_chapter = chapter

	var min_x: float = bounds["min_x"]
	var max_x: float = bounds["max_x"]
	var min_z: float = bounds["min_z"]
	var max_z: float = bounds["max_z"]
	var center := Vector3((min_x + max_x) * 0.5, 0.0, (min_z + max_z) * 0.5)
	var width := max_x - min_x + 1.0
	var depth := max_z - min_z + 1.0
	var sanctuary_theme := chapter == 3
	var central_core_theme := chapter == 4
	var steel_color := COLOR_ARCHIVE_STEEL
	var panel_color := COLOR_ARCHIVE_PANEL
	var recess_color := Color(0.012, 0.018, 0.035)
	if chapter == 2:
		steel_color = COLOR_FOUNDRY_STEEL
		panel_color = COLOR_FOUNDRY_PANEL
		recess_color = Color(0.025, 0.008, 0.003)
	elif sanctuary_theme:
		steel_color = Color(0.018, 0.09, 0.11)
		panel_color = Color(0.025, 0.14, 0.16)
		recess_color = Color(0.006, 0.035, 0.05)
	elif central_core_theme:
		steel_color = COLOR_CORE_STEEL
		panel_color = COLOR_CORE_PANEL
		recess_color = COLOR_CORE_RECESS

	var steel := MeshFactory.mat(steel_color)
	steel.metallic = 0.72
	steel.roughness = 0.32
	var panel := MeshFactory.mat(panel_color)
	panel.metallic = 0.55
	panel.roughness = 0.42
	var recess := MeshFactory.mat(recess_color)
	recess.metallic = 0.25
	recess.roughness = 0.7

	# Deep layered plinth beneath the puzzle grid.
	MeshFactory.box(root, center + Vector3(0, -0.49, 0), Vector3(width + 0.9, 0.62, depth + 0.9), steel)
	MeshFactory.box(root, center + Vector3(0, -0.83, 0), Vector3(width + 0.3, 0.16, depth + 0.3), recess)
	for x in range(int(min_x), int(max_x) + 1, 2):
		MeshFactory.box(root, Vector3(float(x), -0.54, max_z + 0.58), Vector3(1.42, 0.25, 0.11), panel)
	for z in range(int(min_z), int(max_z) + 1, 2):
		MeshFactory.box(root, Vector3(max_x + 0.58, -0.54, float(z)), Vector3(0.11, 0.25, 1.42), panel)

	_build_sector_facade(
		Vector3(center.x, 1.18, min_z - 0.78),
		Vector3(width + 1.5, 2.55, 0.34),
		false,
		panel,
		recess)
	_build_sector_facade(
		Vector3(min_x - 0.78, 1.08, center.z),
		Vector3(0.34, 2.35, depth + 1.5),
		true,
		panel,
		recess)

	for corner in [
		Vector3(min_x - 0.72, 1.45, min_z - 0.72),
		Vector3(max_x + 0.72, 1.18, min_z - 0.72),
		Vector3(min_x - 0.72, 1.22, max_z + 0.72),
		Vector3(max_x + 0.72, 0.82, max_z + 0.72),
	]:
		MeshFactory.box(root, corner, Vector3(0.48, corner.y * 2.0, 0.48), steel)
		_lighting.add_power_strip(
			root,
			corner + Vector3(0.0, 0.36, 0.25),
			Vector3(0.12, 0.78, 0.018),
			COLOR_CORE_CYAN if central_core_theme else COLOR_ARCHIVE_CYAN,
			0.08,
			2.5)

	MeshFactory.box(root, Vector3(center.x - 1.2, 3.05, min_z - 0.68), Vector3(width - 1.4, 0.18, 0.24), steel)
	MeshFactory.box(root, Vector3(min_x - 0.68, 2.92, center.z - 0.8), Vector3(0.24, 0.18, depth - 1.2), steel)
	MeshFactory.box(root, Vector3(max_x - 0.8, 3.18, min_z - 0.68), Vector3(1.4, 0.16, 0.22), panel)

	var power_color := COLOR_CORE_CYAN if central_core_theme else COLOR_ARCHIVE_CYAN
	_lighting.add_power_strip(root, Vector3(center.x, 0.175, center.z - 0.43), Vector3(width * 0.38, 0.016, 0.028), power_color, 0.05, 3.2)
	_lighting.add_power_strip(root, Vector3(center.x, 0.175, center.z + 0.43), Vector3(width * 0.38, 0.016, 0.028), power_color, 0.05, 3.2)
	_lighting.add_power_strip(root, Vector3(center.x, 1.86, min_z - 0.58), Vector3(width * 0.38, 0.035, 0.025), power_color, 0.04, 3.8)

	if RENDER_QUALITY.background_fx_enabled():
		_add_dust_volume(center + Vector3(0, 1.25, 0), Vector3(width * 0.48, 1.2, depth * 0.48))
		_add_light_shaft(
			Vector3(center.x - 1.2, 1.82, center.z - 0.8),
			0.72,
			COLOR_CORE_CYAN if central_core_theme else Color(0.16, 0.62, 0.90))

	if central_core_theme:
		var ring_radius := minf(width, depth) * 0.38
		var cyan_ring_mat := MeshFactory.transparent_mat(Color(0.52, 0.86, 1.0, 0.13), 0.75)
		var violet_ring_mat := MeshFactory.transparent_mat(Color(0.42, 0.35, 0.66, 0.11), 0.55)
		MeshFactory.torus(root, center + Vector3(0, 2.48, 0), ring_radius - 0.045, ring_radius, cyan_ring_mat)
		MeshFactory.torus(root, center + Vector3(0, 2.26, 0), ring_radius * 0.72 - 0.035, ring_radius * 0.72, violet_ring_mat)
		_lighting.register_power_material(cyan_ring_mat, 0.55, 1.2)
		_lighting.register_power_material(violet_ring_mat, 0.40, 0.9)


func _build_sector_facade(
		position: Vector3,
		size: Vector3,
		along_z: bool,
		panel: Material,
		recess: Material) -> void:
	MeshFactory.box(_root, position, size, recess)
	var strip_color := COLOR_CORE_CYAN if _chapter == 4 else COLOR_ARCHIVE_CYAN
	var count := 5
	for i in count:
		var t := (float(i) + 0.5) / float(count) - 0.5
		var module_position := position
		var module_size: Vector3
		if along_z:
			module_position.z += t * (size.z - 0.5)
			module_size = Vector3(size.x + 0.055, size.y * (0.72 if i == 4 else 0.88), (size.z - 0.72) / count)
		else:
			module_position.x += t * (size.x - 0.5)
			module_size = Vector3((size.x - 0.72) / count, size.y * (0.70 if i == 0 else 0.88), size.z + 0.055)
		module_position.y -= (size.y - module_size.y) * 0.5
		MeshFactory.box(_root, module_position, module_size, panel)
		if i % 2 == 0:
			var strip_size := Vector3(0.025, module_size.y * 0.52, 0.018)
			var strip_position := module_position
			if along_z:
				strip_position.x += size.x * 0.52
			else:
				strip_position.z += size.z * 0.52
			_lighting.add_power_strip(_root, strip_position, strip_size, strip_color, 0.025, 1.35)


func _add_dust_volume(position: Vector3, extents: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.position = position
	particles.amount = RENDER_QUALITY.particle_amount(42)
	particles.lifetime = 10.0
	particles.preprocess = 10.0
	particles.randomness = 0.7
	particles.visibility_aabb = AABB(-extents, extents * 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.028, 0.028)
	var dust_color := Color(0.54, 0.78, 0.86) if _chapter == 4 else Color(0.42, 0.70, 0.82)
	var dust_mat := MeshFactory.transparent_mat(Color(dust_color.r, dust_color.g, dust_color.b, 0.23), 0.5)
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = dust_mat
	particles.draw_pass_1 = quad
	var process_mat := ParticleProcessMaterial.new()
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.emission_box_extents = extents
	process_mat.direction = Vector3(0.12, 1.0, 0.08)
	process_mat.spread = 32.0
	process_mat.initial_velocity_min = 0.015
	process_mat.initial_velocity_max = 0.055
	process_mat.gravity = Vector3(0, 0.004, 0)
	process_mat.scale_min = 0.45
	process_mat.scale_max = 1.25
	particles.process_material = process_mat
	_root.add_child(particles)
	particles.emitting = true


func _add_light_shaft(position: Vector3, radius: float, color: Color) -> void:
	var shaft := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.22
	mesh.bottom_radius = radius
	mesh.height = 3.6
	mesh.radial_segments = 24
	shaft.mesh = mesh
	shaft.position = position
	shaft.material_override = MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.055), 0.7)
	_root.add_child(shaft)
