extends Control

const COLOR_BG := Color(0.018, 0.025, 0.055)
const COLOR_CYAN := Color(0.08, 0.78, 1.0)
const COLOR_ORANGE := Color(1.0, 0.38, 0.08)
const COLOR_SURFACE := Color(0.035, 0.065, 0.12, 0.96)
const COLOR_LOCKED := Color(0.02, 0.03, 0.06, 0.85)

const CHAPTERS := [
	{"id": 1, "start": 0, "end": 3},
	{"id": 2, "start": 4, "end": 7},
	{"id": 3, "start": 8, "end": 11},
	{"id": 4, "start": 12, "end": 14},
]

var _current_chapter := 0
var _grid_container: GridContainer
var _chapter_title_label: Label
var _chapter_desc_label: Label
var _prev_chapter_btn: Button
var _next_chapter_btn: Button


func _chapter_data(index: int) -> Dictionary:
	return StoryData.get_chapter_data(int(CHAPTERS[index]["id"]))


func _chapter_display_name(index: int) -> String:
	var data := _chapter_data(index)
	return "%s: %s" % [str(data.get("roman", "CHƯƠNG %d" % (index + 1))), str(data.get("title", ""))]


func _ready() -> void:
	_init_chapter_from_progress()
	_build_ui()
	_render_chapter_levels()


func _init_chapter_from_progress() -> void:
	var unlocked_idx := GameState.unlocked - 1
	for idx in CHAPTERS.size():
		var ch: Dictionary = CHAPTERS[idx]
		if unlocked_idx >= int(ch["start"]) and unlocked_idx <= int(ch["end"]):
			_current_chapter = idx
			break


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
	overlay.color = Color(0.012, 0.018, 0.038, 0.80)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var glow := ColorRect.new()
	glow.color = Color(0.04, 0.22, 0.38, 0.18)
	glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	glow.offset_bottom = 200
	add_child(glow)

	# Top Bar
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 24
	top_bar.offset_right = -24
	top_bar.offset_top = 20
	top_bar.offset_bottom = 68
	top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(top_bar)

	var back_btn := Button.new()
	back_btn.text = "← QUAY LẠI"
	back_btn.custom_minimum_size = Vector2(140, 44)
	_style_button(back_btn, COLOR_CYAN)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn"))
	top_bar.add_child(back_btn)

	var title := Label.new()
	title.text = "CHỌN MÀN CHƠI"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := LabelSettings.new()
	ts.font_size = 28
	ts.font_color = Color(0.35, 0.9, 1.0)
	ts.outline_size = 8
	ts.outline_color = Color(0.01, 0.04, 0.10, 0.95)
	title.label_settings = ts
	top_bar.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(140, 44)
	top_bar.add_child(spacer)

	# Chapter Navigation Bar
	var nav_container := VBoxContainer.new()
	nav_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	nav_container.offset_top = 80
	nav_container.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_container.add_theme_constant_override("separation", 4)
	add_child(nav_container)

	var nav_hbox := HBoxContainer.new()
	nav_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_hbox.add_theme_constant_override("separation", 20)
	nav_container.add_child(nav_hbox)

	_prev_chapter_btn = Button.new()
	_prev_chapter_btn.text = " ⟨ "
	_prev_chapter_btn.custom_minimum_size = Vector2(48, 40)
	_style_button(_prev_chapter_btn, COLOR_CYAN)
	_prev_chapter_btn.pressed.connect(_on_prev_chapter)
	nav_hbox.add_child(_prev_chapter_btn)

	_chapter_title_label = Label.new()
	_chapter_title_label.text = _chapter_display_name(_current_chapter)
	var ch_settings := LabelSettings.new()
	ch_settings.font_size = 22
	ch_settings.font_color = Color(1.0, 0.65, 0.2)
	ch_settings.outline_size = 6
	ch_settings.outline_color = Color(0.08, 0.02, 0.01, 0.9)
	_chapter_title_label.label_settings = ch_settings
	nav_hbox.add_child(_chapter_title_label)

	_next_chapter_btn = Button.new()
	_next_chapter_btn.text = " ⟩ "
	_next_chapter_btn.custom_minimum_size = Vector2(48, 40)
	_style_button(_next_chapter_btn, COLOR_CYAN)
	_next_chapter_btn.pressed.connect(_on_next_chapter)
	nav_hbox.add_child(_next_chapter_btn)

	_chapter_desc_label = Label.new()
	_chapter_desc_label.text = str(_chapter_data(_current_chapter).get("description", ""))
	_chapter_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cd_settings := LabelSettings.new()
	cd_settings.font_size = 14
	cd_settings.font_color = Color(0.65, 0.82, 0.94, 0.75)
	_chapter_desc_label.label_settings = cd_settings
	nav_container.add_child(_chapter_desc_label)

	# Content scroll & grid
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 160
	scroll.offset_bottom = -30
	scroll.offset_left = 40
	scroll.offset_right = -40
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var center_wrap := CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_wrap)

	_grid_container = GridContainer.new()
	_grid_container.columns = 3
	_grid_container.add_theme_constant_override("h_separation", 24)
	_grid_container.add_theme_constant_override("v_separation", 20)
	center_wrap.add_child(_grid_container)


func _render_chapter_levels() -> void:
	for child in _grid_container.get_children():
		child.queue_free()

	_chapter_title_label.text = _chapter_display_name(_current_chapter)
	_chapter_desc_label.text = str(_chapter_data(_current_chapter).get("description", ""))
	_prev_chapter_btn.disabled = _current_chapter <= 0
	_next_chapter_btn.disabled = _current_chapter >= CHAPTERS.size() - 1

	if Levels.ALL.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Dữ liệu màn chơi đang được chuẩn bị..."
		var es := LabelSettings.new()
		es.font_size = 18
		es.font_color = Color(0.6, 0.75, 0.88, 0.8)
		empty_lbl.label_settings = es
		_grid_container.add_child(empty_lbl)
		return

	var start_idx: int = CHAPTERS[_current_chapter]["start"]
	var end_idx: int = mini(int(CHAPTERS[_current_chapter]["end"]), Levels.ALL.size() - 1)
	if start_idx >= Levels.ALL.size() or end_idx < start_idx:
		var pending_lbl := Label.new()
		pending_lbl.text = "Dữ liệu chương đang được chuẩn bị..."
		var pending_settings := LabelSettings.new()
		pending_settings.font_size = 18
		pending_settings.font_color = Color(0.6, 0.75, 0.88, 0.8)
		pending_lbl.label_settings = pending_settings
		_grid_container.add_child(pending_lbl)
		return

	for i in range(start_idx, end_idx + 1):
		if i >= Levels.ALL.size():
			break
		var unlocked := GameState.is_unlocked(i)
		var record: Dictionary = GameState.get_level_record(i)
		var level_btn := Button.new()
		level_btn.custom_minimum_size = Vector2(240, 110)
		level_btn.disabled = not unlocked

		var level_name: String = str(Levels.ALL[i].get("name", "Màn %d" % (i + 1)))
		var best_moves: int = int(record.get("best_moves", 0))
		var memory_collected: bool = bool(record.get("memory_collected", false))

		if unlocked:
			var best_str := "★ Kỷ lục: %d bước" % best_moves if best_moves > 0 else "Chưa hoàn thành"
			var mem_str := " ◆ Ký ức" if memory_collected else ""
			level_btn.text = "MÀN %02d\n%s\n%s%s" % [i + 1, level_name, best_str, mem_str]
			level_btn.pressed.connect(_on_level_pressed.bind(i))
		else:
			level_btn.text = "MÀN %02d\n🔒 Khóa" % [i + 1]

		_style_level_card(level_btn, COLOR_CYAN if unlocked else Color(0.25, 0.32, 0.42), unlocked)
		_grid_container.add_child(level_btn)


func _style_level_card(button: Button, accent: Color, unlocked: bool) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.35, 0.42, 0.52))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_SURFACE if unlocked else COLOR_LOCKED
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.5)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		button.add_theme_stylebox_override(state, style)


func _style_button(button: Button, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.3, 0.38, 0.48))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_SURFACE
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.5)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		button.add_theme_stylebox_override(state, style)


func _on_prev_chapter() -> void:
	if _current_chapter > 0:
		_current_chapter -= 1
		_render_chapter_levels()


func _on_next_chapter() -> void:
	if _current_chapter < CHAPTERS.size() - 1:
		_current_chapter += 1
		_render_chapter_levels()


func _on_level_pressed(i: int) -> void:
	GameState.current_level = i
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")
