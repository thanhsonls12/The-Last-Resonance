extends CanvasLayer

var status: Label
var hint: Label
var valve_button: Button
var cosmetic_button: Button
var controls: Array[Button] = []
var memory_panel: AcceptDialog
var _actions_row: GridContainer
var _bottom: MarginContainer


func build(actions: Dictionary) -> void:
	var top := MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_right = -18
	top.offset_top = 14
	add_child(top)
	var column := VBoxContainer.new()
	top.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	_button(row, "Menu", actions.back)
	status = Label.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 20)
	row.add_child(status)
	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 16)
	column.add_child(hint)
	var bottom := MarginContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 14
	bottom.offset_right = -14
	bottom.offset_top = -136
	bottom.offset_bottom = -14
	add_child(bottom)
	_bottom = bottom
	var rows := VBoxContainer.new()
	bottom.add_child(rows)
	var actions_row := GridContainer.new()
	actions_row.columns = 3
	_actions_row = actions_row
	var center := CenterContainer.new()
	rows.add_child(center)
	center.add_child(actions_row)
	valve_button = _button(actions_row, "Nâng nước · E", actions.valve)
	controls.append(_button(actions_row, "Hoàn tác · Z", actions.undo))
	controls.append(_button(actions_row, "Chơi lại", actions.restart))
	var move_row := HBoxContainer.new()
	move_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_child(move_row)
	for item in [["←", Vector3i.LEFT], ["↑", Vector3i.FORWARD], ["↓", Vector3i.BACK], ["→", Vector3i.RIGHT]]:
		controls.append(_button(move_row, item[0], actions.move.bind(item[1])))
	cosmetic_button = _button(move_row, "Lõi Ngọc triều", actions.cosmetic)
	memory_panel = AcceptDialog.new()
	memory_panel.title = "Ký ức vọng âm"
	memory_panel.exclusive = true
	memory_panel.dialog_text = preload("res://resources/trials/tidal_echo.tres").memory_fragment
	memory_panel.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	memory_panel.get_label().custom_minimum_size = Vector2(0, 90)
	var dialog_theme := Theme.new()
	dialog_theme.default_font = load("res://assets/fonts/ChakraPetch-SemiBold.ttf")
	dialog_theme.default_font_size = 17
	dialog_theme.set_color("font_color", "Label", Color(.82, .94, .89))
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color(.015, .055, .064, .98)
	glass.border_color = Color(.20, .55, .48)
	glass.set_border_width_all(1)
	glass.set_corner_radius_all(8)
	dialog_theme.set_stylebox("panel", "AcceptDialog", glass)
	memory_panel.theme = dialog_theme
	memory_panel.ok_button_text = "Tiếp tục khám phá"
	add_child(memory_panel)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var portrait := get_viewport().get_visible_rect().size.x < 720
	_actions_row.columns = 2 if portrait else 3
	_bottom.offset_top = -190 if portrait else -136
	status.add_theme_font_size_override("font_size", 14 if portrait else 20)
	memory_panel.min_size = Vector2i(280, 180)


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(48, 48)
	button.add_theme_font_size_override("font_size", 16)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.025, .065, .075, .95)
	style.border_color = Color(.18, .53, .49)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14
	style.content_margin_right = 14
	button.add_theme_stylebox_override("normal", style)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func update(trial, busy: bool) -> void:
	status.text = "VỌNG ÂM  ·  %s  ·  Bước: %d" % ["Nước cao" if trial.high_water else "Nước thấp", trial.logic.moves]
	hint.text = trial.message
	if trial.solved():
		hint.text = "Hoàn thành! Đã mở lõi Ngọc triều." if trial.memory_collected else "Đã giải phòng. Tìm ký ức ở bờ phải để mở lõi Ngọc triều."
	valve_button.text = "Hạ nước · E" if trial.high_water else "Nâng nước · E"
	valve_button.disabled = busy or not trial.can_use_valve()
	for button in controls:
		button.disabled = busy
	cosmetic_button.visible = bool(GameState.echo_chamber.get("tidal_unlocked", false))
	cosmetic_button.text = "Lõi: Ngọc" if bool(GameState.echo_chamber.get("tidal_equipped", false)) else "Lõi: Gốc"
	cosmetic_button.disabled = busy
