class_name DialogueBox
extends CanvasLayer

signal dialogue_finished
signal line_started(index: int, speaker: String)

const COLOR_EVA := Color(0.12, 0.90, 1.0)
const COLOR_ELIAS := Color(1.0, 0.58, 0.15)
const COLOR_KIRO := Color(0.20, 0.95, 0.70)
const COLOR_SYSTEM := Color(0.85, 0.90, 0.95)

var _dialogue_lines: Array = []
var _current_index: int = 0
var _is_typing: bool = false
var _type_tween: Tween

var _root_container: Control
var _panel: PanelContainer
var _portrait_frame: PanelContainer
var _portrait: TextureRect
var _speaker_label: Label
var _text_label: RichTextLabel
var _indicator: Label
var _glitch_rect: ColorRect

static var _portraits: Dictionary = {}


func _ready() -> void:
	layer = 10
	_load_portraits()
	_build_ui()
	visible = false



func _load_portraits() -> void:
	if not _portraits.is_empty():
		return
	var eva_tex: Texture2D = load("res://assets/ui/portraits/eva_avatar_dialogue.png")
	var elias_tex: Texture2D = load("res://assets/ui/portraits/elias_avatar_dialogue.png")
	var kiro_tex: Texture2D = load("res://assets/ui/portraits/kiro_avatar_dialogue.png")
	var sys_tex: Texture2D = load("res://assets/ui/portraits/system_avatar_dialogue.png")

	_portraits["EVA"] = eva_tex
	_portraits["Eva"] = eva_tex
	_portraits["DR. ELIAS VALE"] = elias_tex
	_portraits["ELIAS"] = elias_tex
	_portraits["Elias"] = elias_tex
	_portraits["KIRO-K7"] = kiro_tex
	_portraits["KIRO"] = kiro_tex
	_portraits["Kiro"] = kiro_tex
	_portraits["HỆ THỐNG"] = sys_tex
	_portraits["Hệ Thống"] = sys_tex
	_portraits["Hệ thống"] = sys_tex
	_portraits["SYSTEM"] = sys_tex
	_portraits["System"] = sys_tex


func _build_ui() -> void:
	_root_container = Control.new()
	_root_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root_container)

	# Optional Glitch overlay
	_glitch_rect = ColorRect.new()
	_glitch_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glitch_rect.color = Color(0, 0, 0, 0)
	var glitch_shader := load("res://assets/shaders/screen_glitch_corruption.gdshader") as Shader
	if glitch_shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = glitch_shader
		mat.set_shader_parameter("glitch_intensity", 0.0)
		_glitch_rect.material = mat
	_root_container.add_child(_glitch_rect)

	# Bottom Dialogue Panel
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 60
	_panel.offset_right = -60
	_panel.offset_bottom = -28
	_panel.offset_top = -180

	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.015, 0.03, 0.06, 0.95)
	ps.border_color = COLOR_EVA
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.05, 0.45, 0.85, 0.35)
	ps.shadow_size = 14
	ps.content_margin_left = 18
	ps.content_margin_right = 18
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", ps)
	_root_container.add_child(_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	_panel.add_child(hbox)

	# Portrait Container
	_portrait_frame = PanelContainer.new()
	_portrait_frame.custom_minimum_size = Vector2(120, 120)
	var pbs := StyleBoxFlat.new()
	pbs.bg_color = Color(0.02, 0.05, 0.10, 0.85)
	pbs.border_color = Color(0.12, 0.85, 1.0, 0.4)
	pbs.set_border_width_all(1)
	pbs.set_corner_radius_all(6)
	_portrait_frame.add_theme_stylebox_override("panel", pbs)
	hbox.add_child(_portrait_frame)

	_portrait = TextureRect.new()
	_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_frame.add_child(_portrait)

	# Text Content Column
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(text_vbox)

	_speaker_label = Label.new()
	var sps := LabelSettings.new()
	sps.font_size = 16
	sps.font_color = COLOR_EVA
	sps.outline_size = 4
	sps.outline_color = Color.BLACK
	_speaker_label.label_settings = sps
	text_vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.bbcode_enabled = true
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.scroll_active = false
	text_vbox.add_child(_text_label)

	# Continue indicator
	_indicator = Label.new()
	_indicator.text = "[ Chạm để tiếp tục ▼ ]"
	_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var ind_s := LabelSettings.new()
	ind_s.font_size = 12
	ind_s.font_color = Color(0.5, 0.65, 0.75, 0.8)
	_indicator.label_settings = ind_s
	text_vbox.add_child(_indicator)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_pressed():
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.is_pressed():
		advance()
		get_viewport().set_input_as_handled()



func play_dialogue(lines: Array) -> void:
	if lines.is_empty():
		return
	_dialogue_lines = lines
	_current_index = 0
	visible = true
	_display_line(_current_index)


func advance() -> void:
	if _is_typing:
		# Instant finish current line
		if _type_tween:
			_type_tween.kill()
		_text_label.visible_ratio = 1.0
		_is_typing = false
		return

	_current_index += 1
	if _current_index >= _dialogue_lines.size():
		visible = false
		dialogue_finished.emit()
	else:
		_display_line(_current_index)


func _display_line(index: int) -> void:
	var item: Dictionary = _dialogue_lines[index]
	var speaker: String = str(item.get("speaker", "HỆ THỐNG"))
	var text: String = str(item.get("text", ""))

	_speaker_label.text = speaker
	_text_label.text = "[font_size=18]%s[/font_size]" % text
	_text_label.visible_ratio = 0.0
	_is_typing = true

	# Set Speaker Color & Portrait
	var color := COLOR_SYSTEM
	var upper_spk := speaker.to_upper()
	if "EVA" in upper_spk:
		color = COLOR_EVA
	elif "ELIAS" in upper_spk:
		color = COLOR_ELIAS
	elif "KIRO" in upper_spk:
		color = COLOR_KIRO

	_speaker_label.label_settings.font_color = color
	
	# Portrait lookup
	var port_tex: Texture2D = null
	if item.has("portrait") and item["portrait"] is Texture2D:
		port_tex = item["portrait"]
	elif _portraits.has(speaker):
		port_tex = _portraits[speaker]
	else:
		for key: String in _portraits.keys():
			if key.to_upper() in upper_spk or key in speaker:
				port_tex = _portraits[key]
				break
	_portrait.texture = port_tex
	_portrait.visible = port_tex != null
	_portrait_frame.visible = port_tex != null

	# Trigger Glitch effect briefly on EVA alert or warning
	if "EVA" in upper_spk and _glitch_rect.material is ShaderMaterial:
		var sm := _glitch_rect.material as ShaderMaterial
		sm.set_shader_parameter("glitch_intensity", 0.4)
		var gt := create_tween()
		gt.tween_property(sm, "shader_parameter/glitch_intensity", 0.0, 0.35)

	# Fast & crisp Typewriter Tween
	var duration: float = clampf(float(text.length()) * 0.015, 0.25, 0.45)
	if _type_tween:
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(_text_label, "visible_ratio", 1.0, duration)
	_type_tween.finished.connect(func() -> void:
		_is_typing = false
	)

	line_started.emit(index, speaker)
