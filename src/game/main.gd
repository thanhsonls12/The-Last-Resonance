extends Node3D

const MOVE_TIME := 0.14
const STEP_TIME := 0.1

## Per-chapter lighting profiles; chapter N loads resources/visuals/chapter_N.tres.
const CHAPTER_VISUALS_PATHS := {
	1: "res://resources/visuals/chapter_01.tres",
	2: "res://resources/visuals/chapter_02.tres",
	3: "res://resources/visuals/chapter_03.tres",
}

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
		hud.set_bridge_available(false)
		hud.set_hint_available(false)
		vfx.clear_loops()
		return

	# Advance session token to invalidate any in-flight async work from prior level.
	coordinator.new_session()
	coordinator.set_busy(false)

	_first_move_hinted = false
	hints.reset()

	story.reset_for_level()
	GameState.set_current_level(i)

	var data: LevelData = flow.load_level(i)
	if data == null:
		return

	audio.set_ambience_for_chapter(data.chapter)
	vfx.refresh(logic, board_view)
	hud.hide_win()
	hud.set_fragment("")
	hud.set_bridge_available(logic.bridge_control_available())
	hints.load_route(data.hint_route)
	hud.set_hint_available(hints.is_available())
	hud.clear_hint()

	board_view.chapter = data.chapter
	board_view.power_level = data.power_level
	board_view.build(logic, _decorations)
	_apply_chapter_environment(data.chapter, data.power_level)
	_update_label()
	camera_controller.fit_to_cells(logic.floors)

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
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.70
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	# Depth fog separates the play area from the ruins behind it without hiding cells.
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.10, 0.18)
	env.fog_density = 0.020
	env.fog_sky_affect = 0.0

	we.environment = env
	world_environment = env
	add_child(we)


	sector_key_light = DirectionalLight3D.new()
	sector_key_light.rotation_degrees = Vector3(-54, -36, 0)
	sector_key_light.shadow_enabled = true
	sector_key_light.directional_shadow_max_distance = 48.0
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
	hud.set_stats(
		logic.level_name,
		logic.moves,
		logic.pushes,
		int(record.get("best_moves", 0)),
		par_moves)
	hud.set_bridge_available(logic.bridge_control_available())
	_update_lock_feedback()
	_update_hint_ui()


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

	var disp := hints.get_display()
	if disp.get("desynced", false) or hints.cursor >= hints.route.length():
		var fallback_cell := _fallback_hint_cell()
		board_view.set_hint_cell(fallback_cell, true)
		var fallback_text: String = disp.get("text", _fallback_hint_text())
		if disp.get("desynced", false):
			fallback_text = "Đường gợi ý đã lệch khỏi nước đi hiện tại. " + fallback_text
		hud.set_hint_text("GỢI Ý %d/3 — %s" % [hints.stage, fallback_text])
		return

	var action: String = hints.get_current_action()
	var target := _hint_target_for_action(action)
	board_view.set_hint_cell(target, true)
	hud.set_hint_text(disp.get("text", ""))


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
	if not logic.bridge_open and not logic.bridge_controls.is_empty():
		return _nearest_hint_cell(logic.bridge_controls.keys(), logic.player)
	for slot in logic.slots.keys():
		if not logic.blocks.has(slot):
			return slot
	for plate in logic.plates.keys():
		if logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
			return plate
	if logic.energy_progress < logic.energy_nodes.size():
		return logic.energy_nodes[logic.energy_progress]
	return logic.player


func _fallback_hint_text() -> String:
	if not logic.bridge_open and not logic.bridge_controls.is_empty():
		return "Mở cầu ở bảng điều khiển được đánh dấu."
	for slot in logic.slots.keys():
		if not logic.blocks.has(slot):
			return "Đưa một Lumina Core vào ô đích được đánh dấu."
	for plate in logic.plates.keys():
		if logic.plate_hold_required.get(plate, true) and not logic.blocks.has(plate):
			return "Đặt Core lên bàn áp lực được đánh dấu để mở khóa."
	if logic.energy_progress < logic.energy_nodes.size():
		return "Đưa Core tới nút năng lượng theo thứ tự được đánh dấu."
	return "Tiếp tục di chuyển và quan sát các ô sáng."


func _record_hint_action(action: String) -> void:
	hints.record_action(action)

func _undo_hint_action() -> void:
	hints.undo_action()


func _active_plate_count() -> int:
	var active := 0
	for plate_position in logic.plates.keys():
		if logic.blocks.has(plate_position):
			active += 1
	return active


func _update_lock_feedback() -> void:
	var total_plates := logic.plates.size()
	var active_plates := _active_plate_count()
	var placed_cores := logic.placed_core_count()
	var total_targets := logic.required_target_count()
	
	if audio:
		audio.update_core_resonance_layer(placed_cores, total_targets)
	if board_view:
		board_view.set_lock_state(logic)
	if hud:
		hud.set_core_progress(placed_cores, total_targets)
		hud.set_lock_progress(active_plates, total_plates, logic.doors_open())


# ---------- input ----------

func _on_step_requested(dir: Vector3i) -> void:
	_try_step(dir)


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	hud.set_paused(paused)


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
	return not logic.floors.has(v) or logic.walls.has(v) \
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
			await _blocked_feedback(dir)
		return false
	_record_hint_action(_hint_action_for_direction(dir))
	audio.play_move()
	vfx.play_footstep_dust(board_view.world_position(logic.player))
	board_view.face_player(dir)
	board_view.play_player_animation(&"Push" if res["pushed"] else &"Walk")
	var tw := create_tween()
	tw.tween_property(
		board_view.player_node,
		"position",
		board_view.player_target(logic.player, logic.blocks),
		MOVE_TIME)
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
		audio.play_door()
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
	# Normal Level 1 flow reaches this point after Kiro walks beside the first Core.
	# Keep the step busy until the tutorial line is dismissed so the next input
	# cannot push the Core before the hint is read.
	if not res["pushed"]:
		await _show_push_hint_if_near_core()
	await _play_post_step_story(res)
	if not coordinator.guard(pid):
		return false
	if settle:
		board_view.play_player_animation(&"Idle")
	_update_label()
	if logic.won:
		await _on_win()
	return true


func _play_post_step_story(move_result: Dictionary) -> void:
	await story.play_post_step_story(level_index, _decorations, move_result, logic.player)


func _show_push_hint_if_near_core() -> void:
	_first_move_hinted = await story.show_push_hint_if_near_core(
		level_index, _first_move_hinted, logic.blocks, logic.player)


func _blocked_feedback(dir: Vector3i) -> void:
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
	busy = true
	await story.play_chapter_start_sequence(
		chapter, vfx, func() -> Vector3i: return logic.player)
	board_view.face_player(Vector3i(1, 0, 0))
	busy = false


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
		audio.set_ambience(&"foundry")
		vfx.play_resonance_ping(target_world_pos)
	if await story.play_win_skit(level_index, target_slot, target_world_pos):
		if not coordinator.guard(pid):
			return

	# Save progress and records
	var fragment := flow.get_memory_fragment()
	if not fragment.is_empty():
		hud.set_fragment(fragment)
	GameState.complete_level(
		level_index,
		logic.moves,
		logic.pushes,
		current_data != null and not current_data.memory_fragment.is_empty(),
		hints.get_hints_used())

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
		hints.get_hints_used())


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
	var tween := create_tween().set_parallel(true)
	tween.tween_property(world_environment, "ambient_light_energy", powered.x, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(world_environment, "fog_light_color", profile.fog_awake, 0.9)
	tween.tween_property(sector_key_light, "light_energy", powered.y, 0.9)
	tween.tween_property(sector_fill_light, "light_energy", powered.z, 0.9)


func _on_undo() -> void:
	if busy or get_tree().paused or not logic.undo():
		return
	_undo_hint_action()
	audio.play_undo()
	_snap_visuals()


func _on_bridge() -> void:
	if busy or get_tree().paused:
		return
	var result := logic.rotate_bridge()
	if result.is_empty():
		return
	_record_hint_action("B")
	var pid := coordinator.begin_operation()
	audio.play_bridge()
	vfx.play_bridge(board_view.player_target(logic.player, logic.blocks))
	board_view.play_oneshot(&"Interact")
	board_view.set_bridges_open(result["bridge_open"], true)
	_update_label()
	await get_tree().create_timer(0.48).timeout
	if level_index == 6:
		await story.play_story_event_once("level_7_bridge_warning")
	coordinator.end_operation(pid)


func _on_restart() -> void:
	if Levels.ALL.is_empty():
		return
	if get_tree().paused:
		get_tree().paused = false
		hud.set_paused(false)
	audio.play_reset()
	_load_level(level_index)


func _snap_visuals() -> void:
	board_view.build(logic, _decorations)
	hud.hide_win()
	_update_label()


func _apply_chapter_environment(chapter: int, power_level := 0.0) -> void:
	if not world_environment or not sector_key_light or not sector_fill_light or not sector_wash_light:
		return
	var profile := _chapter_visuals(chapter)
	var lift := clampf(power_level, 0.0, 1.0)
	world_environment.background_color = profile.background
	world_environment.ambient_light_color = profile.ambient
	world_environment.ambient_light_energy = lerpf(profile.ambient_range.x, profile.ambient_range.y, lift)
	world_environment.fog_light_color = profile.fog.lerp(profile.fog_awake, lift)
	world_environment.fog_light_energy = lerpf(profile.fog_energy_range.x, profile.fog_energy_range.y, lift)
	sector_key_light.light_color = profile.key
	sector_key_light.light_energy = lerpf(profile.key_range.x, profile.key_range.y, lift)
	sector_fill_light.light_color = profile.fill
	sector_fill_light.light_energy = lerpf(profile.fill_range.x, profile.fill_range.y, lift)
	sector_wash_light.light_color = profile.wash
	sector_wash_light.light_energy = lerpf(profile.wash_range.x, profile.wash_range.y, lift)


func _roman_numeral(value: int) -> String:
	return ["I", "II", "III", "IV"][clampi(value - 1, 0, 3)]
