class_name HudWinPanel
extends Control

const HUD_STYLE = preload("res://src/ui/hud_style.gd")

signal next_level_requested
signal restart_requested
signal menu_requested

const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)
const ICON_PLAY := preload("res://assets/ui/icons/play.svg")
const ICON_RESTART := preload("res://assets/ui/icons/restart.svg")
const ICON_MENU := preload("res://assets/ui/icons/menu.svg")

var card: PanelContainer
var badge: Label
var title: Label
var level_label: Label
var stars_label: Label
var stats_label: Label
var next_button: Button
var restart_button: Button
var menu_button: Button
var _buttons: Array[Button] = []
var _accents: Dictionary = {}


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	card = get_node("Backdrop/Center/Card")
	badge = get_node("Backdrop/Center/Card/Content/Badge")
	title = get_node("Backdrop/Center/Card/Content/Title")
	level_label = get_node("Backdrop/Center/Card/Content/LevelLabel")
	stars_label = get_node("Backdrop/Center/Card/Content/StarsLabel")
	stats_label = get_node("Backdrop/Center/Card/Content/StatsLabel")
	next_button = get_node("Backdrop/Center/Card/Content/NextButton")
	restart_button = get_node("Backdrop/Center/Card/Content/RestartButton")
	menu_button = get_node("Backdrop/Center/Card/Content/MenuButton")
	badge.label_settings = HUD_STYLE.label_settings(12, Color(0.35, 0.92, 1.0, 0.95))
	title.label_settings = HUD_STYLE.label_settings(36, Color(1.0, 0.80, 0.24), 6, Color(0.10, 0.04, 0.02, 0.95), 8, Color(1.0, 0.45, 0.10, 0.5))
	level_label.label_settings = HUD_STYLE.label_settings(18, Color(0.85, 0.95, 1.0), 4, Color.BLACK)
	stars_label.label_settings = HUD_STYLE.label_settings(16, Color(1.0, 0.88, 0.24), 4, Color(0.12, 0.08, 0.02), 4, Color(1.0, 0.65, 0.15, 0.5))
	stats_label.label_settings = HUD_STYLE.label_settings(14, Color(0.70, 0.88, 1.0, 0.90))
	_configure_button(next_button, "  MÀN TIẾP THEO", ICON_PLAY, COLOR_CYAN)
	_configure_button(restart_button, "  CHƠI LẠI", ICON_RESTART, COLOR_ORANGE)
	_configure_button(menu_button, "  VỀ MENU", ICON_MENU, Color(0.55, 0.65, 0.80))
	next_button.pressed.connect(func() -> void:
		hide_panel()
		next_level_requested.emit())
	restart_button.pressed.connect(func() -> void:
		hide_panel()
		restart_requested.emit())
	menu_button.pressed.connect(func() -> void:
		hide_panel()
		menu_requested.emit())
	apply_accessibility(GameState.high_contrast)


func show_result(
		level_name: String,
		moves: int,
		pushes: int,
		best_moves: int,
		par_moves: int,
		next_button_text: String,
		completion_badge: String,
		hints_used: int,
		run: Dictionary) -> void:
	level_label.text = level_name.to_upper()
	badge.text = completion_badge
	var stars := int(run.get("stars", 0))
	if stars > 0:
		var star_text := "★ ★ ★   XUẤT SẮC (EXCELLENT)" if stars == 3 else ("★ ★ ☆   HOÀN THÀNH" if stars == 2 else "★ ☆ ☆   HOÀN THÀNH")
		if bool(run.get("perfect", false)):
			star_text += "   •   HOÀN HẢO (PERFECT)"
		stars_label.text = star_text
		stars_label.label_settings.font_color = Color(1.0, 0.88, 0.24) if stars == 3 else (Color(0.35, 0.92, 1.0) if stars == 2 else Color(0.75, 0.85, 0.95))
		stars_label.visible = true
	else:
		stars_label.visible = false
	if moves >= 0 and pushes >= 0:
		var best_text := str(best_moves) if best_moves > 0 else "--"
		var penalty := int(run.get("hint_penalty", hints_used))
		var score_moves := int(run.get("score_moves", moves + maxi(0, penalty)))
		stats_label.text = "Bước: %d   |   Phí gợi ý: +%d   |   Tính sao: %d   |   Par: %d   |   Đẩy: %d   |   Kỷ lục: %s" % [moves, maxi(0, penalty), score_moves, par_moves, pushes, best_text]
		stats_label.visible = true
	else:
		stats_label.visible = false
	next_button.text = "  %s  [Enter/Space]" % next_button_text.strip_edges()
	visible = true
	if GameState.reduced_motion:
		modulate.a = 1.0
		card.scale = Vector2.ONE
	else:
		modulate.a = 0.0
		card.scale = Vector2(0.88, 0.88)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2.ONE, 0.4)
		tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_panel() -> void:
	visible = false


func apply_accessibility(high_contrast: bool) -> void:
	card.add_theme_stylebox_override("panel", HUD_STYLE.panel_style(Color(0.12, 0.88, 1.0, 0.90), high_contrast, true))
	for button in _buttons:
		HUD_STYLE.apply_button(button, _accents.get(button.get_instance_id(), COLOR_CYAN), false, high_contrast)
	for label in [badge, title, level_label, stars_label, stats_label]:
		if label == null or label.label_settings == null:
			continue
		if high_contrast:
			label.label_settings.outline_size = maxi(label.label_settings.outline_size, 9)
			label.label_settings.outline_color = Color.BLACK


func layout(viewport_size: Vector2, compact: bool) -> void:
	var width := minf(520.0, maxf(240.0, viewport_size.x - (24.0 if compact else 80.0)))
	card.custom_minimum_size = Vector2(width, 350.0 if compact else 380.0)
	var button_width := maxf(190.0, width - 64.0)
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
