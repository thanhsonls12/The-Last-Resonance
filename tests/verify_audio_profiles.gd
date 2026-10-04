extends Node

const AUDIO = preload("res://src/view/audio_manager.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	check(AUDIO.SFX_STREAMS.has(&"plate_press"), "pressure plate press SFX is registered")
	check(AUDIO.SFX_STREAMS.has(&"plate_release"), "pressure plate release SFX is registered")
	check(str(AUDIO.SFX_STREAMS[&"plate_press"].resource_path).ends_with("SFX_PressurePlate_Press.wav"), "press mapping points to the authored press asset")
	check(str(AUDIO.SFX_STREAMS[&"plate_release"].resource_path).ends_with("SFX_PressurePlate_Release.wav"), "release mapping points to the authored release asset")
	var manager := AUDIO.new()
	manager.enabled = false
	add_child(manager)
	await get_tree().process_frame
	var expected := {
		1: &"archive",
		2: &"foundry",
		3: &"sanctuary",
		4: &"core",
	}
	for chapter in range(1, 5):
		manager.set_ambience_for_chapter(chapter)
		var key: StringName = expected[chapter]
		var source := AUDIO.AMBIENCE_STREAMS[key] as AudioStreamWAV
		var assigned := manager.ambience_player.stream as AudioStreamWAV
		check(manager._ambience_key == key, "chapter %d selects the correct base ambience" % chapter)
		check(manager._ambience_detail_key == key, "chapter %d selects a detail ambience layer" % chapter)
		check(assigned != null, "chapter %d base stream is loaded" % chapter)
		if assigned != null and source != null:
			check(assigned.loop_mode == AudioStreamWAV.LOOP_FORWARD, "chapter %d base stream is configured to loop" % chapter)
			check(is_equal_approx(assigned.get_length(), source.get_length()), "chapter %d base stream keeps the authored audio content" % chapter)
		check(manager.ambience_detail_player.stream != null, "chapter %d detail stream is loaded" % chapter)
		if key in AUDIO.AMBIENCE_ACCENT_STREAMS:
			check(manager._ambience_accent_key == key, "chapter %d selects an accent ambience layer" % chapter)
			check(manager.ambience_accent_player.stream != null, "chapter %d accent stream is loaded" % chapter)
		else:
			check(manager.ambience_accent_player.stream == null, "chapter %d has no accent layer" % chapter)
	for chapter in range(1, 5):
		var key: StringName = expected[chapter]
		check(key in AUDIO.AMBIENCE_ACCENT_STREAMS,
			"chapter %d has an accent ambience layer" % chapter)
	for key in [&"portal_reject", &"elevator_loop", &"door_close", &"fragment", &"core_pulse"]:
		check(AUDIO.SFX_STREAMS.has(key), "sfx %s is registered" % str(key))
	# Previously-unused authored clips must now be reachable from the manager.
	for key in [&"level_start", &"goal_lock", &"checkpoint", &"door_locked", &"switch_on", &"switch_off",
			&"terminal_on", &"terminal_error", &"portal_charge", &"conveyor_start", &"conveyor_loop",
			&"conveyor_stop", &"debris_rumble", &"player_interact", &"player_turn", &"player_push_start",
			&"player_success_beep", &"player_robot_beep", &"player_robot_alert", &"player_low_battery",
			&"player_damage_glitch", &"ui_back", &"ui_resume", &"ui_focus"]:
		check(AUDIO.SFX_STREAMS.has(key), "newly wired sfx %s is registered" % str(key))
	# Every SFX key referenced from gameplay code must resolve in the catalog.
	check(AUDIO.SFX_STREAMS.has(&"ui_focus"), "ui_focus exists so memory codex focus feedback plays")
	for key in [&"chapter_1", &"chapter_2", &"chapter_3", &"chapter_4"]:
		check(AUDIO.BGM_STREAMS.has(key), "chapter bgm %s is registered" % str(key))
	check(AUDIO.CHAPTER_BGM.size() == 4, "all four chapters map to a bgm key")
	# bgm ships non-looping; the manager must return a looping stream for playback.
	var distinct_tracks := {}
	for chapter in range(1, 5):
		var bgm_key: StringName = AUDIO.CHAPTER_BGM[chapter]
		distinct_tracks[bgm_key] = true
		var stream_src := AUDIO.BGM_STREAMS[bgm_key] as AudioStream
		check(stream_src != null, "chapter %d bgm stream loads" % chapter)
		var looped_src := AUDIO._looped_bgm(stream_src)
		check(looped_src != null, "chapter %d bgm is playable" % chapter)
		check(looped_src != stream_src, "chapter %d looping bgm leaves the imported resource untouched" % chapter)
		if looped_src is AudioStreamOggVorbis:
			check((looped_src as AudioStreamOggVorbis).loop, "chapter %d bgm is configured to loop" % chapter)
			check(not (stream_src as AudioStreamOggVorbis).loop, "chapter %d source ogg was not mutated" % chapter)
		elif looped_src is AudioStreamWAV:
			check((looped_src as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD, "chapter %d bgm is configured to loop" % chapter)
		else:
			check(false, "unexpected chapter %d bgm type: %s" % [chapter, looped_src.get_class()])
	check(distinct_tracks.size() == 4, "the four chapters use four distinct music tracks")
	for player in manager.sfx_players:
		player.stop()
	manager.ambience_player.stop()
	manager.ambience_detail_player.stop()
	if manager.ambience_accent_player:
		manager.ambience_accent_player.stop()
	if manager.elevator_loop_player:
		manager.elevator_loop_player.stop()
	manager.reactor_layer_player.stop()
	manager.voice_player.stop()
	manager.set_process(false)
	manager.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("Audio profile checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
