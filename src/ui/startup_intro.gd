extends Control
## Startup-only presentation. Returning from settings or gameplay stays instant.

static var shown_this_session := false

var logo_material: Material
var _timeline: Tween
var _sound: AudioStreamPlayer
var _closing := false


func _ready() -> void:
	if shown_this_session:
		queue_free()
		return
	shown_this_session = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	grab_focus()

	var darkness := ColorRect.new()
	darkness.color = Color(0.004, 0.008, 0.018)
	darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(darkness)

	if GameState.reduced_motion:
		_timeline = create_tween()
		_timeline.tween_interval(0.1)
		_timeline.tween_callback(_finish)
		return

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 18)
	center.add_child(content)
	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo_title_center.jpg")
	logo.material = logo_material
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(logo)
	var resize_logo := func() -> void:
		logo.custom_minimum_size = Vector2(minf(600.0, size.x * 0.84), minf(245.0, size.y * 0.38))
	resized.connect(resize_logo)
	resize_logo.call()
	var tagline := Label.new()
	tagline.text = "Một tiếng vọng. Một ký ức còn lại."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 16)
	tagline.add_theme_color_override("font_color", Color(0.65, 0.85, 0.94))
	content.add_child(tagline)
	content.modulate.a = 0.0

	var hint := Label.new()
	hint.text = "Chạm hoặc nhấn phím bất kỳ để bỏ qua"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -56.0
	hint.offset_bottom = -24.0
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(0.7, 0.8, 0.9, 0.8)
	add_child(hint)

	_sound = AudioStreamPlayer.new()
	_sound.stream = preload("res://assets/audio/sfx/SFX_MemoryFragment_Collect.wav")
	# Master carries the global gain; apply SFX gain locally even before buses exist.
	_sound.volume_db = linear_to_db(maxf(GameState.sfx_volume, 0.0001)) - 10.0
	add_child(_sound)
	if GameState.sfx_enabled and GameState.master_volume > 0.0:
		AudioServer.set_bus_volume_db(0, linear_to_db(GameState.master_volume))
		_sound.play()

	_timeline = create_tween()
	_timeline.tween_interval(0.2)
	_timeline.tween_property(content, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	_timeline.tween_interval(1.35)
	_timeline.tween_callback(_finish)


func _input(event: InputEvent) -> void:
	if shown_this_session and not is_queued_for_deletion():
		# Consume the skip event so it cannot also activate a menu button.
		get_viewport().set_input_as_handled()
		if event.is_pressed() and not event.is_echo() and (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton):
			_finish()


func _finish() -> void:
	if _closing:
		return
	_closing = true
	if _timeline and _timeline.is_running():
		_timeline.kill()
	var fade := create_tween().set_parallel(true)
	fade.tween_property(self, "modulate:a", 0.0, 0.35)
	if is_instance_valid(_sound):
		fade.tween_property(_sound, "volume_db", -80.0, 0.3)
	fade.chain().tween_callback(func() -> void:
		release_focus()
		queue_free())
