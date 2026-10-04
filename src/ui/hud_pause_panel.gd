class_name HudPausePanel
extends Control

const HUD_STYLE = preload("res://src/ui/hud_style.gd")

signal resume_requested
signal restart_requested
signal menu_requested
signal settings_requested

const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)
const ICON_RESTART := preload("res://assets/ui/icons/restart.svg")
const ICON_MENU := preload("res://assets/ui/icons/menu.svg")
const ICON_PLAY := preload("res://assets/ui/icons/play.svg")
const ICON_SETTINGS := preload("res://assets/ui/icons/settings.svg")

var card: PanelContainer
var badge: Label
var title: Label
var resume_button: Button
var restart_button: Button
var settings_button: Button
var menu_button: Button
var _buttons: Array[Button] = []
var _accents: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	card = get_node("Backdrop/Center/Card")
	badge = get_node("Backdrop/Center/Card/Margin/Content/Badge")
	title = get_node("Backdrop/Center/Card/Margin/Content/Title")
	resume_button = get_node("Backdrop/Center/Card/Margin/Content/ResumeButton")
	restart_button = get_node("Backdrop/Center/Card/Margin/Content/RestartButton")
	settings_button = get_node_or_null("Backdrop/Center/Card/Margin/Content/SettingsButton")
	if settings_button == null:
		settings_button = get_node("Backdrop/Center/Card/Margin/Content/AudioButton")
	menu_button = get_node("Backdrop/Center/Card/Margin/Content/MenuButton")
	_configure_button(resume_button, "  TIẾP TỤC", ICON_PLAY, COLOR_CYAN)
	_configure_button(restart_button, "  CHƠI LẠI", ICON_RESTART, COLOR_ORANGE)
	_configure_button(settings_button, "  CÀI ĐẶT", ICON_SETTINGS, COLOR_CYAN)
	_configure_button(menu_button, "  VỀ MENU", ICON_MENU, Color(0.55, 0.65, 0.80))
	badge.label_settings = HUD_STYLE.label_settings(12, Color(0.12, 0.82, 1.0))
	title.label_settings = HUD_STYLE.label_settings(26, Color.WHITE, 4, Color(0.02, 0.04, 0.08, 0.95), 6, Color(0.12, 0.82, 1.0, 0.45))
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	restart_button.pressed.connect(func() -> void:
		resume_requested.emit()
		restart_requested.emit())
	settings_button.pressed.connect(func() -> void: settings_requested.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	apply_accessibility(GameState.high_contrast)


func set_paused(paused: bool) -> void:
	visible = paused
	if not paused:
		return
	if GameState.reduced_motion:
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func apply_accessibility(high_contrast: bool) -> void:
	card.add_theme_stylebox_override("panel", HUD_STYLE.panel_style(Color(0.12, 0.82, 1.0, 0.85), high_contrast))
	badge.label_settings.font_color = Color.WHITE if high_contrast else Color(0.12, 0.82, 1.0)
	title.label_settings.outline_size = 9 if high_contrast else 4
	title.label_settings.outline_color = Color.BLACK if high_contrast else Color(0.02, 0.04, 0.08, 0.95)
	for button in _buttons:
		HUD_STYLE.apply_button(button, _accents.get(button.get_instance_id(), COLOR_CYAN), false, high_contrast)


func layout(viewport_size: Vector2, compact: bool) -> void:
	var width := minf(360.0, maxf(240.0, viewport_size.x - 24.0))
	card.custom_minimum_size = Vector2(width, 350.0 if compact else 360.0)
	var button_width := maxf(180.0, width - 56.0)
	for button in _buttons:
		button.custom_minimum_size.x = button_width


func _configure_button(button: Button, text: String, icon: Texture2D, accent: Color) -> void:
	button.text = text
	button.icon = icon
	button.expand_icon = true
	button.custom_minimum_size = Vector2(280, 44)
	_buttons.append(button)
	_accents[button.get_instance_id()] = accent
	HUD_STYLE.apply_button(button, accent, false, GameState.high_contrast)
