class_name BoardActors
extends RefCounted

## Owns character presentation for the board: Kiro animation/power state and
## story holograms. It does not read or mutate puzzle state.

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")

const KIRO_MODEL_PATH := "res://assets/models/animations/Kiro_K7/Kiro_K7_Animation_Library.glb"
const KIRO_MODEL_SCALE := 0.28
const KIRO_MODEL_FLOOR_OFFSET := -0.38
const EVA_MODEL_PATH := "res://assets/models/characters/EVA_v5.glb"
const ELIAS_MODEL_PATH := "res://assets/models/characters/Dr-Elias-Vale_v3.glb"
const HOLOGRAM_SHADER_PATH := "res://assets/shaders/hologram_eva.gdshader"
const COLOR_PLAYER := Color(0.92, 0.12, 0.34)

var player_node: Node3D
var player_animation: AnimationPlayer
var player_visual_offset := Vector3.ZERO
var kiro_glow_materials: Array[StandardMaterial3D] = []
var eva_hologram_node: Node3D
var eva_hologram_material: ShaderMaterial
var elias_hologram_node: Node3D

var _root: Node3D
var _current_clip: StringName = &""
var _turn_tween: Tween
var _eva_bob_tween: Tween
var _elias_bob_tween: Tween
var _weight_tween: Tween
var _glow_tween: Tween
var _kiro_powered := true
var _ground_ring_material: StandardMaterial3D
var _tidal_attachment: Node3D


func reset(root: Node3D) -> void:
	_root = root
	for tween in [_weight_tween, _glow_tween]:
		if tween and tween.is_valid():
			tween.kill()
	_weight_tween = null
	_glow_tween = null
	_ground_ring_material = null
	_tidal_attachment = null
	player_node = null
	player_animation = null
	player_visual_offset = Vector3.ZERO
	_current_clip = &""
	kiro_glow_materials.clear()
	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()
	_turn_tween = null
	if _eva_bob_tween and _eva_bob_tween.is_valid():
		_eva_bob_tween.kill()
	_eva_bob_tween = null
	eva_hologram_node = null
	eva_hologram_material = null
	if _elias_bob_tween and _elias_bob_tween.is_valid():
		_elias_bob_tween.kill()
	_elias_bob_tween = null
	elias_hologram_node = null


func build_player(parent: Node3D, position: Vector3, player_material: Material, accent_material: Material) -> Node3D:
	_root = parent
	var kiro_scene := load(KIRO_MODEL_PATH) as PackedScene
	if kiro_scene:
		var model := kiro_scene.instantiate() as Node3D
		model.name = "Kiro_K7"
		player_visual_offset = Vector3(0, KIRO_MODEL_FLOOR_OFFSET, 0)
		model.position = position + player_visual_offset
		model.scale = Vector3.ONE * KIRO_MODEL_SCALE
		parent.add_child(model)
		player_node = model
		_collect_kiro_glow_materials(model)
		set_kiro_powered(true, true)
		player_animation = _find_animation_player(model)
		play_player_animation(&"Idle")
		_add_player_ground_ring(model)
		_update_tidal_armor()
		return model
	player_node = _build_player_procedural(parent, position, player_material, accent_material)
	return player_node


func set_kiro_powered(powered: bool, immediate := false) -> void:
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_kiro_powered = powered
	_update_tidal_armor()
	if _ground_ring_material:
		var ring_color := GameState.kiro_glow_color() if bool(GameState.echo_chamber.get("tidal_equipped", false)) and bool(GameState.echo_chamber.get("tidal_unlocked", false)) else COLOR_PLAYER
		_ground_ring_material.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, .55)
		_ground_ring_material.emission = ring_color
	for material in kiro_glow_materials:
		if not is_instance_valid(material):
			continue
		if immediate:
			material.emission_enabled = powered
			material.emission_energy_multiplier = 1.6 if powered else 0.0
			material.albedo_color = GameState.kiro_glow_color() if powered else Color(0.04, 0.06, 0.08)
			material.emission = GameState.kiro_glow_color()
		elif powered:
			material.emission_enabled = true
			material.emission = GameState.kiro_glow_color()
			if _root:
				var tween := _root.create_tween()
				tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tween.tween_property(material, "emission_energy_multiplier", 1.6, 0.45)
				tween.parallel().tween_property(material, "albedo_color", GameState.kiro_glow_color(), 0.45)
		else:
			material.emission_energy_multiplier = 0.0
			material.albedo_color = Color(0.04, 0.06, 0.08)


func _update_tidal_armor() -> void:
	if not is_instance_valid(player_node):
		return
	var equipped := bool(GameState.echo_chamber.get("tidal_unlocked", false)) and bool(GameState.echo_chamber.get("tidal_equipped", false))
	if not _tidal_attachment and equipped:
		var skeleton := player_node.find_child("Skeleton3D", true, false) as Skeleton3D
		if not skeleton:
			for node in player_node.find_children("*", "Skeleton3D", true, false):
				skeleton = node
				break
		if skeleton and skeleton.find_bone("torso") >= 0:
			var attachment := BoneAttachment3D.new()
			attachment.name = "TidalArmorAttachment"
			attachment.bone_name = "torso"
			skeleton.add_child(attachment)
			var armor := (load("res://assets/models/echo_expansion/kiro_tidal_pack.glb") as PackedScene).instantiate() as Node3D
			armor.scale = Vector3.ONE * (.5 / KIRO_MODEL_SCALE)
			armor.position = Vector3(0, .02, -.16) / KIRO_MODEL_SCALE
			armor.rotation.y = PI
			attachment.add_child(armor)
			_collect_kiro_glow_materials(armor)
			_tidal_attachment = attachment
	if _tidal_attachment:
		_tidal_attachment.visible = equipped


func play_player_animation(clip: StringName) -> void:
	if not player_animation or not player_animation.has_animation(clip):
		return
	if clip == _current_clip and player_animation.is_playing():
		return
	var animation := player_animation.get_animation(clip)
	animation.loop_mode = Animation.LOOP_LINEAR if clip in [&"Idle", &"Walk", &"Victory"] else Animation.LOOP_NONE
	player_animation.speed_scale = .92 if clip == &"Push" else 1.0
	player_animation.play(clip, .07)
	_current_clip = clip
	if clip in [&"Interact", &"Victory"]:
		pulse_kiro_glow(2.7 if clip == &"Victory" else 2.2)


func play_step_weight(pushing: bool, duration: float) -> void:
	if not player_node:
		return
	if _weight_tween and _weight_tween.is_valid():
		_weight_tween.kill()
	player_node.rotation.x = 0
	if GameState.reduced_motion:
		return
	_weight_tween = player_node.create_tween()
	_weight_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weight_tween.tween_property(player_node, "rotation:x", -.09 if pushing else -.035, duration * .35)
	_weight_tween.tween_property(player_node, "rotation:x", 0.0, duration * .65)
	pulse_kiro_glow(2.25 if pushing else 1.85)


func pulse_kiro_glow(energy: float) -> void:
	if not _kiro_powered or not _root or GameState.reduced_motion:
		return
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = _root.create_tween().set_parallel(true)
	for material in kiro_glow_materials:
		material.emission_energy_multiplier = energy
		_glow_tween.tween_property(material, "emission_energy_multiplier", 1.6, .5)


func play_oneshot(clip: StringName) -> void:
	if not player_animation or not player_animation.has_animation(clip):
		return
	play_player_animation(clip)
	await player_animation.animation_finished
	play_player_animation(&"Idle")


func play_boot_awakening() -> void:
	if not player_node:
		return
	if player_animation and player_animation.has_animation(&"Power_On"):
		play_player_animation(&"Power_On")
		return
	var initial_y := player_node.position.y
	player_node.position.y -= 0.12
	var tween := player_node.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_node, "position:y", initial_y, 0.75)
	play_player_animation(&"Idle")


func face_player(direction: Vector3i) -> void:
	if not player_node or (direction.x == 0 and direction.z == 0):
		return
	var target := atan2(float(direction.x), float(direction.z))
	var current := player_node.rotation.y
	var next := current + angle_difference(current, target)
	if _turn_tween and _turn_tween.is_valid():
		_turn_tween.kill()
	_turn_tween = player_node.create_tween()
	_turn_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_turn_tween.tween_property(player_node, "rotation:y", next, 0.09)


func spawn_eva_hologram(world_position: Vector3, look_at_target := Vector3.ZERO, stage := 4) -> Node3D:
	dismiss_eva_hologram(true)
	if _root == null:
		return null
	var scene := load(EVA_MODEL_PATH) as PackedScene
	if scene == null:
		return null
	var eva := scene.instantiate() as Node3D
	eva.name = "EVA_Hologram"
	eva.position = world_position + Vector3(0, 0.28, 0)
	eva.scale = Vector3.ONE * 0.01
	_face_toward(eva, world_position, look_at_target)
	var shader := load(HOLOGRAM_SHADER_PATH) as Shader
	if shader:
		var material := ShaderMaterial.new()
		material.shader = shader
		eva_hologram_material = material
		_apply_hologram_material(eva, material)
	if RENDER_QUALITY.local_lights_enabled():
		var light := OmniLight3D.new()
		light.light_color = Color(0.3, 0.85, 1.0)
		light.light_energy = 0.9
		light.omni_range = 1.8
		light.position = Vector3(0, 0.15, 0)
		eva.add_child(light)
	_root.add_child(eva)
	eva_hologram_node = eva
	_configure_eva_hologram(stage)
	var target_scale := Vector3.ONE * _eva_stage_scale(stage)
	var enter := _root.create_tween().set_parallel(true)
	enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(eva, "scale", target_scale, 0.5)
	enter.tween_property(eva, "position:y", world_position.y + 0.36, 0.5)
	_eva_bob_tween = _root.create_tween().set_loops()
	_eva_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_eva_bob_tween.tween_property(eva, "position:y", world_position.y + 0.40, 1.2)
	_eva_bob_tween.tween_property(eva, "position:y", world_position.y + 0.34, 1.2)
	return eva


func set_eva_hologram_stage(stage: int, world_position: Vector3, look_at_target := Vector3.ZERO) -> Node3D:
	stage = clampi(stage, 0, 4)
	if stage <= 0:
		dismiss_eva_hologram()
		return null
	if eva_hologram_node == null or not is_instance_valid(eva_hologram_node):
		return spawn_eva_hologram(world_position, look_at_target, stage)
	_face_toward(eva_hologram_node, world_position, look_at_target)
	_configure_eva_hologram(stage)
	if _root:
		_root.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(
			eva_hologram_node, "scale", Vector3.ONE * _eva_stage_scale(stage), 0.32)
	return eva_hologram_node


func spawn_elias_hologram(world_position: Vector3, look_at_target := Vector3.ZERO) -> Node3D:
	dismiss_elias_hologram(true)
	if _root == null:
		return null
	var scene := load(ELIAS_MODEL_PATH) as PackedScene
	if scene == null:
		return null
	var elias := scene.instantiate() as Node3D
	elias.name = "EliasHologram"
	elias.position = world_position + Vector3(0, 0.36, 0)
	elias.scale = Vector3.ONE * 0.01
	_face_toward(elias, world_position, look_at_target)
	var shader := load(HOLOGRAM_SHADER_PATH) as Shader
	if shader:
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("hologram_color", Color(1.0, 0.62, 0.18, 0.72))
		material.set_shader_parameter("rim_color", Color(1.0, 0.85, 0.40, 0.95))
		material.set_shader_parameter("emission_energy", 1.4)
		material.set_shader_parameter("scanline_frequency", 70.0)
		material.set_shader_parameter("glitch_strength", 0.08)
		_apply_hologram_material(elias, material)
	_root.add_child(elias)
	elias_hologram_node = elias
	var enter := _root.create_tween().set_parallel(true)
	enter.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	enter.tween_property(elias, "scale", Vector3.ONE * 0.16, 0.45)
	enter.tween_property(elias, "position:y", world_position.y + 0.42, 0.45)
	_elias_bob_tween = _root.create_tween().set_loops()
	_elias_bob_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_elias_bob_tween.tween_property(elias, "position:y", world_position.y + 0.46, 1.35)
	_elias_bob_tween.tween_property(elias, "position:y", world_position.y + 0.39, 1.35)
	return elias


func dismiss_eva_hologram(immediate := false) -> void:
	if _eva_bob_tween and _eva_bob_tween.is_valid():
		_eva_bob_tween.kill()
	_eva_bob_tween = null
	if not eva_hologram_node or not is_instance_valid(eva_hologram_node):
		eva_hologram_node = null
		return
	var target := eva_hologram_node
	eva_hologram_node = null
	if immediate:
		target.queue_free()
		return
	var tween := target.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", Vector3(0.01, 0.8, 0.01), 0.4)
	tween.tween_property(target, "position:y", target.position.y - 0.2, 0.4)
	tween.finished.connect(func() -> void:
		if is_instance_valid(target):
			target.queue_free())


func dismiss_elias_hologram(immediate := false) -> void:
	if _elias_bob_tween and _elias_bob_tween.is_valid():
		_elias_bob_tween.kill()
	_elias_bob_tween = null
	if not elias_hologram_node or not is_instance_valid(elias_hologram_node):
		elias_hologram_node = null
		return
	var target := elias_hologram_node
	elias_hologram_node = null
	if immediate:
		target.queue_free()
		return
	var tween := target.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(target, "scale", Vector3(0.01, 0.8, 0.01), 0.38)
	tween.tween_property(target, "position:y", target.position.y - 0.18, 0.38)
	tween.finished.connect(func() -> void:
		if is_instance_valid(target):
			target.queue_free())


func _collect_kiro_glow_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			for surface in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.get_active_material(surface)
				if source is StandardMaterial3D:
					var material := source.duplicate() as StandardMaterial3D
					mesh_instance.set_surface_override_material(surface, material)
					var name := material.resource_name.to_lower()
					if "glow" in name or "cyan" in name or material.emission_enabled:
						kiro_glow_materials.append(material)
	for child in node.get_children():
		_collect_kiro_glow_materials(child)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found:
			return found
	return null


func _build_player_procedural(parent: Node3D, position: Vector3, player_material: Material, accent_material: Material) -> Node3D:
	player_visual_offset = Vector3.ZERO
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	MeshFactory.box(root, Vector3(-0.13, -0.23, 0), Vector3(0.15, 0.28, 0.16), player_material)
	MeshFactory.box(root, Vector3(0.13, -0.23, 0), Vector3(0.15, 0.28, 0.16), player_material)
	MeshFactory.box(root, Vector3(0, 0.02, 0), Vector3(0.52, 0.44, 0.34), player_material)
	MeshFactory.box(root, Vector3(0, 0.05, 0.18), Vector3(0.16, 0.16, 0.02), accent_material)
	MeshFactory.box(root, Vector3(-0.34, 0.02, 0), Vector3(0.12, 0.34, 0.14), player_material)
	MeshFactory.box(root, Vector3(0.34, 0.02, 0), Vector3(0.12, 0.34, 0.14), player_material)
	MeshFactory.box(root, Vector3(0, 0.28, 0), Vector3(0.16, 0.08, 0.16), accent_material)
	MeshFactory.box(root, Vector3(0, 0.42, 0), Vector3(0.36, 0.30, 0.30), player_material)
	MeshFactory.box(root, Vector3(-0.08, 0.44, 0.16), Vector3(0.08, 0.08, 0.03), accent_material)
	MeshFactory.box(root, Vector3(0.08, 0.44, 0.16), Vector3(0.08, 0.08, 0.03), accent_material)
	MeshFactory.cylinder(root, Vector3(0, 0.66, 0), 0.02, 0.14, accent_material)
	MeshFactory.sphere(root, Vector3(0, 0.75, 0), 0.05, accent_material)
	return root


func _add_player_ground_ring(model: Node3D) -> void:
	var color := GameState.kiro_glow_color() if bool(GameState.echo_chamber.get("tidal_equipped", false)) and bool(GameState.echo_chamber.get("tidal_unlocked", false)) else COLOR_PLAYER
	var material := MeshFactory.mat(color, 1.3)
	_ground_ring_material = material
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.55)
	var inverse_scale := 1.0 / KIRO_MODEL_SCALE
	MeshFactory.torus(model, Vector3(0, 0.03 * inverse_scale, 0), 0.30 * inverse_scale, 0.38 * inverse_scale, material)


func _face_toward(node: Node3D, source_position: Vector3, target_position: Vector3) -> void:
	if target_position == Vector3.ZERO:
		return
	var direction := target_position - source_position
	if direction.x != 0.0 or direction.z != 0.0:
		node.rotation.y = atan2(direction.x, direction.z)


func _eva_stage_scale(stage: int) -> float:
	match clampi(stage, 1, 4):
		1: return 0.09
		2: return 0.12
		3: return 0.15
		_: return 0.18


func _configure_eva_hologram(stage: int) -> void:
	if eva_hologram_material == null:
		return
	var alpha := float([0.0, 0.22, 0.38, 0.58, 0.76][clampi(stage, 0, 4)])
	var emission := float([0.0, 0.85, 1.05, 1.30, 1.60][clampi(stage, 0, 4)])
	var glitch := float([0.0, 0.34, 0.24, 0.14, 0.06][clampi(stage, 0, 4)])
	eva_hologram_material.set_shader_parameter("hologram_color", Color(0.18, 0.75, 1.0, alpha))
	eva_hologram_material.set_shader_parameter("rim_color", Color(0.78, 0.35, 1.0, minf(1.0, alpha + 0.18)))
	eva_hologram_material.set_shader_parameter("emission_energy", emission)
	eva_hologram_material.set_shader_parameter("scanline_frequency", 100.0 - float(stage) * 2.5)
	eva_hologram_material.set_shader_parameter("flicker_amount", 0.18 - float(stage) * 0.025)
	eva_hologram_material.set_shader_parameter("glitch_strength", glitch)


func _apply_hologram_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_hologram_material(child, material)
