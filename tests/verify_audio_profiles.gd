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
		check(manager._ambience_key == key, "chapter %d selects the correct base ambience" % chapter)
		check(manager._ambience_detail_key == key, "chapter %d selects a detail ambience layer" % chapter)
		check(manager.ambience_player.stream == AUDIO.AMBIENCE_STREAMS[key], "chapter %d base stream is loaded" % chapter)
		check(manager.ambience_detail_player.stream != null, "chapter %d detail stream is loaded" % chapter)
		if key in AUDIO.AMBIENCE_ACCENT_STREAMS:
			check(manager._ambience_accent_key == key, "chapter %d selects an accent ambience layer" % chapter)
			check(manager.ambience_accent_player.stream != null, "chapter %d accent stream is loaded" % chapter)
		else:
			check(manager.ambience_accent_player.stream == null, "chapter %d has no accent layer" % chapter)
	for key in [&"portal_reject", &"elevator_loop", &"door_close", &"fragment", &"core_pulse"]:
		check(AUDIO.SFX_STREAMS.has(key), "sfx %s is registered" % str(key))
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
