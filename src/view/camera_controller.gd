class_name EchoCameraController
extends Node3D

const ROTATE_TIME := 0.2
const BOARD_FOV := 48.0
const PORTRAIT_FOV_MAX := 62.0
const PORTRAIT_ASPECT_REFERENCE := 1.0

var camera: Camera3D
var yaw := PI * 0.25
var _impulse_tween: Tween
var _layer_tween: Tween
var active_layer := 0
var _board_framing_active := false


func setup() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 8, 8)
	camera.rotation_degrees.x = -43
	camera.fov = BOARD_FOV
	camera.current = true
	rotation.y = yaw
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


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
	position = Vector3(
		(min_cell.x + max_cell.x) * 0.5 + 0.5,
		0,
		(min_cell.z + max_cell.z) * 0.5 + 0.5)
	var span: float = max(
		float(max_cell.x - min_cell.x),
		float(max_cell.z - min_cell.z)) + 2.0
	camera.position = Vector3(0, span * 0.62, span * 0.66)
	_board_framing_active = true
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
		camera.fov = BOARD_FOV
		return
	camera.fov = board_fov_for_aspect(viewport_size.x / viewport_size.y)


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
	var target_center := Vector3(
		(min_cell.x + max_cell.x) * 0.5 + 0.5,
		float(active_layer) * 1.15,
		(min_cell.z + max_cell.z) * 0.5 + 0.5)
	var target_camera_position := Vector3(0, span * 0.62, span * 0.66)
	_board_framing_active = true
	if animated and not GameState.reduced_motion:
		_layer_tween = create_tween().set_parallel(true)
		_layer_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_layer_tween.tween_property(self, "position", target_center, ROTATE_TIME * 3.5)
		_layer_tween.tween_property(camera, "position", target_camera_position, ROTATE_TIME * 3.5)
		_layer_tween.tween_property(camera, "fov", board_fov_for_aspect(_viewport_aspect()), ROTATE_TIME * 3.5)
	else:
		position = target_center
		camera.position = target_camera_position
		_apply_board_fov()


func set_close_up(player_pos: Vector3) -> void:
	# Position camera in front of Kiro in the clear north corridor looking straight at Kiro
	_board_framing_active = false
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
	var target_center := Vector3(
		(min_cell.x + max_cell.x) * 0.5 + 0.5,
		0,
		(min_cell.z + max_cell.z) * 0.5 + 0.5)
	var span: float = max(
		float(max_cell.x - min_cell.x),
		float(max_cell.z - min_cell.z)) + 2.0
	var target_cam_pos := Vector3(0, span * 0.62, span * 0.66)
	yaw = PI * 0.25
	_board_framing_active = true
	
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", target_center, 1.5)
	tw.tween_property(self, "rotation:y", yaw, 1.5)
	tw.tween_property(camera, "position", target_cam_pos, 1.5)
	tw.tween_property(camera, "rotation_degrees", Vector3(-43.0, 0.0, 0.0), 1.5)
	tw.tween_property(camera, "fov", board_fov_for_aspect(_viewport_aspect()), 1.5)
	return tw


func play_victory_focus(player_pos: Vector3) -> Tween:
	_board_framing_active = false
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
	if _impulse_tween and _impulse_tween.is_valid():
		_impulse_tween.kill()
	if GameState.reduced_motion:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return
	camera.h_offset = strength
	camera.v_offset = -strength * 0.45
	_impulse_tween = create_tween().set_parallel(true)
	_impulse_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_impulse_tween.tween_property(camera, "h_offset", 0.0, 0.32)
	_impulse_tween.tween_property(camera, "v_offset", 0.0, 0.32)


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
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, float(active_layer) * 1.15 + 0.04).intersects_ray(origin, direction)
	if hit == null:
		return null
	return Vector3i(roundi(hit.x), 0, roundi(hit.z))
