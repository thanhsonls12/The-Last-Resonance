class_name EchoCameraController
extends Node3D

const ROTATE_TIME := 0.2

var camera: Camera3D
var yaw := PI * 0.25
var _impulse_tween: Tween


func setup() -> void:
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(0, 8, 8)
	camera.rotation_degrees.x = -43
	camera.fov = 48.0
	camera.current = true
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
	camera.fov = 48.0
	yaw = PI * 0.25
	rotation.y = yaw


func set_close_up(player_pos: Vector3) -> void:
	# Position camera in front of Kiro in the clear north corridor looking straight at Kiro
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
	
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", target_center, 1.5)
	tw.tween_property(self, "rotation:y", yaw, 1.5)
	tw.tween_property(camera, "position", target_cam_pos, 1.5)
	tw.tween_property(camera, "rotation_degrees", Vector3(-43.0, 0.0, 0.0), 1.5)
	tw.tween_property(camera, "fov", 48.0, 1.5)
	return tw


func play_victory_focus(player_pos: Vector3) -> Tween:
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
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "rotation:y", yaw, ROTATE_TIME)


func play_impulse(strength := 0.12) -> void:
	if not camera:
		return
	if _impulse_tween and _impulse_tween.is_valid():
		_impulse_tween.kill()
	camera.h_offset = strength
	camera.v_offset = -strength * 0.45
	_impulse_tween = create_tween().set_parallel(true)
	_impulse_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_impulse_tween.tween_property(camera, "h_offset", 0.0, 0.32)
	_impulse_tween.tween_property(camera, "v_offset", 0.0, 0.32)


func drag_pixels(delta_x: float) -> void:
	yaw -= delta_x * 0.008
	rotation.y = yaw


func screen_to_grid(screen_pos: Vector2) -> Variant:
	var origin := camera.project_ray_origin(screen_pos)
	var direction := camera.project_ray_normal(screen_pos)
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(origin, direction)
	if hit == null:
		return null
	return Vector3i(roundi(hit.x), 0, roundi(hit.z))
