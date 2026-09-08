extends Control

const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)
const COLOR_GREEN := Color(0.35, 0.85, 0.65)
const COLOR_SURFACE := Color(0.035, 0.065, 0.12, 0.96)
const COLOR_TEXT := Color(0.84, 0.94, 1.0)
const COLOR_MUTED := Color(0.62, 0.78, 0.90, 0.88)

var _scroll: ScrollContainer
var _panel: PanelContainer
var _content: VBoxContainer
var _fs_button: Button
var _sfx_toggle: Button
var _haptics_button: Button
var _motion_button: Button
var _contrast_button: Button
var _reset_button: Button
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _slider_value_labels: Dictionary = {}
var _toggle_buttons: Dictionary = {}
var _styled_buttons: Array[Button] = []
var _section_cards: Array[PanelContainer] = []
var _sliders: Array[HSlider] = []
var _labels: Array[Label] = []
var _syncing := false
var _reset_confirm := false
var _grabber_tex: Texture2D
var _grabber_hover_tex: Texture2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_grabber_tex = _make_knob_texture(COLOR_CYAN, 22)
	_grabber_hover_tex = _make_knob_texture(Color(0.55, 0.95, 1.0), 24)
	_build_ui()
	if not GameState.settings_changed.is_connected(_on_settings_changed):
		GameState.settings_changed.connect(_on_settings_changed)
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_layout_for_viewport):
		get_viewport().size_changed.connect(_layout_for_viewport)
	_sync_controls()
	_layout_for_viewport()


func _build_ui() -> void:
	# Background art is deliberately non-interactive so every touch reaches the
	# controls even when the device is using edge-to-edge display mode.
	var bg_tex_rect := TextureRect.new()
	bg_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_tex := load("res://assets/ui/start_menu_background_android_v2.png") as Texture2D
	if bg_tex != null:
		bg_tex_rect.texture = bg_tex
	add_child(bg_tex_rect)

	var overlay := ColorRect.new()
	overlay.color = Color(0.012, 0.018, 0.038, 0.78)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var glow := ColorRect.new()
	glow.color = Color(0.04, 0.22, 0.38, 0.18)
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 220
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_scroll)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	_panel.add_child(margin)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 14)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(_content)

	var title := _make_label("CÀI ĐẶT", 36, COLOR_CYAN, true)
	_content.add_child(title)
	var subtitle := _make_label("TÙY CHỈNH TRẢI NGHIỆM KIRO-K7", 12, COLOR_MUTED)
	_content.add_child(subtitle)

	var audio_body := _add_section_card("ÂM THANH")
	_master_slider = _add_slider_row(audio_body, "Âm lượng tổng", "master", GameState.master_volume, func(value: float) -> void:
		GameState.set_master_volume(value))
	_music_slider = _add_slider_row(audio_body, "Nhạc nền", "music", GameState.music_volume, func(value: float) -> void:
		GameState.set_music_volume(value))
	_sfx_slider = _add_slider_row(audio_body, "Hiệu ứng & thoại", "sfx", GameState.sfx_volume, func(value: float) -> void:
		GameState.set_sfx_volume(value))
	_sfx_toggle = _add_toggle_row(audio_body, "sfx_enabled", COLOR_GREEN)
	_sfx_toggle.pressed.connect(func() -> void:
		GameState.set_sfx_enabled(not GameState.sfx_enabled)
		GameState.haptic_feedback(14, 0.20)
		EchoAudioManager.play_menu_sfx(self, &"ui_click", -5.0))

	var access_body := _add_section_card("ĐIỀU KHIỂN & KHẢ NĂNG TIẾP CẬN")
	_haptics_button = _add_toggle_row(access_body, "haptics", COLOR_GREEN)
	_haptics_button.pressed.connect(func() -> void:
		GameState.set_haptics_enabled(not GameState.haptics_enabled)
		GameState.haptic_feedback(14, 0.20))
	_motion_button = _add_toggle_row(access_body, "reduced_motion", COLOR_CYAN)
	_motion_button.pressed.connect(func() -> void:
		GameState.set_reduced_motion(not GameState.reduced_motion)
		GameState.haptic_feedback(14, 0.20))
	_contrast_button = _add_toggle_row(access_body, "high_contrast", COLOR_CYAN)
	_contrast_button.pressed.connect(func() -> void:
		GameState.set_high_contrast(not GameState.high_contrast)
		GameState.haptic_feedback(14, 0.20))

	var display_body := _add_section_card("HIỂN THỊ")
	_fs_button = _add_toggle_row(display_body, "fullscreen", COLOR_CYAN)
	_fs_button.pressed.connect(func() -> void:
		GameState.set_fullscreen(not GameState.fullscreen)
		EchoAudioManager.play_menu_sfx(self, &"ui_save", -4.0))
	if OS.has_feature("android") or OS.has_feature("ios"):
		display_body.get_parent().visible = false

	var back := _make_action_button("  QUAY LẠI", COLOR_CYAN)
	var back_icon := load("res://assets/ui/icons/back.svg") as Texture2D
	if back_icon:
		back.icon = back_icon
		back.expand_icon = true
	_content.add_child(back)
	EchoAudioManager.bind_button_sfx(self, back, &"ui_cancel")
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn"))

	_reset_button = _make_ghost_button("Xóa tiến độ chơi")
	_content.add_child(_reset_button)
	_reset_button.pressed.connect(_on_reset)

	_apply_accessibility()


func _add_section_card(title: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_cards.append(card)
	_content.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(body)

	var header := _make_label(title, 12, Color(0.42, 0.90, 1.0, 0.95))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.add_child(header)
	return body


func _make_label(text: String, font_size: int, color: Color, is_title := false) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF if is_title else TextServer.AUTOWRAP_WORD_SMART
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 8 if is_title else 3
	settings.outline_color = Color(0.01, 0.04, 0.10, 0.95)
	settings.shadow_size = 5 if is_title else 1
	settings.shadow_color = Color(0.0, 0.65, 1.0, 0.28)
	label.label_settings = settings
	label.set_meta("base_color", color)
	label.set_meta("base_outline_size", settings.outline_size)
	_labels.append(label)
	return label


func _add_slider_row(parent: Control, title: String, key: String, initial: float, changed: Callable) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var label := _make_label(title, 15, COLOR_TEXT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(label)

	var track := HBoxContainer.new()
	track.add_theme_constant_override("separation", 12)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(track)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = clampf(initial, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(0, 36)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.tooltip_text = title
	slider.focus_mode = Control.FOCUS_ALL
	_style_slider(slider)
	_sliders.append(slider)
	track.add_child(slider)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.custom_minimum_size = Vector2(56, 0)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value_settings := LabelSettings.new()
	value_settings.font_size = 16
	value_settings.font_color = COLOR_CYAN
	value_settings.outline_size = 4
	value_settings.outline_color = Color(0.01, 0.04, 0.10, 0.95)
	value_label.label_settings = value_settings
	value_label.set_meta("base_color", COLOR_CYAN)
	value_label.set_meta("base_outline_size", 4)
	_labels.append(value_label)
	_slider_value_labels[key] = value_label
	track.add_child(value_label)

	slider.value_changed.connect(func(value: float) -> void:
		_update_slider_label(key, value)
		if not _syncing:
			EchoAudioManager.play_menu_sfx(self, &"ui_slider", -10.0)
			changed.call(value))
	_update_slider_label(key, slider.value)
	return slider


func _add_toggle_row(parent: Control, key: String, accent: Color) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.custom_minimum_size = Vector2(0, 44)
	parent.add_child(row)

	var title := _make_label("", 15, COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.set_meta("toggle_title", true)
	row.add_child(title)

	var button := Button.new()
	button.custom_minimum_size = Vector2(92, 36)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.tooltip_text = "Chạm để bật/tắt"
	button.set_meta("title_label", title)
	_toggle_buttons[key] = button
	_style_button(button, accent)
	row.add_child(button)
	return button


func _make_action_button(text: String, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, accent)
	return button


func _make_ghost_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("ghost", true)
	_style_button(button, COLOR_ORANGE)
	return button


func _sync_controls() -> void:
	_syncing = true
	if is_instance_valid(_master_slider):
		_master_slider.value = GameState.master_volume
	if is_instance_valid(_music_slider):
		_music_slider.value = GameState.music_volume
	if is_instance_valid(_sfx_slider):
		_sfx_slider.value = GameState.sfx_volume
	_update_slider_label("master", GameState.master_volume)
	_update_slider_label("music", GameState.music_volume)
	_update_slider_label("sfx", GameState.sfx_volume)
	_update_toggle("fullscreen", "Toàn màn hình", GameState.fullscreen)
	_update_toggle("sfx_enabled", "Âm thanh tổng", GameState.sfx_enabled)
	_update_toggle("haptics", "Phản hồi rung", GameState.haptics_enabled)
	_update_toggle("reduced_motion", "Giảm chuyển động", GameState.reduced_motion)
	_update_toggle("high_contrast", "Tương phản cao", GameState.high_contrast)
	_syncing = false
	_apply_accessibility()


func _update_slider_label(key: String, value: float) -> void:
	var label: Label = _slider_value_labels.get(key)
	if label != null:
		label.text = "%d%%" % roundi(clampf(value, 0.0, 1.0) * 100.0)


func _update_toggle(key: String, title: String, enabled: bool) -> void:
	var button: Button = _toggle_buttons.get(key)
	if button == null:
		return
	var title_label: Label = button.get_meta("title_label", null)
	if title_label:
		title_label.text = title
	button.text = "BẬT" if enabled else "TẮT"
	button.button_pressed = enabled
	button.set_meta("enabled", enabled)
	var accent: Color = COLOR_GREEN if enabled else button.get_meta("accent", COLOR_CYAN)
	_apply_button_style(button, accent)


func _on_settings_changed() -> void:
	_sync_controls()


func _on_reset() -> void:
	if not _reset_confirm:
		_reset_confirm = true
		_reset_button.text = "Bấm lần nữa để xác nhận"
		_reset_button.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22))
		return
	GameState.reset_progress()
	_reset_button.text = "Đã xóa tiến độ"
	_reset_button.disabled = true
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")


func _layout_for_viewport() -> void:
	if not is_instance_valid(_scroll) or not is_instance_valid(_panel):
		return
	var viewport_size := get_viewport_rect().size
	var edge := clampf(minf(viewport_size.x, viewport_size.y) * 0.045, 16.0, 36.0)
	var panel_width := clampf(viewport_size.x - edge * 2.0, 280.0, 560.0)
	var panel_height := clampf(viewport_size.y - edge * 2.0, 260.0, 720.0)
	_scroll.custom_minimum_size = Vector2(panel_width, panel_height)
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	if _content:
		_content.add_theme_constant_override("separation", 10 if viewport_size.x < 480.0 else 14)


func _apply_accessibility() -> void:
	var high := GameState.high_contrast
	for label in _labels:
		if not is_instance_valid(label) or label.label_settings == null:
			continue
		var base_color: Color = label.get_meta("base_color", COLOR_TEXT)
		var base_outline: int = int(label.get_meta("base_outline_size", 4))
		label.label_settings.font_color = Color.WHITE if high else base_color
		label.label_settings.outline_size = maxi(base_outline, 9) if high else base_outline
		label.label_settings.outline_color = Color.BLACK if high else Color(0.01, 0.04, 0.10, 0.95)
	for button in _styled_buttons:
		if is_instance_valid(button):
			var accent: Color = button.get_meta("accent", COLOR_CYAN)
			if bool(button.get_meta("enabled", false)) and not bool(button.get_meta("ghost", false)):
				accent = COLOR_GREEN
			_apply_button_style(button, accent)
	for slider in _sliders:
		if is_instance_valid(slider):
			_style_slider(slider)
	if is_instance_valid(_panel):
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.98) if high else Color(0.015, 0.03, 0.055, 0.94)
		panel_style.border_color = Color.WHITE if high else Color(0.12, 0.88, 1.0, 0.72)
		panel_style.set_border_width_all(3 if high else 2)
		panel_style.set_corner_radius_all(18)
		panel_style.shadow_size = 24
		panel_style.shadow_color = Color(0.0, 0.65, 1.0, 0.38)
		_panel.add_theme_stylebox_override("panel", panel_style)
	for card in _section_cards:
		if not is_instance_valid(card):
			continue
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.0, 0.0, 0.0, 0.92) if high else Color(0.02, 0.05, 0.09, 0.55)
		card_style.border_color = Color.WHITE if high else Color(0.12, 0.82, 1.0, 0.22)
		card_style.set_border_width_all(2 if high else 1)
		card_style.set_corner_radius_all(12)
		card.add_theme_stylebox_override("panel", card_style)


func _style_button(button: Button, accent: Color) -> void:
	if not _styled_buttons.has(button):
		_styled_buttons.append(button)
	button.set_meta("accent", accent)
	button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(button, accent)


func _apply_button_style(button: Button, accent: Color) -> void:
	var high := GameState.high_contrast
	var ghost := bool(button.get_meta("ghost", false))
	var enabled := bool(button.get_meta("enabled", false)) and not ghost
	button.add_theme_font_size_override("font_size", 16 if ghost else (18 if high else 15))
	button.add_theme_color_override("font_color", Color.WHITE if high else (COLOR_ORANGE if ghost else COLOR_TEXT))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 3 if high else 0)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		if high:
			style.bg_color = Color(0.0, 0.0, 0.0, 0.98)
			style.set_border_width_all(3)
			style.border_color = Color.WHITE
		elif ghost:
			style.bg_color = Color(0.12, 0.03, 0.02, 0.35 if state == "normal" else 0.55)
			style.set_border_width_all(1)
			style.border_color = Color(accent.r, accent.g, accent.b, 0.55 if state == "normal" else 0.95)
		elif enabled:
			style.bg_color = Color(0.06, 0.22, 0.16, 0.92 if state == "normal" else 1.0)
			style.set_border_width_all(1)
			style.border_color = Color(COLOR_GREEN.r, COLOR_GREEN.g, COLOR_GREEN.b, 0.85)
		else:
			style.bg_color = COLOR_SURFACE if state == "normal" else Color(0.05, 0.14, 0.24, 0.96)
			style.set_border_width_all(1)
			style.border_color = Color(accent.r, accent.g, accent.b, 0.45 if state == "normal" else 0.95)
		style.set_corner_radius_all(10)
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, style)


func _style_slider(slider: HSlider) -> void:
	var high := GameState.high_contrast
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0.04, 0.08, 0.14, 0.95) if not high else Color(0.08, 0.08, 0.08, 1.0)
	groove.set_corner_radius_all(8)
	groove.content_margin_top = 7
	groove.content_margin_bottom = 7
	groove.content_margin_left = 2
	groove.content_margin_right = 2
	groove.border_color = Color.WHITE if high else Color(0.12, 0.55, 0.78, 0.35)
	groove.set_border_width_all(1 if high else 0)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color.WHITE if high else Color(0.10, 0.72, 0.95, 0.95)
	fill.set_corner_radius_all(8)
	fill.content_margin_top = 7
	fill.content_margin_bottom = 7

	var fill_hover := fill.duplicate()
	if not high:
		fill_hover.bg_color = Color(0.35, 0.88, 1.0, 1.0)

	slider.add_theme_stylebox_override("slider", groove)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hover)
	if _grabber_tex:
		slider.add_theme_icon_override("grabber", _grabber_tex)
		slider.add_theme_icon_override("grabber_disabled", _grabber_tex)
	if _grabber_hover_tex:
		slider.add_theme_icon_override("grabber_highlight", _grabber_hover_tex)
	slider.add_theme_constant_override("center_grabber", 1)


func _make_knob_texture(color: Color, size: int) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	var outer := size * 0.5 - 0.6
	var ring := outer - 3.2
	var inner := ring - 2.4
	for y in size:
		for x in size:
			var distance := Vector2(x, y).distance_to(center)
			if distance <= inner:
				img.set_pixel(x, y, Color(0.94, 0.99, 1.0, 1.0))
			elif distance <= ring:
				img.set_pixel(x, y, color)
			elif distance <= outer:
				var alpha := clampf((outer - distance) / 1.2, 0.0, 1.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha * 0.55))
	return ImageTexture.create_from_image(img)
