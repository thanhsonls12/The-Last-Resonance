extends Node3D

const MOVE_TIME := 0.14
const STEP_TIME := 0.1
const ELEVATOR_RIDE_TIME := 0.9

const ScoreRules = preload("res://src/core/score_rules.gd")
const PlayerNavigationScript = preload("res://src/game/player_navigation.gd")
const ActionExecutionScript = preload("res://src/game/action_execution.gd")
const SceneEnvironmentScript = preload("res://src/view/scene_environment.gd")

## Core managers extracted from the monolithic controller.
var flow := LevelFlow.new()
var hints := HintManager.new()
var coordinator := GameCoordinator.new()
var navigation := PlayerNavigationScript.new()
var actions := ActionExecutionScript.new()

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
var scene_environment
var world_environment: Environment:
	get: return scene_environment.environment if scene_environment != null else null
var sector_key_light: DirectionalLight3D:
	get: return scene_environment.key_light if scene_environment != null else null
var sector_fill_light: DirectionalLight3D:
	get: return scene_environment.fill_light if scene_environment != null else null
var sector_wash_light: DirectionalLight3D:
	get: return scene_environment.wash_light if scene_environment != null else null

var _first_move_hinted := false
var input_controller: GameplayInput
var story: StoryDirector


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
	if scene_environment != null:
		scene_environment.cancel_transitions()

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
	hints.load_level(data)
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
	else:
		audio.play_level_start()


func _build_environment() -> void:
	scene_environment = SceneEnvironmentScript.new()
	add_child(scene_environment)


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
	camera_controller.set_player_focus(board_view.world_position(logic.player))


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
	hints.sync_to_logic(logic)

	var disp := hints.get_display()
	if disp.get("desynced", false):
		var recovery_path := hints.recovery_path(
			logic,
			func(target: Vector3i) -> Array: return navigation.path_to(logic, target))
		if not recovery_path.is_empty():
			var recovery_target: Vector3i = logic.player + recovery_path[0]
			board_view.set_hint_cell(recovery_target, true)
			hud.set_hint_text(hints.recovery_text(recovery_path))
		else:
			board_view.set_hint_cell(Vector3i.ZERO, false)
			hud.set_hint_text("GỢI Ý %d/3 — Trạng thái puzzle đã lệch khỏi đường tối ưu. Hãy Hoàn tác cho tới khi gợi ý khớp lại." % hints.stage)
		return
	if hints.cursor >= hints.route.length():
		var fallback_cell := hints.fallback_cell(logic)
		board_view.set_hint_cell(fallback_cell, true)
		var fallback_text := hints.fallback_text(logic)
		hud.set_hint_text("GỢI Ý %d/3 — %s" % [hints.stage, fallback_text])
		return

	var action := hints.get_current_action()
	var target := hints.target_for_current_action(logic)
	if action.is_empty() or target == logic.player:
		board_view.set_hint_cell(Vector3i.ZERO, false)
		hud.set_hint_text("GỢI Ý %d/3 — Không tìm được hướng hợp lệ. Miễn phí." % hints.stage)
		return
	var charged := hints.reveal_current_stage()
	board_view.set_hint_cell(target, true)
	var fee_text := "  •  Phí +%d" % charged if charged > 0 else "  •  Không tính thêm phí"
	hud.set_hint_text(str(disp.get("text", "")) + fee_text)
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
	var plan := navigation.plan_tap(logic, grid_target)
	if plan.is_empty():
		return
	match StringName(plan.get("kind", &"")):
		PlayerNavigationScript.KIND_STEP:
			_try_step(plan.get("direction", Vector3i.ZERO))
		PlayerNavigationScript.KIND_WALK:
			_execute_navigation_path(plan.get("path", []))
		PlayerNavigationScript.KIND_BLOCK_APPROACH:
			_execute_navigation_path(plan.get("path", []), plan.get("target", grid_target))
		PlayerNavigationScript.KIND_ELEVATOR:
			_execute_elevator_plan(plan)


func _execute_navigation_path(path: Array, face_target: Variant = null) -> void:
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
	if face_target is Vector3i:
		var look_target: Vector3i = face_target
		board_view.face_player(look_target - logic.player)
	board_view.play_player_animation(&"Idle")
	coordinator.end_operation(pid)


func _execute_elevator_plan(plan: Dictionary) -> void:
	var target: Vector3i = plan.get("target", logic.player)
	var path: Array = plan.get("path", [])
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
	var diff := target - logic.player
	if navigation.is_cardinal_step(diff):
		await _step(diff, true, true)
	if coordinator.guard(pid):
		coordinator.end_operation(pid)


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
	var action_plan := actions.step(logic, dir)
	if action_plan.is_empty():
		if feedback:
			GameState.haptic_feedback(12, 0.18)
			await _blocked_feedback(dir)
		return false
	var res: Dictionary = action_plan["result"]
	hints.record_action(hints.action_for_direction(dir))
	var player_from: Vector3i = action_plan["player_from"]
	var player_to: Vector3i = action_plan["player_to"]
	var bridge_from := bool(action_plan["bridge_from"])
	var bridge_to := bool(action_plan["bridge_to"])
	if bridge_to:
		board_view.set_bridge_rails_retracted(player_to, dir, true)
	if bridge_from:
		board_view.set_bridge_rails_retracted(player_from, dir, true)
	if feedback:
		GameState.haptic_feedback(24 if res["pushed"] else 14, 0.48 if res["pushed"] else 0.24)
	audio.play_move()
	var floor_transition := bool(action_plan["floor_transition"])
	var elevator_entry: Vector3i = action_plan["elevator_entry"]
	board_view.face_player(dir)
	board_view.play_player_animation(&"Push" if res["pushed"] else &"Walk")
	board_view.play_step_weight(bool(res["pushed"]), MOVE_TIME)
	var tw := create_tween()
	tw.tween_property(
		board_view.player_node,
		"position",
		board_view.player_target(elevator_entry, logic.blocks) if floor_transition else board_view.player_target(logic.player, logic.blocks),
		MOVE_TIME)
	camera_controller.set_player_focus(board_view.world_position(logic.player))
	if res["elevated"] and not res["pushed"]:
		audio.play_elevator()
		vfx.play_elevator(board_view.world_position(elevator_entry if floor_transition else logic.player))
		if not floor_transition:
			camera_controller.focus_layer(logic.player.y)
	if res["teleported"]:
		audio.play_portal_charge()
	if res["pushed"]:
		var block_transition: Dictionary = action_plan["block_transition"]
		var from: Vector3i = block_transition["from"]
		var to: Vector3i = block_transition["to"]
		var node: Node3D = board_view.block_nodes[from]
		board_view.block_nodes.erase(from)
		board_view.block_nodes[to] = node
		if block_transition["teleported"]:
			audio.play_portal()
			vfx.play_portal(board_view.world_position(to))
		elif block_transition["elevated"]:
			audio.play_elevator()
			vfx.play_elevator(board_view.world_position(to))
		else:
			audio.play_push_start()
			audio.play_push()
			vfx.play_push_impact(
				board_view.world_position(to),
				Vector3(float(to.x - from.x), 0, float(to.z - from.z)))
			camera_controller.play_impulse(0.05)
		tw.parallel().tween_property(
			node,
			"position",
			board_view.world_position(to) + Vector3(0, 0.45, 0),
			MOVE_TIME)
		if logic.plates.has(from):
			board_view.send_lock_pulse(from, false)
			audio.play_plate(false)
			vfx.play_plate_activation(board_view.world_position(from), false)
		if logic.plates.has(to):
			board_view.send_lock_pulse(to, true)
			audio.play_plate(true)
			vfx.play_plate_activation(board_view.world_position(to), true)
		if logic.slots.has(to):
			audio.play_box_on_goal()
			audio.play_goal_lock()
			vfx.play_goal_activation(board_view.world_position(to))
			camera_controller.play_impulse(0.08)
		_update_lock_feedback()
	if res["energy_advanced"]:
		audio.play_energy()
		if is_instance_valid(board_view.void_environment):
			board_view.void_environment.resonate()
		vfx.play_core_insert(board_view.world_position(logic.player))
	var door_transitions: Array = action_plan["door_transitions"]
	if not door_transitions.is_empty():
		var opened := false
		var closed := false
		for transition in door_transitions:
			if bool(transition["open"]):
				opened = true
			else:
				closed = true
			if opened:
				audio.play_door(true)
			if closed:
				audio.play_door(false)
			camera_controller.play_impulse(0.14)
			for door_transition in door_transitions:
				var door_pos: Vector3i = door_transition["position"]
				if not board_view.door_nodes.has(door_pos):
					continue
				var target := board_view.door_position(door_pos, bool(door_transition["open"]))
				vfx.play_door_unlock(target)
				tw.parallel().tween_property(board_view.door_nodes[door_pos], "position", target, MOVE_TIME)
	board_view.set_energy_progress(logic.energy_progress)
	await tw.finished
	if not coordinator.guard(pid):
		return false
	if not res["teleported"] and not floor_transition:
		vfx.play_surface_step(board_view.world_position(logic.player), board_view.chapter)
		if is_instance_valid(board_view.void_environment):
			board_view.void_environment.react_to_step(board_view.world_position(logic.player))
	if bridge_from and player_from != player_to:
		board_view.set_bridge_rails_retracted(player_from, dir, false)
	if floor_transition:
		await _play_elevator_transition(elevator_entry, logic.player, pid)
		if not coordinator.guard(pid):
			return false
	if bool(action_plan["floor_completed"]):
		_play_floor_complete_feedback(int(action_plan["completed_floor"]))
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
	camera_controller.play_impulse(0.08)
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
	if scene_environment == null:
		return
	await scene_environment.play_blackout(
		audio,
		func() -> bool: return coordinator.guard(pid),
		GameState.reduced_motion)


func _play_post_step_story(move_result: Dictionary) -> void:
	await story.play_post_step_story(level_index, _decorations, move_result, logic.player, logic.won)


func _show_push_hint_if_near_core() -> void:
	var pid := coordinator.play_id
	var hinted: bool = await story.show_push_hint_if_near_core(
		level_index, _first_move_hinted, logic.blocks, logic.player)
	if coordinator.guard(pid):
		_first_move_hinted = hinted


func _blocked_feedback(dir: Vector3i) -> void:
	var target := logic.player + dir
	var beyond := target + dir
	if logic.doors.has(target) and not logic.door_open(target):
		audio.play_door_locked()
	elif logic.portals.has(target) or logic.portals.has(beyond):
		audio.play_portal_reject()
	else:
		audio.play_blocked()
	board_view.face_player(dir)
	vfx.play_blocked(board_view.player_target(logic.player, logic.blocks))
	camera_controller.play_impulse(0.04)
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
	if is_instance_valid(board_view.drone):
		board_view.drone.play_victory_cheer()

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
	var run := flow.complete_current(logic.moves, logic.pushes, hints.get_hint_penalty())

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


func _power_up_sector(chapter: int) -> void:
	if scene_environment != null:
		scene_environment.power_up(chapter)


func _on_undo() -> void:
	if busy or get_tree().paused or not logic.undo():
		return
	GameState.haptic_feedback(18, 0.22)
	hints.undo_action()
	audio.play_undo()
	_snap_visuals()


func _on_bridge() -> void:
	if busy or get_tree().paused:
		return
	var action_plan := actions.rotate_bridge(logic)
	if action_plan.is_empty():
		return
	GameState.haptic_feedback(26, 0.34)
	hints.record_action("B")
	var pid := coordinator.begin_operation()
	audio.play_bridge()
	vfx.play_bridge(board_view.player_target(logic.player, logic.blocks))
	board_view.play_oneshot(&"Interact")
	board_view.set_bridges_open(bool(action_plan["bridge_open"]), true)
	_update_label()
	await get_tree().create_timer(0.48).timeout
	if not coordinator.guard(pid):
		return
	await story.play_bridge_story(level_index)
	coordinator.end_operation(pid)


func _fragment_cell() -> Vector3i:
	return story.fragment_cell(_decorations, logic)


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
	if scene_environment != null:
		scene_environment.apply_chapter(chapter, power_level)


func _roman_numeral(value: int) -> String:
	return ["I", "II", "III", "IV"][clampi(value - 1, 0, 3)]
