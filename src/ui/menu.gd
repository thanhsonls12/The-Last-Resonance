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
var _top_bar: HBoxContainer
var _logo_center_container: CenterContainer
var _menu_logo: TextureRect
var _level_scroll: ScrollContainer


func _chapter_data(index: int) -> Dictionary:
	return StoryData.get_chapter_data(int(CHAPTERS[index]["id"]))


func _chapter_display_name(index: int) -> String:
	var data := _chapter_data(index)
	return "%s: %s" % [str(data.get("roman", "CHƯƠNG %d" % (index + 1))), str(data.get("title", ""))]


func _ready() -> void:
	_init_chapter_from_progress()
	_build_ui()
	_render_chapter_levels()
	if get_viewport() != null and not get_viewport().size_changed.is_connected(_layout_for_viewport):
		get_viewport().size_changed.connect(_layout_for_viewport)
	_layout_for_viewport()


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
	_top_bar = HBoxContainer.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_left = 24
	_top_bar.offset_right = -24
	_top_bar.offset_top = 20
	_top_bar.offset_bottom = 68
	_top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_top_bar)

	var back_btn := Button.new()
	back_btn.text = "← QUAY LẠI"
	back_btn.custom_minimum_size = Vector2(140, 44)
	_style_button(back_btn, COLOR_CYAN)
	EchoAudioManager.bind_button_sfx(self, back_btn, &"ui_cancel")
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn"))
	_top_bar.add_child(back_btn)

	# Logo Header Centered independently across the top bar
	_logo_center_container = CenterContainer.new()
	_logo_center_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_logo_center_container.offset_top = 16
	_logo_center_container.offset_bottom = 72
	_logo_center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo_center_container)

	_menu_logo = TextureRect.new()
	_menu_logo.custom_minimum_size = Vector2(340, 52)
	_menu_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var logo_tex := load("res://assets/ui/logo_header_horizontal.jpg") as Texture2D
	if logo_tex != null:
		_menu_logo.texture = logo_tex

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float luma = max(col.r, max(col.g, col.b));
	float alpha = smoothstep(0.03, 0.35, luma);
	COLOR = vec4(col.rgb * COLOR.rgb, alpha * COLOR.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_menu_logo.material = mat
	_logo_center_container.add_child(_menu_logo)

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
	EchoAudioManager.bind_button_sfx(self, _prev_chapter_btn, &"ui_page_prev")
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
	EchoAudioManager.bind_button_sfx(self, _next_chapter_btn, &"ui_page_next")
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
	_level_scroll = ScrollContainer.new()
	_level_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_level_scroll.offset_top = 160
	_level_scroll.offset_bottom = -30
	_level_scroll.offset_left = 40
	_level_scroll.offset_right = -40
	_level_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_level_scroll)

	var center_wrap := CenterContainer.new()
	center_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_level_scroll.add_child(center_wrap)

	_grid_container = GridContainer.new()
	_grid_container.columns = 2
	_grid_container.add_theme_constant_override("h_separation", 28)
	_grid_container.add_theme_constant_override("v_separation", 22)
	center_wrap.add_child(_grid_container)


func _layout_for_viewport() -> void:
	if not is_instance_valid(_grid_container) or not is_instance_valid(_level_scroll):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var compact := viewport_size.x < 720.0 or viewport_size.y < 560.0
	var edge := clampf(minf(viewport_size.x, viewport_size.y) * 0.045, 16.0, 40.0)
	_level_scroll.offset_left = edge
	_level_scroll.offset_right = -edge
	_level_scroll.offset_top = 154.0 if compact else 160.0
	_level_scroll.offset_bottom = -edge

	# Tính chính xác số lượng màn chơi của chương hiện tại từ dữ liệu chương
	var start_idx: int = int(CHAPTERS[_current_chapter]["start"])
	var end_idx: int = mini(int(CHAPTERS[_current_chapter]["end"]), Levels.ALL.size() - 1)
	var level_count: int = maxi(1, end_idx - start_idx + 1)

	# Bố cục lưới cân xứng tuyệt đối:
	# - 4 màn: LUÔN bố trí 2x2 (2 cột x 2 hàng), không bao giờ để 3+1 gây lẻ màn
	# - 3 màn: 3 cột trên màn hình rộng (1 hàng x 3 màn) hoặc 1-2 cột trên màn nhỏ
	# - 2 màn: 2 cột
	# - 1 màn: 1 cột
	if compact:
		_grid_container.columns = 1
	elif level_count == 4:
		_grid_container.columns = 2
	elif level_count == 3:
		_grid_container.columns = 3 if viewport_size.x >= 920.0 else (2 if viewport_size.x >= 640.0 else 1)
	elif level_count <= 2:
		_grid_container.columns = level_count
	else:
		_grid_container.columns = 2 if viewport_size.x < 1060.0 else 3

	var gap := 16.0 if compact else 28.0
	_grid_container.add_theme_constant_override("h_separation", gap)
	_grid_container.add_theme_constant_override("v_separation", 16.0 if compact else 22.0)
	
	# Tính kích thước thẻ hợp lý và cân đối
	var cols: float = float(_grid_container.columns)
	var max_grid_w := 820.0 if _grid_container.columns == 2 else 1140.0
	var avail_w := minf(viewport_size.x - edge * 2.0, max_grid_w)
	var card_width := clampf((avail_w - gap * (cols - 1.0)) / cols, 240.0, 420.0)

	for child in _grid_container.get_children():
		if child is Button:
			var level_button := child as Button
			level_button.custom_minimum_size = Vector2(card_width, 106.0 if compact else 115.0)

	if _logo_center_container:
		_logo_center_container.visible = not compact
		_logo_center_container.offset_top = 14.0
		_logo_center_container.offset_bottom = 68.0
	if _menu_logo:
		_menu_logo.visible = not compact
		_menu_logo.custom_minimum_size = Vector2(280.0, 48.0)
	if _top_bar:
		_top_bar.offset_left = edge
		_top_bar.offset_right = -edge
		if _top_bar.get_child_count() > 0 and _top_bar.get_child(0) is Button:
			(_top_bar.get_child(0) as Button).custom_minimum_size.x = 120.0 if compact else 140.0
	if _chapter_title_label and _chapter_title_label.label_settings:
		_chapter_title_label.label_settings.font_size = 17 if compact else 22
		_chapter_title_label.label_settings.font_color = Color.WHITE if GameState.high_contrast else Color(1.0, 0.65, 0.2)
	if _chapter_desc_label and _chapter_desc_label.label_settings:
		_chapter_desc_label.label_settings.font_size = 12 if compact else 14
		_chapter_desc_label.label_settings.font_color = Color.WHITE if GameState.high_contrast else Color(0.65, 0.82, 0.94, 0.75)


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
		level_btn.disabled = false

		var level_data: LevelData = Levels.get_data(i)
		var level_name: String = str(level_data.title if level_data else Levels.ALL[i].get("name", "Màn %d" % (i + 1)))
		var par_moves: int = level_data.par_moves if level_data else 0
		var achievement: Dictionary = GameState.get_level_achievement(i)
		var best_moves: int = int(achievement.get("actual_moves", achievement.get("best_moves", 0)))
		var memory_collected: bool = bool(record.get("memory_collected", false))

		if unlocked:
			var stars: int = int(achievement.get("stars", 0))
			var star_str := "★★★ " if stars == 3 else ("★★☆ " if stars == 2 else ("★☆☆ " if stars == 1 else ""))
			var best_str := "Chưa hoàn thành (Par %d)" % par_moves
			if best_moves > 0:
				if bool(achievement.get("legacy", false)):
					best_str = "%sThành tích cũ · %d bước" % [star_str, best_moves]
				else:
					best_str = "%s%d tính sao · %d bước +%d phí" % [star_str, int(achievement.get("score_moves", best_moves)), best_moves, int(achievement.get("hint_penalty", 0))]
			var mem_str := "  •  ◆ Ký ức" if memory_collected else ""
			level_btn.text = "MÀN %02d\n%s\n%s%s" % [i + 1, level_name, best_str, mem_str]
			var unlock_icon := load("res://assets/ui/icons/unlock.svg") as Texture2D
			if unlock_icon:
				level_btn.icon = unlock_icon
				level_btn.expand_icon = true
			EchoAudioManager.bind_button_sfx(self, level_btn, &"ui_level_select")
			level_btn.pressed.connect(_on_level_pressed.bind(i))
		else:
			level_btn.text = "MÀN %02d\nKhóa" % [i + 1]
			var lock_icon := load("res://assets/ui/icons/lock.svg") as Texture2D
			if lock_icon:
				level_btn.icon = lock_icon
				level_btn.expand_icon = true
			EchoAudioManager.bind_button_sfx(self, level_btn, &"ui_error")
			level_btn.pressed.connect(func() -> void: GameState.haptic_feedback(10, 0.12))

		_style_level_card(level_btn, COLOR_CYAN if unlocked else Color(0.25, 0.32, 0.42), unlocked)
		_grid_container.add_child(level_btn)

	_layout_for_viewport()


func _style_level_card(button: Button, accent: Color, unlocked: bool) -> void:
	var high := GameState.high_contrast
	button.add_theme_font_size_override("font_size", 17 if high else 16)
	button.add_theme_color_override("font_color", Color.WHITE if high else Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.75, 0.75) if high else Color(0.35, 0.42, 0.52))
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.BLACK if high else (COLOR_SURFACE if unlocked else COLOR_LOCKED)
		style.border_width_left = 3 if high else 2
		style.border_width_top = 3 if high else 2
		style.border_width_right = 3 if high else 2
		style.border_width_bottom = 3 if high else 2
		style.border_color = Color.WHITE if high else (accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.5))
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
	var high := GameState.high_contrast
	button.add_theme_font_size_override("font_size", 17 if high else 16)
	button.add_theme_color_override("font_color", Color.WHITE if high else Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.75, 0.75) if high else Color(0.3, 0.38, 0.48))
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.BLACK if high else COLOR_SURFACE
		style.border_width_left = 3 if high else 2
		style.border_width_top = 3 if high else 2
		style.border_width_right = 3 if high else 2
		style.border_width_bottom = 3 if high else 2
		style.border_color = Color.WHITE if high else (accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.5))
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
	GameState.set_current_level(i)
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")
