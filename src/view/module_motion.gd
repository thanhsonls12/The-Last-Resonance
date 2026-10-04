extends Node3D

const CATALOG = preload("res://src/data/module_motion_catalog.gd")
const QUALITY = preload("res://src/data/render_quality.gd")
const SIGNAL_SHADER = preload("res://assets/shaders/module_signal.gdshader")
const HOLOGRAM_SHADER = preload("res://assets/shaders/module_hologram.gdshader")
const SPARK_SOUND = preload("res://assets/audio/sfx/SFX_VFX_Spark.wav")
const STEAM_SOUND = preload("res://assets/audio/sfx/SFX_VFX_Steam_Hiss.wav")
static var _burst_owners: Dictionary = {}
static var _last_sound_ms := -2000
static var _spark_texture: Texture2D
static var _steam_texture: Texture2D

var profile: StringName
var asset_name := ""
var animation_player: AnimationPlayer
var signal_materials: Array[ShaderMaterial] = []
var particles: GPUParticles3D
var mobile_particles: Array[MeshInstance3D] = []
var _board: Node3D
var _chapter := 1
var _clock := 0.0
var _phase := 0.0
var _next_burst := 2.0
var _burst_left := 0.0
var _burst_elapsed := 0.0
var _sound: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()
var _velocities: Array[Vector3] = []
var _socket := Vector3.ZERO
var _anchor: MeshInstance3D
var _model: Node3D
var _clip: StringName
var _pressed := false
var _press_progress := 0.0
var _render_bindings: Array[Dictionary] = []
var _startup_left := -1.0
var _startup_gain := 1.0


func begin_startup(delay: float) -> void:
	if GameState.reduced_motion or profile in [&"plate", &"energy", &"node", &"wind", &"hologram"]:
		return
	_startup_left = delay
	_startup_gain = 0.0


func cancel_startup() -> void:
	if _startup_left >= 0 or _startup_gain < 1.0:
		_stop_burst()
	_startup_left = -1.0
	_startup_gain = 1.0


static func attach(model: Node3D, path: String, board: Node3D, chapter: int) -> Node3D:
	var kind := CATALOG.profile_for(path, chapter)
	if kind == &"":
		return null
	var controller := new()
	controller.name = "ModuleMotion"
	controller.profile = kind
	controller.asset_name = path.get_file().get_basename()
	controller._board = board
	controller._chapter = chapter
	model.add_child(controller)
	controller.configure(model)
	return controller


func configure(model: Node3D) -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_model = model
	_rng.seed = hash(asset_name) + int(model.position.x * 173 + model.position.z * 397 + model.position.y * 631)
	_phase = _rng.randf_range(0, TAU)
	_next_burst = _rng.randf_range(1.2, 7.0)
	animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player:
		animation_player.process_mode = Node.PROCESS_MODE_PAUSABLE
		for candidate in animation_player.get_animation_list():
			if candidate != &"RESET":
				_clip = candidate
				var animation := animation_player.get_animation(candidate)
				animation.loop_mode = Animation.LOOP_NONE if profile == &"plate" else Animation.LOOP_LINEAR
				animation_player.play(candidate)
				animation_player.seek(0 if profile == &"plate" else _phase / TAU * animation.length, true)
				if profile == &"plate":
					animation_player.pause()
				break
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(model, meshes)
	var bounds := AABB()
	var first := true
	for mesh in meshes:
		var local := _relative_transform(mesh)
		var item_bounds := local * mesh.mesh.get_aabb()
		bounds = item_bounds if first else bounds.merge(item_bounds)
		first = false
		var node_name := String(mesh.name).to_lower()
		if node_name.contains("exhaustcap") or node_name.contains("chimney") or node_name.contains("brokenrobot_eye"):
			_anchor = mesh
		_apply_signal(mesh, node_name)
	_socket = Vector3(bounds.get_center().x, bounds.end.y * .72, bounds.position.z - .02)
	if profile in [&"steam", &"heat"]:
		_socket = Vector3(bounds.get_center().x, bounds.end.y, bounds.get_center().z)
	if signal_materials.is_empty() and profile in [&"signal", &"hologram", &"reactor", &"lamp"]:
		var status := MeshInstance3D.new()
		status.name = "ModuleStatusStrip"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(minf(.32, bounds.size.x * .45), .025, .012)
		status.mesh = mesh
		status.position = _socket
		var source := StandardMaterial3D.new()
		source.albedo_color = Color("183848")
		source.emission_enabled = true
		source.emission = Color("72bad0")
		status.material_override = source
		status.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(status)
		_apply_signal(status, "screen")
	if profile in [&"spark", &"steam", &"heat"]:
		_build_burst()
		_sound = AudioStreamPlayer3D.new()
		_sound.name = "ModuleAccentSound"
		_sound.stream = SPARK_SOUND if profile == &"spark" else STEAM_SOUND
		_sound.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		_sound.volume_db = -27 if profile == &"spark" else -31
		_sound.max_distance = 28.0
		_sound.unit_size = 8.0
		add_child(_sound)


func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child == self:
			continue
		if child is MeshInstance3D and child.mesh:
			result.append(child)
		_collect_meshes(child, result)


func _relative_transform(node: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var cursor: Node = node
	while cursor != _model and cursor is Node3D:
		result = (cursor as Node3D).transform * result
		cursor = cursor.get_parent()
	return result


func _apply_signal(mesh: MeshInstance3D, node_name: String) -> void:
	if profile in [&"wind", &"water", &"machine", &"plate"]:
		return
	var screen := (node_name.contains("screen") and not node_name.contains("frame")) or node_name.contains("gaugecore")
	var reactor := node_name.contains("generator_top") or (node_name.contains("central_core") and not node_name.contains("base"))
	var projection := node_name.contains("core_hologram") or node_name.contains("shrine_crystal")
	var heat := node_name.contains("furnace_mouth")
	var common_override := mesh.material_override
	var replaced := false
	var original_surfaces: Array[Material] = []
	for surface in mesh.mesh.get_surface_count():
		original_surfaces.append(mesh.get_surface_override_material(surface))
	for surface in mesh.mesh.get_surface_count():
		var source: Material = common_override if common_override != null else mesh.get_active_material(surface)
		if not source is StandardMaterial3D:
			continue
		if not source.emission_enabled and not screen and not reactor and not projection and not heat:
			continue
		var material := ShaderMaterial.new()
		material.shader = HOLOGRAM_SHADER if source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or node_name.contains("core_hologram") else SIGNAL_SHADER
		material.set_shader_parameter("base_color", source.albedo_color)
		material.set_shader_parameter("metallic", source.metallic)
		material.set_shader_parameter("roughness", source.roughness)
		var color := Color("6bc9e6")
		if _chapter == 2:
			color = Color("ee8a35")
		elif _chapter == 3:
			color = Color("62b7a9")
		elif _chapter == 4:
			color = Color("85c9e7")
		if profile == &"energy":
			color = source.emission if source.emission_enabled else source.albedo_color
		material.set_shader_parameter("tint", color)
		material.set_shader_parameter("phase", _phase + surface * .41)
		if asset_name == "Energy-Core" and node_name.contains("faceted"):
			material.set_shader_parameter("emission_scale", .42)
		elif asset_name == "Core-Pedestal":
			material.set_shader_parameter("emission_scale", .75)
		material.set_shader_parameter("unstable", _chapter == 1 and profile in [&"spark", &"lamp", &"signal"])
		material.set_shader_parameter("scan", screen or reactor or projection or profile in [&"signal", &"hologram"])
		if profile == &"node":
			material.set_shader_parameter("state", 0)
		mesh.set_surface_override_material(surface, material)
		replaced = true
		signal_materials.append(material)
	if replaced:
		_render_bindings.append({"mesh": weakref(mesh), "override": common_override, "surfaces": original_surfaces})
		mesh.material_override = null


static func _texture(steam: bool) -> Texture2D:
	if steam and _steam_texture:
		return _steam_texture
	if not steam and _spark_texture:
		return _spark_texture
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var u := (x + .5) / 32.0 * 2 - 1
			var v := (y + .5) / 32.0 * 2 - 1
			var radius := u * u + v * v
			var alpha := pow(maxf(0, 1 - radius), 2) if steam else exp(-u * u * 26) * pow(maxf(0, 1 - absf(v)), .65)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	var texture := ImageTexture.create_from_image(image)
	if steam:
		_steam_texture = texture
	else:
		_spark_texture = texture
	return texture


func _particle_mesh(steam: bool) -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(.22, .22) if steam else Vector2(.035, .14)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _texture(steam)
	mat.albedo_color = Color(.67, .77, .79, .32) if steam else Color(1, .62, .18, 1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not steam:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.emission_enabled = true
		mat.emission = Color(1, .45, .10)
		mat.emission_energy_multiplier = 2.0
	mesh.material = mat
	return mesh


func _build_burst() -> void:
	var steam := profile != &"spark"
	if QUALITY.is_mobile() or DisplayServer.get_name() == "headless":
		for i in range(2 if steam else 4):
			var particle := MeshInstance3D.new()
			particle.mesh = _particle_mesh(steam)
			particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			particle.visible = false
			add_child(particle)
			mobile_particles.append(particle)
		return
	particles = GPUParticles3D.new()
	particles.name = "ModuleSteam" if steam else "ModuleSparks"
	particles.amount = 9 if steam else 16
	particles.lifetime = 1.1 if steam else .4
	particles.one_shot = true
	particles.explosiveness = .75 if steam else 1.0
	particles.randomness = .45
	particles.local_coords = true
	particles.emitting = false
	particles.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	particles.draw_pass_1 = _particle_mesh(steam)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP if steam else Vector3(.35, .6, -.7)
	process.spread = 25 if steam else 62
	process.initial_velocity_min = .25 if steam else .8
	process.initial_velocity_max = .6 if steam else 2.2
	process.gravity = Vector3(0, .15, 0) if steam else Vector3(0, -4.8, 0)
	process.scale_min = .5
	process.scale_max = 1.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, .6 if steam else 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(.25, Color(1, 1, 1, 1))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	particles.process_material = process
	add_child(particles)


func set_state(state: int) -> void:
	for material in signal_materials:
		material.set_shader_parameter("state", state)


func set_pressed(pressed: bool) -> void:
	_pressed = pressed


func trigger_burst() -> bool:
	if not is_visible_in_tree() or _burst_left > 0:
		return false
	var budget := 1 if QUALITY.is_mobile() else 3
	if _burst_owners.size() >= budget:
		return false
	if particles == null and mobile_particles.is_empty():
		return false
	_burst_owners[get_instance_id()] = true
	_burst_left = 1.45 if profile != &"spark" else .45
	_burst_elapsed = 0
	if particles:
		particles.position = _socket
		particles.restart()
		particles.emitting = true
	_velocities.clear()
	for particle in mobile_particles:
		particle.visible = true
		particle.position = _socket
		if profile == &"spark":
			_velocities.append(Vector3(_rng.randf_range(-.7, .7), _rng.randf_range(.5, 1.8), _rng.randf_range(-1.5, -.3)))
		else:
			_velocities.append(Vector3(_rng.randf_range(-.1, .1), _rng.randf_range(.3, .6), _rng.randf_range(-.1, .1)))
	var now := Time.get_ticks_msec()
	if _sound and now - _last_sound_ms > 1400:
		_sound.position = _socket
		_sound.pitch_scale = _rng.randf_range(.9, 1.1)
		_sound.play()
		_last_sound_ms = now
	return true


func _stop_burst() -> void:
	_burst_left = 0
	_burst_owners.erase(get_instance_id())
	if particles:
		particles.emitting = false
	for particle in mobile_particles:
		particle.visible = false
	if _sound:
		_sound.stop()


func _exit_tree() -> void:
	_burst_owners.erase(get_instance_id())
	for binding in _render_bindings:
		var mesh := (binding.mesh as WeakRef).get_ref() as MeshInstance3D
		if is_instance_valid(mesh):
			mesh.material_override = binding.override
			for surface in binding.surfaces.size():
				mesh.set_surface_override_material(surface, binding.surfaces[surface])
	_render_bindings.clear()
	signal_materials.clear()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		if animation_player:
			animation_player.speed_scale = 0
		_stop_burst()
		return
	_clock += delta
	if GameState.reduced_motion and _startup_left >= 0:
		_startup_left = -1.0
		_startup_gain = 1.0
	if _startup_left >= 0:
		_startup_left -= delta
		if _startup_left < 0:
			trigger_burst()
	else:
		_startup_gain = move_toward(_startup_gain, 1.0, delta * 2.0)
	var power := .7
	if is_instance_valid(_board):
		var powered := _board.has_method("is_sector_powered") and bool(_board.call("is_sector_powered"))
		power = 1.0 if powered else clampf(float(_board.get("power_level")) + .2, .2, .65)
	if animation_player:
		var organic := profile in [&"wind", &"hologram", &"energy"]
		if profile == &"plate":
			var length := animation_player.get_animation(_clip).length
			_press_progress = move_toward(_press_progress, 1.0 if _pressed else 0.0, delta / maxf(length, .01))
			animation_player.seek(_press_progress * length, true)
		else:
			animation_player.speed_scale = (1.0 if organic else lerpf(.35, 1.0, power) * _startup_gain) * (.75 if QUALITY.is_mobile() else 1.0)
	for material in signal_materials:
		material.set_shader_parameter("fx_time", _clock)
		var hero := profile in [&"energy", &"node"]
		material.set_shader_parameter("intensity", (1.5 if hero else .75 * power * _startup_gain) * QUALITY.environment_emission_scale())
	if _anchor and is_instance_valid(_anchor):
		_socket = _relative_transform(_anchor) * _anchor.mesh.get_aabb().get_center()
	if profile in [&"spark", &"steam", &"heat"]:
		_next_burst -= delta
		if _next_burst <= 0:
			trigger_burst()
			_next_burst = _rng.randf_range(4.5, 10.0) * (1.8 if QUALITY.is_mobile() else 1.0)
	if _burst_left > 0:
		_burst_left -= delta
		_burst_elapsed += delta
		for i in mobile_particles.size():
			var spark := profile == &"spark"
			var life := clampf(_burst_elapsed / (.45 if spark else 1.45), 0, 1)
			mobile_particles[i].position = _socket + _velocities[i] * _burst_elapsed
			if spark:
				mobile_particles[i].position += Vector3(0, -2.4, 0) * _burst_elapsed * _burst_elapsed
			mobile_particles[i].scale = Vector3.ONE * (maxf(.1, 1 - life) if spark else .5 + life * 1.6)
			var material := (mobile_particles[i].mesh as QuadMesh).material as StandardMaterial3D
			material.albedo_color.a = (1.0 if spark else .32) * (1 - life)
		if _burst_left <= 0:
			_stop_burst()
