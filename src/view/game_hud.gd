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

const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)

const ICON_UNDO := preload("res://assets/ui/icons/undo.svg")
const ICON_RESTART := preload("res://assets/ui/icons/restart.svg")
const ICON_BRIDGE := preload("res://assets/ui/icons/bridge.svg")
const ICON_MENU := preload("res://assets/ui/icons/menu.svg")
const ICON_PAUSE := preload("res://assets/ui/icons/pause.svg")
const ICON_PLAY := preload("res://assets/ui/icons/play.svg")
const ICON_VOLUME_ON := preload("res://assets/ui/icons/volume_on.svg")
const ICON_VOLUME_OFF := preload("res://assets/ui/icons/volume_off.svg")
const ICON_ENERGY := preload("res://assets/ui/icons/energy_core.svg")
const ICON_LOCK := preload("res://assets/ui/icons/lock.svg")
const ICON_UNLOCK := preload("res://assets/ui/icons/unlock.svg")
const ICON_CLOSE := preload("res://assets/ui/icons/close.svg")
const ICON_CHECK := preload("res://assets/ui/icons/check.svg")

var level_label: Label
var floor_label: Label
var floor_status_label: Label
var core_label: Label
var energy_label: Label
var lock_label: Label
var fragment_label: Label
var win_panel: Control
var win_level_label: Label
var win_stats_label: Label
var win_sub_badge: Label
var pause_panel: Control
var bridge_button: Button
var hint_button: Button
var hint_label: Label
var undo_button: Button
var restart_button: Button
var menu_button: Button
var pause_button: Button

var _win_root: Control
var _win_card: PanelContainer
var _win_next_btn: Button
var _win_restart_btn: Button
var _win_menu_btn: Button
var _pause_root: Control
var _pause_card: PanelContainer
var _pause_resume_btn: Button
var _pause_restart_btn: Button
var _pause_menu_btn: Button
var _pause_audio_btn: Button
var _styled_buttons: Array[Button] = []
var _labels: Array[Label] = []
var _label_defaults: Dictionary = {}
var _button_accents: Dictionary = {}
var _compact_layout := false


var win_stars_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_labels()
	_build_buttons()
	if not GameState.settings_changed.is_connected(_on_settings_changed):
		GameState.settings_changed.connect(_on_settings_changed)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_layout_for_viewport):
		get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()
	_apply_accessibility()


func set_stats(level_name: String, moves: int, pushes: int, best_moves: int, par_moves: int = -1, hint_penalty := 0, three_star_max := 0) -> void:
	var best_text := "--" if best_moves <= 0 else str(best_moves)
	var score_moves := moves + hint_penalty
	var target_text := "/%d ★★★" % three_star_max if three_star_max > 0 else ""
	var par_text := "   |   Par: %d" % par_moves if par_moves > 0 else ""
	level_label.text = "%s   |   Bước: %d   |   Phí gợi ý: +%d   |   Tính sao: %d%s%s   |   Đẩy: %d   |   Kỷ lục: %s" % [
		level_name,
		moves,
		hint_penalty,
		score_moves,
		target_text,
		par_text,
		pushes,
		best_text,
	]


func set_floor(current_floor: int, floor_count: int) -> void:
	if floor_label == null:
		return
	floor_label.visible = floor_count > 1
	if floor_count > 1:
		floor_label.text = "TẦNG %d / %d" % [current_floor + 1, floor_count]


func set_floor_status(message: String) -> void:
	if floor_status_label == null:
		return
	floor_status_label.text = message
	floor_status_label.visible = not message.is_empty()


func set_core_progress(active: int, total: int) -> void:
	if core_label == null:
		return
	core_label.visible = total > 0
	if total <= 0:
		return
	var is_all := active >= total
	core_label.text = "LUMINA CORE: %d/%d%s" % [
		active,
		total,
		"  •  ĐÃ VÀO VỊ TRÍ" if is_all else "",
	]
	var settings := core_label.label_settings
	if settings:
		settings.font_color = Color(0.15, 0.95, 0.75) if is_all \
			else (Color(1.0, 0.82, 0.20) if active > 0 else Color(0.70, 0.88, 1.0, 0.92))


func set_energy_nodes(active: int, total: int) -> void:
	if energy_label == null:
		return
	energy_label.visible = total > 0
	if total <= 0:
		return
	energy_label.text = "◆ NÚT NĂNG LƯỢNG: %d/%d" % [active, total]
	var settings := energy_label.label_settings
	if settings:
		settings.font_color = Color(0.25, 1.0, 0.70) if active >= total \
			else (Color(1.0, 0.82, 0.25) if active > 0 else Color(0.70, 0.88, 1.0, 0.92))


func set_fragment(fragment: String) -> void:
	fragment_label.text = "◆ %s" % fragment
	fragment_label.visible = not fragment.is_empty()


func set_lock_progress(active: int, total: int, open: bool) -> void:
	if lock_label == null:
		return
	lock_label.visible = total > 0
	if total <= 0:
		return
	lock_label.text = "%s KHÓA LIÊN ĐỘNG: %d/%d%s" % [
		"🔓" if open else "🔒",
		active,
		total,
		"  •  ĐÃ MỞ" if open else "",
	]
	var settings := lock_label.label_settings
	if settings:
		settings.font_color = Color(0.12, 0.95, 1.0) if open \
			else (Color(1.0, 0.78, 0.12) if active > 0 else Color(1.0, 0.30, 0.22))


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
	win_level_label.text = level_name.to_upper()
	win_sub_badge.text = completion_badge

	if win_stars_label:
		var stars := int(run.get("stars", 0))
		if stars > 0:
			var star_text := "★ ★ ★   XUẤT SẮC (EXCELLENT)" if stars == 3 else ("★ ★ ☆   HOÀN THÀNH" if stars == 2 else "★ ☆ ☆   HOÀN THÀNH")
			if bool(run.get("perfect", false)):
				star_text += "   •   HOÀN HẢO (PERFECT)"
			win_stars_label.text = star_text
			win_stars_label.label_settings.font_color = Color(1.0, 0.88, 0.24) if stars == 3 else (Color(0.35, 0.92, 1.0) if stars == 2 else Color(0.75, 0.85, 0.95))
			win_stars_label.visible = true
		else:
			win_stars_label.visible = false

	if moves >= 0 and pushes >= 0:
		var best_str := str(best_moves) if best_moves > 0 else "--"
		var penalty := int(run.get("hint_penalty", hints_used))
		var score_moves := int(run.get("score_moves", moves + maxi(0, penalty)))
		win_stats_label.text = "Bước: %d   |   Phí gợi ý: +%d   |   Tính sao: %d   |   Par: %d   |   Đẩy: %d   |   Kỷ lục: %s" % [moves, maxi(0, penalty), score_moves, par_moves, pushes, best_str]
		win_stats_label.visible = true
	else:
		win_stats_label.visible = false

	if _win_next_btn:
		_win_next_btn.text = "  %s  [Enter/Space]" % next_button_text.strip_edges()

	if _win_root:
		_win_root.visible = true
		if GameState.reduced_motion:
			_win_root.modulate.a = 1.0
			if _win_card:
				_win_card.scale = Vector2.ONE
		else:
			_win_root.modulate.a = 0.0
			if _win_card:
				_win_card.scale = Vector2(0.88, 0.88)
			var tw := create_tween().set_parallel(true)
			tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			if _win_card:
				tw.tween_property(_win_card, "scale", Vector2.ONE, 0.4)
			tw.tween_property(_win_root, "modulate:a", 1.0, 0.3)


func hide_win() -> void:
	if _win_root:
		_win_root.visible = false
	elif win_panel:
		win_panel.visible = false


func set_bridge_available(available: bool) -> void:
	if bridge_button != null:
		bridge_button.visible = available
		if available:
			bridge_button.text = " Triển khai cầu"
		_layout_for_viewport()


func set_hint_available(available: bool) -> void:
	if hint_button != null:
		hint_button.visible = available
	if not available:
		clear_hint()


func set_hint_text(message: String, shown := true) -> void:
	if hint_label == null:
		return
	hint_label.text = message
	hint_label.visible = shown and not message.is_empty()


func clear_hint() -> void:
	if hint_label != null:
		hint_label.text = ""
		hint_label.visible = false


func _build_labels() -> void:
	level_label = Label.new()
	level_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	level_label.offset_top = 20
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var level_settings := LabelSettings.new()
	level_settings.font_size = 22
	level_settings.font_color = Color(0.78, 0.93, 1.0)
	level_settings.outline_size = 8
	level_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	level_settings.shadow_size = 6
	level_settings.shadow_color = Color(0.0, 0.65, 1.0, 0.35)
	level_label.label_settings = level_settings
	_register_label(level_label)
	add_child(level_label)

	floor_label = Label.new()
	floor_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	floor_label.offset_left = -150
	floor_label.offset_right = -18
	floor_label.offset_top = 58
	floor_label.offset_bottom = 88
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	floor_label.visible = false
	floor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var floor_settings := LabelSettings.new()
	floor_settings.font_size = 15
	floor_settings.font_color = Color(0.15, 0.95, 0.75)
	floor_settings.outline_size = 6
	floor_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	floor_label.label_settings = floor_settings
	_register_label(floor_label)
	add_child(floor_label)

	floor_status_label = Label.new()
	floor_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	floor_status_label.offset_left = -330
	floor_status_label.offset_right = -18
	floor_status_label.offset_top = 84
	floor_status_label.offset_bottom = 108
	floor_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	floor_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	floor_status_label.visible = false
	floor_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var floor_status_settings := LabelSettings.new()
	floor_status_settings.font_size = 12
	floor_status_settings.font_color = Color(1.0, 0.80, 0.26)
	floor_status_settings.outline_size = 5
	floor_status_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	floor_status_label.label_settings = floor_status_settings
	_register_label(floor_status_label)
	add_child(floor_status_label)

	core_label = Label.new()
	core_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	core_label.offset_top = 54
	core_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core_label.visible = false
	var core_settings := LabelSettings.new()
	core_settings.font_size = 16
	core_settings.font_color = Color(0.70, 0.88, 1.0, 0.92)
	core_settings.outline_size = 6
	core_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	core_settings.shadow_size = 6
	core_settings.shadow_color = Color(0.0, 0.65, 1.0, 0.35)
	core_label.label_settings = core_settings
	_register_label(core_label)
	add_child(core_label)

	energy_label = Label.new()
	energy_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	energy_label.offset_top = 80
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.visible = false
	var energy_settings := LabelSettings.new()
	energy_settings.font_size = 15
	energy_settings.font_color = Color(0.70, 0.88, 1.0, 0.92)
	energy_settings.outline_size = 6
	energy_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	energy_label.label_settings = energy_settings
	_register_label(energy_label)
	add_child(energy_label)

	lock_label = Label.new()
	lock_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lock_label.offset_top = 104
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.visible = false
	var lock_settings := LabelSettings.new()
	lock_settings.font_size = 15
	lock_settings.font_color = Color(1.0, 0.30, 0.22)
	lock_settings.outline_size = 6
	lock_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	lock_label.label_settings = lock_settings
	_register_label(lock_label)
	add_child(lock_label)

	hint_label = Label.new()
	hint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_label.offset_left = 16
	hint_label.offset_right = -16
	hint_label.offset_top = 108
	hint_label.offset_bottom = 154
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.visible = false
	var hint_settings := LabelSettings.new()
	hint_settings.font_size = 15
	hint_settings.font_color = Color(1.0, 0.84, 0.30, 0.98)
	hint_settings.outline_size = 7
	hint_settings.outline_color = Color(0.02, 0.04, 0.10, 0.98)
	hint_settings.shadow_size = 5
	hint_settings.shadow_color = Color(1.0, 0.45, 0.08, 0.42)
	hint_label.label_settings = hint_settings
	_register_label(hint_label)
	add_child(hint_label)

	fragment_label = Label.new()
	fragment_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fragment_label.offset_left = 150
	fragment_label.offset_right = -150
	fragment_label.offset_top = -132
	fragment_label.offset_bottom = -76
	fragment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fragment_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	fragment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fragment_label.visible = false
	var fragment_settings := LabelSettings.new()
	fragment_settings.font_size = 15
	fragment_settings.font_color = Color(0.72, 0.90, 0.96, 0.94)
	fragment_settings.outline_size = 5
	fragment_settings.outline_color = Color(0.02, 0.04, 0.10, 0.95)
	fragment_label.label_settings = fragment_settings
	_register_label(fragment_label)
	add_child(fragment_label)

	# --- Centered Modal Victory Card ---
	_win_root = Control.new()
	_win_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_root.visible = false
	add_child(_win_root)
	win_panel = _win_root

	# Translucent dark backdrop
	var win_bg := ColorRect.new()
	win_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_bg.color = Color(0.008, 0.015, 0.025, 0.60)
	win_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_root.add_child(win_bg)

	var win_center := CenterContainer.new()
	win_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	win_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_root.add_child(win_center)

	_win_card = PanelContainer.new()
	_win_card.custom_minimum_size = Vector2(440, 380)
	_win_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	win_center.add_child(_win_card)

	var wp_style := StyleBoxFlat.new()
	wp_style.bg_color = Color(0.015, 0.03, 0.055, 0.96)
	wp_style.border_color = Color(0.12, 0.88, 1.0, 0.90)
	wp_style.set_border_width_all(2)
	wp_style.set_corner_radius_all(16)
	wp_style.shadow_size = 24
	wp_style.shadow_color = Color(0.0, 0.65, 1.0, 0.45)
	wp_style.content_margin_left = 32
	wp_style.content_margin_right = 32
	wp_style.content_margin_top = 24
	wp_style.content_margin_bottom = 24
	_win_card.add_theme_stylebox_override("panel", wp_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_win_card.add_child(vbox)

	win_sub_badge = Label.new()
	win_sub_badge.text = "◆ NĂNG LƯỢNG ĐÃ KHÔI PHỤC ◆"
	win_sub_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var badge_s := LabelSettings.new()
	badge_s.font_size = 12
	badge_s.font_color = Color(0.35, 0.92, 1.0, 0.95)
	win_sub_badge.label_settings = badge_s
	_register_label(win_sub_badge)
	vbox.add_child(win_sub_badge)

	var main_title := Label.new()
	main_title.text = "HOÀN THÀNH"
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_s := LabelSettings.new()
	title_s.font_size = 36
	title_s.font_color = Color(1.0, 0.80, 0.24)
	title_s.outline_size = 6
	title_s.outline_color = Color(0.10, 0.04, 0.02, 0.95)
	title_s.shadow_size = 8
	title_s.shadow_color = Color(1.0, 0.45, 0.10, 0.5)
	main_title.label_settings = title_s
	_register_label(main_title)
	vbox.add_child(main_title)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.12, 0.88, 1.0, 0.40)
	vbox.add_child(sep)

	win_level_label = Label.new()
	win_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lvl_s := LabelSettings.new()
	lvl_s.font_size = 18
	lvl_s.font_color = Color(0.85, 0.95, 1.0)
	lvl_s.outline_size = 4
	lvl_s.outline_color = Color.BLACK
	win_level_label.label_settings = lvl_s
	_register_label(win_level_label)
	vbox.add_child(win_level_label)

	win_stars_label = Label.new()
	win_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var star_s := LabelSettings.new()
	star_s.font_size = 16
	star_s.font_color = Color(1.0, 0.88, 0.24)
	star_s.outline_size = 4
	star_s.outline_color = Color(0.12, 0.08, 0.02)
	star_s.shadow_size = 4
	star_s.shadow_color = Color(1.0, 0.65, 0.15, 0.5)
	win_stars_label.label_settings = star_s
	_register_label(win_stars_label)
	vbox.add_child(win_stars_label)

	win_stats_label = Label.new()
	win_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var st_s := LabelSettings.new()
	st_s.font_size = 14
	st_s.font_color = Color(0.70, 0.88, 1.0, 0.90)
	win_stats_label.label_settings = st_s
	_register_label(win_stats_label)
	vbox.add_child(win_stats_label)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(sp)

	# 1. Màn tiếp theo (Next Level)
	_win_next_btn = Button.new()
	_win_next_btn.text = "  MÀN TIẾP THEO"
	_win_next_btn.icon = ICON_PLAY
	_win_next_btn.expand_icon = true
	_win_next_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_win_next_btn, COLOR_CYAN)
	_win_next_btn.pressed.connect(func() -> void:
		hide_win()
		next_level_requested.emit()
	)
	vbox.add_child(_win_next_btn)

	# 2. Chơi lại (Restart)
	_win_restart_btn = Button.new()
	_win_restart_btn.text = "  CHƠI LẠI"
	_win_restart_btn.icon = ICON_RESTART
	_win_restart_btn.expand_icon = true
	_win_restart_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_win_restart_btn, COLOR_ORANGE)
	_win_restart_btn.pressed.connect(func() -> void:
		hide_win()
		restart_requested.emit()
	)
	vbox.add_child(_win_restart_btn)

	# 3. Về Menu
	_win_menu_btn = Button.new()
	_win_menu_btn.text = "  VỀ MENU"
	_win_menu_btn.icon = ICON_MENU
	_win_menu_btn.expand_icon = true
	_win_menu_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_win_menu_btn, Color(0.55, 0.65, 0.80))
	_win_menu_btn.pressed.connect(func() -> void:
		hide_win()
		menu_requested.emit()
	)
	vbox.add_child(_win_menu_btn)


func _build_buttons() -> void:
	undo_button = Button.new()
	undo_button.text = " Hoàn tác"
	undo_button.icon = ICON_UNDO
	undo_button.expand_icon = true
	undo_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	undo_button.offset_left = 24
	undo_button.offset_top = -80
	undo_button.offset_bottom = -24
	undo_button.custom_minimum_size = Vector2(130, 56)
	_style_button(undo_button, COLOR_CYAN)
	undo_button.pressed.connect(func() -> void: undo_requested.emit())
	add_child(undo_button)

	restart_button = Button.new()
	restart_button.text = " Chơi lại"
	restart_button.icon = ICON_RESTART
	restart_button.expand_icon = true
	restart_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	restart_button.offset_left = -154
	restart_button.offset_top = -80
	restart_button.offset_bottom = -24
	restart_button.custom_minimum_size = Vector2(130, 56)
	_style_button(restart_button, COLOR_ORANGE)
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	add_child(restart_button)

	bridge_button = Button.new()
	bridge_button.text = " Triển khai cầu"
	bridge_button.icon = ICON_BRIDGE
	bridge_button.expand_icon = true
	bridge_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bridge_button.offset_left = -75
	bridge_button.offset_right = 75
	bridge_button.offset_top = -80
	bridge_button.offset_bottom = -24
	bridge_button.custom_minimum_size = Vector2(150, 56)
	bridge_button.visible = false
	_style_button(bridge_button, COLOR_ORANGE)
	bridge_button.pressed.connect(func() -> void: bridge_requested.emit())
	add_child(bridge_button)

	menu_button = Button.new()
	menu_button.text = " Menu"
	menu_button.icon = ICON_MENU
	menu_button.expand_icon = true
	menu_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu_button.offset_left = 16
	menu_button.offset_top = 12
	menu_button.custom_minimum_size = Vector2(110, 46)
	_style_button(menu_button, COLOR_CYAN)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	add_child(menu_button)

	hint_button = Button.new()
	hint_button.text = " Gợi ý"
	hint_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint_button.offset_left = 16
	hint_button.offset_top = 64
	hint_button.custom_minimum_size = Vector2(110, 46)
	_style_button(hint_button, Color(1.0, 0.78, 0.12))
	hint_button.pressed.connect(func() -> void: hint_requested.emit())
	add_child(hint_button)

	pause_button = Button.new()
	pause_button.text = " Tạm dừng"
	pause_button.icon = ICON_PAUSE
	pause_button.expand_icon = true
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -136
	pause_button.offset_top = 12
	pause_button.custom_minimum_size = Vector2(125, 46)
	_style_button(pause_button, COLOR_CYAN)
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	add_child(pause_button)

	_build_pause_panel()


func set_paused(paused: bool) -> void:
	if _pause_root:
		_pause_root.visible = paused
		if paused:
			_update_pause_audio_text()
			if GameState.reduced_motion:
				_pause_root.modulate.a = 1.0
			else:
				_pause_root.modulate.a = 0.0
				var tw := create_tween()
				tw.tween_property(_pause_root, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif pause_panel:
		pause_panel.visible = paused


func _update_pause_audio_text() -> void:
	if _pause_audio_btn:
		_pause_audio_btn.text = "  ÂM THANH: BẬT" if GameState.sfx_enabled else "  ÂM THANH: TẮT"
		_pause_audio_btn.icon = ICON_VOLUME_ON if GameState.sfx_enabled else ICON_VOLUME_OFF


func _build_pause_panel() -> void:
	_pause_root = Control.new()
	_pause_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.visible = false
	add_child(_pause_root)
	pause_panel = _pause_root

	# Translucent dark backdrop
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.008, 0.015, 0.025, 0.65)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_root.add_child(bg)

	# Centered Modal Container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_root.add_child(center)

	_pause_card = PanelContainer.new()
	_pause_card.custom_minimum_size = Vector2(360, 360)
	_pause_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_pause_card)

	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.018, 0.032, 0.055, 0.96)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = Color(0.12, 0.82, 1.0, 0.85)
	card_style.corner_radius_top_left = 14
	card_style.corner_radius_top_right = 14
	card_style.corner_radius_bottom_left = 14
	card_style.corner_radius_bottom_right = 14
	card_style.shadow_color = Color(0.0, 0.55, 0.9, 0.4)
	card_style.shadow_size = 22
	_pause_card.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)

	# Header badge
	var badge := Label.new()
	badge.text = "─── HỆ THỐNG ───"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b_s := LabelSettings.new()
	b_s.font_size = 12
	b_s.font_color = Color(0.12, 0.82, 1.0)
	badge.label_settings = b_s
	content.add_child(badge)

	# Main Title
	var title := Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings := LabelSettings.new()
	title_settings.font_size = 26
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 4
	title_settings.outline_color = Color(0.02, 0.04, 0.08, 0.95)
	title_settings.shadow_size = 6
	title_settings.shadow_color = Color(0.12, 0.82, 1.0, 0.45)
	title.label_settings = title_settings
	content.add_child(title)

	# Glowing Divider Line
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.12, 0.82, 1.0, 0.45)
	content.add_child(sep)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 4)
	content.add_child(sp)

	# 1. Tiếp tục (Resume)
	_pause_resume_btn = Button.new()
	_pause_resume_btn.text = "  TIẾP TỤC"
	_pause_resume_btn.icon = ICON_PLAY
	_pause_resume_btn.expand_icon = true
	_pause_resume_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_pause_resume_btn, COLOR_CYAN)
	_pause_resume_btn.pressed.connect(func() -> void: resume_requested.emit())
	content.add_child(_pause_resume_btn)

	# 2. Chơi lại (Restart)
	_pause_restart_btn = Button.new()
	_pause_restart_btn.text = "  CHƠI LẠI"
	_pause_restart_btn.icon = ICON_RESTART
	_pause_restart_btn.expand_icon = true
	_pause_restart_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_pause_restart_btn, COLOR_ORANGE)
	_pause_restart_btn.pressed.connect(func() -> void:
		resume_requested.emit()
		restart_requested.emit()
	)
	content.add_child(_pause_restart_btn)

	# 3. Âm thanh Toggle (Audio)
	_pause_audio_btn = Button.new()
	_pause_audio_btn.expand_icon = true
	_update_pause_audio_text()
	_pause_audio_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_pause_audio_btn, Color(0.35, 0.85, 0.65))
	_pause_audio_btn.pressed.connect(func() -> void:
		GameState.set_sfx_enabled(not GameState.sfx_enabled)
		_update_pause_audio_text()
	)
	content.add_child(_pause_audio_btn)

	# 4. Về Menu
	_pause_menu_btn = Button.new()
	_pause_menu_btn.text = "  VỀ MENU"
	_pause_menu_btn.icon = ICON_MENU
	_pause_menu_btn.expand_icon = true
	_pause_menu_btn.custom_minimum_size = Vector2(280, 44)
	_style_button(_pause_menu_btn, Color(0.55, 0.65, 0.80))
	_pause_menu_btn.pressed.connect(func() -> void: menu_requested.emit())
	content.add_child(_pause_menu_btn)


func _register_label(label: Label) -> void:
	if label == null or _labels.has(label):
		return
	_labels.append(label)
	if label.label_settings:
		_label_defaults[label.get_instance_id()] = {
			"font_color": label.label_settings.font_color,
			"outline_size": label.label_settings.outline_size,
			"outline_color": label.label_settings.outline_color,
		}


func _on_settings_changed() -> void:
	_update_pause_audio_text()
	_apply_accessibility()
	_layout_for_viewport()


func _apply_accessibility() -> void:
	var high := GameState.high_contrast
	for label in _labels:
		if not is_instance_valid(label) or label.label_settings == null:
			continue
		var defaults: Dictionary = _label_defaults.get(label.get_instance_id(), {})
		var base_color: Color = defaults.get("font_color", Color.WHITE)
		var base_outline := int(defaults.get("outline_size", 4))
		label.label_settings.font_color = Color.WHITE if high else base_color
		label.label_settings.outline_size = maxi(base_outline, 9) if high else base_outline
		label.label_settings.outline_color = Color.BLACK if high else defaults.get("outline_color", Color.BLACK)
	for button in _styled_buttons:
		if is_instance_valid(button):
			_apply_button_style(button, _button_accents.get(button.get_instance_id(), COLOR_CYAN))
	if is_instance_valid(_win_card):
		_apply_panel_contrast(_win_card, high, Color(0.12, 0.88, 1.0, 0.90))
	if is_instance_valid(_pause_card):
		_apply_panel_contrast(_pause_card, high, Color(0.12, 0.82, 1.0, 0.85))


func _apply_panel_contrast(panel: PanelContainer, high: bool, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.BLACK if high else Color(0.015, 0.03, 0.055, 0.96)
	style.border_color = Color.WHITE if high else accent
	style.set_border_width_all(3 if high else 2)
	style.set_corner_radius_all(16)
	style.shadow_size = 24
	style.shadow_color = Color(0.0, 0.65, 1.0, 0.45)
	if panel == _win_card:
		style.content_margin_left = 32.0
		style.content_margin_right = 32.0
		style.content_margin_top = 24.0
		style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", style)


func _style_button(button: Button, accent: Color) -> void:
	if not _styled_buttons.has(button):
		_styled_buttons.append(button)
	_button_accents[button.get_instance_id()] = accent
	if not button.has_meta("wide_text"):
		button.set_meta("wide_text", button.text)
	button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(button, accent)


func _apply_button_style(button: Button, accent: Color) -> void:
	var high := GameState.high_contrast
	button.add_theme_font_size_override("font_size", 16 if not _compact_layout else 15)
	button.add_theme_color_override("font_color", Color.WHITE if high else Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 3 if high else 0)
	button.add_theme_constant_override("icon_max_width", 24 if _compact_layout else 22)
	button.add_theme_constant_override("h_separation", 8)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.BLACK if high else Color(0.035, 0.065, 0.12, 0.96)
		style.border_width_left = 3 if high else 2
		style.border_width_top = 3 if high else 2
		style.border_width_right = 3 if high else 2
		style.border_width_bottom = 3 if high else 2
		style.border_color = Color.WHITE if high else (accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.65))
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 12.0 if _compact_layout else 16.0
		style.content_margin_right = 12.0 if _compact_layout else 16.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, style)


func _position_bottom_button(button: Button, left: float, width: float, height: float, bottom_margin: float) -> void:
	if button == null:
		return
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = left
	button.offset_right = left + width
	button.offset_top = -bottom_margin - height
	button.offset_bottom = -bottom_margin
	button.custom_minimum_size = Vector2(width, height)


func _position_center_bottom_button(button: Button, width: float, height: float, bottom_margin: float) -> void:
	if button == null:
		return
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = -width * 0.5
	button.offset_right = width * 0.5
	button.offset_top = -bottom_margin - height
	button.offset_bottom = -bottom_margin
	button.custom_minimum_size = Vector2(width, height)


func _set_compact_button_text(button: Button, compact: bool, compact_text := "") -> void:
	if button == null or button == _pause_audio_btn:
		return
	button.text = compact_text if compact else str(button.get_meta("wide_text", button.text))


func _layout_for_viewport() -> void:
	if not is_instance_valid(level_label):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var edge := clampf(minf(viewport_size.x, viewport_size.y) * 0.035, 12.0, 28.0)
	_compact_layout = viewport_size.x < 760.0 or viewport_size.y < 560.0

	level_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	level_label.offset_left = edge + (62.0 if _compact_layout else 20.0)
	level_label.offset_right = -edge - (62.0 if _compact_layout else 20.0)
	level_label.offset_top = 8.0 if _compact_layout else 20.0
	level_label.offset_bottom = 38.0 if _compact_layout else 48.0
	level_label.label_settings.font_size = 17 if _compact_layout else 22

	floor_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	floor_label.offset_left = -(112.0 if _compact_layout else 150.0)
	floor_label.offset_right = -edge
	floor_label.offset_top = 44.0 if _compact_layout else 58.0
	floor_label.offset_bottom = floor_label.offset_top + 26.0
	floor_label.label_settings.font_size = 13 if _compact_layout else 15

	floor_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	floor_status_label.offset_left = -(230.0 if _compact_layout else 330.0)
	floor_status_label.offset_right = -edge
	floor_status_label.offset_top = 93.0 if _compact_layout else 84.0
	floor_status_label.offset_bottom = floor_status_label.offset_top + 30.0
	floor_status_label.label_settings.font_size = 10 if _compact_layout else 12

	core_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	core_label.offset_left = edge
	core_label.offset_right = -edge
	core_label.offset_top = 44.0 if _compact_layout else 54.0
	core_label.offset_bottom = core_label.offset_top + 24.0
	core_label.label_settings.font_size = 14 if _compact_layout else 16

	energy_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	energy_label.offset_left = edge
	energy_label.offset_right = -edge
	energy_label.offset_top = 67.0 if _compact_layout else 80.0
	energy_label.offset_bottom = energy_label.offset_top + 22.0
	energy_label.label_settings.font_size = 13 if _compact_layout else 15

	lock_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lock_label.offset_left = edge
	lock_label.offset_right = -edge
	lock_label.offset_top = 88.0 if _compact_layout else 104.0
	lock_label.offset_bottom = lock_label.offset_top + 24.0
	lock_label.label_settings.font_size = 13 if _compact_layout else 15

	hint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_label.offset_left = edge
	hint_label.offset_right = -edge
	hint_label.offset_top = 118.0 if _compact_layout else 108.0
	hint_label.offset_bottom = hint_label.offset_top + (40.0 if _compact_layout else 46.0)
	hint_label.label_settings.font_size = 13 if _compact_layout else 15

	fragment_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fragment_label.offset_left = edge + (72.0 if _compact_layout else 150.0)
	fragment_label.offset_right = -edge - (72.0 if _compact_layout else 150.0)
	fragment_label.offset_top = -104.0 if _compact_layout else -132.0
	fragment_label.offset_bottom = -72.0 if _compact_layout else -76.0
	fragment_label.label_settings.font_size = 13 if _compact_layout else 15

	var bottom_margin := 12.0 if _compact_layout else 24.0
	var bottom_height := 54.0 if _compact_layout else 56.0
	if _compact_layout:
		var gap := 7.0
		var count := 3 if bridge_button != null and bridge_button.visible else 2
		var available := maxf(180.0, viewport_size.x - edge * 2.0)
		var width := maxf(72.0, minf(132.0, (available - gap * float(count - 1)) / float(count)))
		var total := width * float(count) + gap * float(count - 1)
		var left := maxf(edge, (viewport_size.x - total) * 0.5)
		_position_bottom_button(undo_button, left, width, bottom_height, bottom_margin)
		if count == 3:
			_position_bottom_button(bridge_button, left + width + gap, width, bottom_height, bottom_margin)
			_position_bottom_button(restart_button, left + (width + gap) * 2.0, width, bottom_height, bottom_margin)
		else:
			_position_bottom_button(restart_button, left + width + gap, width, bottom_height, bottom_margin)
			_position_bottom_button(bridge_button, (viewport_size.x - width) * 0.5, width, bottom_height, bottom_margin)
		_set_compact_button_text(undo_button, true)
		_set_compact_button_text(restart_button, true)
		_set_compact_button_text(bridge_button, true)
	else:
		_position_bottom_button(undo_button, edge, 130.0, bottom_height, bottom_margin)
		_position_bottom_button(restart_button, viewport_size.x - edge - 130.0, 130.0, bottom_height, bottom_margin)
		_position_center_bottom_button(bridge_button, 150.0, bottom_height, bottom_margin)
		_set_compact_button_text(undo_button, false)
		_set_compact_button_text(restart_button, false)
		_set_compact_button_text(bridge_button, false)

	menu_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu_button.offset_left = edge
	menu_button.offset_top = 10.0
	menu_button.offset_right = edge + (56.0 if _compact_layout else 110.0)
	menu_button.offset_bottom = menu_button.offset_top + (52.0 if _compact_layout else 46.0)
	menu_button.custom_minimum_size = Vector2(menu_button.offset_right - menu_button.offset_left, menu_button.offset_bottom - menu_button.offset_top)
	_set_compact_button_text(menu_button, _compact_layout)
	menu_button.tooltip_text = "Menu"

	hint_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint_button.offset_left = edge
	hint_button.offset_top = 68.0 if _compact_layout else 64.0
	hint_button.offset_right = edge + (56.0 if _compact_layout else 110.0)
	hint_button.offset_bottom = hint_button.offset_top + (52.0 if _compact_layout else 46.0)
	hint_button.custom_minimum_size = Vector2(hint_button.offset_right - hint_button.offset_left, hint_button.offset_bottom - hint_button.offset_top)
	_set_compact_button_text(hint_button, _compact_layout, "?")
	hint_button.tooltip_text = "Gợi ý"

	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -(edge + (56.0 if _compact_layout else 125.0))
	pause_button.offset_right = -edge
	pause_button.offset_top = 10.0
	pause_button.offset_bottom = pause_button.offset_top + (52.0 if _compact_layout else 46.0)
	pause_button.custom_minimum_size = Vector2(pause_button.offset_right - pause_button.offset_left, pause_button.offset_bottom - pause_button.offset_top)
	_set_compact_button_text(pause_button, _compact_layout)
	pause_button.tooltip_text = "Tạm dừng"

	if is_instance_valid(_win_card):
		var card_width := minf(520.0, maxf(240.0, viewport_size.x - (24.0 if _compact_layout else 80.0)))
		_win_card.custom_minimum_size = Vector2(card_width, 350.0 if _compact_layout else 380.0)
		var win_button_width := maxf(190.0, card_width - 64.0)
		_win_next_btn.custom_minimum_size.x = win_button_width
		_win_restart_btn.custom_minimum_size.x = win_button_width
		_win_menu_btn.custom_minimum_size.x = win_button_width
	if is_instance_valid(_pause_card):
		var pause_width := minf(360.0, maxf(240.0, viewport_size.x - 24.0))
		_pause_card.custom_minimum_size = Vector2(pause_width, 350.0 if _compact_layout else 360.0)
		var pause_button_width := maxf(180.0, pause_width - 56.0)
		_pause_resume_btn.custom_minimum_size.x = pause_button_width
		_pause_restart_btn.custom_minimum_size.x = pause_button_width
		_pause_audio_btn.custom_minimum_size.x = pause_button_width
		_pause_menu_btn.custom_minimum_size.x = pause_button_width
