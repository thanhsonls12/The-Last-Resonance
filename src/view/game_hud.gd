class_name GameHud
extends CanvasLayer

signal undo_requested
signal restart_requested
signal menu_requested
signal pause_requested
signal resume_requested
signal bridge_requested
signal hint_requested
signal next_level_requested

const STATUS_SCENE := preload("res://scenes/ui/hud_status_panel.tscn")
const CONTROLS_SCENE := preload("res://scenes/ui/hud_controls.tscn")
const WIN_SCENE := preload("res://scenes/ui/hud_win_panel.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/hud_pause_panel.tscn")
const SETTINGS_SCENE := preload("res://scenes/ui/settings.tscn")

var status
var controls
var win_panel
var pause_panel
var settings_modal: Control
var _compact_layout := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	status = STATUS_SCENE.instantiate()
	controls = CONTROLS_SCENE.instantiate()
	win_panel = WIN_SCENE.instantiate()
	pause_panel = PAUSE_SCENE.instantiate()
	add_child(status)
	add_child(controls)
	add_child(win_panel)
	add_child(pause_panel)
	_wire_signals()
	if not GameState.settings_changed.is_connected(_on_settings_changed):
		GameState.settings_changed.connect(_on_settings_changed)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_layout_for_viewport):
		get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_apply_accessibility()


func set_stats(level_name: String, moves: int, pushes: int, best_moves: int, par_moves: int = -1, hint_penalty := 0, three_star_max := 0) -> void:
	status.set_stats(level_name, moves, pushes, best_moves, par_moves, hint_penalty, three_star_max)


func set_floor(current_floor: int, floor_count: int) -> void:
	status.set_floor(current_floor, floor_count)


func set_floor_status(message: String) -> void:
	status.set_floor_status(message)


func set_core_progress(active: int, total: int) -> void:
	status.set_core_progress(active, total)


func set_energy_nodes(active: int, total: int) -> void:
	status.set_energy_nodes(active, total)


func set_fragment(fragment: String) -> void:
	status.set_fragment(fragment)


func set_lock_progress(active: int, total: int, open: bool) -> void:
	status.set_lock_progress(active, total, open)


func show_win(
		level_name: String,
		moves: int = -1,
		pushes: int = -1,
		best_moves: int = -1,
		par_moves: int = -1,
		next_button_text := "MÀN TIẾP THEO",
		completion_badge := "◆ NĂNG LƯỢNG ĐÃ KHÔI PHỤC ◆",
		hints_used: int = -1,
		run: Dictionary = {}) -> void:
	win_panel.show_result(
		level_name,
		moves,
		pushes,
		best_moves,
		par_moves,
		next_button_text,
		completion_badge,
		hints_used,
		run)


func hide_win() -> void:
	win_panel.hide_panel()


func set_bridge_available(available: bool) -> void:
	controls.set_bridge_available(available)
	_layout_for_viewport()


func set_hint_available(available: bool) -> void:
	controls.set_hint_available(available)
	if not available:
		clear_hint()


func set_hint_text(message: String, shown := true) -> void:
	status.set_hint_text(message, shown)


func clear_hint() -> void:
	status.clear_hint()


func set_paused(paused: bool) -> void:
	if not paused and is_instance_valid(settings_modal):
		settings_modal.queue_free()
	pause_panel.set_paused(paused)


func _wire_signals() -> void:
	controls.undo_requested.connect(func() -> void: undo_requested.emit())
	controls.restart_requested.connect(func() -> void: restart_requested.emit())
	controls.menu_requested.connect(func() -> void: menu_requested.emit())
	controls.pause_requested.connect(func() -> void: pause_requested.emit())
	controls.bridge_requested.connect(func() -> void: bridge_requested.emit())
	controls.hint_requested.connect(func() -> void: hint_requested.emit())
	pause_panel.resume_requested.connect(func() -> void: resume_requested.emit())
	pause_panel.restart_requested.connect(func() -> void: restart_requested.emit())
	pause_panel.menu_requested.connect(func() -> void: menu_requested.emit())
	pause_panel.settings_requested.connect(_on_settings_requested)
	win_panel.next_level_requested.connect(func() -> void: next_level_requested.emit())
	win_panel.restart_requested.connect(func() -> void: restart_requested.emit())
	win_panel.menu_requested.connect(func() -> void: menu_requested.emit())


func _on_settings_requested() -> void:
	if is_instance_valid(settings_modal):
		return
	pause_panel.visible = false
	settings_modal = SETTINGS_SCENE.instantiate()
	settings_modal.is_overlay = true
	settings_modal.closed.connect(func() -> void:
		pause_panel.visible = true)
	add_child(settings_modal)


func _on_settings_changed() -> void:
	_apply_accessibility()
	_layout_for_viewport()


func _apply_accessibility() -> void:
	var high := GameState.high_contrast
	status.apply_accessibility(high)
	controls.apply_accessibility(high)
	win_panel.apply_accessibility(high)
	pause_panel.apply_accessibility(high)


func _layout_for_viewport() -> void:
	if get_viewport() == null or status == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	_compact_layout = viewport_size.x < 760.0 or viewport_size.y < 560.0
	status.layout(viewport_size, _compact_layout)
	controls.layout(viewport_size, _compact_layout)
	win_panel.layout(viewport_size, _compact_layout)
	pause_panel.layout(viewport_size, _compact_layout)
