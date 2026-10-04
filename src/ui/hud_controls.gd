class_name HudControls
extends Control

const HUD_STYLE = preload("res://src/ui/hud_style.gd")

signal undo_requested
signal restart_requested
signal menu_requested
signal pause_requested
signal bridge_requested
signal hint_requested

const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)
const ICON_UNDO := preload("res://assets/ui/icons/undo.svg")
const ICON_RESTART := preload("res://assets/ui/icons/restart.svg")
const ICON_BRIDGE := preload("res://assets/ui/icons/bridge.svg")
const ICON_MENU := preload("res://assets/ui/icons/menu.svg")
const ICON_PAUSE := preload("res://assets/ui/icons/pause.svg")

var undo_button: Button
var restart_button: Button
var bridge_button: Button
var menu_button: Button
var hint_button: Button
var pause_button: Button

var _buttons: Array[Button] = []
var _accents: Dictionary = {}
var _compact := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	undo_button = get_node("UndoButton")
	restart_button = get_node("RestartButton")
	bridge_button = get_node("BridgeButton")
	menu_button = get_node("MenuButton")
	hint_button = get_node("HintButton")
	pause_button = get_node("PauseButton")
	_configure_button(undo_button, " Hoàn tác", ICON_UNDO, COLOR_CYAN)
	_configure_button(restart_button, " Chơi lại", ICON_RESTART, COLOR_ORANGE)
	_configure_button(bridge_button, " Triển khai cầu", ICON_BRIDGE, COLOR_ORANGE)
	_configure_button(menu_button, " Menu", ICON_MENU, COLOR_CYAN)
	_configure_button(hint_button, " Gợi ý", null, Color(1.0, 0.78, 0.12))
	_configure_button(pause_button, " Tạm dừng", ICON_PAUSE, COLOR_CYAN)
	bridge_button.visible = false
	undo_button.pressed.connect(func() -> void: undo_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	bridge_button.pressed.connect(func() -> void: bridge_requested.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	hint_button.pressed.connect(func() -> void: hint_requested.emit())
	pause_button.pressed.connect(func() -> void: pause_requested.emit())


func set_bridge_available(available: bool) -> void:
	bridge_button.visible = available
	if available:
		bridge_button.text = " Triển khai cầu"


func set_hint_available(available: bool) -> void:
	hint_button.visible = available


func apply_accessibility(high_contrast: bool) -> void:
	for button in _buttons:
		HUD_STYLE.apply_button(button, _accents.get(button.get_instance_id(), COLOR_CYAN), _compact, high_contrast)


func layout(viewport_size: Vector2, compact: bool) -> void:
	_compact = compact
	var edge := clampf(minf(viewport_size.x, viewport_size.y) * 0.035, 12.0, 28.0)
	var bottom_margin := 12.0 if compact else 24.0
	var bottom_height := 54.0 if compact else 56.0
	if compact:
		var gap := 7.0
		var count := 3 if bridge_button.visible else 2
		var available := maxf(180.0, viewport_size.x - edge * 2.0)
		var width := maxf(72.0, minf(132.0, (available - gap * float(count - 1)) / float(count)))
		var total := width * float(count) + gap * float(count - 1)
		var left := maxf(edge, (viewport_size.x - total) * 0.5)
		_position_bottom(undo_button, left, width, bottom_height, bottom_margin)
		if count == 3:
			_position_bottom(bridge_button, left + width + gap, width, bottom_height, bottom_margin)
			_position_bottom(restart_button, left + (width + gap) * 2.0, width, bottom_height, bottom_margin)
		else:
			_position_bottom(restart_button, left + width + gap, width, bottom_height, bottom_margin)
			_position_center_bottom(bridge_button, width, bottom_height, bottom_margin)
		_set_compact_text(undo_button, true)
		_set_compact_text(restart_button, true)
		_set_compact_text(bridge_button, true)
	else:
		_position_bottom(undo_button, edge, 130.0, bottom_height, bottom_margin)
		_position_bottom(restart_button, viewport_size.x - edge - 130.0, 130.0, bottom_height, bottom_margin)
		_position_center_bottom(bridge_button, 150.0, bottom_height, bottom_margin)
		_set_compact_text(undo_button, false)
		_set_compact_text(restart_button, false)
		_set_compact_text(bridge_button, false)

	menu_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu_button.offset_left = edge
	menu_button.offset_top = 10.0
	menu_button.offset_right = edge + (56.0 if compact else 110.0)
	menu_button.offset_bottom = menu_button.offset_top + (52.0 if compact else 46.0)
	menu_button.custom_minimum_size = Vector2(menu_button.offset_right - menu_button.offset_left, menu_button.offset_bottom - menu_button.offset_top)
	_set_compact_text(menu_button, compact)
	menu_button.tooltip_text = "Menu"

	hint_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint_button.offset_left = edge
	hint_button.offset_top = 68.0 if compact else 64.0
	hint_button.offset_right = edge + (56.0 if compact else 110.0)
	hint_button.offset_bottom = hint_button.offset_top + (52.0 if compact else 46.0)
	hint_button.custom_minimum_size = Vector2(hint_button.offset_right - hint_button.offset_left, hint_button.offset_bottom - hint_button.offset_top)
	_set_compact_text(hint_button, compact, "?")
	hint_button.tooltip_text = "Gợi ý"

	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -(edge + (56.0 if compact else 125.0))
	pause_button.offset_right = -edge
	pause_button.offset_top = 10.0
	pause_button.offset_bottom = pause_button.offset_top + (52.0 if compact else 46.0)
	pause_button.custom_minimum_size = Vector2(pause_button.offset_right - pause_button.offset_left, pause_button.offset_bottom - pause_button.offset_top)
	_set_compact_text(pause_button, compact)
	pause_button.tooltip_text = "Tạm dừng"
	apply_accessibility(GameState.high_contrast)


func _configure_button(button: Button, text: String, icon: Texture2D, accent: Color) -> void:
	button.text = text
	button.icon = icon
	button.expand_icon = true
	button.set_meta("wide_text", text)
	_buttons.append(button)
	_accents[button.get_instance_id()] = accent
	HUD_STYLE.apply_button(button, accent, false, GameState.high_contrast)


func _position_bottom(button: Button, left: float, width: float, height: float, bottom_margin: float) -> void:
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left
	button.offset_right = left + width
	button.offset_top = -bottom_margin - height
	button.offset_bottom = -bottom_margin
	button.custom_minimum_size = Vector2(width, height)


func _position_center_bottom(button: Button, width: float, height: float, bottom_margin: float) -> void:
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = -width * 0.5
	button.offset_right = width * 0.5
	button.offset_top = -bottom_margin - height
	button.offset_bottom = -bottom_margin
	button.custom_minimum_size = Vector2(width, height)


func _set_compact_text(button: Button, compact: bool, compact_text := "") -> void:
	button.text = compact_text if compact else str(button.get_meta("wide_text", button.text))
