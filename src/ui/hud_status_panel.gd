class_name HudStatusPanel
extends Control

const HUD_STYLE = preload("res://src/ui/hud_style.gd")

var level_label: Label
var floor_label: Label
var floor_status_label: Label
var core_label: Label
var energy_label: Label
var lock_label: Label
var hint_label: Label
var fragment_label: Label

var _labels: Array[Label] = []
var _defaults: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label = get_node("LevelLabel")
	floor_label = get_node("FloorLabel")
	floor_status_label = get_node("FloorStatusLabel")
	core_label = get_node("CoreLabel")
	energy_label = get_node("EnergyLabel")
	lock_label = get_node("LockLabel")
	hint_label = get_node("HintLabel")
	fragment_label = get_node("FragmentLabel")
	_configure_labels()


func set_stats(level_name: String, moves: int, pushes: int, best_moves: int, par_moves := -1, hint_penalty := 0, three_star_max := 0) -> void:
	var best_text := "--" if best_moves <= 0 else str(best_moves)
	var score_moves := moves + hint_penalty
	var target_text := "/%d ★★★" % three_star_max if three_star_max > 0 else ""
	var par_text := "   |   Par: %d" % par_moves if par_moves > 0 else ""
	level_label.text = "%s   |   Bước: %d   |   Phí gợi ý: +%d   |   Tính sao: %d%s%s   |   Đẩy: %d   |   Kỷ lục: %s" % [
		level_name, moves, hint_penalty, score_moves, target_text, par_text, pushes, best_text]


func set_floor(current_floor: int, floor_count: int) -> void:
	floor_label.visible = floor_count > 1
	if floor_count > 1:
		floor_label.text = "TẦNG %d / %d" % [current_floor + 1, floor_count]


func set_floor_status(message: String) -> void:
	floor_status_label.text = message
	floor_status_label.visible = not message.is_empty()


func set_core_progress(active: int, total: int) -> void:
	core_label.visible = total > 0
	if total <= 0:
		return
	var is_all := active >= total
	core_label.text = "LUMINA CORE: %d/%d%s" % [active, total, "  •  ĐÃ VÀO VỊ TRÍ" if is_all else ""]
	core_label.label_settings.font_color = Color(0.15, 0.95, 0.75) if is_all \
		else (Color(1.0, 0.82, 0.20) if active > 0 else Color(0.70, 0.88, 1.0, 0.92))


func set_energy_nodes(active: int, total: int) -> void:
	energy_label.visible = total > 0
	if total <= 0:
		return
	energy_label.text = "◆ NÚT NĂNG LƯỢNG: %d/%d" % [active, total]
	energy_label.label_settings.font_color = Color(0.25, 1.0, 0.70) if active >= total \
		else (Color(1.0, 0.82, 0.25) if active > 0 else Color(0.70, 0.88, 1.0, 0.92))


func set_fragment(fragment: String) -> void:
	fragment_label.text = "◆ %s" % fragment
	fragment_label.visible = not fragment.is_empty()


func set_lock_progress(active: int, total: int, open: bool) -> void:
	lock_label.visible = total > 0
	if total <= 0:
		return
	lock_label.text = "%s KHÓA LIÊN ĐỘNG: %d/%d%s" % [
		"🔓" if open else "🔒", active, total, "  •  ĐÃ MỞ" if open else ""]
	lock_label.label_settings.font_color = Color(0.12, 0.95, 1.0) if open \
		else (Color(1.0, 0.78, 0.12) if active > 0 else Color(1.0, 0.30, 0.22))


func set_hint_text(message: String, shown := true) -> void:
	hint_label.text = message
	hint_label.visible = shown and not message.is_empty()


func clear_hint() -> void:
	hint_label.text = ""
	hint_label.visible = false


func apply_accessibility(high_contrast: bool) -> void:
	for label in _labels:
		var defaults: Dictionary = _defaults.get(label.get_instance_id(), {})
		label.label_settings.font_color = Color.WHITE if high_contrast else defaults.get("font_color", Color.WHITE)
		var base_outline := int(defaults.get("outline_size", 4))
		label.label_settings.outline_size = maxi(base_outline, 9) if high_contrast else base_outline
		label.label_settings.outline_color = Color.BLACK if high_contrast else defaults.get("outline_color", Color.BLACK)


func layout(viewport_size: Vector2, compact: bool) -> void:
	var edge := clampf(minf(viewport_size.x, viewport_size.y) * 0.035, 12.0, 28.0)

	# --- TẦNG 1: Thanh thông số màn chơi (Level Header & Stats) ---
	level_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	level_label.offset_left = edge + (62.0 if compact else 125.0)
	level_label.offset_right = -edge - (62.0 if compact else 135.0)
	level_label.offset_top = 8.0 if compact else 14.0
	level_label.offset_bottom = 36.0 if compact else 46.0
	level_label.label_settings.font_size = 16 if compact else 20

	# --- TẦNG 2: Mục tiêu nhiệm vụ (Cores, Energy Nodes, Locks) ---
	for entry in [
		[core_label, 46.0 if compact else 60.0, 13 if compact else 15],
		[energy_label, 70.0 if compact else 86.0, 13 if compact else 15],
		[lock_label, 94.0 if compact else 112.0, 13 if compact else 15],
	]:
		var label := entry[0] as Label
		label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		label.offset_left = edge
		label.offset_right = -edge
		label.offset_top = float(entry[1])
		label.offset_bottom = label.offset_top + 24.0
		label.label_settings.font_size = int(entry[2])

	# --- Tầng và trạng thái tầng ---
	floor_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	floor_label.offset_left = -(112.0 if compact else 150.0)
	floor_label.offset_right = -edge
	floor_label.offset_top = 46.0 if compact else 60.0
	floor_label.offset_bottom = floor_label.offset_top + 26.0
	floor_label.label_settings.font_size = 13 if compact else 15

	floor_status_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	floor_status_label.offset_left = -(230.0 if compact else 330.0)
	floor_status_label.offset_right = -edge
	floor_status_label.offset_top = 96.0 if compact else 88.0
	floor_status_label.offset_bottom = floor_status_label.offset_top + 30.0
	floor_status_label.label_settings.font_size = 10 if compact else 12

	# --- Dòng gợi ý (Hint) ---
	hint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint_label.offset_left = edge
	hint_label.offset_right = -edge
	hint_label.offset_top = 122.0 if compact else 142.0
	hint_label.offset_bottom = hint_label.offset_top + (40.0 if compact else 46.0)
	hint_label.label_settings.font_size = 13 if compact else 15

	fragment_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	fragment_label.offset_left = edge + (72.0 if compact else 150.0)
	fragment_label.offset_right = -edge - (72.0 if compact else 150.0)
	fragment_label.offset_top = -104.0 if compact else -132.0
	fragment_label.offset_bottom = -72.0 if compact else -76.0
	fragment_label.label_settings.font_size = 13 if compact else 15


func _configure_labels() -> void:
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.label_settings = HUD_STYLE.label_settings(22, Color(0.78, 0.93, 1.0), 8, Color(0.02, 0.04, 0.10, 0.95), 6, Color(0.0, 0.65, 1.0, 0.35))
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	floor_label.visible = false
	floor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_label.label_settings = HUD_STYLE.label_settings(15, Color(0.15, 0.95, 0.75), 6, Color(0.02, 0.04, 0.10, 0.95))
	floor_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	floor_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	floor_status_label.visible = false
	floor_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_status_label.label_settings = HUD_STYLE.label_settings(12, Color(1.0, 0.80, 0.26), 5, Color(0.02, 0.04, 0.10, 0.95))
	core_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core_label.visible = false
	core_label.label_settings = HUD_STYLE.label_settings(16, Color(0.70, 0.88, 1.0, 0.92), 6, Color(0.02, 0.04, 0.10, 0.95), 6, Color(0.0, 0.65, 1.0, 0.35))
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.visible = false
	energy_label.label_settings = HUD_STYLE.label_settings(15, Color(0.70, 0.88, 1.0, 0.92), 6, Color(0.02, 0.04, 0.10, 0.95))
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.visible = false
	lock_label.label_settings = HUD_STYLE.label_settings(15, Color(1.0, 0.30, 0.22), 6, Color(0.02, 0.04, 0.10, 0.95))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.visible = false
	hint_label.label_settings = HUD_STYLE.label_settings(15, Color(1.0, 0.84, 0.30, 0.98), 7, Color(0.02, 0.04, 0.10, 0.98), 5, Color(1.0, 0.45, 0.08, 0.42))
	fragment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fragment_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	fragment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fragment_label.visible = false
	fragment_label.label_settings = HUD_STYLE.label_settings(15, Color(0.72, 0.90, 0.96, 0.94), 5, Color(0.02, 0.04, 0.10, 0.95))
	for label in [level_label, floor_label, floor_status_label, core_label, energy_label, lock_label, hint_label, fragment_label]:
		_register_label(label)


func _register_label(label: Label) -> void:
	_labels.append(label)
	_defaults[label.get_instance_id()] = {
		"font_color": label.label_settings.font_color,
		"outline_size": label.label_settings.outline_size,
		"outline_color": label.label_settings.outline_color,
	}
