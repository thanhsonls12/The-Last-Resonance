class_name EchoCameraController
extends Node3D

const ROTATE_TIME := 0.2
const BOARD_FOV := 48.0
const PORTRAIT_FOV_MAX := 62.0
const PORTRAIT_ASPECT_REFERENCE := 1.0

# Base camera framing and zoom bounds
const BASE_PITCH := -43.0
const ZOOM_FOV_MIN_DELTA := -10.0
const ZOOM_FOV_MAX_DELTA := 12.0

# Dynamic follow / parallax configuration
const FOLLOW_LERP_SPEED := 4.5
const FOLLOW_MAX_LEAD := 0.45

# Multi-layer vertical depth tilt
const LAYER_PITCH_OFFSET := -1.8

var camera: Camera3D
var yaw := PI * 0.25
var _impulse_tween: Tween
var _layer_tween: Tween
var active_layer := 0
var _board_framing_active := false

# Base targets determined by board bounds
var _board_center := Vector3.ZERO
var _base_cam_pos := Vector3(0, 8, 8)
var _base_fov := BOARD_FOV
var _user_zoom_delta := 0.0

# Player tracking
var _player_world_pos := Vector3.ZERO
var _player_lead_offset := Vector3.ZERO
var _has_player := false

# Trauma-based shake
var _trauma := 0.0
var _shake_noise: FastNoiseLite
var _shake_time := 0.0


func setup() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 8, 8)
	camera.rotation_degrees.x = BASE_PITCH
	camera.fov = BOARD_FOV
	camera.current = true
	rotation.y = yaw

	_shake_noise = FastNoiseLite.new()
	_shake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shake_noise.seed = 1337
	_shake_noise.frequency = 4.0

	if get_viewport() != null and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not _board_framing_active or GameState.reduced_motion:
		return
	if event is InputEventMouseButton and event.is_pressed():
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			adjust_zoom(-1.5)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			adjust_zoom(1.5)
			get_viewport().set_input_as_handled()


func adjust_zoom(delta_fov: float) -> void:
	_user_zoom_delta = clampf(_user_zoom_delta + delta_fov, ZOOM_FOV_MIN_DELTA, ZOOM_FOV_MAX_DELTA)
	if camera != null and _board_framing_active:
		camera.fov = clampf(_base_fov + _user_zoom_delta, 28.0, 75.0)


func reset_zoom() -> void:
	_user_zoom_delta = 0.0
	_apply_board_fov()


func _process(delta: float) -> void:
	_process_player_follow(delta)
	_process_trauma_shake(delta)


func set_player_focus(world_pos: Vector3) -> void:
	_player_world_pos = world_pos
	_has_player = true


func _process_player_follow(delta: float) -> void:
	if not _board_framing_active or not _has_player or GameState.reduced_motion:
		_player_lead_offset = _player_lead_offset.lerp(Vector3.ZERO, delta * FOLLOW_LERP_SPEED)
	else:
		var diff := _player_world_pos - _board_center
		var target_offset := Vector3(
			clampf(diff.x * 0.12, -FOLLOW_MAX_LEAD, FOLLOW_MAX_LEAD),
			0.0,
			clampf(diff.z * 0.12, -FOLLOW_MAX_LEAD, FOLLOW_MAX_LEAD)
		)
		_player_lead_offset = _player_lead_offset.lerp(target_offset, delta * FOLLOW_LERP_SPEED)

	if _board_framing_active and camera != null:
		var layer_pitch := float(active_layer) * LAYER_PITCH_OFFSET
		camera.rotation_degrees.x = BASE_PITCH + layer_pitch
		camera.position.x = _base_cam_pos.x + _player_lead_offset.x
		camera.position.y = _base_cam_pos.y
		camera.position.z = _base_cam_pos.z + _player_lead_offset.z


func _process_trauma_shake(delta: float) -> void:
	if not camera:
		return
	if GameState.reduced_motion or _trauma <= 0.001:
		_trauma = 0.0
		if _impulse_tween == null or not _impulse_tween.is_valid():
			camera.h_offset = 0.0
			camera.v_offset = 0.0
			camera.rotation_degrees.z = 0.0
		return

	_shake_time += delta * 30.0
	var shake := _trauma * _trauma
	var sample_x := _shake_noise.get_noise_2d(_shake_time, 0.0)
	var sample_y := _shake_noise.get_noise_2d(0.0, _shake_time)
	var sample_roll := _shake_noise.get_noise_2d(_shake_time, _shake_time)

	camera.h_offset = sample_x * 0.18 * shake
	camera.v_offset = sample_y * 0.14 * shake
	camera.rotation_degrees.z = sample_roll * 1.6 * shake

	_trauma = maxf(0.0, _trauma - delta * 1.8)


func reset_board_yaw() -> void:
	yaw = PI * 0.25
	rotation.y = yaw


func fit_to_cells(cells: Dictionary) -> void:
	if cells.is_empty():
		return
	var min_cell := Vector3i(999999999, 0, 999999999)
	var max_cell := Vector3i(-999999999, 0, -999999999)
	for cell in cells.keys():
		min_cell.x = mini(min_cell.x, cell.x)
		max_cell.x = maxi(max_cell.x, cell.x)
		min_cell.z = mini(min_cell.z, cell.z)
		max_cell.z = maxi(max_cell.z, cell.z)

	_board_center = Vector3(
		(min_cell.x + max_cell.x) * 0.5 + 0.5,
		0,
		(min_cell.z + max_cell.z) * 0.5 + 0.5)
	position = _board_center
	var span: float = max(
		float(max_cell.x - min_cell.x),
		float(max_cell.z - min_cell.z)) + 2.0
	_base_cam_pos = Vector3(0, span * 0.62, span * 0.66)
	camera.position = _base_cam_pos
	_board_framing_active = true
	_user_zoom_delta = 0.0
	_apply_board_fov()
	yaw = PI * 0.25
	rotation.y = yaw
	active_layer = 0


static func board_fov_for_aspect(aspect: float) -> float:
	if aspect <= 0.0:
		return BOARD_FOV
	var portrait_delta := maxf(0.0, PORTRAIT_ASPECT_REFERENCE - aspect)
	return clampf(BOARD_FOV + portrait_delta * 14.0, BOARD_FOV, PORTRAIT_FOV_MAX)


func _apply_board_fov() -> void:
	if camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2.ZERO
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		_base_fov = BOARD_FOV
	else:
		_base_fov = board_fov_for_aspect(viewport_size.x / viewport_size.y)
	camera.fov = clampf(_base_fov + _user_zoom_delta, 28.0, 75.0)


func _on_viewport_size_changed() -> void:
	if _board_framing_active:
		_apply_board_fov()


func focus_layer(layer: int, animated := true) -> void:
	if _layer_tween != null and _layer_tween.is_valid():
		_layer_tween.kill()
	active_layer = maxi(0, layer)
	var target_y := float(active_layer) * 1.15
	if animated and not GameState.reduced_motion:
		_layer_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_layer_tween.tween_property(self, "position:y", target_y, ROTATE_TIME * 2.0)
	else:
		position.y = target_y


## Reframe the camera around one playable floor. Sequential levels use this
## instead of fitting both floors at once, keeping the active puzzle readable.
func focus_cells(cells: Dictionary, layer: int, animated := true) -> void:
	if cells.is_empty():
		focus_layer(layer, animated)
		return
	if _layer_tween != null and _layer_tween.is_valid():
		_layer_tween.kill()
	active_layer = maxi(0, layer)
	var min_cell := Vector3i(999999999, 0, 999999999)
	var max_cell := Vector3i(-999999999, 0, -999999999)
	for cell in cells.keys():
		min_cell.x = mini(min_cell.x, cell.x)
		max_cell.x = maxi(max_cell.x, cell.x)
		min_cell.z = mini(min_cell.z, cell.z)
		max_cell.z = maxi(max_cell.z, cell.z)
	var span: float = max(
		float(max_cell.x - min_cell.x),
		float(max_cell.z - min_cell.z)) + 2.0
	_board_center = Vector3(
		(min_cell.x + max_cell.x) * 0.5 + 0.5,
		float(active_layer) * 1.15,
		(min_cell.z + max_cell.z) * 0.5 + 0.5)
	_base_cam_pos = Vector3(0, span * 0.62, span * 0.66)
	_board_framing_active = true
	_user_zoom_delta = 0.0

	var target_pitch := BASE_PITCH + float(active_layer) * LAYER_PITCH_OFFSET

	if animated and not GameState.reduced_motion:
		_base_fov = board_fov_for_aspect(_viewport_aspect())
		_layer_tween = create_tween().set_parallel(true)
		_layer_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_layer_tween.tween_property(self, "position", _board_center, ROTATE_TIME * 3.5)
		_layer_tween.tween_property(camera, "position", _base_cam_pos, ROTATE_TIME * 3.5)
		_layer_tween.tween_property(camera, "rotation_degrees:x", target_pitch, ROTATE_TIME * 3.5)
		_layer_tween.tween_property(camera, "fov", _base_fov, ROTATE_TIME * 3.5)
	else:
		position = _board_center
		camera.position = _base_cam_pos
		camera.rotation_degrees.x = target_pitch
		_apply_board_fov()


func set_close_up(player_pos: Vector3) -> void:
	# Position camera in front of Kiro in the clear north corridor looking straight at Kiro
	_board_framing_active = false
	_trauma = 0.0
	position = player_pos + Vector3(0, 0.45, 0)
	camera.position = Vector3(0, 0.30, -2.40)
	camera.rotation_degrees = Vector3(-6.0, 180.0, 0.0)
	camera.fov = 34.0
	yaw = 0.0
	rotation.y = 0.0


func play_intro_zoom(cells: Dictionary) -> Tween:
	if cells.is_empty():
		return null
	var min_cell := Vector3i(999999999, 0, 999999999)
	var max_cell := Vector3i(-999999999, 0, -999999999)
	for cell in cells.keys():
		min_cell.x = mini(min_cell.x, cell.x)
		max_cell.x = maxi(max_cell.x, cell.x)
		min_cell.z = mini(min_cell.z, cell.z)
		max_cell.z = maxi(max_cell.z, cell.z)
	_board_center = Vector3(
		(min_cell.x + max_cell.x) * 0.5 + 0.5,
		0,
		(min_cell.z + max_cell.z) * 0.5 + 0.5)
	var span: float = max(
		float(max_cell.x - min_cell.x),
		float(max_cell.z - min_cell.z)) + 2.0
	_base_cam_pos = Vector3(0, span * 0.62, span * 0.66)
	_base_fov = board_fov_for_aspect(_viewport_aspect())
	_user_zoom_delta = 0.0
	yaw = PI * 0.25
	_board_framing_active = true
	_trauma = 0.0

	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", _board_center, 1.5)
	tw.tween_property(self, "rotation:y", yaw, 1.5)
	tw.tween_property(camera, "position", _base_cam_pos, 1.5)
	tw.tween_property(camera, "rotation_degrees", Vector3(BASE_PITCH, 0.0, 0.0), 1.5)
	tw.tween_property(camera, "fov", _base_fov, 1.5)
	return tw


func play_victory_focus(player_pos: Vector3) -> Tween:
	_board_framing_active = false
	_trauma = 0.0
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var target_center := player_pos + Vector3(0, 0.45, 0)
	var target_cam_pos := Vector3(0, 0.30, -2.40)
	yaw = 0.0
	tw.tween_property(self, "position", target_center, 0.9)
	tw.tween_property(self, "rotation:y", yaw, 0.9)
	tw.tween_property(camera, "position", target_cam_pos, 0.9)
	tw.tween_property(camera, "rotation_degrees", Vector3(-6.0, 180.0, 0.0), 0.9)
	tw.tween_property(camera, "fov", 34.0, 0.9)
	return tw


func rotate_step(direction: int) -> void:
	yaw += direction * PI * 0.5
	if GameState.reduced_motion:
		rotation.y = yaw
		return
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "rotation:y", yaw, ROTATE_TIME)


func play_impulse(strength := 0.12) -> void:
	if not camera:
		return
	if GameState.reduced_motion:
		return
	# Add trauma for natural noise-based shake
	var trauma_add := clampf(strength * 2.8, 0.15, 0.75)
	_trauma = clampf(_trauma + trauma_add, 0.0, 1.0)


func drag_pixels(delta_x: float) -> void:
	yaw -= delta_x * 0.008
	rotation.y = yaw


func _viewport_aspect() -> float:
	if get_viewport() == null:
		return 0.0
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y <= 0.0:
		return 0.0
	return viewport_size.x / viewport_size.y


func screen_to_grid(screen_pos: Vector2) -> Variant:
	if camera == null:
		return null
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, float(active_layer) * 1.15 + 0.04).intersects_ray(origin, direction)
	if hit == null:
		return null
	# Screen-to-grid hits world coordinates directly
	return Vector3i(roundi(hit.x), 0, roundi(hit.z))
