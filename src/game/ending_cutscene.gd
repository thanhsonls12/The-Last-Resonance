class_name EndingCutscene
extends Control

const COLOR_CYAN := Color(0.12, 0.90, 1.0)
const COLOR_AMBER := Color(1.0, 0.55, 0.15)
const COLOR_EMERALD := Color(0.35, 1.0, 0.65)
const COLOR_BG := Color(0.015, 0.02, 0.04, 0.98)

var _choice_container: VBoxContainer
var _epilogue_panel: PanelContainer
var _epilogue_title: Label
var _epilogue_quote: Label
var _epilogue_cg_rect: TextureRect
var _epilogue_body: RichTextLabel
var _epilogue_meaning: Label
var _restart_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 1. Background
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_tex := load("res://assets/ui/start_menu_background_android_v2.png") as Texture2D
	if bg_tex != null:
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = COLOR_BG
	add_child(overlay)

	# 2. Main Margin Container
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	# 3. Choice Phase Container
	_choice_container = VBoxContainer.new()
	_choice_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choice_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_choice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_choice_container.add_theme_constant_override("separation", 24)
	margin.add_child(_choice_container)

	var header := Label.new()
	header.text = "LÕI TRUNG TÂM — PHÁN QUYẾT CUỐI CÙNG"
	var hs := LabelSettings.new()
	hs.font_size = 28
	hs.font_color = COLOR_CYAN
	hs.outline_size = 8
	hs.outline_color = Color.BLACK
	header.label_settings = hs
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_container.add_child(header)

	var sub := Label.new()
	sub.text = "Không có ô Goal nào được định sẵn. Tương lai của Asteria nằm ở lựa chọn của ngươi, Kiro."
	var ss := LabelSettings.new()
	ss.font_size = 15
	ss.font_color = Color(0.7, 0.85, 0.95)
	sub.label_settings = ss
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_container.add_child(sub)

	# Button Choices Row
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	_choice_container.add_child(btn_hbox)

	var mem_count := GameState.memory_fragment_count()
	var total_mem := StoryData.get_total_fragments()
	var has_all_memories := mem_count >= total_mem

	# Ending 1 Button
	var btn1 := _create_choice_button(
		"I. RESTORE\n(TÁI SINH)",
		"Kết nối Central Core.\nĐánh thức Resonance Network.",
		COLOR_CYAN
	)
	btn1.pressed.connect(_on_ending_selected.bind("RESTORE"))
	btn_hbox.add_child(btn1)

	# Ending 2 Button
	var btn2 := _create_choice_button(
		"II. RELEASE\n(GIẢI THOÁT)",
		"Ngắt nguồn vĩnh viễn.\nGiải phóng các mảnh ý thức.",
		COLOR_AMBER
	)
	btn2.pressed.connect(_on_ending_selected.bind("RELEASE"))
	btn_hbox.add_child(btn2)

	# Ending 3 Button
	var btn3 := _create_choice_button(
		"III. PRESERVE\n(BẢO TỒN & TỰ DO)",
		"Lưu trữ độc lập.\nGiải phóng EVA và Kiro." if has_all_memories else "🔒 YÊU CẦU 15/15 KÝ ỨC\n(Hiện có: %d/%d)" % [mem_count, total_mem],
		COLOR_EMERALD,
		not has_all_memories
	)
	if has_all_memories:
		btn3.pressed.connect(_on_ending_selected.bind("PRESERVE"))
	btn_hbox.add_child(btn3)

	# 4. Epilogue Panel (Hidden by default)
	_epilogue_panel = PanelContainer.new()
	_epilogue_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_epilogue_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_epilogue_panel.visible = false

	var eps := StyleBoxFlat.new()
	eps.bg_color = Color(0.01, 0.02, 0.04, 0.96)
	eps.border_color = COLOR_CYAN
	eps.set_border_width_all(2)
	eps.set_corner_radius_all(10)
	eps.shadow_color = Color(0.05, 0.45, 0.8, 0.4)
	eps.shadow_size = 20
	eps.content_margin_left = 36
	eps.content_margin_right = 36
	eps.content_margin_top = 28
	eps.content_margin_bottom = 28
	_epilogue_panel.add_theme_stylebox_override("panel", eps)
	margin.add_child(_epilogue_panel)

	var ep_vbox := VBoxContainer.new()
	ep_vbox.add_theme_constant_override("separation", 16)
	_epilogue_panel.add_child(ep_vbox)

	_epilogue_title = Label.new()
	var ets := LabelSettings.new()
	ets.font_size = 24
	ets.font_color = COLOR_CYAN
	_epilogue_title.label_settings = ets
	_epilogue_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_vbox.add_child(_epilogue_title)

	_epilogue_quote = Label.new()
	var eqs := LabelSettings.new()
	eqs.font_size = 18
	eqs.font_color = Color(1.0, 0.85, 0.4)
	_epilogue_quote.label_settings = eqs
	_epilogue_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_vbox.add_child(_epilogue_quote)

	var sep := ColorRect.new()
	sep.custom_minimum_size.y = 1
	sep.color = Color(0.12, 0.85, 1.0, 0.3)
	ep_vbox.add_child(sep)

	# Ending CG Image
	_epilogue_cg_rect = TextureRect.new()
	_epilogue_cg_rect.custom_minimum_size = Vector2(0, 240)
	_epilogue_cg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_epilogue_cg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ep_vbox.add_child(_epilogue_cg_rect)

	_epilogue_body = RichTextLabel.new()
	_epilogue_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_epilogue_body.bbcode_enabled = true
	_epilogue_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ep_vbox.add_child(_epilogue_body)

	_epilogue_meaning = Label.new()
	var ems := LabelSettings.new()
	ems.font_size = 14
	ems.font_color = Color(0.65, 0.85, 0.95)
	_epilogue_meaning.label_settings = ems
	_epilogue_meaning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ep_vbox.add_child(_epilogue_meaning)

	var ep_bottom := HBoxContainer.new()
	ep_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	ep_vbox.add_child(ep_bottom)

	_restart_btn = Button.new()
	_restart_btn.text = "  TRỞ VỀ MENU CHÍNH  "
	_restart_btn.custom_minimum_size = Vector2(220, 48)
	var restart_style := StyleBoxFlat.new()
	restart_style.bg_color = Color(0.06, 0.22, 0.42, 0.9)
	restart_style.border_color = COLOR_CYAN
	restart_style.set_border_width_all(2)
	restart_style.set_corner_radius_all(8)
	_restart_btn.add_theme_stylebox_override("normal", restart_style)
	_restart_btn.pressed.connect(_on_return_to_menu)
	ep_bottom.add_child(_restart_btn)


func _create_choice_button(title: String, desc: String, accent: Color, is_disabled := false) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 200)
	btn.disabled = is_disabled
	btn.text = "%s\n\n%s" % [title, desc]

	for state in ["normal", "hover", "pressed", "disabled"]:
		var s := StyleBoxFlat.new()
		s.set_corner_radius_all(10)
		s.set_border_width_all(2)
		s.content_margin_left = 18
		s.content_margin_right = 18
		s.content_margin_top = 16
		s.content_margin_bottom = 16
		if state == "disabled":
			s.bg_color = Color(0.02, 0.03, 0.05, 0.6)
			s.border_color = Color(0.2, 0.25, 0.3, 0.3)
		elif state == "hover":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.25)
			s.border_color = Color.WHITE
			s.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
			s.shadow_size = 14
		elif state == "pressed":
			s.bg_color = Color(accent.r, accent.g, accent.b, 0.45)
			s.border_color = accent
		else:
			s.bg_color = Color(0.02, 0.05, 0.10, 0.85)
			s.border_color = Color(accent.r, accent.g, accent.b, 0.5)
		btn.add_theme_stylebox_override(state, s)

	return btn


func _on_ending_selected(ending_key: String) -> void:
	var data: Dictionary = StoryData.get_ending_data(ending_key)
	_choice_container.visible = false
	_epilogue_panel.visible = true

	var accent: Color = data.get("color", COLOR_CYAN)
	_epilogue_title.text = str(data.get("title", ""))
	_epilogue_title.label_settings.font_color = accent
	_epilogue_quote.text = "“%s”" % str(data.get("quote", ""))

	# Load Ending CG Texture
	var cg_path := "res://assets/ui/endings/ending_%s_cg.jpg" % ending_key.to_lower()
	var cg_tex := load(cg_path) as Texture2D
	if cg_tex != null:
		_epilogue_cg_rect.texture = cg_tex
		_epilogue_cg_rect.visible = true
	else:
		_epilogue_cg_rect.visible = false
	
	var summary_text: String = str(data.get("summary", ""))
	_epilogue_body.text = "[font_size=18][color=#dff6ff]%s[/color][/font_size]" % summary_text
	_epilogue_meaning.text = "Ý NGHĨA: %s" % str(data.get("meaning", ""))


func _on_return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
