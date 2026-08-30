extends Control

const BTN_SIZE := Vector2(360, 56)
const COLOR_BG := Color(0.018, 0.025, 0.055)
const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)
const COLOR_SURFACE := Color(0.035, 0.065, 0.12, 0.96)

var _fs_button: Button
var _sfx_button: Button
var _reset_confirm := false


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# Background Art
	var bg_tex_rect := TextureRect.new()
	bg_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_tex := load("res://assets/ui/start_menu_background_android_v2.png") as Texture2D
	if bg_tex != null:
		bg_tex_rect.texture = bg_tex
	add_child(bg_tex_rect)

	# Dark Atmospheric Tint Overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.012, 0.018, 0.038, 0.76)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var glow := ColorRect.new()
	glow.color = Color(0.04, 0.22, 0.38, 0.18)
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 220
	add_child(glow)

	var title := Label.new()
	title.text = "CÀI ĐẶT"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 80
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 44
	ts.font_color = Color(0.35, 0.9, 1.0)
	ts.outline_size = 10
	ts.outline_color = Color(0.01, 0.04, 0.10, 0.95)
	ts.shadow_size = 8
	ts.shadow_color = Color(0.0, 0.65, 1.0, 0.4)
	title.label_settings = ts
	add_child(title)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(vbox)

	_fs_button = Button.new()
	_fs_button.custom_minimum_size = BTN_SIZE
	_style_button(_fs_button, COLOR_CYAN)
	_fs_button.pressed.connect(_on_toggle_fullscreen)
	if not OS.has_feature("android"):
		vbox.add_child(_fs_button)
	_refresh_fs_label()

	_sfx_button = Button.new()
	_sfx_button.custom_minimum_size = BTN_SIZE
	_style_button(_sfx_button, COLOR_CYAN)
	_sfx_button.pressed.connect(_on_toggle_sfx)
	vbox.add_child(_sfx_button)
	_refresh_sfx_label()

	var reset := Button.new()
	reset.text = "XÓA TIẾN ĐỘ CHƠI"
	reset.custom_minimum_size = BTN_SIZE
	_style_button(reset, COLOR_ORANGE)
	reset.pressed.connect(_on_reset.bind(reset))
	vbox.add_child(reset)

	var back := Button.new()
	back.text = "← QUAY LẠI"
	back.custom_minimum_size = BTN_SIZE
	_style_button(back, COLOR_CYAN)
	back.pressed.connect(_on_back)
	vbox.add_child(back)


func _refresh_fs_label() -> void:
	_fs_button.text = "Toàn màn hình: %s" % ("BẬT" if GameState.fullscreen else "TẮT")


func _on_toggle_fullscreen() -> void:
	GameState.set_fullscreen(not GameState.fullscreen)
	_refresh_fs_label()


func _refresh_sfx_label() -> void:
	_sfx_button.text = "Âm thanh hiệu ứng: %s" % ("BẬT" if GameState.sfx_enabled else "TẮT")


func _on_toggle_sfx() -> void:
	GameState.set_sfx_enabled(not GameState.sfx_enabled)
	_refresh_sfx_label()


func _on_reset(btn: Button) -> void:
	if not _reset_confirm:
		_reset_confirm = true
		btn.text = "BẤM LẦN NỮA ĐỂ XÁC NHẬN"
		btn.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		return
	GameState.reset_progress()
	btn.text = "ĐÃ XÓA TIẾN ĐỘ!"
	btn.disabled = true
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")


func _style_button(button: Button, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_SURFACE
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.5)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, style)

