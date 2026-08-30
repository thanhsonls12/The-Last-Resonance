extends Control

const BTN_SIZE := Vector2(340, 52)
const BTN_PRIMARY_SIZE := Vector2(340, 56)
const COLOR_CYAN := Color(0.12, 0.82, 1.0)
const COLOR_ORANGE := Color(1.0, 0.52, 0.12)
const COLOR_GLASS := Color(0.01, 0.02, 0.04, 0.28)
const TOTAL_MEMORIES := 15


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	# 1. Background Texture
	var bg_tex_rect := TextureRect.new()
	bg_tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_tex := load("res://assets/ui/start_menu_background_android_v2.png") as Texture2D
	if bg_tex != null:
		bg_tex_rect.texture = bg_tex
	add_child(bg_tex_rect)

	# 2. Subtle Cinematic Vignette (keeps background visible)
	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.008, 0.014, 0.028, 0.22)
	add_child(vignette)

	# 3. Soft Ambient Center Glow
	var center_glow := ColorRect.new()
	center_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_glow.color = Color(0.04, 0.25, 0.42, 0.08)
	add_child(center_glow)

	# 3.5. Dynamic Meteor & Ambient Particle FX Layer
	var fx_layer := MeteorCanvas.new()
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)

	# 4. Center Container for Perfect Centering
	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	# 5. Semi-Transparent Glassmorphism Hero Panel
	var glass_panel := PanelContainer.new()
	var glass_style := StyleBoxFlat.new()
	glass_style.bg_color = COLOR_GLASS
	glass_style.border_width_left = 1
	glass_style.border_width_top = 1
	glass_style.border_width_right = 1
	glass_style.border_width_bottom = 1
	glass_style.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.22)
	glass_style.corner_radius_top_left = 18
	glass_style.corner_radius_top_right = 18
	glass_style.corner_radius_bottom_left = 18
	glass_style.corner_radius_bottom_right = 18
	glass_style.shadow_color = Color(0.0, 0.3, 0.6, 0.12)
	glass_style.shadow_size = 14
	glass_style.content_margin_left = 38.0
	glass_style.content_margin_right = 38.0
	glass_style.content_margin_top = 18.0
	glass_style.content_margin_bottom = 24.0
	glass_panel.add_theme_stylebox_override("panel", glass_style)
	center_container.add_child(glass_panel)

	# Content Box inside Glass Panel
	var content_box := VBoxContainer.new()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.add_theme_constant_override("separation", 8)
	glass_panel.add_child(content_box)

	# Title Block with Centered Crystal Logo (Sample B)
	var logo_container := CenterContainer.new()
	content_box.add_child(logo_container)

	var logo_rect := TextureRect.new()
	logo_rect.custom_minimum_size = Vector2(480, 185)
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var logo_tex := load("res://assets/ui/logo_title_center.jpg") as Texture2D
	if logo_tex != null:
		logo_rect.texture = logo_tex

	# Shader to remove black background and blend glowing crystal seamlessly with background
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
	logo_rect.material = mat
	logo_container.add_child(logo_rect)

	# Gentle breathing glow animation (floating effect)
	var logo_tween := create_tween().set_loops()
	logo_tween.tween_property(logo_rect, "modulate", Color(1.15, 1.15, 1.30), 2.2).set_trans(Tween.TRANS_SINE)
	logo_tween.tween_property(logo_rect, "modulate", Color(0.90, 0.95, 1.05), 2.2).set_trans(Tween.TRANS_SINE)

	# Action Buttons List
	var btn_box := VBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 10)
	content_box.add_child(btn_box)

	var has_progress := GameState.unlocked > 1 or GameState.current_level > 0
	var play_btn := Button.new()
	play_btn.text = "  TIẾP TỤC" if has_progress else "  BẮT ĐẦU CHƠI"
	play_btn.custom_minimum_size = BTN_PRIMARY_SIZE
	play_btn.icon = load("res://assets/ui/icons/play.svg")
	play_btn.expand_icon = true
	_style_button(play_btn, COLOR_CYAN)
	play_btn.pressed.connect(_on_continue)
	btn_box.add_child(play_btn)

	var select_btn := Button.new()
	select_btn.text = "  CHỌN MÀN CHƠI"
	select_btn.custom_minimum_size = BTN_SIZE
	select_btn.icon = load("res://assets/ui/icons/menu.svg")
	select_btn.expand_icon = true
	_style_button(select_btn, COLOR_CYAN)
	select_btn.pressed.connect(_on_level_select)
	btn_box.add_child(select_btn)

	var archive_btn := Button.new()
	archive_btn.text = "  THƯ VIỆN KÝ ỨC"
	archive_btn.custom_minimum_size = BTN_SIZE
	archive_btn.icon = load("res://assets/ui/icons/memory_fragment.svg")
	archive_btn.expand_icon = true
	_style_button(archive_btn, COLOR_CYAN)
	archive_btn.pressed.connect(_on_archive)
	btn_box.add_child(archive_btn)

	# 6. Top Bar Header
	var top_bar := HBoxContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 32
	top_bar.offset_right = -32
	top_bar.offset_top = 22
	top_bar.offset_bottom = 68
	add_child(top_bar)

	var memory_badge := PanelContainer.new()
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.02, 0.06, 0.12, 0.85)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.border_color = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, 0.5)
	badge_style.corner_radius_top_left = 8
	badge_style.corner_radius_top_right = 8
	badge_style.corner_radius_bottom_left = 8
	badge_style.corner_radius_bottom_right = 8
	badge_style.content_margin_left = 14.0
	badge_style.content_margin_right = 14.0
	badge_style.content_margin_top = 6.0
	badge_style.content_margin_bottom = 6.0
	memory_badge.add_theme_stylebox_override("panel", badge_style)
	top_bar.add_child(memory_badge)

	var memory_lbl := Label.new()
	var mem_count := mini(GameState.memory_fragment_count(), TOTAL_MEMORIES)
	memory_lbl.text = "★ %d/%d KÝ ỨC" % [mem_count, TOTAL_MEMORIES]
	var ms := LabelSettings.new()
	ms.font_size = 14
	ms.font_color = Color(0.78, 0.94, 1.0)
	memory_lbl.label_settings = ms
	memory_badge.add_child(memory_lbl)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_spacer)

	var version_lbl := Label.new()
	version_lbl.text = "ASTERIA // SYS-327"
	var vs := LabelSettings.new()
	vs.font_size = 13
	vs.font_color = Color(0.55, 0.72, 0.88, 0.7)
	version_lbl.label_settings = vs
	top_bar.add_child(version_lbl)

	# 7. Bottom Bar
	var bottom_bar := HBoxContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_left = 32
	bottom_bar.offset_right = -32
	bottom_bar.offset_bottom = -22
	bottom_bar.offset_top = -68
	bottom_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(bottom_bar)

	var settings_btn := Button.new()
	settings_btn.text = "  CÀI ĐẶT"
	settings_btn.icon = load("res://assets/ui/icons/settings.svg")
	settings_btn.expand_icon = true
	settings_btn.custom_minimum_size = Vector2(140, 44)
	_style_button(settings_btn, COLOR_CYAN)
	settings_btn.pressed.connect(_on_settings)
	bottom_bar.add_child(settings_btn)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_bar.add_child(bottom_spacer)

	if not OS.has_feature("android"):
		var quit_btn := Button.new()
		quit_btn.text = "  THOÁT"
		quit_btn.icon = load("res://assets/ui/icons/quit.svg")
		quit_btn.expand_icon = true
		quit_btn.custom_minimum_size = Vector2(130, 44)
		_style_button(quit_btn, COLOR_ORANGE)
		quit_btn.pressed.connect(_on_quit)
		bottom_bar.add_child(quit_btn)


func _style_button(button: Button, accent: Color) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.80, 0.92, 1.0, 0.88))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		if state == "hover":
			style.bg_color = Color(0.04, 0.16, 0.30, 0.88)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color.WHITE
			style.shadow_color = Color(accent.r, accent.g, accent.b, 0.70)
			style.shadow_size = 18
		elif state == "pressed":
			style.bg_color = Color(0.06, 0.24, 0.44, 0.95)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = accent
			style.shadow_color = Color(accent.r, accent.g, accent.b, 0.85)
			style.shadow_size = 20
		else:
			style.bg_color = Color(0.015, 0.035, 0.07, 0.35)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(accent.r, accent.g, accent.b, 0.22)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 18.0
		style.content_margin_right = 18.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, style)


func _on_continue() -> void:
	if Levels.ALL.is_empty():
		get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")
		return
	var target_lvl := clampi(GameState.current_level, 0, maxi(0, GameState.unlocked - 1))
	GameState.current_level = target_lvl
	get_tree().change_scene_to_file("res://scenes/game/main.tscn")


func _on_level_select() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


func _on_archive() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/memory_codex.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn")


func _on_quit() -> void:
	get_tree().quit()


class MeteorCanvas:
	extends Control

	var meteors: Array = []
	var dust_particles: Array = []
	var spawn_timer := 0.0
	var next_spawn_interval := 1.2
	var rng := RandomNumberGenerator.new()


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		rng.randomize()
		_init_dust()


	func _init_dust() -> void:
		for i in 40:
			dust_particles.append({
				"pos": Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080)),
				"speed": rng.randf_range(12.0, 32.0),
				"wobble_speed": rng.randf_range(1.0, 2.5),
				"phase": rng.randf_range(0.0, TAU),
				"radius": rng.randf_range(1.2, 2.8),
				"color": Color(0.2, 0.85, 1.0, rng.randf_range(0.25, 0.65)) if rng.randf() > 0.35 else Color(1.0, 0.65, 0.2, rng.randf_range(0.3, 0.7)),
			})


	func _process(delta: float) -> void:
		var vp_size := get_viewport_rect().size
		if vp_size.x <= 1.0:
			vp_size = Vector2(1920, 1080)

		# 1. Update Dust Particles
		for dust in dust_particles:
			dust["pos"].y -= float(dust["speed"]) * delta
			dust["phase"] += float(dust["wobble_speed"]) * delta
			dust["pos"].x += sin(float(dust["phase"])) * 0.4
			if dust["pos"].y < -20.0:
				dust["pos"].y = vp_size.y + 20.0
				dust["pos"].x = rng.randf_range(0, vp_size.x)

		# 2. Meteor Spawner
		spawn_timer += delta
		if spawn_timer >= next_spawn_interval:
			spawn_timer = 0.0
			next_spawn_interval = rng.randf_range(1.5, 3.8)
			_spawn_meteor(vp_size)

		# 3. Update Meteors
		var alive_meteors: Array = []
		for m in meteors:
			m["progress"] += delta / float(m["duration"])
			m["pos"] += (m["dir"] as Vector2) * float(m["speed"]) * delta
			if m["progress"] < 1.0:
				alive_meteors.append(m)
		meteors = alive_meteors

		queue_redraw()


	func _spawn_meteor(vp_size: Vector2) -> void:
		var start_x := rng.randf_range(vp_size.x * 0.25, vp_size.x * 1.15)
		var start_y := rng.randf_range(-60.0, vp_size.y * 0.35)
		var angle_rad := deg_to_rad(rng.randf_range(130.0, 145.0))
		var dir := Vector2(cos(angle_rad), sin(angle_rad)).normalized()

		var is_orange := rng.randf() < 0.25
		var base_col := Color(1.0, 0.60, 0.18) if is_orange else Color(0.20, 0.90, 1.0)
		var speed := rng.randf_range(750.0, 1250.0)
		var length := rng.randf_range(120.0, 220.0)

		meteors.append({
			"pos": Vector2(start_x, start_y),
			"dir": dir,
			"speed": speed,
			"length": length,
			"progress": 0.0,
			"duration": rng.randf_range(1.0, 1.8),
			"color": base_col,
			"width": rng.randf_range(2.0, 3.2),
		})


	func _draw() -> void:
		# Draw Floating Dust
		for dust in dust_particles:
			var col: Color = dust["color"]
			var pulse := 0.7 + 0.3 * sin(float(dust["phase"]))
			var alpha_col := Color(col.r, col.g, col.b, col.a * pulse)
			draw_circle(dust["pos"], float(dust["radius"]), alpha_col)

		# Draw Meteors with glowing tail
		for m in meteors:
			var pos: Vector2 = m["pos"]
			var dir: Vector2 = m["dir"]
			var length: float = m["length"]
			var prog: float = m["progress"]
			var base_col: Color = m["color"]
			var width: float = m["width"]

			# Alpha fade in at start, fade out at end
			var alpha := 1.0
			if prog < 0.2:
				alpha = prog / 0.2
			elif prog > 0.65:
				alpha = (1.0 - prog) / 0.35
			alpha = clampf(alpha, 0.0, 1.0)

			var tail_end := pos - dir * length
			# Draw multi-pass tail for glowing neon falloff
			var seg_count := 8
			for i in seg_count:
				var t1 := float(i) / float(seg_count)
				var t2 := float(i + 1) / float(seg_count)
				var p1 := pos.lerp(tail_end, t1)
				var p2 := pos.lerp(tail_end, t2)
				var seg_alpha := alpha * (1.0 - t1) * 0.9
				draw_line(p1, p2, Color(base_col.r, base_col.g, base_col.b, seg_alpha), width * (1.0 - t1 * 0.5))

			# Bright Head Core
			var head_color := Color(1.0, 1.0, 1.0, alpha)
			draw_circle(pos, width * 1.2, head_color)
			draw_circle(pos, width * 2.2, Color(base_col.r, base_col.g, base_col.b, alpha * 0.5))
