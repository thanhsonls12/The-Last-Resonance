extends Node3D

const MOVE_TIME := 0.14
const STEP_TIME := 0.1
const ELEVATOR_RIDE_TIME := 0.9

## Per-chapter lighting profiles; chapter N loads resources/visuals/chapter_N.tres.
const CHAPTER_VISUALS_PATHS := {
	1: "res://resources/visuals/chapter_01.tres",
	2: "res://resources/visuals/chapter_02.tres",
	3: "res://resources/visuals/chapter_03.tres",
	4: "res://resources/visuals/chapter_04.tres",
}
const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
const ScoreRules = preload("res://src/core/score_rules.gd")

## Core managers extracted from the monolithic controller.
var flow := LevelFlow.new()
var hints := HintManager.new()
var coordinator := GameCoordinator.new()

## Convenience mirrors for legacy access patterns in this file.
var logic: GameLogic:
	get: return flow.logic
var level_index: int:
	get: return flow.level_index
var busy: bool:
	get: return coordinator.busy
	set(v): coordinator.set_busy(v)
var _decorations: Array:
	get: return flow.decorations

var camera_controller: EchoCameraController
var board_view: BoardView
var hud: GameHud
var dialogue_box: DialogueBox
var chapter_intro_card: ChapterIntroCard
var audio: EchoAudioManager
var vfx: EchoVfxManager
var world_environment: Environment
var sector_key_light: DirectionalLight3D
var sector_fill_light: DirectionalLight3D
var sector_wash_light: DirectionalLight3D

var _first_move_hinted := false
var input_controller: GameplayInput
var story: StoryDirector
var _power_tween: Tween
var _hint_route_states: Array[Dictionary] = []


func _exit_tree() -> void:
	coordinator.new_session()
	if story:
		story.reset_for_level()


func _ready() -> void:
	_build_environment()
	_build_camera()
	_build_board()
	_build_input()
	_build_ui()
	_build_audio()
	_build_vfx()
	_load_level(_requested_level())


func _requested_level() -> int:
	# QA and preview renders launch a specific level: godot -- --level=2
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			return maxi(0, arg.trim_prefix("--level=").to_int() - 1)
	return GameState.current_level


func _load_level(i: int) -> void:
	if Levels.ALL.is_empty() or i < 0 or i >= Levels.ALL.size():
		hud.hide_win()
		hud.set_stats("Chua co level", 0, 0, 0)
		hud.set_fragment("")
		hud.set_floor_status("")
		hud.set_bridge_available(false)
		hud.set_hint_available(false)
		vfx.clear_loops()
		return

	# Advance session token to invalidate any in-flight async work from prior level.
	coordinator.new_session()
	coordinator.set_busy(false)
	input_controller.cancel_gesture()
	if _power_tween != null and _power_tween.is_valid():
		_power_tween.kill()

	_first_move_hinted = false
	hints.reset()

	story.reset_for_level()
	GameState.set_current_level(i)

	var data: LevelData = flow.load_level(i)
	if data == null:
		return

	audio.stop_elevator_loop(false)
	audio.set_ambience_for_chapter(data.chapter)
	vfx.refresh(logic, board_view)
	hud.hide_win()
	hud.set_fragment("")
	hud.set_bridge_available(logic.bridge_control_available())
	hints.load_route(data.hint_route)
	_build_hint_route_states(data)
	hud.set_hint_available(hints.is_available())
	hud.clear_hint()

	board_view.chapter = data.chapter
	board_view.power_level = data.power_level
	board_view.build(logic, _decorations)
	if not data.memory_fragment.is_empty():
		board_view.place_memory_fragment(_fragment_cell())
	_apply_chapter_environment(data.chapter, data.power_level)
	_update_label()
	camera_controller.reset_board_yaw()
	_focus_active_floor(false)

	var prev_data: LevelData = Levels.get_data(i - 1) if i > 0 else null
	var is_first_level_of_chapter: bool = (i == 0) or (prev_data != null and prev_data.chapter != data.chapter)
	if is_first_level_of_chapter and not GameState.has_seen_chapter(data.chapter):
		GameState.mark_chapter_seen(data.chapter)
		_play_chapter_start_sequence(data.chapter)





func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.002, 0.003, 0.006)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.20, 0.31)
	env.ambient_light_energy = 0.58
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = RENDER_QUALITY.tonemap_exposure()
	env.glow_enabled = RENDER_QUALITY.glow_enabled()
	env.glow_intensity = 0.55 if RENDER_QUALITY.is_mobile() else 0.70
	env.glow_bloom = 0.08 if RENDER_QUALITY.is_mobile() else 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	# Depth fog separates the play area from the ruins behind it without hiding cells.
	env.fog_enabled = not RENDER_QUALITY.is_mobile()
	env.fog_light_color = Color(0.06, 0.10, 0.18)
	env.fog_density = 0.020
	env.fog_sky_affect = 0.0

	we.environment = env
	world_environment = env
	add_child(we)


	sector_key_light = DirectionalLight3D.new()
	sector_key_light.rotation_degrees = Vector3(-54, -36, 0)
	sector_key_light.shadow_enabled = RENDER_QUALITY.shadows_enabled()
	sector_key_light.directional_shadow_max_distance = 28.0 if RENDER_QUALITY.is_mobile() else 48.0
	add_child(sector_key_light)

	# Faint magenta rim light
	sector_fill_light = DirectionalLight3D.new()
	sector_fill_light.rotation_degrees = Vector3(38, 142, 0)
	sector_fill_light.shadow_enabled = false
	add_child(sector_fill_light)

	# Low wash from the side the key light leaves in shadow, so the far half of the
	# room keeps a readable face instead of dropping to black.
	sector_wash_light = DirectionalLight3D.new()
	sector_wash_light.rotation_degrees = Vector3(-22, 148, 0)
	sector_wash_light.shadow_enabled = false
	add_child(sector_wash_light)




func _build_camera() -> void:
	camera_controller = EchoCameraController.new()
	add_child(camera_controller)
	camera_controller.setup()


func _build_board() -> void:
	board_view = BoardView.new()
	add_child(board_view)


func _build_input() -> void:
	input_controller = GameplayInput.new()
	add_child(input_controller)
	input_controller.setup(camera_controller)
	input_controller.step_requested.connect(_on_step_requested)
	input_controller.undo_requested.connect(_on_undo)
	input_controller.restart_requested.connect(_on_restart)
	input_controller.bridge_requested.connect(_on_bridge)
	input_controller.hint_requested.connect(_on_hint)
	input_controller.pause_requested.connect(_toggle_pause)
	input_controller.camera_rotate_requested.connect(func(direction: int) -> void:
		camera_controller.rotate_step(direction))
	input_controller.tap_requested.connect(_handle_tap)


func _build_ui() -> void:
	hud = GameHud.new()
	add_child(hud)
	hud.undo_requested.connect(_on_undo)
	hud.restart_requested.connect(_on_restart)
	hud.pause_requested.connect(_toggle_pause)
	hud.resume_requested.connect(_toggle_pause)
	hud.menu_requested.connect(_on_menu_requested)
	hud.bridge_requested.connect(_on_bridge)
	hud.hint_requested.connect(_on_hint)
	hud.next_level_requested.connect(_on_next_level)
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	chapter_intro_card = ChapterIntroCard.new()
	add_child(chapter_intro_card)
	story = StoryDirector.new()
	story.setup(dialogue_box, board_view, chapter_intro_card, func() -> Vector3i: return logic.player)



func _build_audio() -> void:
	audio = EchoAudioManager.new()
	add_child(audio)
	if dialogue_box != null:
		dialogue_box.set_audio_manager(audio)


func _build_vfx() -> void:
	vfx = EchoVfxManager.new()
	add_child(vfx)


func _on_menu_requested() -> void:
	get_tree().paused = false
	hud.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


func _update_label() -> void:
	var record: Dictionary = GameState.get_level_record(level_index)
	var current_data: LevelData = Levels.get_data(level_index)
	var par_moves: int = current_data.par_moves if current_data else -1
	var limits := ScoreRules.thresholds(
		par_moves, current_data.difficulty,
		current_data.three_star_moves_override,
		current_data.two_star_moves_override) if current_data else {}
	hud.set_stats(
		logic.level_name,
		logic.moves,
		logic.pushes,
		GameState.get_best_moves(level_index),
		par_moves,
		hints.get_hint_penalty(),
		int(limits.get("three_star_max", 0)))
	hud.set_bridge_available(logic.bridge_control_available())
	hud.set_floor(logic.active_floor, logic.floor_count())
	_update_floor_status()
	_update_lock_feedback()
	_update_hint_ui()


func _focus_active_floor(animated := false) -> void:
	if logic == null:
		return
	board_view.set_active_floor(logic.active_floor, animated)
	if vfx != null:
		vfx.set_active_floor(logic.active_floor)
	camera_controller.focus_cells(logic.cells_on_floor(logic.active_floor), logic.active_floor, animated)


func _update_floor_status() -> void:
	if hud == null or logic == null or not logic.sequential_floors:
		if hud != null:
			hud.set_floor_status("")
		return
	var floor := logic.active_floor
	var total := logic.floor_count()
	if floor < total - 1 and logic.is_floor_completed(floor):
		hud.set_floor_status("TẦNG %d HOÀN TẤT — ĐẾN THANG MÁY" % (floor + 1))
	elif floor < total - 1:
		hud.set_floor_status("HOÀN TẤT MỤC TIÊU ĐỂ MỞ THANG MÁY")
	else:
		var slots := 0
		var held_plates := 0
		for position in logic.slots.keys():
			if position.y == floor:
				slots += 1
		for position in logic.plates.keys():
			if position.y == floor and logic.plate_hold_required.get(position, true):
				held_plates += 1
		if slots > 0 and held_plates > 0:
			hud.set_floor_status("TẦNG %d — %d CORE VÀO BỆ SÁNG + %d CORE GIỮ PLATE" % [floor + 1, slots, held_plates])
		elif slots > 0:
			hud.set_floor_status("TẦNG %d — ĐƯA %d CORE VÀO %d BỆ SÁNG" % [floor + 1, slots, slots])
		elif held_plates > 0:
			hud.set_floor_status("TẦNG %d — GIỮ %d CORE TRÊN PRESSURE PLATE" % [floor + 1, held_plates])
		else:
			hud.set_floor_status("TẦNG %d — HOÀN TẤT MỤC TIÊU CUỐI" % (floor + 1))


func _on_hint() -> void:
	if busy or get_tree().paused or logic.won or not hints.is_available():
		return
	var new_stage := hints.advance_stage()
	if new_stage == 0:
		_update_hint_ui()
		return
	_update_hint_ui()


func _update_hint_ui() -> void:
	if hud == null or board_view == null:
		return
	if hints.stage <= 0 or logic.won or not hints.is_available():
		board_view.set_hint_cell(Vector3i.ZERO, false)
		hud.clear_hint()
		return
	_sync_hint_cursor_to_logic()

	var disp := hints.get_display()
	if disp.get("desynced", false):
		var recovery_path := _hint_recovery_path()
		if not recovery_path.is_empty():
			var recovery_target: Vector3i = logic.player + recovery_path[0]
			board_view.set_hint_cell(recovery_target, true)
			hud.set_hint_text(_hint_recovery_text(recovery_path))
		else:
			board_view.set_hint_cell(Vector3i.ZERO, false)
			hud.set_hint_text("GỢI Ý %d/3 — Trạng thái puzzle đã lệch khỏi đường tối ưu. Hãy Hoàn tác cho tới khi gợi ý khớp lại." % hints.stage)
		return
	if hints.cursor >= hints.route.length():
		var fallback_cell := _fallback_hint_cell()
		board_view.set_hint_cell(fallback_cell, true)
		var fallback_text := _fallback_hint_text()
		hud.set_hint_text("GỢI Ý %d/3 — %s" % [hints.stage, fallback_text])
		return

	var action: String = hints.get_current_action()
	var target := _hint_target_for_action(action)
	if action.is_empty() or target == logic.player:
		board_view.set_hint_cell(Vector3i.ZERO, false)
		hud.set_hint_text("GỢI Ý %d/3 — Không tìm được hướng hợp lệ. Miễn phí." % hints.stage)
		return
	var charged := hints.reveal_current_stage()
	board_view.set_hint_cell(target, true)
	var fee_text := "  •  Phí +%d" % charged if charged > 0 else "  •  Không tính thêm phí"
	hud.set_hint_text(str(disp.get("text", "")) + fee_text)


func _hint_target_for_action(action: String) -> Vector3i:
	if action == "B":
		var controls := logic.bridge_controls.keys()
		if controls.is_empty():
			controls = logic.bridges.keys()
		return _nearest_hint_cell(controls, logic.player)
	var direction := _hint_direction(action)
	if direction == Vector3i.ZERO:
		return logic.player
	var candidate := logic.player + direction
	if logic.floors.has(candidate) and not logic.walls.has(candidate):
		return candidate
	return logic.player


func _hint_direction(action: String) -> Vector3i:
	match action:
		"U": return Vector3i(0, 0, -1)
		"D": return Vector3i(0, 0, 1)
		"L": return Vector3i(-1, 0, 0)
		"R": return Vector3i(1, 0, 0)
	return Vector3i.ZERO


func _hint_action_for_direction(direction: Vector3i) -> String:
	if direction == Vector3i(0, 0, -1):
		return "U"
	if direction == Vector3i(0, 0, 1):
		return "D"
	if direction == Vector3i(-1, 0, 0):
		return "L"
	if direction == Vector3i(1, 0, 0):
		return "R"
	return ""


func _build_hint_route_states(data: LevelData) -> void:
	_hint_route_states.clear()
	if data == null or data.hint_route.is_empty():
		return
	var simulation := GameLogic.new()
	simulation.load_level(data)
	_hint_route_states.append(_capture_hint_state(simulation))
	for action in data.hint_route:
		var result: Dictionary
		if action == "B":
			result = simulation.rotate_bridge()
		else:
			var direction := _hint_direction(action)
			if direction == Vector3i.ZERO:
				_hint_route_states.clear()
				return
			result = simulation.try_move(direction)
		if result.is_empty():
			_hint_route_states.clear()
			return
		_hint_route_states.append(_capture_hint_state(simulation))


func _capture_hint_state(source: GameLogic) -> Dictionary:
	return {
		"player": source.player,
		"blocks": source.blocks.duplicate(),
		"bridge_open": source.bridge_open,
		"energy_progress": source.energy_progress,
		"active_floor": source.active_floor,
		"completed_floors": source.completed_floors.duplicate(),
		"energy_progress_by_floor": source.energy_progress_by_floor.duplicate(),
		"won": source.won,
	}


func _sync_hint_cursor_to_logic() -> void:
	if _hint_route_states.is_empty() or not hints.is_available():
		return
	var exact_checkpoint := -1
	for i in _hint_route_states.size():
		if _hint_state_matches(_hint_route_states[i], true):
			exact_checkpoint = i
	if exact_checkpoint >= 0:
		hints.resync_to(exact_checkpoint)
	else:
		hints.mark_desynced()


func _hint_state_matches(checkpoint: Dictionary, include_player: bool) -> bool:
	if include_player and logic.player != checkpoint.get("player", Vector3i.ZERO):
		return false
	if not _same_hint_key_set(logic.blocks, checkpoint.get("blocks", {})):
		return false
	if logic.bridge_open != bool(checkpoint.get("bridge_open", true)):
		return false
	if logic.energy_progress != int(checkpoint.get("energy_progress", 0)):
		return false
	if logic.active_floor != int(checkpoint.get("active_floor", 0)):
		return false
	if not _same_hint_key_set(logic.completed_floors, checkpoint.get("completed_floors", {})):
		return false
	if logic.energy_progress_by_floor != checkpoint.get("energy_progress_by_floor", {}):
		return false
	return logic.won == bool(checkpoint.get("won", false))


func _same_hint_key_set(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for key in left.keys():
		if not right.has(key):
			return false
	return true


func _hint_recovery_path() -> Array:
	var best_path: Array = []
	for checkpoint in _hint_route_states:
		if not _hint_state_matches(checkpoint, false):
			continue
		var target: Vector3i = checkpoint.get("player", logic.player)
		if target == logic.player:
			continue
		var path := _path_to(target)
		if path.is_empty():
			continue
		if best_path.is_empty() or path.size() < best_path.size():
			best_path = path
	return best_path


func _hint_recovery_text(path: Array) -> String:
	var action := _hint_action_for_direction(path[0]) if not path.is_empty() else ""
	match hints.stage:
		1:
			return "GỢI Ý 1/3 — Bạn đã đi lệch. Hãy quay lại đường gợi ý qua ô đang phát sáng."
		2:
			return "GỢI Ý 2/3 — Bước phục hồi: %s." % _hint_action_text(action)
		_:
			return "GỢI Ý 3/3 — Đường trở lại: %s" % _hint_path_preview(path)


func _hint_action_text(action: String) -> String:
	match action:
		"U": return "↑ Lên"
		"D": return "↓ Xuống"
		"L": return "← Trái"
		"R": return "→ Phải"
		"B": return "xoay cầu tại bảng điều khiển"
	return "tiếp tục"


func _hint_path_preview(path: Array, max_steps := 5) -> String:
	var preview := ""
	var count := mini(path.size(), max_steps)
	for i in count:
		if i > 0:
			preview += " • "
		match _hint_action_for_direction(path[i]):
			"U": preview += "↑"
			"D": preview += "↓"
			"L": preview += "←"
			"R": preview += "→"
			_: preview += "•"
	return preview


func _nearest_hint_cell(cells: Array, origin: Vector3i) -> Vector3i:
	if cells.is_empty():
		return origin
	var best: Vector3i = cells[0]
	var best_distance := absi(best.x - origin.x) + absi(best.y - origin.y) + absi(best.z - origin.z)
	for raw_cell in cells:
		var cell: Vector3i = raw_cell
		var distance := absi(cell.x - origin.x) + absi(cell.y - origin.y) + absi(cell.z - origin.z)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best


func _fallback_hint_cell() -> Vector3i:
	var floor := logic.active_floor
	var floor_nodes := logic.energy_nodes_on_floor(floor)
	var floor_progress := logic.energy_progress_for_floor(floor)
	if floor_progress < floor_nodes.size():
		return floor_nodes[floor_progress]
	if logic.sequential_floors and logic.is_floor_completed(floor):
		for elevator in logic.elevators.keys():
			if elevator.y == floor and logic.elevator_is_unlocked(elevator):
				return elevator
	if not logic.bridge_open and not logic.bridge_controls.is_empty():
		var controls: Array = []
		for control in logic.bridge_controls.keys():
			if control.y == floor:
				controls.append(control)
		if not controls.is_empty():
			return _nearest_hint_cell(controls, logic.player)
	for slot in logic.slots.keys():
		if slot.y == floor and not logic.blocks.has(slot):
			return slot
	for plate in logic.plates.keys():
		if plate.y == floor and logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
			return plate
	return logic.player


func _fallback_hint_text() -> String:
	if logic.sequential_floors:
		var floor := logic.active_floor
		var floor_nodes := logic.energy_nodes_on_floor(floor)
		var floor_progress := logic.energy_progress_for_floor(floor)
		if floor_progress < floor_nodes.size():
			return "Đưa Core tới nút năng lượng %d/%d được đánh dấu trước khi về chân đế." % [floor_progress + 1, floor_nodes.size()]
		if logic.is_floor_completed(floor) and floor < logic.floor_count() - 1:
			return "Thang máy đã mở. Hãy bước vào vòng sáng để lên tầng tiếp theo."
		for slot in logic.slots.keys():
			if slot.y == floor and not logic.blocks.has(slot):
				return "Đưa một Lumina Core vào ô đích được đánh dấu."
		for plate in logic.plates.keys():
			if plate.y == floor and logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
				return "Đặt Core lên bàn áp lực được đánh dấu để mở khóa."
		return "Tiếp tục di chuyển và quan sát các ô sáng."
	if logic.energy_progress < logic.energy_nodes.size():
		return "Đưa Core tới nút năng lượng %d/%d được đánh dấu trước khi về chân đế." % [logic.energy_progress + 1, logic.energy_nodes.size()]
	if not logic.bridge_open and not logic.bridge_controls.is_empty():
		return "Mở cầu ở bảng điều khiển được đánh dấu."
	for slot in logic.slots.keys():
		if not logic.blocks.has(slot):
			return "Đưa một Lumina Core vào ô đích được đánh dấu."
	for plate in logic.plates.keys():
		if logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
			return "Đặt Core lên bàn áp lực được đánh dấu để mở khóa."
	return "Tiếp tục di chuyển và quan sát các ô sáng."


func _record_hint_action(action: String) -> void:
	hints.record_action(action)

func _undo_hint_action() -> void:
	hints.undo_action()


func _active_plate_count(floor := -1) -> int:
	var active := 0
	for plate_position in logic.plates.keys():
		if (floor < 0 or plate_position.y == floor) and logic.blocks.has(plate_position):
			active += 1
	return active


func _update_lock_feedback() -> void:
	var floor := logic.active_floor
	var total_plates := 0
	for plate_position in logic.plates.keys():
		if plate_position.y == floor:
			total_plates += 1
	var active_plates := _active_plate_count(floor)
	var placed_cores := logic.placed_core_count_for_floor(floor)
	var total_targets := logic.required_target_count_for_floor(floor)
	
	if audio:
		audio.update_core_resonance_layer(placed_cores, total_targets)
	if board_view:
		board_view.set_lock_state(logic)
		board_view.set_energy_progress(logic.energy_progress)
	if hud:
		hud.set_core_progress(placed_cores, total_targets)
		hud.set_energy_nodes(logic.energy_progress, logic.energy_nodes.size())
		hud.set_lock_progress(active_plates, total_plates, logic.doors_open_on_floor(floor))


# ---------- input ----------

func _on_step_requested(dir: Vector3i) -> void:
	_try_step(dir)


func _toggle_pause() -> void:
	input_controller.cancel_gesture()
	var paused := not get_tree().paused
	GameState.haptic_feedback(16, 0.20)
	get_tree().paused = paused
	hud.set_paused(paused)
	if audio:
		audio.play_ui_pause(paused)


func _handle_tap(screen_pos: Vector2) -> void:
	if busy or get_tree().paused:
		return
	var target: Variant = camera_controller.screen_to_grid(screen_pos)
	if target == null:
		return
	var grid_target := Vector3i(target.x, logic.player.y, target.z)

	# If tapping outside walkable floor or on a wall/obstacle, ignore tap
	if not logic.floors.has(grid_target) or logic.walls.has(grid_target):
		return

	# Elevators are excluded from generic auto-walk so a tap elsewhere can never
	# transfer floors by accident. Tapping the elevator tile itself is explicit:
	# walk to a reachable adjacent cell, then take the final step into the lift.
	if logic.elevators.has(grid_target):
		_enter_elevator_from_tap(grid_target)
		return

	# If tapping directly on an Energy Core
	if logic.blocks.has(grid_target):

		var diff: Vector3i = grid_target - logic.player
		# If adjacent, push directly in that direction
		if (abs(diff.x) == 1 and diff.z == 0) or (abs(diff.z) == 1 and diff.x == 0):
			_try_step(diff)
			return
		else:
			# Walk to closest adjacent valid neighbor
			var best_path: Array = []
			var directions: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]
			for d in directions:
				var neighbor: Vector3i = grid_target + d
				if not _auto_walk_blocked(neighbor):
					var p: Array = _path_to(neighbor)
					if not p.is_empty() and (best_path.is_empty() or p.size() < best_path.size()):
						best_path = p
			if not best_path.is_empty():
				var pid := coordinator.begin_operation()
				for dir in best_path:
					if not coordinator.guard(pid):
						return
					var moved: bool = await _step(dir, false, false)
					if not moved:
						break
				if not coordinator.guard(pid):
					return
				board_view.face_player(grid_target - logic.player)
				board_view.play_player_animation(&"Idle")
				coordinator.end_operation(pid)
			return

	_walk_to(grid_target)


func _enter_elevator_from_tap(target: Vector3i) -> void:
	if busy or get_tree().paused or not logic.elevator_is_unlocked(target):
		return
	var diff := target - logic.player
	if _is_cardinal_step(diff):
		_try_step(diff)
		return

	var path := _path_to_elevator_approach(target)
	if path.is_empty():
		return
	var pid := coordinator.begin_operation()
	for direction in path:
		if not coordinator.guard(pid):
			return
		var moved: bool = await _step(direction, false, false)
		if not moved:
			coordinator.end_operation(pid)
			return
	if not coordinator.guard(pid):
		return
	diff = target - logic.player
	if _is_cardinal_step(diff):
		await _step(diff, true, true)
	if coordinator.guard(pid):
		coordinator.end_operation(pid)


func _path_to_elevator_approach(target: Vector3i) -> Array:
	var best_path: Array = []
	for direction in [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.BACK, Vector3i.FORWARD]:
		var neighbor: Vector3i = target + Vector3i(direction)
		if _auto_walk_blocked(neighbor):
			continue
		var path: Array = _path_to(neighbor)
		if path.is_empty():
			continue
		if best_path.is_empty() or path.size() < best_path.size():
			best_path = path
	return best_path


func _is_cardinal_step(diff: Vector3i) -> bool:
	return diff.y == 0 and absi(diff.x) + absi(diff.z) == 1




func _walk_to(target: Vector3i) -> void:
	# Tap-to-move only walks through empty cells; it never pushes an Energy Core,
	# so a stray tap cannot shove a Core into a dead corner.
	target = Vector3i(target.x, logic.player.y, target.z)
	var path := _path_to(target)
	if path.is_empty():
		return
	var pid := coordinator.begin_operation()
	for dir in path:
		if not coordinator.guard(pid):
			return
		var moved: bool = await _step(dir, false, false)
		if not moved:
			break
	if not coordinator.guard(pid):
		return
	board_view.play_player_animation(&"Idle")
	coordinator.end_operation(pid)


func _path_to(target: Vector3i) -> Array:
	if target == logic.player or _auto_walk_blocked(target):
		return []
	var came := {logic.player: null}
	var queue: Array = [logic.player]
	while not queue.is_empty():
		var cur: Vector3i = queue.pop_front()
		if cur == target:
			break
		for dir in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			var nxt: Vector3i = cur + dir
			if came.has(nxt) or _auto_walk_blocked(nxt):
				continue
			came[nxt] = cur
			queue.append(nxt)
	if not came.has(target):
		return []
	var dirs: Array = []
	var node: Vector3i = target
	while came[node] != null:
		var prev: Vector3i = came[node]
		dirs.push_front(node - prev)
		node = prev
	return dirs


func _auto_walk_blocked(v: Vector3i) -> bool:
	# Elevators excluded so auto-walk never triggers a surprise floor teleport;
	# ride them with an explicit step instead.
	return not logic.is_active_floor_cell(v) or not logic.floors.has(v) or logic.walls.has(v) \
			or logic.blocks.has(v) \
			or logic.elevators.has(v) \
			or (logic.doors.has(v) and not logic.door_open(v)) \
			or (logic.bridges.has(v) and not logic.bridge_open)


func _try_step(dir: Vector3i) -> void:
	if busy or get_tree().paused:
		return
	var pid := coordinator.begin_operation()
	await _step(dir)
	coordinator.end_operation(pid)


func _step(dir: Vector3i, feedback := true, settle := true) -> bool:
	var pid := coordinator.play_id
	# If a map starts beside a Core, teach pushing before accepting that push.
	await _show_push_hint_if_near_core()
	if not coordinator.guard(pid):
		return false
	var res: Dictionary = logic.try_move(dir)
	if res.is_empty():
		if feedback:
			GameState.haptic_feedback(12, 0.18)
			await _blocked_feedback(dir)
		return false
	_record_hint_action(_hint_action_for_direction(dir))
	var player_from: Vector3i = res["player_from"]
	var player_to: Vector3i = res["player_to"]
	var bridge_from := logic.bridges.has(player_from)
	var bridge_to := logic.bridges.has(player_to)
	if bridge_to:
		board_view.set_bridge_rails_retracted(player_to, dir, true)
	if bridge_from:
		board_view.set_bridge_rails_retracted(player_from, dir, true)
	if feedback:
		GameState.haptic_feedback(24 if res["pushed"] else 14, 0.48 if res["pushed"] else 0.24)
	audio.play_move()
	var floor_transition := bool(res.get("floor_transition", false))
	var elevator_entry: Vector3i = res.get("elevator_entry", Vector3i.ZERO)
	vfx.play_footstep_dust(board_view.world_position(elevator_entry if floor_transition else logic.player))
	board_view.face_player(dir)
	board_view.play_player_animation(&"Push" if res["pushed"] else &"Walk")
	var tw := create_tween()
	tw.tween_property(
		board_view.player_node,
		"position",
		board_view.player_target(elevator_entry, logic.blocks) if floor_transition else board_view.player_target(logic.player, logic.blocks),
		MOVE_TIME)
	if res["elevated"] and not res["pushed"]:
		audio.play_elevator()
		vfx.play_elevator(board_view.world_position(elevator_entry if floor_transition else logic.player))
		if not floor_transition:
			camera_controller.focus_layer(logic.player.y)
	if res["pushed"]:
		var from: Vector3i = res["pushed_from"]
		var to: Vector3i = res["pushed_to"]
		var node: Node3D = board_view.block_nodes[from]
		board_view.block_nodes.erase(from)
		board_view.block_nodes[to] = node
		if res["teleported"]:
			audio.play_portal()
			vfx.play_portal(board_view.world_position(to))
		elif res["elevated"]:
			audio.play_elevator()
			vfx.play_elevator(board_view.world_position(to))
		else:
			audio.play_push()
			vfx.play_push_impact(
				board_view.world_position(to),
				Vector3(float(to.x - from.x), 0, float(to.z - from.z)))
		tw.parallel().tween_property(
			node,
			"position",
			board_view.world_position(to) + Vector3(0, 0.45, 0),
			MOVE_TIME)
		if logic.plates.has(from):
			audio.play_plate(false)
			vfx.play_plate_activation(board_view.world_position(from), false)
		if logic.plates.has(to):
			audio.play_plate(true)
			vfx.play_plate_activation(board_view.world_position(to), true)
		if logic.slots.has(to):
			audio.play_box_on_goal()
			vfx.play_goal_activation(board_view.world_position(to))
			camera_controller.play_impulse(0.08)
		_update_lock_feedback()
	if res["energy_advanced"]:
		audio.play_energy()
		vfx.play_core_insert(board_view.world_position(logic.player))
		if level_index == 0 and not logic.won:
			var core_lines := StoryData.get_dialogue_event("first_core_connected")
			if not core_lines.is_empty() and dialogue_box:
				dialogue_box.play_dialogue(core_lines)
	if not res["doors_changed"].is_empty():
		var opened := false
		var closed := false
		var door_after: Dictionary = res["door_state_after"]
		for door_pos in res["doors_changed"]:
			if bool(door_after.get(door_pos, false)):
				opened = true
			else:
				closed = true
		if opened:
			audio.play_door(true)
		if closed:
			audio.play_door(false)
		camera_controller.play_impulse(0.14)
		var door_state: Dictionary = res["door_state_after"]
		for door_pos in res["doors_changed"]:
			if not board_view.door_nodes.has(door_pos):
				continue
			var target := board_view.door_position(door_pos, bool(door_state[door_pos]))
			vfx.play_door_unlock(target)
			tw.parallel().tween_property(board_view.door_nodes[door_pos], "position", target, MOVE_TIME)
	board_view.set_energy_progress(logic.energy_progress)
	await tw.finished
	if not coordinator.guard(pid):
		return false
	if bridge_from and player_from != player_to:
		board_view.set_bridge_rails_retracted(player_from, dir, false)
	if floor_transition:
		await _play_elevator_transition(elevator_entry, logic.player, pid)
		if not coordinator.guard(pid):
			return false
	if bool(res.get("floor_completed", false)):
		_play_floor_complete_feedback(int(res.get("completed_floor", logic.active_floor)))
	# Normal Level 1 flow reaches this point after Kiro walks beside the first Core.
	# Keep the step busy until the tutorial line is dismissed so the next input
	# cannot push the Core before the hint is read.
	if not res["pushed"]:
		await _show_push_hint_if_near_core()
	if not coordinator.guard(pid):
		return false
	await _play_post_step_story(res)
	if not coordinator.guard(pid):
		return false
	if settle:
		board_view.play_player_animation(&"Idle")
	_update_label()
	if logic.won:
		await _on_win()
	return true


func _play_floor_complete_feedback(floor: int) -> void:
	if logic == null or not logic.sequential_floors:
		return
	for elevator in logic.elevators.keys():
		if elevator.y == floor and logic.elevator_is_unlocked(elevator):
			vfx.play_door_unlock(board_view.world_position(elevator))
			vfx.play_elevator(board_view.world_position(elevator))
			board_view.set_elevator_state(logic, true)
			break
	_update_label()


func _play_elevator_transition(entry: Vector3i, destination: Vector3i, pid: int) -> void:
	if not coordinator.guard(pid):
		return
	var ride_duration := 0.12 if GameState.reduced_motion else ELEVATOR_RIDE_TIME
	hud.set_floor_status("ĐANG LÊN TẦNG %d…" % (destination.y + 1))
	if level_index == 10:
		await _play_silence_protocol_blackout(pid)
		if not coordinator.guard(pid):
			return
	audio.play_elevator()
	audio.play_elevator_loop()
	board_view.play_elevator_ride(entry, destination, ride_duration)
	await get_tree().create_timer(ride_duration * 0.32).timeout
	if not coordinator.guard(pid):
		return
	board_view.set_active_floor(destination.y, true)
	vfx.set_active_floor(destination.y)
	camera_controller.focus_cells(logic.cells_on_floor(destination.y), destination.y, true)
	vfx.play_elevator(board_view.world_position(destination))
	var ride := create_tween()
	ride.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	ride.tween_property(
		board_view.player_node,
		"position",
		board_view.player_target(destination, logic.blocks),
		ride_duration * 0.68)
	await ride.finished
	audio.stop_elevator_loop(true)
	if coordinator.guard(pid):
		# Commit the destination presentation after the ride. The camera starts an
		# animated reframe above, but on some mobile frame timings that tween can be
		# interrupted while the elevator/player tweens are settling. Snap once at the
		# end so Floor 2 can never finish the transition with stale Floor 1 framing.
		board_view.set_active_floor(destination.y, false)
		vfx.set_active_floor(destination.y)
		camera_controller.focus_cells(logic.cells_on_floor(destination.y), destination.y, false)
		board_view.set_lock_state(logic)
		board_view.set_energy_progress(logic.energy_progress)
		_update_label()


func _play_silence_protocol_blackout(pid: int) -> void:
	if not coordinator.guard(pid) or world_environment == null:
		return
	var fade_time := 0.06 if GameState.reduced_motion else 0.14
	var hold_time := 0.04 if GameState.reduced_motion else 0.12
	var restore_time := 0.08 if GameState.reduced_motion else 0.24
	var ambient_before := world_environment.ambient_light_energy
	var key_before := sector_key_light.light_energy if sector_key_light != null else 0.0
	var fill_before := sector_fill_light.light_energy if sector_fill_light != null else 0.0
	var wash_before := sector_wash_light.light_energy if sector_wash_light != null else 0.0
	var ambience_before := audio.ambience_player.volume_db if audio != null and audio.ambience_player != null else -14.0
	var detail_before := audio.ambience_detail_player.volume_db if audio != null and audio.ambience_detail_player != null else -22.0
	var accent_before := audio.ambience_accent_player.volume_db if audio != null and audio.ambience_accent_player != null else -30.0

	var blackout := create_tween().set_parallel(true)
	blackout.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	blackout.tween_property(world_environment, "ambient_light_energy", 0.025, fade_time)
	if sector_key_light != null:
		blackout.tween_property(sector_key_light, "light_energy", 0.015, fade_time)
	if sector_fill_light != null:
		blackout.tween_property(sector_fill_light, "light_energy", 0.0, fade_time)
	if sector_wash_light != null:
		blackout.tween_property(sector_wash_light, "light_energy", 0.0, fade_time)
	if audio != null and audio.ambience_player != null:
		blackout.tween_property(audio.ambience_player, "volume_db", -42.0, fade_time)
	if audio != null and audio.ambience_detail_player != null:
		blackout.tween_property(audio.ambience_detail_player, "volume_db", -48.0, fade_time)
	if audio != null and audio.ambience_accent_player != null:
		blackout.tween_property(audio.ambience_accent_player, "volume_db", -52.0, fade_time)
	await blackout.finished
	if not coordinator.guard(pid):
		return
	await get_tree().create_timer(hold_time).timeout
	if not coordinator.guard(pid):
		return

	var restore := create_tween().set_parallel(true)
	restore.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	restore.tween_property(world_environment, "ambient_light_energy", ambient_before, restore_time)
	if sector_key_light != null:
		restore.tween_property(sector_key_light, "light_energy", key_before, restore_time)
	if sector_fill_light != null:
		restore.tween_property(sector_fill_light, "light_energy", fill_before, restore_time)
	if sector_wash_light != null:
		restore.tween_property(sector_wash_light, "light_energy", wash_before, restore_time)
	if audio != null and audio.ambience_player != null:
		restore.tween_property(audio.ambience_player, "volume_db", ambience_before, restore_time)
	if audio != null and audio.ambience_detail_player != null:
		restore.tween_property(audio.ambience_detail_player, "volume_db", detail_before, restore_time)
	if audio != null and audio.ambience_accent_player != null:
		restore.tween_property(audio.ambience_accent_player, "volume_db", accent_before, restore_time)
	await restore.finished


func _play_post_step_story(move_result: Dictionary) -> void:
	await story.play_post_step_story(level_index, _decorations, move_result, logic.player)


func _show_push_hint_if_near_core() -> void:
	var pid := coordinator.play_id
	var hinted: bool = await story.show_push_hint_if_near_core(
		level_index, _first_move_hinted, logic.blocks, logic.player)
	if coordinator.guard(pid):
		_first_move_hinted = hinted


func _blocked_feedback(dir: Vector3i) -> void:
	var target := logic.player + dir
	var beyond := target + dir
	if logic.portals.has(target) or logic.portals.has(beyond):
		audio.play_portal_reject()
	else:
		audio.play_blocked()
	board_view.face_player(dir)
	vfx.play_blocked(board_view.player_target(logic.player, logic.blocks))
	if not board_view.player_node:
		return
	var base := board_view.player_target(logic.player, logic.blocks)
	var bump := base + Vector3(float(dir.x), 0, float(dir.z)) * 0.12
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(board_view.player_node, "position", bump, 0.07)
	tw.tween_property(board_view.player_node, "position", base, 0.09)
	await tw.finished


func _play_chapter_start_sequence(chapter: int) -> void:
	var pid := coordinator.begin_operation()
	await story.play_chapter_start_sequence(
		chapter, vfx, func() -> Vector3i: return logic.player)
	if not coordinator.guard(pid):
		return
	board_view.face_player(Vector3i(1, 0, 0))
	coordinator.end_operation(pid)


func _on_win() -> void:
	var pid := coordinator.play_id
	coordinator.set_busy(true)
	board_view.play_player_animation(&"Victory")
	board_view.set_sector_powered(true)

	var current_data: LevelData = Levels.get_data(level_index)
	_power_up_sector(current_data.chapter)
	audio.play_win()
	if not board_view.door_nodes.is_empty():
		audio.play_door()
		for door_pos in board_view.door_nodes.keys():
			vfx.play_door_unlock(board_view.door_position(door_pos, true))
			var tw := create_tween()
			tw.tween_property(board_view.door_nodes[door_pos], "position", board_view.door_position(door_pos, true), MOVE_TIME)
	var target_slot: Vector3i = logic.slots.keys()[0] if not logic.slots.is_empty() else logic.player
	var target_world_pos := board_view.world_position(target_slot)
	vfx.play_power_restoration(target_world_pos)
	vfx.play_level_complete(board_view.player_target(logic.player, logic.blocks))

	if level_index == 3:
		await get_tree().create_timer(0.35).timeout
		if not coordinator.guard(pid):
			return
		audio.set_ambience(&"foundry")
		vfx.play_resonance_ping(target_world_pos)
	await story.play_win_skit(level_index, target_slot, target_world_pos, _decorations)
	if not coordinator.guard(pid):
		return

	# Save progress and records
	var fragment := flow.get_memory_fragment()
	if not fragment.is_empty():
		var frag_pos := board_view.collect_memory_fragment()
		audio.play_fragment()
		vfx.play_memory_fragment_collect(
			frag_pos if frag_pos != Vector3.ZERO else board_view.player_target(logic.player, logic.blocks))
		hud.set_fragment(fragment)
	var run := ScoreRules.evaluate_run(logic.moves, hints.get_hint_penalty(), current_data)
	run["pushes"] = logic.pushes
	GameState.complete_level(
		level_index,
		run,
		current_data != null and not current_data.memory_fragment.is_empty())

	var next_data: LevelData = Levels.get_data(level_index + 1)
	var next_button_text := "MÀN TIẾP THEO"
	var completion_badge := "◆ NĂNG LƯỢNG ĐÃ KHÔI PHỤC ◆"
	if next_data != null and next_data.chapter != current_data.chapter:
		next_button_text = "SANG CHƯƠNG %s" % _roman_numeral(next_data.chapter)
	elif next_data == null and Levels.is_chapter_final(level_index):
		next_button_text = "VỀ CHỌN MÀN"
		completion_badge = "◆ CHƯƠNG %s HOÀN TẤT ◆" % _roman_numeral(current_data.chapter)
	elif next_data == null:
		next_button_text = "VỀ CHỌN MÀN"
		completion_badge = "◆ BẢN DỰNG HIỆN TẠI HOÀN TẤT ◆"
	var par_moves: int = current_data.par_moves if current_data else -1
	hud.show_win(
		logic.level_name,
		logic.moves,
		logic.pushes,
		GameState.get_best_moves(level_index),
		par_moves,
		next_button_text,
		completion_badge,
		hints.get_hint_penalty(),
		run)


func _on_next_level() -> void:
	if Levels.ALL.is_empty():
		return
	var next := level_index + 1
	if next >= Levels.ALL.size():
		var current_data: LevelData = Levels.get_data(level_index)
		if current_data != null and Levels.is_campaign_final(level_index):
			get_tree().change_scene_to_file("res://scenes/game/ending_cutscene.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")
		return
	_load_level(next)



func _chapter_visuals(chapter: int) -> ChapterVisuals:
	var path: String = CHAPTER_VISUALS_PATHS.get(chapter, CHAPTER_VISUALS_PATHS[1])
	return load(path) as ChapterVisuals


func _power_up_sector(chapter: int) -> void:
	if not world_environment or not sector_key_light or not sector_fill_light:
		return
	var profile := _chapter_visuals(chapter)
	var powered := profile.powered
	if _power_tween != null and _power_tween.is_valid():
		_power_tween.kill()
	var tween := create_tween().set_parallel(true)
	_power_tween = tween
	tween.tween_property(world_environment, "ambient_light_energy", powered.x, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(world_environment, "fog_light_color", profile.fog_awake, 0.9)
	tween.tween_property(sector_key_light, "light_energy", powered.y, 0.9)
	tween.tween_property(sector_fill_light, "light_energy", powered.z, 0.9)


func _on_undo() -> void:
	if busy or get_tree().paused or not logic.undo():
		return
	GameState.haptic_feedback(18, 0.22)
	_undo_hint_action()
	audio.play_undo()
	_snap_visuals()


func _on_bridge() -> void:
	if busy or get_tree().paused:
		return
	var result := logic.rotate_bridge()
	if result.is_empty():
		return
	GameState.haptic_feedback(26, 0.34)
	_record_hint_action("B")
	var pid := coordinator.begin_operation()
	audio.play_bridge()
	vfx.play_bridge(board_view.player_target(logic.player, logic.blocks))
	board_view.play_oneshot(&"Interact")
	board_view.set_bridges_open(result["bridge_open"], true)
	_update_label()
	await get_tree().create_timer(0.48).timeout
	if not coordinator.guard(pid):
		return
	if level_index == 6:
		await story.play_story_event_once("level_7_bridge_warning")
	coordinator.end_operation(pid)


func _fragment_cell() -> Vector3i:
	for deco in _decorations:
		if not deco is Dictionary:
			continue
		var kind := str(deco.get("type", ""))
		if kind in ["plinth", "resonance_altar", "elias_testament", "holo", "archive_plinth"]:
			var cell: Variant = deco.get("grid_position", null)
			if cell is Vector3i:
				return cell
	if not logic.slots.is_empty():
		return logic.slots.keys()[0]
	return logic.player


func _on_restart() -> void:
	if Levels.ALL.is_empty():
		return
	if get_tree().paused:
		get_tree().paused = false
		hud.set_paused(false)
	GameState.haptic_feedback(32, 0.30)
	audio.play_reset()
	_load_level(level_index)


func _snap_visuals() -> void:
	board_view.build(logic, _decorations)
	_focus_active_floor(false)
	story.sync_level_visuals(
		level_index,
		_decorations,
		logic.player,
		logic.energy_progress_for_floor(logic.active_floor))
	hud.hide_win()
	_update_label()


func _apply_chapter_environment(chapter: int, power_level := 0.0) -> void:
	if not world_environment or not sector_key_light or not sector_fill_light or not sector_wash_light:
		return
	var profile := _chapter_visuals(chapter)
	var lift := clampf(power_level, 0.0, 1.0)
	world_environment.background_color = profile.background.lightened(0.01) if RENDER_QUALITY.is_mobile() else profile.background
	world_environment.ambient_light_color = profile.ambient
	world_environment.ambient_light_energy = lerpf(profile.ambient_range.x, profile.ambient_range.y, lift) * RENDER_QUALITY.ambient_boost()
	world_environment.fog_light_color = profile.fog.lerp(profile.fog_awake, lift)
	world_environment.fog_light_energy = lerpf(profile.fog_energy_range.x, profile.fog_energy_range.y, lift)
	sector_key_light.light_color = profile.key
	sector_key_light.light_energy = lerpf(profile.key_range.x, profile.key_range.y, lift) * RENDER_QUALITY.key_boost()
	sector_fill_light.light_color = profile.fill
	sector_fill_light.light_energy = lerpf(profile.fill_range.x, profile.fill_range.y, lift) * RENDER_QUALITY.fill_boost()
	sector_wash_light.light_color = profile.wash
	sector_wash_light.light_energy = lerpf(profile.wash_range.x, profile.wash_range.y, lift) * RENDER_QUALITY.wash_boost()


func _roman_numeral(value: int) -> String:
	return ["I", "II", "III", "IV"][clampi(value - 1, 0, 3)]
