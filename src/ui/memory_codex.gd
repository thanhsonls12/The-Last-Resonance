class_name MemoryCodex
extends Control

const COLOR_CYAN := Color(0.12, 0.85, 1.0)
const COLOR_PURPLE := Color(0.72, 0.35, 1.0)
const COLOR_ORANGE := Color(1.0, 0.48, 0.12)
const COLOR_BG := Color(0.015, 0.025, 0.05, 0.96)
const COLOR_PANEL := Color(0.03, 0.06, 0.11, 0.90)
const COLOR_LOCKED := Color(0.15, 0.18, 0.22, 0.6)

var _selected_id: int = 1
var _fragment_buttons: Dictionary = {}
var _detail_title: Label
var _detail_sender: Label
var _detail_category: Label
var _detail_content: RichTextLabel
var _detail_status: Label
var _list_container: VBoxContainer
var _portrait_rect: TextureRect


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

	# 2. Main Layout (Margin)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_vbox)

	# 3. Header Bar
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 54
	main_vbox.add_child(header)

	var back_btn := Button.new()
	back_btn.text = "  QUAY LẠI"
	back_btn.custom_minimum_size = Vector2(140, 44)
	var back_icon := load("res://assets/ui/icons/back.svg") as Texture2D
	if back_icon:
		back_btn.icon = back_icon
		back_btn.expand_icon = true
	_style_button(back_btn, COLOR_CYAN)
	back_btn.pressed.connect(_on_back_pressed)
	header.add_child(back_btn)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	var title_box := VBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(title_box)

	var title_lbl := Label.new()
	title_lbl.text = "THƯ VIỆN KÝ ỨC ASTERIA"
	var ts := LabelSettings.new()
	ts.font_size = 22
	ts.font_color = COLOR_CYAN
	ts.outline_size = 6
	ts.outline_color = Color(0.01, 0.02, 0.05)
	title_lbl.label_settings = ts
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_box.add_child(title_lbl)

	var header_spacer2 := Control.new()
	header_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer2)

	# Progress Badge
	var count := GameState.memory_fragment_count()
	var total := StoryData.get_total_fragments()
	var badge := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.04, 0.12, 0.22, 0.9)
	bs.border_color = COLOR_PURPLE if count == total else COLOR_CYAN
	bs.set_border_width_all(1)
	bs.set_corner_radius_all(6)
	bs.content_margin_left = 14
	bs.content_margin_right = 14
	bs.content_margin_top = 6
	bs.content_margin_bottom = 6
	badge.add_theme_stylebox_override("panel", bs)
	var badge_lbl := Label.new()
	badge_lbl.text = "◆ %d/%d ĐÃ GIẢI MÃ" % [count, total]
	var badge_ls := LabelSettings.new()
	badge_ls.font_size = 14
	badge_ls.font_color = Color(0.85, 0.95, 1.0)
	badge_lbl.label_settings = badge_ls
	badge.add_child(badge_lbl)
	header.add_child(badge)

	# 4. Content Area (Split Left / Right)
	var content_split := HBoxContainer.new()
	content_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_split.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_split)

	# --- Left Panel: Scrollable Memory List ---
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size.x = 380
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lps := StyleBoxFlat.new()
	lps.bg_color = COLOR_PANEL
	lps.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.25)
	lps.set_border_width_all(1)
	lps.set_corner_radius_all(8)
	lps.content_margin_left = 12
	lps.content_margin_right = 12
	lps.content_margin_top = 12
	lps.content_margin_bottom = 12
	left_panel.add_theme_stylebox_override("panel", lps)
	content_split.add_child(left_panel)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_list_container)

	_populate_list()

	# --- Right Panel: Memory Reader & Transcript ---
	var right_panel := PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rps := StyleBoxFlat.new()
	rps.bg_color = COLOR_PANEL
	rps.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.35)
	rps.set_border_width_all(1)
	rps.set_corner_radius_all(8)
	rps.content_margin_left = 28
	rps.content_margin_right = 28
	rps.content_margin_top = 24
	rps.content_margin_bottom = 24
	right_panel.add_theme_stylebox_override("panel", rps)
	content_split.add_child(right_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 14)
	right_panel.add_child(detail_vbox)

	# Metadata Header
	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 12)
	detail_vbox.add_child(meta_row)

	_detail_category = Label.new()
	var cats := LabelSettings.new()
	cats.font_size = 12
	cats.font_color = COLOR_ORANGE
	_detail_category.label_settings = cats
	meta_row.add_child(_detail_category)

	var dot := Label.new()
	dot.text = "•"
	dot.modulate = Color(0.5, 0.5, 0.5)
	meta_row.add_child(dot)

	_detail_sender = Label.new()
	var sents := LabelSettings.new()
	sents.font_size = 13
	sents.font_color = Color(0.75, 0.88, 1.0)
	_detail_sender.label_settings = sents
	meta_row.add_child(_detail_sender)

	_detail_title = Label.new()
	var dts := LabelSettings.new()
	dts.font_size = 20
	dts.font_color = Color.WHITE
	_detail_title.label_settings = dts
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(_detail_title)

	var sep := ColorRect.new()
	sep.custom_minimum_size.y = 1
	sep.color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.25)
	detail_vbox.add_child(sep)

	# Transcript Text Area
	_detail_content = RichTextLabel.new()
	_detail_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_content.bbcode_enabled = true
	_detail_content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_content.scroll_active = true
	detail_vbox.add_child(_detail_content)

	# Footer Status
	_detail_status = Label.new()
	var sts := LabelSettings.new()
	sts.font_size = 12
	sts.font_color = Color(0.5, 0.6, 0.7)
	_detail_status.label_settings = sts
	detail_vbox.add_child(_detail_status)


func _populate_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()
	_fragment_buttons.clear()

	var total := StoryData.get_total_fragments()
	for i in range(1, total + 1):
		var frag: Dictionary = StoryData.get_fragment_data(i)
		var is_unlocked: bool = _is_unlocked(i)

		var btn := Button.new()
		btn.custom_minimum_size.y = 48
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		var btn_title: String = str(frag.get("title", "KÝ ỨC %02d" % i))
		if not is_unlocked:
			btn.text = "  🔒 [DỮ LIỆU ĐÃ BỊ KHÓA #%02d]" % i
			btn.disabled = true
			_style_list_button(btn, COLOR_LOCKED, false)
		else:
			btn.text = "  ◆ %s" % btn_title
			_style_list_button(btn, COLOR_CYAN, false)
			btn.pressed.connect(_select_fragment.bind(i))

		_fragment_buttons[i] = btn
		_list_container.add_child(btn)


func _is_unlocked(frag_id: int) -> bool:
	var level_idx := frag_id - 1
	var record: Variant = GameState.records.get(level_idx, {})
	if record is Dictionary and bool(record.get("memory_collected", false)):
		return true
	# Alternatively unlocked if level completed
	return level_idx < GameState.unlocked - 1


func _select_fragment(frag_id: int) -> void:
	_selected_id = frag_id
	var frag: Dictionary = StoryData.get_fragment_data(frag_id)
	var unlocked := _is_unlocked(frag_id)

	# Update list styles
	for id in _fragment_buttons.keys():
		var b: Button = _fragment_buttons[id]
		if _is_unlocked(id):
			_style_list_button(b, COLOR_CYAN, id == frag_id)

	if not unlocked:
		_detail_title.text = "DỮ LIỆU BẢO MẬT BỊ KHÓA"
		_detail_sender.text = "HỆ THỐNG ASTERIA"
		_detail_category.text = "[CHƯA GIẢI MÃ]"
		_detail_content.text = "[color=#556677]Mảnh ký ức này chưa được thu thập.\n\nHãy hoàn thành Level %d để giải mã dữ liệu này và tìm hiểu sự thật về Asteria.[/color]" % frag_id
		_detail_status.text = "TRẠNG THÁI: OFFLINE / KHÓA"
		return

	_detail_title.text = str(frag.get("title", ""))
	_detail_sender.text = "NGUỒN PHÁT: %s" % str(frag.get("sender", "VÔ DANH"))
	_detail_category.text = "[%s]" % str(frag.get("category", "SYSTEM_LOG"))
	
	var raw_content: String = str(frag.get("content", ""))
	_detail_content.text = "[font_size=17][color=#d8f4ff]%s[/color][/font_size]" % raw_content
	_detail_status.text = "TRẠNG THÁI: GIẢI MÃ HOÀN TẤT • PHÂN KHU CHAPTER %d" % int(frag.get("chapter", 1))


func _style_button(btn: Button, accent: Color) -> void:
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(6)
		s.content_margin_left = 12
		s.content_margin_right = 12
		if state == "hover":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.25)
			s.border_color = accent
			s.set_border_width_all(1)
		elif state == "pressed":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.45)
			s.border_color = Color.WHITE
			s.set_border_width_all(1)
		else:
			s.bg_color = Color(0.04, 0.08, 0.14, 0.8)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.3)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override(state, s)


func _style_list_button(btn: Button, accent: Color, is_selected: bool) -> void:
	for state in ["normal", "hover", "pressed"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(4)
		s.content_margin_left = 10
		s.content_margin_right = 10
		if is_selected:
			s.bg_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.28)
			s.border_color = COLOR_CYAN
			s.set_border_width_all(1)
		elif state == "hover":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.15)
			s.border_color = accent
			s.set_border_width_all(1)
		else:
			s.bg_color = Color(0.02, 0.04, 0.08, 0.6)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.15)
			s.set_border_width_all(1)
		btn.add_theme_stylebox_override(state, s)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
