class_name EchoCompanionDrone
extends Node3D

## Mote uses a Blender-authored body and wing clips, following Kiro's presentation.

const BOB_PERIOD := 2.6
const BOB_AMP := 0.06
const FOLLOW_SPEED := 5.0
const ROTATION_SPEED := 6.0
const ORBIT_RADIUS := 0.28
const ORBIT_HEIGHT := 0.85

var _drone_light: OmniLight3D

var _target_node: Node3D
var _idle_time := 0.0
var _mode := &"follow" # &"follow", &"hint", &"celebrate"
var _hint_world_target := Vector3.ZERO
var _celebrate_time := 0.0

var _glow_material: StandardMaterial3D
var _authored_animation: AnimationPlayer
var _idle_since := 0.0
var _last_target := Vector3.ZERO
var _perched := false
var _perch_skeleton: Skeleton3D
var _perch_bone := -1


func _ready() -> void:
	_build_visuals()


func _build_visuals() -> void:
	_build_authored_mote()


func _build_authored_mote() -> void:
	var model := (load("res://assets/models/echo_expansion/mote.glb") as PackedScene).instantiate() as Node3D
	model.name = "MoteModel"
	model.scale = Vector3.ONE * .5
	add_child(model)
	_authored_animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _authored_animation:
		_authored_animation.get_animation("Hover").loop_mode = Animation.LOOP_LINEAR
		_authored_animation.play("Hover")
	_glow_material = MeshFactory.mat(Color(.2, .88, 1), 1.2)
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			if mesh.get_active_material(surface).resource_name == "Tidal Signal":
				mesh.set_surface_override_material(surface, _glow_material)
	if RenderQuality.local_lights_enabled():
		_drone_light = OmniLight3D.new()
		_drone_light.light_color = Color(.3, .88, 1)
		_drone_light.light_energy = .3
		_drone_light.omni_range = 1.0
		add_child(_drone_light)


func setup_companion(target: Node3D) -> void:
	_target_node = target
	for skeleton in target.find_children("*", "Skeleton3D", true, false):
		_perch_skeleton = skeleton
		_perch_bone = skeleton.find_bone("upper_arm_r")
		break
	if is_instance_valid(_target_node):
		global_position = _target_node.global_position + Vector3(0.35, ORBIT_HEIGHT, -0.2)


func set_hint_focus(world_target: Vector3, active := true) -> void:
	_idle_since = 0
	_perched = false
	if _authored_animation:
		_authored_animation.play("Hover", .12)
	if not active:
		_mode = &"follow"
		_set_theme_color(Color(0.20, 0.88, 1.0))
		return

	_mode = &"hint"
	_hint_world_target = world_target + Vector3(0, 1.05, 0)
	# Đổi đèn sang màu vàng hổ phách đặc trưng của Hint
	_set_theme_color(Color(1.0, 0.82, 0.18))


func play_victory_cheer() -> void:
	if GameState.reduced_motion:
		_set_theme_color(Color(.25, 1, .65))
		return
	_mode = &"celebrate"
	_celebrate_time = 0.0
	_idle_since = 0
	_perched = false
	if _authored_animation:
		_authored_animation.play("Hover", .12)
	_set_theme_color(Color(0.25, 1.0, 0.65))


func _set_theme_color(color: Color) -> void:
	if _glow_material:
		_glow_material.albedo_color = color
		_glow_material.emission = color
	if _drone_light:
		_drone_light.light_color = color


func _process(delta: float) -> void:
	if _authored_animation:
		_authored_animation.speed_scale = 0.0 if GameState.reduced_motion else 1.0
	_idle_time += delta

	match _mode:
		&"follow":
			_process_follow(delta)
		&"hint":
			_process_hint(delta)
		&"celebrate":
			_process_celebrate(delta)


func _process_follow(delta: float) -> void:
	if not is_instance_valid(_target_node):
		return
	_idle_since = _idle_since + delta if _target_node.global_position.distance_to(_last_target) < .005 else 0.0
	_last_target = _target_node.global_position
	var perched := _idle_since > 3.0
	if perched != _perched and _authored_animation:
		_perched = perched
		_authored_animation.play("Perch" if perched else "Hover", .12)
		if GameState.reduced_motion:
			_authored_animation.seek(_authored_animation.get_animation("Perch").length if perched else 0.0, true)
	rotation.x = move_toward(rotation.x, 0.0, delta * 2.0)

	# Vị trí bay lơ lửng phía trên bên phải của Kiro
	var bob := 0.0 if GameState.reduced_motion or _idle_since > 3.0 else sin(_idle_time * (TAU / BOB_PERIOD)) * BOB_AMP
	var desired_pos := _target_node.global_position + (Vector3(.27, .69, -.08) if _idle_since > 3.0 else Vector3(ORBIT_RADIUS, ORBIT_HEIGHT + bob, -0.25))
	if _perched and is_instance_valid(_perch_skeleton) and _perch_bone >= 0:
		desired_pos = _perch_skeleton.global_transform * _perch_skeleton.get_bone_global_pose(_perch_bone).origin + Vector3(0, .14, 0)
	global_position = global_position.lerp(desired_pos, minf(1.0, delta * FOLLOW_SPEED))

	# Nhìn về hướng Kiro đang quay mặt
	var target_look := _target_node.global_position + Vector3(0, 0.35, 0)
	var forward := (target_look - global_position).normalized()
	if forward.length_squared() > 0.001:
		var target_rot_y := atan2(forward.x, forward.z) + PI
		rotation.y = lerp_angle(rotation.y, target_rot_y, delta * ROTATION_SPEED)


func _process_hint(delta: float) -> void:
	var bob := 0.0 if GameState.reduced_motion else sin(_idle_time * (TAU / 1.5)) * 0.04
	var target_pos := _hint_world_target + Vector3(0, bob, 0)
	global_position = global_position.lerp(target_pos, minf(1.0, delta * (FOLLOW_SPEED * 1.2)))
	# Nhìn thẳng xuống ô mục tiêu
	rotation.x = deg_to_rad(-85.0)


func _process_celebrate(delta: float) -> void:
	_celebrate_time += delta
	if _celebrate_time > 2.2:
		_mode = &"follow"
		_set_theme_color(Color(.2, .88, 1))
		return
	if not is_instance_valid(_target_node):
		return
	# Bay lượn tròn ăn mừng quanh Kiro
	var angle := _celebrate_time * 4.0
	var radius := 0.65
	var orbit_x := cos(angle) * radius
	var orbit_z := sin(angle) * radius
	var orbit_y := ORBIT_HEIGHT + sin(_celebrate_time * 5.0) * 0.15

	var target_pos := _target_node.global_position + Vector3(orbit_x, orbit_y, orbit_z)
	global_position = global_position.lerp(target_pos, minf(1.0, delta * 8.0))
	rotation.y = angle + PI * 0.5
