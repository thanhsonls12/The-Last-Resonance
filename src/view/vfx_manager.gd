class_name EchoVfxManager
extends Node3D

const COLOR_CYAN := Color(0.12, 0.92, 1.0)
const COLOR_TEAL := Color(0.18, 1.0, 0.78)
const COLOR_PURPLE := Color(0.68, 0.18, 1.0)
const COLOR_ORANGE := Color(1.0, 0.34, 0.08)
const COLOR_YELLOW := Color(1.0, 0.72, 0.08)
const COLOR_DUST := Color(0.42, 0.50, 0.62)

var _time := 0.0
var _loop_effects: Array[Node3D] = []
var _loop_phases: Dictionary = {}


func _process(delta: float) -> void:
	_time += delta
	for root in _loop_effects:
		if not is_instance_valid(root):
			continue
		var phase: float = float(_loop_phases.get(root, 0.0))
		var pulse := 1.0 + sin(_time * 2.2 + phase) * 0.08
		root.scale = Vector3.ONE * pulse
		root.rotation.y += delta * 0.55


func refresh(logic: GameLogic, board: BoardView) -> void:
	clear_loops()
	for cell in logic.energy_nodes:
		_add_core_loop(board.world_position(cell) + Vector3(0, 0.12, 0))
	for cell in logic.portals.keys():
		_add_portal_loop(board.world_position(cell) + Vector3(0, 0.10, 0))


func clear_loops() -> void:
	for root in _loop_effects:
		if is_instance_valid(root):
			root.queue_free()
	_loop_effects.clear()
	_loop_phases.clear()


func play_footstep_dust(position: Vector3) -> void:
	_burst(position + Vector3(0, 0.04, 0), COLOR_DUST, 7, 0.48, Vector3.UP, 55.0, 0.35, 0.10)


func play_push_impact(position: Vector3, direction := Vector3.ZERO) -> void:
	var burst_direction := direction.normalized() if direction.length_squared() > 0.001 else Vector3.UP
	_burst(position + Vector3(0, 0.16, 0), COLOR_ORANGE, 14, 0.55, burst_direction, 42.0, 2.2, 0.12)
	_pulse_ring(position + Vector3(0, 0.08, 0), COLOR_ORANGE, 0.22, 0.85, 0.22)


func play_blocked(position: Vector3) -> void:
	_burst(position + Vector3(0, 0.22, 0), COLOR_ORANGE, 8, 0.32, Vector3.UP, 30.0, 1.0, 0.08)


func play_goal_activation(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.08, 0), COLOR_CYAN, 0.25, 1.8, 0.32)
	_burst(position + Vector3(0, 0.18, 0), COLOR_CYAN, 18, 0.75, Vector3.UP, 32.0, 2.4, 0.11)


func play_core_insert(position: Vector3) -> void:
	play_goal_activation(position)
	_pulse_ring(position + Vector3(0, 0.28, 0), COLOR_TEAL, 0.16, 0.62, 0.24)


func play_door_unlock(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.35, 0), COLOR_YELLOW, 0.20, 1.35, 0.34)
	_burst(position + Vector3(0, 0.40, 0), COLOR_YELLOW, 14, 0.8, Vector3.UP, 38.0, 2.0, 0.10)


func play_plate_activation(position: Vector3, active: bool) -> void:
	var color := COLOR_CYAN if active else COLOR_ORANGE
	_pulse_ring(position + Vector3(0, 0.08, 0), color, 0.18, 1.1, 0.30)
	_burst(position + Vector3(0, 0.14, 0), color, 10, 0.42, Vector3.UP, 35.0, 1.4, 0.08)


func play_portal(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.12, 0), COLOR_PURPLE, 0.24, 1.5, 0.42)
	_burst(position + Vector3(0, 0.20, 0), COLOR_PURPLE, 16, 0.7, Vector3.UP, 65.0, 1.8, 0.10)


func play_elevator(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.10, 0), COLOR_TEAL, 0.22, 1.0, 0.30)
	_burst(position + Vector3(0, 0.22, 0), COLOR_TEAL, 12, 0.55, Vector3.UP, 22.0, 1.8, 0.09)


func play_bridge(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.10, 0), COLOR_ORANGE, 0.20, 0.95, 0.28)
	_burst(position + Vector3(0, 0.16, 0), COLOR_ORANGE, 8, 0.42, Vector3.UP, 40.0, 1.4, 0.08)


func play_level_complete(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.30, 0), COLOR_CYAN, 0.18, 2.6, 0.55)
	_burst(position + Vector3(0, 0.35, 0), COLOR_CYAN, 30, 1.5, Vector3.UP, 55.0, 3.8, 0.14)
	_burst(position + Vector3(0, 0.35, 0), COLOR_YELLOW, 20, 1.2, Vector3.UP, 45.0, 2.8, 0.10)


func play_power_restoration(origin: Vector3) -> void:
	_pulse_ring(origin + Vector3(0, 0.15, 0), COLOR_CYAN, 0.20, 5.2, 1.2)
	_pulse_ring(origin + Vector3(0, 0.22, 0), COLOR_TEAL, 0.28, 4.2, 0.9)
	_burst(origin + Vector3(0, 0.35, 0), COLOR_CYAN, 40, 2.2, Vector3.UP, 65.0, 4.0, 0.16)
	_burst(origin + Vector3(0, 0.35, 0), COLOR_YELLOW, 24, 1.6, Vector3.UP, 45.0, 3.0, 0.12)


func play_boot_sparks(position: Vector3) -> void:
	_burst(position + Vector3(0, 0.35, 0), COLOR_CYAN, 18, 0.75, Vector3.UP, 70.0, 1.8, 0.08)
	_pulse_ring(position + Vector3(0, 0.08, 0), COLOR_CYAN, 0.12, 1.4, 0.50)



func play_memory_fragment_collect(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.25, 0), COLOR_PURPLE, 0.15, 2.2, 0.60)
	_pulse_ring(position + Vector3(0, 0.30, 0), COLOR_TEAL, 0.20, 1.4, 0.40)
	_burst(position + Vector3(0, 0.30, 0), COLOR_PURPLE, 24, 1.2, Vector3.UP, 60.0, 2.5, 0.12)
	_burst(position + Vector3(0, 0.30, 0), COLOR_YELLOW, 16, 0.9, Vector3.UP, 45.0, 1.8, 0.09)


func play_resonance_ping(position: Vector3) -> void:
	_pulse_ring(position + Vector3(0, 0.15, 0), COLOR_CYAN, 0.10, 3.5, 0.75)
	_pulse_ring(position + Vector3(0, 0.20, 0), COLOR_PURPLE, 0.20, 2.8, 0.55)


func _add_core_loop(position: Vector3) -> void:
	var root := Node3D.new()
	root.position = position
	add_child(root)
	var ring := _ring_mesh(COLOR_TEAL, 0.22, 0.30, 2.8)
	root.add_child(ring)
	var orb := _sphere_mesh(COLOR_CYAN, 0.10, 3.2)
	orb.position.y = 0.14
	root.add_child(orb)
	_register_loop(root)


func _add_portal_loop(position: Vector3) -> void:
	var root := Node3D.new()
	root.position = position
	add_child(root)
	var ring := _ring_mesh(COLOR_PURPLE, 0.22, 0.31, 3.0)
	root.add_child(ring)
	var inner := _ring_mesh(COLOR_CYAN, 0.12, 0.17, 1.8)
	inner.rotation.x = 0.18
	root.add_child(inner)
	_register_loop(root)


func _register_loop(root: Node3D) -> void:
	_loop_effects.append(root)
	_loop_phases[root] = float(_loop_effects.size()) * 0.73


func _burst(
	position: Vector3,
	color: Color,
	amount: int,
	lifetime: float,
	direction: Vector3,
	spread: float,
	velocity: float,
	size: float) -> void:
	var particles := GPUParticles3D.new()
	particles.position = position
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.35
	particles.draw_pass_1 = _particle_mesh(color, size)
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = direction
	process_material.spread = spread
	process_material.initial_velocity_min = velocity * 0.55
	process_material.initial_velocity_max = velocity
	process_material.gravity = Vector3(0, -2.4, 0)
	process_material.scale_min = 0.55
	process_material.scale_max = 1.0
	particles.process_material = process_material
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(lifetime + 0.35).timeout.connect(func() -> void:
		if is_instance_valid(particles):
			particles.queue_free())


func _pulse_ring(position: Vector3, color: Color, start_scale: float, end_scale: float, lifetime: float) -> void:
	var ring := _ring_mesh(color, 0.20, 0.28, 3.0)
	ring.position = position
	ring.scale = Vector3.ONE * start_scale
	add_child(ring)
	var material := ring.material_override as StandardMaterial3D
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * end_scale, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, lifetime)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free())


func _particle_mesh(color: Color, size: float) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE * size
	var material := _emissive_material(color, 2.2)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	mesh.material = material
	return mesh


func _ring_mesh(color: Color, inner_radius: float, outer_radius: float, emission: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_radius
	mesh.outer_radius = outer_radius
	mesh.rings = 32
	mesh.ring_segments = 12
	instance.mesh = mesh
	instance.material_override = _emissive_material(color, emission)
	return instance


func _sphere_mesh(color: Color, radius: float, emission: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	instance.mesh = mesh
	instance.material_override = _emissive_material(color, emission)
	return instance


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.86)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
