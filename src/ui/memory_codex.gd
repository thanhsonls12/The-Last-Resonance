class_name MemoryCodex
extends Control

# Colors
const COLOR_CYAN := Color(0.12, 0.85, 1.0)
const COLOR_PURPLE := Color(0.75, 0.35, 1.0)
const COLOR_ORANGE := Color(1.0, 0.52, 0.12)
const COLOR_GOLD := Color(1.0, 0.82, 0.2)
const COLOR_BG := Color(0.015, 0.025, 0.05, 0.96)
const COLOR_PANEL := Color(0.03, 0.06, 0.11, 0.92)
const COLOR_LOCKED := Color(0.18, 0.22, 0.28, 0.6)

const CHAPTER_COLORS: Dictionary = {
	1: COLOR_CYAN,
	2: COLOR_ORANGE,
	3: COLOR_PURPLE,
	4: COLOR_GOLD,
}

var _selected_id: int = 1
var _current_chapter_filter: int = 0 # 0 = All chapters
var _fragment_buttons: Dictionary = {}
var _filter_buttons: Dictionary = {}

var _detail_title: Label
var _detail_sender: Label
var _detail_category: Label
var _detail_chapter: Label
var _detail_content: RichTextLabel
var _detail_status: Label
var _list_container: VBoxContainer
var _portrait_rect: TextureRect
var _sync_bar: ProgressBar
var _sync_label: Label

# Typewriter variables
var _typewriter_tween: Tween
var _full_content_text: String = ""


func _ready() -> void:
	_build_ui()
	_select_fragment(1)


func _build_ui() -> void:
	# 1. Background Art
	var bg_tex := load("res://assets/ui/start_menu_background_android_v2.png") as Texture2D
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(bg)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = COLOR_BG
	add_child(overlay)

	# 2. Main Margin Layout
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(main_vbox)

	# 3. Header Bar
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 54
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(header)

	var back_btn := Button.new()
	back_btn.text = "  QUAY LẠI"
	back_btn.custom_minimum_size = Vector2(130, 42)
	var back_icon := load("res://assets/ui/icons/back.svg") as Texture2D
	if back_icon:
		back_btn.icon = back_icon
		back_btn.expand_icon = true
	_style_action_button(back_btn, COLOR_CYAN)
	EchoAudioManager.bind_button_sfx(self, back_btn, &"ui_cancel")
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	# Central Title & Terminal Codename
	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_box)

	var sub_header_lbl := Label.new()
	sub_header_lbl.text = "ASTERIA ARCHIVE TERMINAL // PROTOCOL 327"
	var subs := LabelSettings.new()
	subs.font_size = 11
	subs.font_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.75)
	sub_header_lbl.label_settings = subs
	sub_header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(sub_header_lbl)

	var title_lbl := Label.new()
	title_lbl.text = "THƯ VIỆN KÝ ỨC ASTERIA"
	var ts := LabelSettings.new()
	ts.font_size = 22
	ts.font_color = Color.WHITE
	ts.outline_size = 5
	ts.outline_color = Color(0.01, 0.02, 0.05)
	title_lbl.label_settings = ts
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title_lbl)

	var header_spacer2 := Control.new()
	header_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer2)

	# Memory Sync Gauge
	var count := GameState.memory_fragment_count()
	var total := StoryData.get_total_fragments()
	var sync_pct: float = (float(count) / float(maxi(total, 1))) * 100.0

	var sync_box := PanelContainer.new()
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.03, 0.08, 0.16, 0.85)
	sbs.border_color = COLOR_PURPLE if count == total else COLOR_CYAN
	sbs.set_border_width_all(1)
	sbs.set_corner_radius_all(6)
	sbs.content_margin_left = 14
	sbs.content_margin_right = 14
	sbs.content_margin_top = 4
	sbs.content_margin_bottom = 4
	sync_box.add_theme_stylebox_override("panel", sbs)

	var sync_inner := VBoxContainer.new()
	sync_inner.add_theme_constant_override("separation", 2)
	sync_box.add_child(sync_inner)

	_sync_label = Label.new()
	_sync_label.text = "ĐỒNG BỘ: %.1f%% (%d/%d)" % [sync_pct, count, total]
	var sls := LabelSettings.new()
	sls.font_size = 12
	sls.font_color = Color(0.85, 0.95, 1.0)
	_sync_label.label_settings = sls
	_sync_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sync_inner.add_child(_sync_label)

	_sync_bar = ProgressBar.new()
	_sync_bar.custom_minimum_size = Vector2(160, 6)
	_sync_bar.show_percentage = false
	_sync_bar.max_value = 100.0
	_sync_bar.value = sync_pct
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.05, 0.1, 0.15, 0.9)
	bar_bg.set_corner_radius_all(3)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = COLOR_PURPLE if count == total else COLOR_CYAN
	bar_fill.set_corner_radius_all(3)
	_sync_bar.add_theme_stylebox_override("background", bar_bg)
	_sync_bar.add_theme_stylebox_override("fill", bar_fill)
	sync_inner.add_child(_sync_bar)

	header.add_child(sync_box)

	# 4. Content Area (Split Left / Right)
	var content_split := HBoxContainer.new()
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.add_theme_constant_override("separation", 18)
	main_vbox.add_child(content_split)

	# --- Left Panel: Filter Tabs + Scrollable List ---
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size.x = 420
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lps := StyleBoxFlat.new()
	lps.bg_color = COLOR_PANEL
	lps.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.3)
	lps.set_border_width_all(1)
	lps.set_corner_radius_all(8)
	lps.content_margin_left = 12
	lps.content_margin_right = 12
	lps.content_margin_top = 10
	lps.content_margin_bottom = 12
	left_panel.add_theme_stylebox_override("panel", lps)
	content_split.add_child(left_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 10)
	left_panel.add_child(left_vbox)

	# Chapter Filter Tabs
	var tab_bar := HBoxContainer.new()
	tab_bar.custom_minimum_size.y = 34
	tab_bar.add_theme_constant_override("separation", 6)
	left_vbox.add_child(tab_bar)

	var filter_options: Array = [
		{"name": "TẤT CẢ", "id": 0, "color": COLOR_CYAN},
		{"name": "CH.I", "id": 1, "color": COLOR_CYAN},
		{"name": "CH.II", "id": 2, "color": COLOR_ORANGE},
		{"name": "CH.III", "id": 3, "color": COLOR_PURPLE},
		{"name": "CH.IV", "id": 4, "color": COLOR_GOLD},
	]

	for opt in filter_options:
		var f_btn := Button.new()
		f_btn.text = str(opt["name"])
		f_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f_btn.custom_minimum_size.y = 30
		_style_filter_button(f_btn, opt["color"], opt["id"] == _current_chapter_filter)
		var cid: int = int(opt["id"])
		f_btn.pressed.connect(_on_chapter_filter_changed.bind(cid))
		EchoAudioManager.bind_button_sfx(self, f_btn, &"ui_focus")
		_filter_buttons[cid] = f_btn
		tab_bar.add_child(f_btn)

	# Scroll List
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vbox.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_list_container)

	_populate_list()

	# --- Right Panel: Holo Memory Reader & Transcript ---
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rps := StyleBoxFlat.new()
	rps.bg_color = COLOR_PANEL
	rps.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.4)
	rps.set_border_width_all(1)
	rps.set_corner_radius_all(8)
	rps.content_margin_left = 24
	rps.content_margin_right = 24
	rps.content_margin_top = 20
	rps.content_margin_bottom = 20
	right_panel.add_theme_stylebox_override("panel", rps)
	content_split.add_child(right_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 14)
	right_panel.add_child(detail_vbox)

	# Header: Sender Portrait + Hologram Metadata
	var header_card := HBoxContainer.new()
	header_card.add_theme_constant_override("separation", 16)
	detail_vbox.add_child(header_card)

	# Portrait Frame
	var portrait_panel := PanelContainer.new()
	portrait_panel.custom_minimum_size = Vector2(72, 72)
	var pps := StyleBoxFlat.new()
	pps.bg_color = Color(0.02, 0.05, 0.1, 0.95)
	pps.border_color = COLOR_CYAN
	pps.set_border_width_all(1)
	pps.set_corner_radius_all(6)
	portrait_panel.add_theme_stylebox_override("panel", pps)
	header_card.add_child(portrait_panel)

	_portrait_rect = TextureRect.new()
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.custom_minimum_size = Vector2(68, 68)
	portrait_panel.add_child(_portrait_rect)

	# Metadata Box
	var meta_vbox := VBoxContainer.new()
	meta_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_vbox.add_theme_constant_override("separation", 4)
	header_card.add_child(meta_vbox)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 8)
	meta_vbox.add_child(meta_row)

	_detail_category = Label.new()
	var cats := LabelSettings.new()
	cats.font_size = 11
	cats.font_color = COLOR_ORANGE
	_detail_category.label_settings = cats
	meta_row.add_child(_detail_category)

	var dot := Label.new()
	dot.text = "•"
	dot.modulate = Color(0.4, 0.5, 0.6)
	meta_row.add_child(dot)

	_detail_chapter = Label.new()
	var chs := LabelSettings.new()
	chs.font_size = 11
	chs.font_color = Color(0.6, 0.75, 0.9)
	_detail_chapter.label_settings = chs
	meta_row.add_child(_detail_chapter)

	_detail_sender = Label.new()
	var sents := LabelSettings.new()
	sents.font_size = 14
	sents.font_color = Color(0.8, 0.92, 1.0)
	_detail_sender.label_settings = sents
	meta_vbox.add_child(_detail_sender)

	_detail_title = Label.new()
	var dts := LabelSettings.new()
	dts.font_size = 19
	dts.font_color = Color.WHITE
	_detail_title.label_settings = dts
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta_vbox.add_child(_detail_title)

	# Holographic Separator Line
	var sep := ColorRect.new()
	sep.custom_minimum_size.y = 1
	sep.color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.3)
	detail_vbox.add_child(sep)

	# Transcript Text Area (With Typewriter effect)
	_detail_content = RichTextLabel.new()
	_detail_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_content.bbcode_enabled = true
	_detail_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.scroll_active = true
	detail_vbox.add_child(_detail_content)

	# Footer Status Bar
	var footer_row := HBoxContainer.new()
	footer_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	detail_vbox.add_child(footer_row)

	_detail_status = Label.new()
	var sts := LabelSettings.new()
	sts.font_size = 12
	sts.font_color = Color(0.45, 0.58, 0.72)
	_detail_status.label_settings = sts
	footer_row.add_child(_detail_status)


func _on_chapter_filter_changed(chapter_id: int) -> void:
	_current_chapter_filter = chapter_id
	for cid in _filter_buttons.keys():
		var btn: Button = _filter_buttons[cid]
		var col: Color = CHAPTER_COLORS.get(cid, COLOR_CYAN)
		_style_filter_button(btn, col, cid == _current_chapter_filter)
	_populate_list()


func _populate_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()
	_fragment_buttons.clear()

	var total := StoryData.get_total_fragments()
	for i in range(1, total + 1):
		var frag: Dictionary = StoryData.get_fragment_data(i)
		var ch_num: int = int(frag.get("chapter", 1))

		# Apply filter
		if _current_chapter_filter != 0 and ch_num != _current_chapter_filter:
			continue

		var is_unlocked: bool = _is_unlocked(i)
		var ch_color: Color = CHAPTER_COLORS.get(ch_num, COLOR_CYAN)

		var btn := Button.new()
		btn.custom_minimum_size.y = 48
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var btn_title: String = str(frag.get("title", "KÝ ỨC %02d" % i))
		if not is_unlocked:
			btn.text = "  [DỮ LIỆU BẢO MẬT #%02d]" % i
			var lock_icon := load("res://assets/ui/icons/lock.svg") as Texture2D
			if lock_icon:
				btn.icon = lock_icon
				btn.expand_icon = true
			_style_list_button(btn, COLOR_LOCKED, false)
			EchoAudioManager.bind_button_sfx(self, btn, &"ui_error")
			btn.pressed.connect(_select_fragment.bind(i))
		else:
			btn.text = "  ◆ %s" % btn_title
			var unlock_icon := load("res://assets/ui/icons/unlock.svg") as Texture2D
			if unlock_icon:
				btn.icon = unlock_icon
				btn.expand_icon = true
			_style_list_button(btn, ch_color, i == _selected_id)
			EchoAudioManager.bind_button_sfx(self, btn, &"ui_page_next")
			btn.pressed.connect(_select_fragment.bind(i))

		_fragment_buttons[i] = btn
		_list_container.add_child(btn)


func _is_unlocked(frag_id: int) -> bool:
	var level_idx := frag_id - 1
	var record: Dictionary = GameState.get_level_record(level_idx)
	if bool(record.get("memory_collected", false)):
		return true
	return level_idx < GameState.unlocked - 1


func _select_fragment(frag_id: int) -> void:
	_selected_id = frag_id
	var frag: Dictionary = StoryData.get_fragment_data(frag_id)
	var unlocked := _is_unlocked(frag_id)
	var ch_num: int = int(frag.get("chapter", 1))
	var ch_color: Color = CHAPTER_COLORS.get(ch_num, COLOR_CYAN)

	# Update list styles
	for id in _fragment_buttons.keys():
		var b: Button = _fragment_buttons[id]
		var f_data: Dictionary = StoryData.get_fragment_data(id)
		var b_color: Color = CHAPTER_COLORS.get(int(f_data.get("chapter", 1)), COLOR_CYAN)
		if _is_unlocked(id):
			_style_list_button(b, b_color, id == frag_id)
		else:
			_style_list_button(b, COLOR_LOCKED, id == frag_id)

	if _typewriter_tween != null and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	if not unlocked:
		_detail_title.text = "DỮ LIỆU BẢO MẬT BỊ KHÓA"
		_detail_sender.text = "HỆ THỐNG PHÒNG THỦ ASTERIA"
		_detail_category.text = "[LƯU TRỮ CHƯA GIẢI MÃ]"
		_detail_chapter.text = "PHÂN KHU CHAPTER %d" % ch_num
		_portrait_rect.texture = load("res://assets/ui/portraits/system_avatar_dialogue.png")
		_portrait_rect.modulate = Color(0.4, 0.4, 0.4, 0.8)

		var locked_msg: String = "[color=#778899]Mảnh ký ức này hiện chưa thể giải mã do các Lumina Core tương ứng chưa được kết nối.\n\n[color=#ffaa44]▶ YÊU CẦU TRUY CẬP:[/color] Vượt qua Level %d trong Chiến dịch để giải phóng phân vùng bộ nhớ này.[/color]" % frag_id
		_detail_content.text = locked_msg
		_detail_status.text = "STATUS: ENCRYPTED // SECTOR-%02d OFFLINE" % frag_id
		return

	_portrait_rect.modulate = Color.WHITE
	_portrait_rect.texture = _resolve_portrait(str(frag.get("sender", "")))

	_detail_title.text = str(frag.get("title", ""))
	_detail_sender.text = "NGUỒN PHÁT: %s" % str(frag.get("sender", "VÔ DANH"))
	_detail_category.text = "[%s]" % str(frag.get("category", "SYSTEM_LOG"))
	_detail_chapter.text = "PHÂN KHU CHAPTER %d" % ch_num

	var raw_content: String = str(frag.get("content", ""))
	_full_content_text = "[font_size=16][color=#dff4ff]%s[/color][/font_size]" % raw_content
	_detail_content.text = _full_content_text
	_detail_content.visible_ratio = 0.0

	# Typewriter reveal animation
	_typewriter_tween = create_tween()
	var duration: float = clampf(float(raw_content.length()) * 0.008, 0.35, 1.2)
	_typewriter_tween.tween_property(_detail_content, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_LINEAR)

	_detail_status.text = "STATUS: DECRYPTED // PROTOCOL AST-%03d ONLINE" % frag_id


func _resolve_portrait(sender: String) -> Texture2D:
	var s := sender.to_upper()
	if "EVA" in s:
		return load("res://assets/ui/portraits/eva_avatar_dialogue.png") as Texture2D
	elif "ELIAS" in s or "TIẾN SĨ" in s or "VALE" in s:
		return load("res://assets/ui/portraits/elias_avatar_dialogue.png") as Texture2D
	elif "KIRO" in s or "K-7" in s:
		return load("res://assets/ui/portraits/kiro_avatar_dialogue.png") as Texture2D
	return load("res://assets/ui/portraits/system_avatar_dialogue.png") as Texture2D


func _style_action_button(btn: Button, accent: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(6)
		s.content_margin_left = 14
		s.content_margin_right = 14
		if state == "hover":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.25)
			s.border_color = accent
			s.set_border_width_all(1)
		elif state == "pressed":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.45)
			s.border_color = Color.WHITE
			s.set_border_width_all(1)
		else:
			s.bg_color = Color(0.04, 0.08, 0.14, 0.85)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.4)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override(state, s)


func _style_filter_button(btn: Button, accent: Color, is_active: bool) -> void:
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(4)
		s.content_margin_left = 8
		s.content_margin_right = 8
		if is_active:
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.35)
			s.border_color = accent
			s.set_border_width_all(1)
		elif state == "hover":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.7)
			s.set_border_width_all(1)
		else:
			s.bg_color = Color(0.02, 0.05, 0.1, 0.6)
			s.border_color = Color(0.15, 0.25, 0.35, 0.4)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override(state, s)
	btn.add_theme_color_override("font_color", Color.WHITE if is_active else Color(0.7, 0.8, 0.9))


func _style_list_button(btn: Button, accent: Color, is_selected: bool) -> void:
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(5)
		s.content_margin_left = 12
		s.content_margin_right = 12
		if is_selected:
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.28)
			s.border_color = accent
			s.set_border_width_all(1)
		elif state == "hover":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.6)
			s.set_border_width_all(1)
		else:
			s.bg_color = Color(0.02, 0.04, 0.08, 0.65)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.18)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override(state, s)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
