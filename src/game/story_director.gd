class_name StoryDirector
extends RefCounted

## Story beats for the gameplay scene: per-level dialogue triggers, the push
## tutorial hint, chapter intro sequences, and the win-scene skits. Split out of
## main.gd so level flow and narrative stay separate. main.gd awaits the
## async helpers below; every await target lives on the scene or UI nodes it
## receives, so RefCounted is safe here.

signal story_event_played(event_key: String)

var dialogue_box: DialogueBox
var board_view: BoardView
var chapter_intro_card: ChapterIntroCard
## Returns the player's current grid cell (logic.player on the scene).
var player_provider: Callable
var _story_event_flags := {}


func setup(
		p_dialogue_box: DialogueBox,
		p_board_view: BoardView,
		p_chapter_intro_card: ChapterIntroCard,
		p_player_provider: Callable) -> void:
	dialogue_box = p_dialogue_box
	board_view = p_board_view
	chapter_intro_card = p_chapter_intro_card
	player_provider = p_player_provider


func reset_for_level() -> void:
	_story_event_flags.clear()


## Runs after every accepted move. Returns true when a dialogue consumed the beat.
func play_post_step_story(level_index: int, decorations: Array, move_result: Dictionary, player: Vector3i) -> bool:
	if level_index == 1:
		for deco in decorations:
			if deco is Dictionary and str(deco.get("type", "")) == "terminal":
				var terminal_position: Variant = deco.get("grid_position", null)
				if terminal_position is Vector3i:
					var offset: Vector3i = terminal_position - player
					if absi(offset.x) + absi(offset.y) + absi(offset.z) <= 1:
						await play_story_event_once("level_2_mara_terminal")
						return true
	elif level_index == 2 \
			and bool(move_result.get("doors_open_after", false)) \
			and not bool(move_result.get("doors_open_before", false)):
		await play_story_event_once("level_3_elias_dossier")
		return true
	elif level_index == 4:
		var changed_doors: Array = move_result.get("doors_changed", [])
		if changed_doors.is_empty():
			return false
		var door_state_after: Dictionary = move_result.get("door_state_after", {})
		for is_open in door_state_after.values():
			if bool(is_open):
				await play_story_event_once("level_5_council_log")
				return true
	elif level_index == 5 and _player_near_decoration(decorations, "k_series_mold", player):
		await play_story_event_once("level_6_k_series_mold")
		return true
	elif level_index == 7:
		var changed_doors: Array = move_result.get("doors_changed", [])
		var door_state_after: Dictionary = move_result.get("door_state_after", {})
		for door_position in changed_doors:
			if bool(door_state_after.get(door_position, false)):
				await play_story_event_once("level_8_eva_lockdown")
				return true
	elif level_index == 8 and bool(move_result.get("teleported", false)):
		await play_story_event_once("level_9_shared_dream")
		return true
	elif level_index == 9 and bool(move_result.get("teleported", false)):
		await play_story_event_once("level_10_resonance_network")
		return true
	return false


func _player_near_decoration(decorations: Array, kind: String, player: Vector3i) -> bool:
	for deco in decorations:
		if not deco is Dictionary or str(deco.get("type", "")) != kind:
			continue
		var position: Variant = deco.get("grid_position", null)
		if position is Vector3i:
			var offset: Vector3i = position - player
			if absi(offset.x) + absi(offset.y) + absi(offset.z) <= 1:
				return true
	return false


func play_story_event_once(event_key: String) -> void:
	if _story_event_flags.has(event_key) or not dialogue_box or dialogue_box.visible:
		return
	var lines := StoryData.get_dialogue_event(event_key)
	if lines.is_empty():
		return
	_story_event_flags[event_key] = true
	dialogue_box.play_dialogue(lines)
	story_event_played.emit(event_key)
	await dialogue_box.dialogue_finished


## If a map starts beside a Core, teach pushing before accepting that push.
func show_push_hint_if_near_core(level_index: int, first_move_hinted: bool, blocks: Dictionary, player: Vector3i) -> bool:
	if level_index != 0 or first_move_hinted or not dialogue_box:
		return first_move_hinted
	if dialogue_box.visible:
		return first_move_hinted
	var near_core := false
	for raw_position in blocks.keys():
		var block_position: Vector3i = raw_position
		var offset: Vector3i = block_position - player
		if absi(offset.x) + absi(offset.y) + absi(offset.z) == 1:
			near_core = true
			break
	if not near_core:
		return first_move_hinted
	var hint_lines := StoryData.get_dialogue_event("first_move_hint")
	if hint_lines.is_empty():
		return first_move_hinted
	dialogue_box.play_dialogue(hint_lines)
	await dialogue_box.dialogue_finished
	return true


## Chapter intro card + opening dialogue; Kiro boots up during chapter 1.
func play_chapter_start_sequence(chapter: int, vfx: EchoVfxManager, player_position_provider: Callable) -> void:
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
				_power_on_kiro(vfx, player_position_provider)

		dialogue_box.line_started.connect(line_handler)
		dialogue_box.play_dialogue(lines)
		await dialogue_box.dialogue_finished
		if dialogue_box.line_started.is_connected(line_handler):
			dialogue_box.line_started.disconnect(line_handler)
		if chapter == 1 and not has_powered_on:
			_power_on_kiro(vfx, player_position_provider)
	elif chapter == 1:
		_power_on_kiro(vfx, player_position_provider)

	board_view.face_player(Vector3i(1, 0, 0))


func _power_on_kiro(vfx: EchoVfxManager, player_position_provider: Callable) -> void:
	board_view.set_kiro_powered(true)
	board_view.play_boot_awakening()
	vfx.play_boot_sparks(player_position_provider.call())


## Win-scene skits for scripted levels. Returns true when it played one.
func play_win_skit(level_index: int, target_slot: Vector3i, target_world_pos: Vector3) -> bool:
	if not dialogue_box:
		return false
	var lines: Array = []
	var pre_delay := 0.4
	match level_index:
		0:
			lines = StoryData.get_dialogue_event("first_puzzle_done")
		3:
			lines = StoryData.get_dialogue_event("level_4_eva_contact")
			pre_delay = 0.35
	if lines.is_empty():
		return false
	var player: Vector3i = player_provider.call()
	var player_world_pos := board_view.world_position(player)
	board_view.face_player(target_slot - player)
	await board_view.get_tree().create_timer(pre_delay).timeout
	board_view.spawn_eva_hologram(target_world_pos, player_world_pos)
	await board_view.get_tree().create_timer(pre_delay).timeout
	dialogue_box.play_dialogue(lines)
	await dialogue_box.dialogue_finished
	board_view.dismiss_eva_hologram()
	await board_view.get_tree().create_timer(0.3).timeout
	return true
