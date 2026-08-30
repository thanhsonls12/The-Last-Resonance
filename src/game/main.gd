extends Node3D

const MOVE_TIME := 0.14
const STEP_TIME := 0.1
const TAP_MAX_MS := 260
const TAP_MAX_PX := 14.0

const COLOR_BG := Color(0.022, 0.008, 0.065)
const COLOR_FLOOR := Color(0.055, 0.075, 0.13)
const COLOR_GRID := Color(0.08, 0.42, 0.72)
const COLOR_WALL := Color(0.10, 0.15, 0.25)
const COLOR_WALL_EDGE := Color(0.12, 0.58, 0.86)
const COLOR_GOAL := Color(1.0, 0.38, 0.08)
const COLOR_PLATE := Color(1.0, 0.72, 0.08)
const COLOR_DOOR := Color(0.82, 0.10, 0.08)
const COLOR_BLOCK := Color(0.48, 0.16, 0.72)
const COLOR_BLOCK_EDGE := Color(0.72, 0.28, 1.0)
const COLOR_PLAYER := Color(0.08, 0.78, 1.0)

var logic := GameLogic.new()
var level_index := 0
var busy := false
var _decorations := []

var camera_controller: EchoCameraController
var board_view: BoardView
var hud: GameHud
var dialogue_box: DialogueBox
var chapter_intro_card: ChapterIntroCard
var audio: EchoAudioManager
var vfx: EchoVfxManager
var world_environment: Environment
var archive_key_light: DirectionalLight3D
var archive_fill_light: DirectionalLight3D

var _dragging := false
var _moved_far := false
var _press_pos := Vector2.ZERO
var _press_ms := 0
var _pending_fragment := ""
var _first_move_hinted := false
var _story_event_flags := {}


func _ready() -> void:
	_ensure_input_actions()
	_build_environment()
	_build_camera()
	_build_board()
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
		vfx.clear_loops()
		return
	level_index = i
	busy = false
	_story_event_flags.clear()
	var data: LevelData = Levels.get_data(i)
	logic.load_level(data)
	_decorations = data.decorations
	audio.set_ambience_for_chapter(data.chapter)
	vfx.refresh(logic, board_view)
	hud.hide_win()
	hud.set_fragment("")
	_pending_fragment = data.memory_fragment
	hud.set_bridge_available(logic.has_bridges())
	board_view.power_level = data.power_level
	board_view.build(logic, _decorations)
	_reset_archive_lighting(data.power_level)
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


	# Cold cyan key light: illuminating archive and background silhouettes
	archive_key_light = DirectionalLight3D.new()
	archive_key_light.rotation_degrees = Vector3(-54, -36, 0)
	archive_key_light.shadow_enabled = true
	archive_key_light.directional_shadow_max_distance = 48.0
	archive_key_light.light_color = Color(0.52, 0.74, 0.98)
	archive_key_light.light_energy = 0.92
	add_child(archive_key_light)

	# Faint magenta rim light
	archive_fill_light = DirectionalLight3D.new()
	archive_fill_light.rotation_degrees = Vector3(38, 142, 0)
	archive_fill_light.shadow_enabled = false
	archive_fill_light.light_color = Color(0.58, 0.22, 0.34)
	archive_fill_light.light_energy = 0.34
	add_child(archive_fill_light)

	# Low wash from the side the key light leaves in shadow, so the far half of the
	# room keeps a readable face instead of dropping to black.
	var wall_wash := DirectionalLight3D.new()
	wall_wash.rotation_degrees = Vector3(-22, 148, 0)
	wall_wash.shadow_enabled = false
	wall_wash.light_color = Color(0.38, 0.54, 0.76)
	wall_wash.light_energy = 0.42
	add_child(wall_wash)




func _build_camera() -> void:
	camera_controller = EchoCameraController.new()
	add_child(camera_controller)
	camera_controller.setup()


func _build_board() -> void:
	board_view = BoardView.new()
	add_child(board_view)


func _build_ui() -> void:
	hud = GameHud.new()
	add_child(hud)
	hud.undo_requested.connect(_on_undo)
	hud.restart_requested.connect(_on_restart)
	hud.pause_requested.connect(_toggle_pause)
	hud.resume_requested.connect(_toggle_pause)
	hud.menu_requested.connect(_on_menu_requested)
	hud.bridge_requested.connect(_on_bridge)
	hud.next_level_requested.connect(_on_next_level)
	dialogue_box = DialogueBox.new()
	add_child(dialogue_box)
	chapter_intro_card = ChapterIntroCard.new()
	add_child(chapter_intro_card)



func _build_audio() -> void:
	audio = EchoAudioManager.new()
	add_child(audio)


func _build_vfx() -> void:
	vfx = EchoVfxManager.new()
	add_child(vfx)


func _on_menu_requested() -> void:
	get_tree().paused = false
	hud.set_paused(false)
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


func _update_label() -> void:
	var record: Dictionary = GameState.get_level_record(level_index)
	hud.set_stats(
		logic.level_name,
		logic.moves,
		logic.pushes,
		int(record.get("best_moves", 0)))
	_update_lock_feedback()


func _active_plate_count() -> int:
	var active := 0
	for plate_position in logic.plates.keys():
		if logic.blocks.has(plate_position):
			active += 1
	return active


func _update_lock_feedback() -> void:
	var total := logic.plates.size()
	var active := _active_plate_count()
	if board_view:
		board_view.set_lock_state(logic)
	if hud:
		hud.set_lock_progress(active, total, logic.doors_open())


# ---------- input ----------

func _ensure_input_actions() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("undo_move", [KEY_Z])
	_add_key_action("restart_level", [KEY_R])
	_add_key_action("rotate_camera_left", [KEY_Q])
	_add_key_action("rotate_camera_right", [KEY_E])
	_add_key_action("rotate_bridge", [KEY_F])
	_add_key_action("pause_game", [KEY_ESCAPE])


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_get_events(action).is_empty():
		return
	for key in keys:
		var input_event := InputEventKey.new()
		input_event.physical_keycode = key
		InputMap.action_add_event(action, input_event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_moved_far = false
				_press_pos = mb.position
				_press_ms = Time.get_ticks_msec()
			else:
				var elapsed: int = Time.get_ticks_msec() - _press_ms
				var drag_dist: float = mb.position.distance_to(_press_pos)
				if _dragging and drag_dist < TAP_MAX_PX and elapsed < TAP_MAX_MS:
					_handle_tap(mb.position)
				elif _dragging and elapsed < 450 and drag_dist >= 16.0 and not _moved_far:
					var delta: Vector2 = mb.position - _press_pos
					var swipe_dir := Vector3i.ZERO
					if abs(delta.x) > abs(delta.y):
						swipe_dir = Vector3i(1, 0, 0) if delta.x > 0 else Vector3i(-1, 0, 0)
					else:
						swipe_dir = Vector3i(0, 0, 1) if delta.y > 0 else Vector3i(0, 0, -1)
					_try_step(_move_dir(swipe_dir))
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		if mm.position.distance_to(_press_pos) > TAP_MAX_PX:
			var elapsed: int = Time.get_ticks_msec() - _press_ms
			if elapsed > 180:
				_moved_far = true
				camera_controller.drag_pixels(mm.relative.x)
	elif event.is_action_pressed("move_left"):

		_try_step(_move_dir(Vector3i(-1, 0, 0)))
	elif event.is_action_pressed("move_right"):
		_try_step(_move_dir(Vector3i(1, 0, 0)))
	elif event.is_action_pressed("move_up"):
		_try_step(_move_dir(Vector3i(0, 0, -1)))
	elif event.is_action_pressed("move_down"):
		_try_step(_move_dir(Vector3i(0, 0, 1)))
	elif event.is_action_pressed("undo_move"):
		_on_undo()
	elif event.is_action_pressed("restart_level"):
		_on_restart()
	elif event.is_action_pressed("rotate_camera_left"):
		_rotate_camera(-1)
	elif event.is_action_pressed("rotate_camera_right"):
		_rotate_camera(1)
	elif event.is_action_pressed("rotate_bridge"):
		_on_bridge()
	elif event.is_action_pressed("pause_game"):
		_toggle_pause()


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	hud.set_paused(paused)


func _rotate_camera(direction: int) -> void:
	camera_controller.rotate_step(direction)


func _move_dir(base: Vector3i) -> Vector3i:
	# Map a screen-relative input to a world grid axis so controls track the
	# camera after Q/E rotation. Default view is a quarter turn (PI*0.25).
	var steps := int(round((camera_controller.yaw - PI * 0.25) / (PI * 0.5)))
	return _rotate_dir_y(base, steps)


func _rotate_dir_y(dir: Vector3i, steps: int) -> Vector3i:
	var result := dir
	var count := ((steps % 4) + 4) % 4
	for i in count:
		result = Vector3i(result.z, 0, -result.x)
	return result


func _handle_tap(screen_pos: Vector2) -> void:
	if busy:
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
				busy = true
				for dir in best_path:
					var moved: bool = await _step(dir, false, false)
					if not moved:
						break
				board_view.face_player(grid_target - logic.player)
				board_view.play_player_animation(&"Idle")
				busy = false
			return

	_walk_to(grid_target)




func _walk_to(target: Vector3i) -> void:
	# Tap-to-move only walks through empty cells; it never pushes an Energy Core,
	# so a stray tap cannot shove a Core into a dead corner.
	target = Vector3i(target.x, logic.player.y, target.z)
	var path := _path_to(target)
	if path.is_empty():
		return
	busy = true
	for dir in path:
		var moved: bool = await _step(dir, false, false)
		if not moved:
			break
	board_view.play_player_animation(&"Idle")
	busy = false


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
	if busy:
		return
	busy = true
	await _step(dir)
	busy = false


func _step(dir: Vector3i, feedback := true, settle := true) -> bool:
	# If a map starts beside a Core, teach pushing before accepting that push.
	await _show_push_hint_if_near_core()
	var res: Dictionary = logic.try_move(dir)
	if res.is_empty():
		if feedback:
			await _blocked_feedback(dir)
		return false
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
	# Normal Level 1 flow reaches this point after Kiro walks beside the first Core.
	# Keep the step busy until the tutorial line is dismissed so the next input
	# cannot push the Core before the hint is read.
	if not res["pushed"]:
		await _show_push_hint_if_near_core()
	await _play_post_step_story(res)
	if settle:
		board_view.play_player_animation(&"Idle")
	_update_label()
	if logic.won:
		await _on_win()
	return true


func _play_post_step_story(move_result: Dictionary) -> void:
	if level_index == 1:
		for deco in _decorations:
			if deco is Dictionary and str(deco.get("type", "")) == "terminal":
				var terminal_position: Variant = deco.get("grid_position", null)
				if terminal_position is Vector3i:
					var offset: Vector3i = terminal_position - logic.player
					if absi(offset.x) + absi(offset.y) + absi(offset.z) <= 1:
						await _play_story_event_once("level_2_mara_terminal")
						return
	elif level_index == 2 \
			and bool(move_result.get("doors_open_after", false)) \
			and not bool(move_result.get("doors_open_before", false)):
		await _play_story_event_once("level_3_elias_dossier")


func _play_story_event_once(event_key: String) -> void:
	if _story_event_flags.has(event_key) or not dialogue_box or dialogue_box.visible:
		return
	var lines := StoryData.get_dialogue_event(event_key)
	if lines.is_empty():
		return
	_story_event_flags[event_key] = true
	dialogue_box.play_dialogue(lines)
	await dialogue_box.dialogue_finished


func _show_push_hint_if_near_core() -> void:
	if level_index != 0 or _first_move_hinted or not dialogue_box:
		return
	if dialogue_box.visible:
		return
	var near_core := false
	for raw_position in logic.blocks.keys():
		var block_position: Vector3i = raw_position
		var offset: Vector3i = block_position - logic.player
		if absi(offset.x) + absi(offset.y) + absi(offset.z) == 1:
			near_core = true
			break
	if not near_core:
		return
	var hint_lines := StoryData.get_dialogue_event("first_move_hint")
	if hint_lines.is_empty():
		return
	_first_move_hinted = true
	dialogue_box.play_dialogue(hint_lines)
	await dialogue_box.dialogue_finished


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
	if chapter_intro_card:
		chapter_intro_card.show_chapter(chapter)
		await chapter_intro_card.finished

	if chapter == 1:
		board_view.set_kiro_powered(false, true)
	
	var lines := StoryData.get_chapter_intro_dialogue(chapter)
	if not lines.is_empty() and dialogue_box:
		var has_powered_on := false
		var line_handler := func(index: int, speaker: String) -> void:
			if chapter == 1 and not has_powered_on and (index >= 2 or "KIRO" in speaker.to_upper()):
				has_powered_on = true
				board_view.set_kiro_powered(true)
				board_view.play_boot_awakening()
				vfx.play_boot_sparks(board_view.world_position(logic.player))

		dialogue_box.line_started.connect(line_handler)
		dialogue_box.play_dialogue(lines)
		await dialogue_box.dialogue_finished
		if dialogue_box.line_started.is_connected(line_handler):
			dialogue_box.line_started.disconnect(line_handler)
		if chapter == 1 and not has_powered_on:
			board_view.set_kiro_powered(true)
			board_view.play_boot_awakening()
	else:
		if chapter == 1:
			board_view.set_kiro_powered(true)
			board_view.play_boot_awakening()
	
	board_view.face_player(Vector3i(1, 0, 0))
	busy = false


func _on_win() -> void:
	busy = true
	board_view.play_player_animation(&"Victory")
	board_view.set_archive_powered(true)

	_power_up_archive()
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
	
	if level_index == 0:
		var lines := StoryData.get_dialogue_event("first_puzzle_done")
		if not lines.is_empty() and dialogue_box:
			var player_world_pos := board_view.world_position(logic.player)
			board_view.face_player(target_slot - logic.player)
			await get_tree().create_timer(0.4).timeout
			board_view.spawn_eva_hologram(target_world_pos, player_world_pos)
			await get_tree().create_timer(0.4).timeout
			dialogue_box.play_dialogue(lines)
			await dialogue_box.dialogue_finished
			board_view.dismiss_eva_hologram()
			await get_tree().create_timer(0.3).timeout
	elif level_index == 3:
		var foundry_lines := StoryData.get_dialogue_event("level_4_eva_contact")
		if not foundry_lines.is_empty() and dialogue_box:
			var player_world_pos := board_view.world_position(logic.player)
			board_view.face_player(target_slot - logic.player)
			await get_tree().create_timer(0.35).timeout
			board_view.spawn_eva_hologram(target_world_pos, player_world_pos)
			audio.set_ambience(&"foundry")
			vfx.play_resonance_ping(target_world_pos)
			dialogue_box.play_dialogue(foundry_lines)
			await dialogue_box.dialogue_finished
			board_view.dismiss_eva_hologram()
			await get_tree().create_timer(0.3).timeout

	# Save progress and records
	if not _pending_fragment.is_empty():
		hud.set_fragment(_pending_fragment)
	var completed_data: LevelData = Levels.get_data(level_index)
	GameState.complete_level(
		level_index,
		logic.moves,
		logic.pushes,
		completed_data != null and not completed_data.memory_fragment.is_empty())

	var is_last := (level_index + 1 >= Levels.ALL.size())
	hud.show_win(logic.level_name, logic.moves, logic.pushes, GameState.get_best_moves(level_index), is_last)


func _on_next_level() -> void:
	if Levels.ALL.is_empty():
		return
	var next := level_index + 1
	if next >= Levels.ALL.size():
		get_tree().change_scene_to_file("res://scenes/game/ending_cutscene.tscn")
		return
	level_index = next
	GameState.current_level = next
	_load_level(level_index)



func _power_up_archive() -> void:
	if not world_environment:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(world_environment, "ambient_light_energy", 0.92, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(world_environment, "fog_light_color", Color(0.10, 0.31, 0.42), 0.9)
	tween.tween_property(archive_key_light, "light_energy", 1.72, 0.9)
	tween.tween_property(archive_fill_light, "light_energy", 0.48, 0.9)


func _on_undo() -> void:
	if busy or not logic.undo():
		return
	audio.play_undo()
	_snap_visuals()


func _on_bridge() -> void:
	if busy:
		return
	var result := logic.rotate_bridge()
	if result.is_empty():
		return
	audio.play_bridge()
	vfx.play_bridge(board_view.player_target(logic.player, logic.blocks))
	board_view.play_oneshot(&"Interact")
	board_view.set_bridges_open(result["bridge_open"])
	_update_label()


func _on_restart() -> void:
	if busy or Levels.ALL.is_empty():
		return
	audio.play_reset()
	var data: LevelData = Levels.get_data(level_index)
	_reset_archive_lighting(data.power_level)
	logic.load_level(data)
	hud.set_fragment("")
	board_view.power_level = data.power_level
	_snap_visuals()


func _snap_visuals() -> void:
	board_view.build(logic, _decorations)
	hud.hide_win()
	_update_label()


func _reset_archive_lighting(power_level := 0.0) -> void:
	if not world_environment:
		return
	# The chapter regains power level by level, so the darkest room is level 1.
	var lift := clampf(power_level, 0.0, 1.0)
	world_environment.ambient_light_energy = lerpf(0.20, 0.42, lift)
	world_environment.fog_light_color = Color(0.04, 0.08, 0.14).lerp(Color(0.08, 0.16, 0.26), lift)
	world_environment.fog_light_energy = lerpf(0.40, 0.70, lift)
	if archive_key_light:
		archive_key_light.light_energy = lerpf(0.38, 0.68, lift)
	if archive_fill_light:
		archive_fill_light.light_energy = lerpf(0.12, 0.24, lift)
