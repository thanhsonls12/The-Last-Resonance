extends Node3D

const TRIAL_DATA = preload("res://resources/trials/tidal_echo.tres")
@export var persist_changes := true
var board := BoardView.new()
var station: Node3D
var animation: AnimationPlayer
var info: Label
var equipment_button: Button
var _busy := false
var audio := EchoAudioManager.new()


func _ready() -> void:
	var environment := SceneEnvironmentController.new()
	add_child(environment)
	environment.apply_chapter(3, .35)
	var data := LevelData.new()
	data.chapter = 3
	data.map.assign(["#######", "#     #", "#     #", "#     #", "#  @  #", "#     #", "#######"])
	var logic := GameLogic.new()
	logic.load_level(data)
	board.chapter = 3
	board.power_level = .35
	add_child(board)
	board.build(logic)
	station = (load("res://assets/models/echo_expansion/restoration_station.glb") as PackedScene).instantiate() as Node3D
	station.position = Vector3(3, .154, 2)
	station.scale = Vector3.ONE * .5
	board.add_child(station)
	animation = station.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var camera := EchoCameraController.new()
	add_child(camera)
	camera.setup()
	camera.focus_cells(logic.floors, 0, false)
	add_child(audio)
	audio.set_ambience_for_chapter(3)
	audio.set_bgm_for_chapter(3)
	_build_ui()


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := Label.new()
	title.text = "ASTERIA  /  TRẠM PHỤC HỒI"
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 18
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	layer.add_child(title)
	info = Label.new()
	info.set_anchors_preset(Control.PRESET_TOP_WIDE)
	info.offset_left = 28
	info.offset_right = -28
	info.offset_top = 57
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.text = "Một nơi yên tĩnh để phục hồi Kiro, xem ký ức và chuẩn bị cho hành trình."
	layer.add_child(info)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 22
	bottom.offset_right = -22
	bottom.offset_top = -140
	bottom.offset_bottom = -15
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	layer.add_child(bottom)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(row)
	_button(row, "Phòng vọng âm", func(): get_tree().change_scene_to_file("res://scenes/game/tidal_trial.tscn"))
	_button(row, "Phục hồi Kiro", restore_kiro)
	_button(row, "Ký ức phụ", show_memory)
	var second := HBoxContainer.new()
	second.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(second)
	equipment_button = _button(second, "Ngoại hình", equip_armor)
	_button(second, "Gọi Mote", call_mote)
	_button(second, "Menu", func(): get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn"))
	_update_equipment()


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 48)
	button.pressed.connect(callback)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.02,.06,.075,.94)
	style.border_color = Color(.16,.54,.47)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	button.add_theme_stylebox_override("normal", style)
	parent.add_child(button)
	return button


func restore_kiro() -> void:
	if _busy:
		return
	_busy = true
	info.text = "Trạm đang kiểm tra khớp máy và cân bằng lõi năng lượng…"
	var original := board.player_node.position
	var dock := board.player_target(Vector3i(3,0,2), {}) + Vector3(0,.18,0)
	var enter := create_tween()
	enter.tween_property(board.player_node, "position", dock, .01 if GameState.reduced_motion else .35)
	await enter.finished
	animation.play("Restore")
	if GameState.reduced_motion:
		animation.seek(animation.get_animation("Restore").length, true)
		animation.stop()
	audio.play_interact()
	board.play_boot_awakening()
	var service := create_tween()
	service.tween_interval(1.1)
	await service.finished
	board.set_kiro_powered(true, true)
	audio.play_checkpoint()
	board.play_player_animation(&"Idle")
	var leave := create_tween()
	leave.tween_property(board.player_node, "position", original, .01 if GameState.reduced_motion else .35)
	await leave.finished
	info.text = "Kiro đã phục hồi. Không tiêu hao vật phẩm hay thay đổi điểm giải đố."
	_busy = false


func show_memory() -> void:
	info.text = TRIAL_DATA.memory_fragment if bool(GameState.echo_chamber.get("memory", false)) else "Ký ức chưa phục hồi. Tìm mảnh ký ức trong Phòng vọng âm và hoàn thành phòng để lưu nó tại đây."


func equip_armor() -> void:
	if not bool(GameState.echo_chamber.get("tidal_unlocked", false)):
		info.text = "Giáp Ngọc triều đang khóa: thu ký ức phụ và hoàn thành Phòng vọng âm để mở."
		return
	if persist_changes:
		GameState.equip_tidal_cosmetic(not bool(GameState.echo_chamber.get("tidal_equipped", false)))
	board.set_kiro_powered(true, true)
	_update_equipment()
	info.text = "Ngoại hình đã được lưu và áp dụng trong các màn chiến dịch."


func _update_equipment() -> void:
	equipment_button.text = "Giáp: Ngọc triều" if bool(GameState.echo_chamber.get("tidal_equipped", false)) else "Giáp: Nguyên bản"


func call_mote() -> void:
	if is_instance_valid(board.drone):
		board.drone.play_victory_cheer()
	info.text = "Mote đã nhận tín hiệu. Khi Kiro nghỉ, Mote sẽ đậu bên vai; khi bật gợi ý, nó hướng tới ô được đánh dấu."
