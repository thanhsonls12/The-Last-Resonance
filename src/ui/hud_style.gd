class_name HudStyle
extends RefCounted


static func label_settings(
		font_size: int,
		font_color: Color,
		outline_size := 0,
		outline_color := Color.BLACK,
		shadow_size := 0,
		shadow_color := Color.TRANSPARENT) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = font_color
	settings.outline_size = outline_size
	settings.outline_color = outline_color
	settings.shadow_size = shadow_size
	settings.shadow_color = shadow_color
	return settings


static func apply_button(button: Button, accent: Color, compact: bool, high_contrast: bool) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15 if compact else 16)
	button.add_theme_color_override("font_color", Color.WHITE if high_contrast else Color(0.84, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 3 if high_contrast else 0)
	button.add_theme_constant_override("icon_max_width", 24 if compact else 22)
	button.add_theme_constant_override("h_separation", 8)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.BLACK if high_contrast else Color(0.035, 0.065, 0.12, 0.96)
		style.set_border_width_all(3 if high_contrast else 2)
		style.border_color = Color.WHITE if high_contrast else (accent if state != "normal" else Color(accent.r, accent.g, accent.b, 0.65))
		style.set_corner_radius_all(10)
		style.content_margin_left = 12.0 if compact else 16.0
		style.content_margin_right = 12.0 if compact else 16.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		button.add_theme_stylebox_override(state, style)


static func panel_style(accent: Color, high_contrast: bool, wide_margins := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.BLACK if high_contrast else Color(0.015, 0.03, 0.055, 0.96)
	style.border_color = Color.WHITE if high_contrast else accent
	style.set_border_width_all(3 if high_contrast else 2)
	style.set_corner_radius_all(16)
	style.shadow_size = 24
	style.shadow_color = Color(0.0, 0.65, 1.0, 0.45)
	if wide_margins:
		style.content_margin_left = 32.0
		style.content_margin_right = 32.0
		style.content_margin_top = 24.0
		style.content_margin_bottom = 24.0
	return style
