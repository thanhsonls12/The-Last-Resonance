class_name ChapterIntroCard
extends CanvasLayer

signal finished

var _root_panel: Control
var _card_panel: PanelContainer
var _roman_label: Label
var _title_label: Label
var _subtitle_label: Label
var _lore_label: Label
var _protocol_label: Label
var _continue_prompt: Label
var _divider: ColorRect

var _pulse_tween: Tween
var _fade_tween: Tween
var _is_active: bool = false


func _ready() -> void:
	layer = 12
	_build_ui()
	visible = false


func _build_ui() -> void:
	_root_panel = Control.new()
	_root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_panel)

	# Fullscreen Translucent Backdrop (Allows 3D game level to remain visible)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.008, 0.015, 0.025, 0.45)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_root_panel.add_child(bg)

	# Centered Card Container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(center)

	_card_panel = PanelContainer.new()
	_card_panel.custom_minimum_size = Vector2(640, 420)
	_card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_card_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# 1. Roman Chapter Header: ─── CHƯƠNG II ───
	_roman_label = Label.new()
	_roman_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rom_s := LabelSettings.new()
	rom_s.font_size = 14
	rom_s.font_color = Color(0.12, 0.82, 1.0)
	_roman_label.label_settings = rom_s
	vbox.add_child(_roman_label)

	# 2. English Title: THE MECHANICAL FOUNDRY
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tit_s := LabelSettings.new()
	tit_s.font_size = 26
	tit_s.font_color = Color.WHITE
	tit_s.outline_size = 4
	tit_s.outline_color = Color(0.02, 0.05, 0.1, 0.9)
	_title_label.label_settings = tit_s
	vbox.add_child(_title_label)

	# 3. Vietnamese Subtitle: (LÒ RÈN CƠ KHÍ)
	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sub_s := LabelSettings.new()
	sub_s.font_size = 16
	sub_s.font_color = Color(0.55, 0.85, 1.0, 0.9)
	_subtitle_label.label_settings = sub_s
	vbox.add_child(_subtitle_label)

	# 4. Glowing Divider Line
	_divider = ColorRect.new()
	_divider.custom_minimum_size = Vector2(0, 2)
	_divider.color = Color(0.12, 0.82, 1.0, 0.6)
	vbox.add_child(_divider)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# 5. Lore Narrative Quote
	_lore_label = Label.new()
	_lore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lore_s := LabelSettings.new()
	lore_s.font_size = 13
	lore_s.font_color = Color(0.90, 0.94, 0.98, 0.96)
	lore_s.line_spacing = 4
	_lore_label.label_settings = lore_s
	vbox.add_child(_lore_label)

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer2)

	# 6. Protocol Badge: [ EVA PROTOCOL: ACT-02 ]
	_protocol_label = Label.new()
	_protocol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var prot_s := LabelSettings.new()
	prot_s.font_size = 11
	prot_s.font_color = Color(0.45, 0.78, 0.98, 0.85)
	_protocol_label.label_settings = prot_s
	vbox.add_child(_protocol_label)

	# 7. Continue Touch Prompt: [ ▶ CHẠM ĐỂ TIẾP TỤC ]
	_continue_prompt = Label.new()
	_continue_prompt.text = "[ ▶ CHẠM ĐỂ TIẾP TỤC ]"
	_continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cont_s := LabelSettings.new()
	cont_s.font_size = 12
	cont_s.font_color = Color(0.12, 0.88, 1.0, 0.9)
	_continue_prompt.label_settings = cont_s
	vbox.add_child(_continue_prompt)


func show_chapter(chapter_id: int) -> void:
	var ch_data: Dictionary = StoryData.get_chapter_data(chapter_id)
	var roman: String = str(ch_data.get("roman", "CHƯƠNG %d" % chapter_id))
	var title: String = str(ch_data.get("title", ""))
	var subtitle: String = str(ch_data.get("subtitle", ""))
	var lore: String = str(ch_data.get("lore_quote", ch_data.get("quote", "")))
	var protocol: String = str(ch_data.get("protocol", "[ EVA PROTOCOL: ACT-%02d ]" % chapter_id))
	var accent: Color = ch_data.get("accent_color", Color(0.12, 0.82, 1.0))

	# Format text
	_roman_label.text = "─── %s ───" % roman
	_roman_label.label_settings.font_color = accent
	_title_label.text = title
	_subtitle_label.text = subtitle
	_subtitle_label.label_settings.font_color = Color(accent.r, accent.g, accent.b, 0.85)
	_divider.color = Color(accent.r, accent.g, accent.b, 0.6)
	_lore_label.text = lore
	_protocol_label.text = protocol
	_continue_prompt.label_settings.font_color = accent

	# Styling Card Panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.025, 0.045, 0.90)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(accent.r, accent.g, accent.b, 0.75)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.shadow_color = Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 0.45)
	style.shadow_size = 18
	_card_panel.add_theme_stylebox_override("panel", style)

	# Animation & State
	_root_panel.modulate.a = 0.0
	visible = true
	_is_active = true

	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root_panel, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Start Pulsing Prompt Animation
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_continue_prompt, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(_continue_prompt, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE)


func _input(event: InputEvent) -> void:
	if not visible or not _is_active:
		return
	var is_touch := event is InputEventScreenTouch and event.is_pressed()
	var is_click := event is InputEventMouseButton and event.is_pressed()
	var is_key := event is InputEventKey and event.is_pressed() and not event.is_echo()

	if is_touch or is_click or is_key:
		_dismiss()
		get_viewport().set_input_as_handled()


func _dismiss() -> void:
	if not _is_active:
		return
	_is_active = false

	if _pulse_tween:
		_pulse_tween.kill()
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(_root_panel, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _fade_tween.finished
	visible = false
	finished.emit()
