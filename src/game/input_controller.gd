class_name GameplayInput
extends Node

## Touch/keyboard input for the gameplay scene, split out of main.gd so the
## scene controller only owns lifecycle and story. Emits intents; main.gd decides.

signal step_requested(dir: Vector3i)
signal undo_requested
signal restart_requested
signal bridge_requested
signal hint_requested
signal pause_requested
signal camera_rotate_requested(direction: int)
signal tap_requested(screen_pos: Vector2)

const TAP_MAX_MS := 260
const TAP_MAX_PX := 14.0
const DRAG_START_MS := 180
const SWIPE_MAX_MS := 450

var camera_controller: EchoCameraController
var _dragging := false
var _moved_far := false
var _press_pos := Vector2.ZERO
var _press_ms := 0


func setup(p_camera_controller: EchoCameraController) -> void:
	camera_controller = p_camera_controller
	_ensure_input_actions()


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	for key in keys:
		var input_event := InputEventKey.new()
		input_event.physical_keycode = key
		InputMap.action_add_event(action, input_event)


func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("undo_move", [KEY_Z, KEY_U])
	_add_key_action("restart_level", [KEY_R])
	_add_key_action("rotate_camera_left", [KEY_Q])
	_add_key_action("rotate_camera_right", [KEY_E])
	_add_key_action("rotate_bridge", [KEY_F, KEY_SPACE])
	_add_key_action("show_hint", [KEY_H])
	_add_key_action("pause_game", [KEY_ESCAPE])


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _dragging:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event.is_action_pressed("move_left"):
		step_requested.emit(camera_relative_dir(Vector3i(-1, 0, 0)))
	elif event.is_action_pressed("move_right"):
		step_requested.emit(camera_relative_dir(Vector3i(1, 0, 0)))
	elif event.is_action_pressed("move_up"):
		step_requested.emit(camera_relative_dir(Vector3i(0, 0, -1)))
	elif event.is_action_pressed("move_down"):
		step_requested.emit(camera_relative_dir(Vector3i(0, 0, 1)))
	elif event.is_action_pressed("undo_move"):
		undo_requested.emit()
	elif event.is_action_pressed("restart_level"):
		restart_requested.emit()
	elif event.is_action_pressed("rotate_camera_left"):
		camera_rotate_requested.emit(-1)
	elif event.is_action_pressed("rotate_camera_right"):
		camera_rotate_requested.emit(1)
	elif event.is_action_pressed("rotate_bridge"):
		bridge_requested.emit()
	elif event.is_action_pressed("show_hint"):
		hint_requested.emit()
	elif event.is_action_pressed("pause_game"):
		pause_requested.emit()


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_dragging = true
		_moved_far = false
		_press_pos = mb.position
		_press_ms = Time.get_ticks_msec()
		return
	var elapsed: int = Time.get_ticks_msec() - _press_ms
	var drag_dist: float = mb.position.distance_to(_press_pos)
	if _dragging and drag_dist < TAP_MAX_PX and elapsed < TAP_MAX_MS:
		tap_requested.emit(mb.position)
	elif _dragging and elapsed < SWIPE_MAX_MS and drag_dist >= 16.0 and not _moved_far:
		var delta: Vector2 = mb.position - _press_pos
		var swipe_dir := Vector3i(1, 0, 0) if delta.x > 0 else Vector3i(-1, 0, 0)
		if abs(delta.y) >= abs(delta.x):
			swipe_dir = Vector3i(0, 0, 1) if delta.y > 0 else Vector3i(0, 0, -1)
		step_requested.emit(camera_relative_dir(swipe_dir))
	_dragging = false


func _handle_mouse_motion(mm: InputEventMouseMotion) -> void:
	if mm.position.distance_to(_press_pos) > TAP_MAX_PX:
		if Time.get_ticks_msec() - _press_ms > DRAG_START_MS:
			_moved_far = true
			camera_controller.drag_pixels(mm.relative.x)


## Map a screen-relative input to a world grid axis so controls track the
## camera after Q/E rotation. Default view is a quarter turn (PI*0.25).
func camera_relative_dir(base: Vector3i) -> Vector3i:
	var steps := int(round((camera_controller.yaw - PI * 0.25) / (PI * 0.5)))
	var result := base
	var count := ((steps % 4) + 4) % 4
	for i in count:
		result = Vector3i(result.z, 0, -result.x)
	return result
