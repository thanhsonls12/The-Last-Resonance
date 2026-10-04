class_name BoardLighting
extends RefCounted

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")

const COLOR_ARCHIVE_CYAN := Color(0.10, 0.82, 1.0)
const COLOR_CORE_CYAN := Color(0.72, 0.94, 1.0)

var _tween_owner: Node
var _power_lights: Array[Dictionary] = []
var _power_materials: Array[Dictionary] = []
var _is_powered := false
var _flicker_timer := 0.0
var _mobile_color_pools_used := 0
var _player_light: SpotLight3D
var _transition_tweens: Array[Tween] = []


func reset(tween_owner: Node) -> void:
	_cancel_transitions()
	_tween_owner = tween_owner
	_power_lights.clear()
	_power_materials.clear()
	_is_powered = false
	_flicker_timer = 0.0
	_mobile_color_pools_used = 0
	_player_light = null


func build_story_lighting(
		logic: GameLogic,
		chapter: int,
		world_position: Callable,
		layer_parent: Callable) -> void:
	if logic == null or not world_position.is_valid() or not layer_parent.is_valid():
		return
	var player_light_color := Color(0.90, 0.95, 1.0)
	var block_light_color := COLOR_CORE_CYAN if chapter == 4 else Color(0.68, 0.20, 1.0)
	var slot_light_color := COLOR_CORE_CYAN if chapter == 4 else COLOR_ARCHIVE_CYAN
	_player_light = add_spotlight(
		_tween_owner,
		world_position.call(logic.player) + Vector3(0, 3.8, 0),
		player_light_color,
		0.85, 5.0, 27.0, false)
	if RENDER_QUALITY.is_mobile():
		return
	for cell in logic.blocks.keys():
		var block: Node3D = _tween_owner.get("block_nodes").get(cell)
		add_spotlight(
			block,
			(world_position.call(cell) as Vector3) + Vector3(0, 3.5, 0) - block.position,
			block_light_color,
			0.40, 4.4, 15.0, false)
	for cell in logic.slots.keys():
		add_spotlight(
			layer_parent.call(cell),
			world_position.call(cell) + Vector3(0, 3.4, 0),
			slot_light_color,
			0.55, 4.4, 15.0, false)


func build_mobile_color_pools(
		logic: GameLogic,
		goal_color: Color,
		plate_color: Color,
		portal_color: Color,
		elevator_color: Color,
		block_color: Color,
		world_position: Callable,
		layer_parent: Callable) -> void:
	if logic == null or not RENDER_QUALITY.mobile_color_pools_enabled():
		return
	var candidates: Array[Dictionary] = []
	for position in logic.slots.keys():
		candidates.append({"position": position, "color": goal_color, "energy": 0.58})
	for position in logic.plates.keys():
		candidates.append({"position": position, "color": plate_color, "energy": 0.46})
	for position in logic.portals.keys():
		candidates.append({"position": position, "color": portal_color, "energy": 0.52})
	for position in logic.elevators.keys():
		candidates.append({"position": position, "color": elevator_color, "energy": 0.48})
	for position in logic.blocks.keys():
		candidates.append({"position": position, "color": block_color, "energy": 0.38})
	for candidate in candidates:
		if _mobile_color_pools_used >= RENDER_QUALITY.mobile_color_pool_budget():
			break
		_add_mobile_color_pool(
			candidate["position"],
			candidate["color"],
			float(candidate["energy"]),
			world_position,
			layer_parent)


func add_spotlight(
		parent: Node3D,
		position: Vector3,
		color: Color,
		energy: float,
		light_range: float,
		angle: float,
		shadows: bool) -> SpotLight3D:
	if parent == null:
		return null
	var spot := SpotLight3D.new()
	spot.position = position
	spot.rotation_degrees.x = -90.0
	spot.light_color = color
	spot.light_energy = energy
	spot.spot_range = light_range
	spot.spot_angle = angle
	spot.shadow_enabled = shadows and RENDER_QUALITY.shadows_enabled()
	parent.add_child(spot)
	return spot


func add_sector_lamp(parent: Node3D, position: Vector3, color: Color) -> void:
	if parent == null:
		return
	if RENDER_QUALITY.local_lights_enabled():
		var light := OmniLight3D.new()
		light.position = position
		light.light_color = color
		light.light_energy = 0.22
		light.omni_range = 2.6
		light.omni_attenuation = 1.45
		parent.add_child(light)
		register_power_light(light, 0.22, 0.70)
	var lens_mat := MeshFactory.mat(color, 0.25)
	var lens := MeshFactory.sphere(parent, position, 0.055, lens_mat)
	lens.scale = Vector3(1.0, 0.55, 1.0)
	register_power_material(lens_mat, 0.25, 1.8, position)


func add_hologram_glow(parent: Node3D, position: Vector3, color := COLOR_ARCHIVE_CYAN) -> void:
	if parent == null:
		return
	if RENDER_QUALITY.local_lights_enabled():
		var light := OmniLight3D.new()
		light.position = position
		light.light_color = color
		light.light_energy = 0.28
		light.omni_range = 1.65
		light.omni_attenuation = 1.65
		parent.add_child(light)
		register_power_light(light, 0.28, 0.65)
	var holo_mat := MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.16), 1.2)
	MeshFactory.cylinder(parent, position + Vector3(0, 0.46, 0), 0.22, 0.82, holo_mat)
	for height in [0.12, 0.40, 0.68]:
		MeshFactory.torus(parent, position + Vector3(0, height, 0), 0.20, 0.225, holo_mat)
	register_power_material(holo_mat, 0.35, 1.5, position)


func add_power_strip(
		parent: Node3D,
		position: Vector3,
		size: Vector3,
		color: Color,
		off_energy: float,
		on_energy: float) -> void:
	if parent == null:
		return
	var material := MeshFactory.mat(color, off_energy)
	MeshFactory.box(parent, position, size, material)
	register_power_material(material, off_energy, minf(on_energy, 1.6), position)


func register_power_light(light: Light3D, off_energy: float, on_energy: float) -> void:
	if light == null:
		return
	_power_lights.append({"node": light, "off": off_energy, "on": on_energy, "delay": _startup_delay(light.global_position)})


func register_power_material(material: StandardMaterial3D, off_energy: float, on_energy: float, position := Vector3.ZERO) -> void:
	if material == null:
		return
	_power_materials.append({"material": material, "off": off_energy, "on": on_energy, "delay": _startup_delay(position)})


func register_mesh_emissives(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D and (material as StandardMaterial3D).emission_enabled:
					var duplicate := material.duplicate() as StandardMaterial3D
					mesh_instance.set_surface_override_material(surface, duplicate)
					var original_energy := duplicate.emission_energy_multiplier
					register_power_material(duplicate, 0.05, clampf(original_energy, 0.7, 1.8), mesh_instance.global_position)
					duplicate.emission_energy_multiplier = 0.05
	for child in node.get_children():
		register_mesh_emissives(child)


func apply_power_baseline(power_level: float) -> void:
	var gain := lerpf(1.0, 2.6, clampf(power_level, 0.0, 1.0))
	if is_equal_approx(gain, 1.0):
		return
	for info in _power_lights:
		info["off"] = minf(float(info["off"]) * gain, float(info["on"]))
	for info in _power_materials:
		info["off"] = minf(float(info["off"]) * gain, float(info["on"]))


func process_power(delta: float) -> void:
	if is_instance_valid(_player_light) and is_instance_valid(_tween_owner):
		var player: Node3D = _tween_owner.get("player_node")
		if is_instance_valid(player):
			_player_light.position = player.position + Vector3(0, 3.1, 0)
	if _is_powered:
		return
	_flicker_timer += delta
	var flicker := 1.0 if GameState.reduced_motion else 0.96 + 0.04 * sin(_flicker_timer * 1.35)
	for info in _power_lights:
		var light: Light3D = info["node"]
		if is_instance_valid(light):
			light.light_energy = float(info["off"]) * flicker
	for info in _power_materials:
		var material: StandardMaterial3D = info["material"]
		if is_instance_valid(material):
			material.emission_energy_multiplier = float(info["off"]) * flicker


func is_powered() -> bool:
	return _is_powered


func set_powered(powered: bool, immediate := false) -> void:
	_cancel_transitions()
	_is_powered = powered
	for info in _power_lights:
		var light: Light3D = info["node"]
		if not is_instance_valid(light):
			continue
		var target := float(info["on"] if powered else info["off"])
		if immediate or _tween_owner == null:
			light.light_energy = target
		else:
			var tween := _tween_owner.create_tween()
			_transition_tweens.append(tween)
			tween.tween_interval(float(info.delay) if powered and not GameState.reduced_motion else 0.0)
			tween.tween_property(light, "light_energy", target, 0.85) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for info in _power_materials:
		var material: StandardMaterial3D = info["material"]
		if not is_instance_valid(material):
			continue
		var target := float(info["on"] if powered else info["off"])
		if immediate or _tween_owner == null:
			material.emission_energy_multiplier = target
		else:
			var tween := _tween_owner.create_tween()
			_transition_tweens.append(tween)
			tween.tween_interval(float(info.delay) if powered and not GameState.reduced_motion else 0.0)
			tween.tween_property(material, "emission_energy_multiplier", target, 0.9) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _startup_delay(position: Vector3) -> float:
	return clampf((absf(position.x) + absf(position.z)) * .045, 0.0, .6)


func _cancel_transitions() -> void:
	for tween in _transition_tweens:
		if tween and tween.is_valid():
			tween.kill()
	_transition_tweens.clear()


func _add_mobile_color_pool(
		cell: Vector3i,
		color: Color,
		energy: float,
		world_position: Callable,
		layer_parent: Callable) -> void:
	var parent: Node3D = layer_parent.call(cell)
	if parent == null:
		return
	var pool := MeshInstance3D.new()
	pool.name = "MobileColorPool%d" % (_mobile_color_pools_used + 1)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.54
	mesh.bottom_radius = 0.54
	mesh.height = 0.012
	mesh.radial_segments = 12
	pool.mesh = mesh
	var pool_material := MeshFactory.transparent_mat(Color(color.r, color.g, color.b, 0.14), energy)
	pool_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pool.material_override = pool_material
	pool.position = world_position.call(cell) + Vector3(0, 0.025, 0)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pool)
	_mobile_color_pools_used += 1
