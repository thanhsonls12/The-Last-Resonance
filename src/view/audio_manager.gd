class_name EchoAudioManager
extends Node

const SFX_PLAYER_COUNT := 8
const DEFAULT_AMBIENCE := &"archive"
const AUDIO_CATALOG = preload("res://src/data/audio_catalog.gd")

## Compatibility aliases: callers/tests may keep inspecting the manager catalog,
## while the asset/config registry itself lives in AudioCatalog.
const SFX_STREAMS = AUDIO_CATALOG.SFX_STREAMS
const BGM_STREAMS = AUDIO_CATALOG.BGM_STREAMS
const CHAPTER_BGM = AUDIO_CATALOG.CHAPTER_BGM
const AMBIENCE_STREAMS = AUDIO_CATALOG.AMBIENCE_STREAMS
const AMBIENCE_DETAIL_STREAMS = AUDIO_CATALOG.AMBIENCE_DETAIL_STREAMS
const AMBIENCE_DETAIL_VOLUME_DB = AUDIO_CATALOG.AMBIENCE_DETAIL_VOLUME_DB
const AMBIENCE_ACCENT_STREAMS = AUDIO_CATALOG.AMBIENCE_ACCENT_STREAMS
const AMBIENCE_ACCENT_VOLUME_DB = AUDIO_CATALOG.AMBIENCE_ACCENT_VOLUME_DB
const LAYER_CORE_HUM = AUDIO_CATALOG.LAYER_CORE_HUM
var sfx_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var ambience_detail_player: AudioStreamPlayer
var ambience_accent_player: AudioStreamPlayer
var elevator_loop_player: AudioStreamPlayer
var reactor_layer_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer
var _bgm_key: StringName = &""
var _bgm_fade_tween: Tween
var _next_player := 0
var _ambience_key: StringName = &""
var _ambience_detail_key: StringName = &""
var _ambience_accent_key: StringName = &""
var _surface: StringName = &"stone"
var _last_sfx_enabled := true
var _music_bus := -1
var _sfx_bus := -1
var enabled := true


static func _looped(src: AudioStreamWAV) -> AudioStreamWAV:
	var stream := src.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(src.get_length() * src.mix_rate))
	return stream


## BGM ships as non-looping .ogg, so a track would otherwise play once and then
## leave the level silent. Enable looping per playback instance; the imported
## resource is never mutated because each play duplicates it.
static func _looped_bgm(src: AudioStream) -> AudioStream:
	if src == null:
		return null
	if src is AudioStreamOggVorbis:
		var ogg := (src as AudioStreamOggVorbis).duplicate() as AudioStreamOggVorbis
		ogg.loop = true
		ogg.loop_offset = 0.0
		return ogg
	if src is AudioStreamWAV:
		return _looped(src as AudioStreamWAV)
	if src is AudioStreamMP3:
		var mp3 := (src as AudioStreamMP3).duplicate() as AudioStreamMP3
		mp3.loop = true
		mp3.loop_offset = 0.0
		return mp3
	return src


func _ready() -> void:
	_ensure_audio_buses()
	for i in SFX_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = &"SFX"
		add_child(player)
		sfx_players.append(player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.bus = &"SFX"
	add_child(ambience_player)
	ambience_detail_player = AudioStreamPlayer.new()
	ambience_detail_player.name = "AmbienceDetailPlayer"
	ambience_detail_player.bus = &"SFX"
	add_child(ambience_detail_player)
	ambience_accent_player = AudioStreamPlayer.new()
	ambience_accent_player.name = "AmbienceAccentPlayer"
	ambience_accent_player.bus = &"SFX"
	add_child(ambience_accent_player)
	elevator_loop_player = AudioStreamPlayer.new()
	elevator_loop_player.name = "ElevatorLoopPlayer"
	elevator_loop_player.bus = &"SFX"
	add_child(elevator_loop_player)

	reactor_layer_player = AudioStreamPlayer.new()
	reactor_layer_player.name = "ReactorLayerPlayer"
	reactor_layer_player.bus = &"SFX"
	if LAYER_CORE_HUM is AudioStreamWAV:
		reactor_layer_player.stream = _looped(LAYER_CORE_HUM)
	else:
		reactor_layer_player.stream = LAYER_CORE_HUM
	reactor_layer_player.volume_db = -80.0
	add_child(reactor_layer_player)

	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = &"SFX"
	add_child(voice_player)

	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = &"Music"
	add_child(bgm_player)

	if not GameState.settings_changed.is_connected(_apply_audio_settings):
		GameState.settings_changed.connect(_apply_audio_settings)
	_ensure_audio_buses()
	_apply_audio_settings()
	set_ambience(DEFAULT_AMBIENCE)


func _ensure_audio_buses() -> void:
	_music_bus = AudioServer.get_bus_index(&"Music")
	if _music_bus < 0:
		AudioServer.add_bus()
		_music_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_music_bus, &"Music")
		AudioServer.set_bus_send(_music_bus, &"Master")
	_sfx_bus = AudioServer.get_bus_index(&"SFX")
	if _sfx_bus < 0:
		AudioServer.add_bus()
		_sfx_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_sfx_bus, &"SFX")
		AudioServer.set_bus_send(_sfx_bus, &"Master")


func _volume_to_db(value: float) -> float:
	return -80.0 if value <= 0.001 else linear_to_db(value)


func _apply_audio_settings() -> void:
	if _music_bus < 0 or _sfx_bus < 0:
		return
	var master_bus := AudioServer.get_bus_index(&"Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, _volume_to_db(GameState.master_volume))
		AudioServer.set_bus_mute(master_bus, not enabled or not GameState.sfx_enabled or GameState.master_volume <= 0.001)
	AudioServer.set_bus_volume_db(_music_bus, _volume_to_db(GameState.music_volume))
	AudioServer.set_bus_mute(_music_bus, GameState.music_volume <= 0.001)
	AudioServer.set_bus_volume_db(_sfx_bus, _volume_to_db(GameState.sfx_volume))
	AudioServer.set_bus_mute(_sfx_bus, GameState.sfx_volume <= 0.001)


func _process(_delta: float) -> void:
	var audio_on := enabled and GameState.sfx_enabled
	if audio_on == _last_sfx_enabled:
		return
	_last_sfx_enabled = audio_on
	if audio_on:
		if ambience_player.stream:
			ambience_player.play()
		if ambience_detail_player.stream:
			ambience_detail_player.play()
		if ambience_accent_player.stream:
			ambience_accent_player.play()
		if bgm_player != null and bgm_player.stream != null and not bgm_player.playing:
			bgm_player.play()
	else:
		ambience_player.stop()
		ambience_detail_player.stop()
		ambience_accent_player.stop()
		if bgm_player != null:
			bgm_player.stop()
		stop_elevator_loop()


func play_bgm(key: StringName, fade_duration := 1.5, volume_offset_db := 1.5) -> void:
	if bgm_player == null:
		return
	if _bgm_key == key and bgm_player.playing:
		return
	var stream := BGM_STREAMS.get(key) as AudioStream
	if stream == null:
		return
	_bgm_key = key
	stream = _looped_bgm(stream)

	if _bgm_fade_tween != null and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()

	if not bgm_player.playing or bgm_player.stream == null:
		bgm_player.stream = stream
		bgm_player.volume_db = -80.0
		if enabled and GameState.sfx_enabled:
			bgm_player.play()
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(bgm_player, "volume_db", volume_offset_db, fade_duration)
	else:
		_bgm_fade_tween = create_tween()
		_bgm_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration * 0.5)
		_bgm_fade_tween.tween_callback(func() -> void:
			bgm_player.stream = stream
			if enabled and GameState.sfx_enabled:
				bgm_player.play()
		)
		_bgm_fade_tween.tween_property(bgm_player, "volume_db", volume_offset_db, fade_duration * 0.5)


func stop_bgm(fade_duration := 1.0) -> void:
	if bgm_player == null or not bgm_player.playing:
		return
	_bgm_key = &""
	if _bgm_fade_tween != null and _bgm_fade_tween.is_valid():
		_bgm_fade_tween.kill()
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
	_bgm_fade_tween.tween_callback(bgm_player.stop)


## Menu and cutscene scenes own their own audio node, so they cannot use the
## gameplay manager instance. This builds a looping, fade-in BGM player that
## honours the Music bus and keeps playing instead of stopping after one pass.
static func create_scene_bgm(host: Node, key: StringName, target_db := -4.0, fade := 1.5) -> AudioStreamPlayer:
	if host == null:
		return null
	var source := BGM_STREAMS.get(key) as AudioStream
	if source == null:
		return null
	var player := AudioStreamPlayer.new()
	player.name = "SceneBGMPlayer"
	player.bus = &"Music"
	player.stream = _looped_bgm(source)
	host.add_child(player)
	if not GameState.sfx_enabled or GameState.music_volume <= 0.001:
		return player
	player.volume_db = -80.0
	player.play()
	var tw := host.create_tween()
	tw.tween_property(player, "volume_db", target_db, fade)
	return player



func set_ambience_for_chapter(chapter: int) -> void:
	match chapter:
		1:
			_surface = &"stone"
			set_ambience(&"archive")
		2:
			_surface = &"metal"
			set_ambience(&"foundry")
		3:
			_surface = &"water"
			set_ambience(&"sanctuary")
		4:
			_surface = &"metal"
			set_ambience(&"core")
		_:
			_surface = &"stone"
			set_ambience(DEFAULT_AMBIENCE)


## Chapter-scoped music. Keeps a single call site for chapters that share a
## track, and is a no-op when the requested chapter already owns the mix.
func set_bgm_for_chapter(chapter: int) -> void:
	var key: StringName = CHAPTER_BGM.get(chapter, CHAPTER_BGM[1])
	play_bgm(key)


## Audible start-of-level cue. Fires on every level load, after any chapter
## intro sequence, so the player hears the level begin.
func play_level_start() -> void:
	_play_sfx(&"level_start", -4.0)


func play_goal_lock() -> void:
	_play_sfx(&"goal_lock", -3.5)
	_play_sfx(&"player_success_beep", -9.0)


func play_checkpoint() -> void:
	_play_sfx(&"checkpoint", -3.0)


func play_door_locked() -> void:
	_play_sfx(&"door_locked", -3.5)
	_play_sfx(&"terminal_error", -9.0)


func play_switch(on: bool) -> void:
	_play_sfx(&"switch_on" if on else &"switch_off", -4.5)


func play_terminal(error := false) -> void:
	_play_sfx(&"terminal_error" if error else &"terminal_on", -4.0)


func play_portal_charge() -> void:
	_play_sfx(&"portal_charge", -6.0)


func play_conveyor_start() -> void:
	_play_sfx(&"conveyor_start", -5.0)


func play_conveyor_loop() -> void:
	_play_sfx(&"conveyor_loop", -10.0)


func play_conveyor_stop() -> void:
	_play_sfx(&"conveyor_stop", -5.0)


func play_debris() -> void:
	_play_sfx(&"debris_rumble", -6.0)


func play_interact() -> void:
	_play_sfx(&"player_interact", -4.0)


func play_turn() -> void:
	_play_sfx(&"player_turn", -8.0)


func play_push_start() -> void:
	_play_sfx(&"player_push_start", -5.0)


func play_robot_alert() -> void:
	_play_sfx(&"player_robot_alert", -5.0)
	_play_sfx(&"player_robot_beep", -10.0)


func play_low_battery() -> void:
	_play_sfx(&"player_low_battery", -5.0)


func play_damage_glitch() -> void:
	_play_sfx(&"player_damage_glitch", -3.0)


func set_ambience(key: StringName) -> void:
	if ambience_player == null:
		return
	var source := AMBIENCE_STREAMS.get(key) as AudioStreamWAV
	if source != null and (_ambience_key != key or ambience_player.stream == null):
		ambience_player.stream = _looped(source)
		ambience_player.volume_db = -7.0
		_ambience_key = key
		_set_ambience_detail(key)
		_set_ambience_accent(key)

	if enabled and GameState.sfx_enabled:
		if ambience_player.stream != null and not ambience_player.playing:
			ambience_player.play()
		if ambience_detail_player != null and ambience_detail_player.stream != null and not ambience_detail_player.playing:
			ambience_detail_player.play()
		if ambience_accent_player != null and ambience_accent_player.stream != null and not ambience_accent_player.playing:
			ambience_accent_player.play()


func _set_ambience_detail(key: StringName) -> void:
	if ambience_detail_player == null:
		return
	var source := AMBIENCE_DETAIL_STREAMS.get(key) as AudioStreamWAV
	if source == null:
		ambience_detail_player.stop()
		ambience_detail_player.stream = null
		_ambience_detail_key = &""
		return
	ambience_detail_player.stream = _looped(source)
	ambience_detail_player.volume_db = float(AMBIENCE_DETAIL_VOLUME_DB.get(key, 0.0))
	_ambience_detail_key = key


func _set_ambience_accent(key: StringName) -> void:
	if ambience_accent_player == null:
		return
	var source := AMBIENCE_ACCENT_STREAMS.get(key) as AudioStreamWAV
	if source == null:
		ambience_accent_player.stop()
		ambience_accent_player.stream = null
		_ambience_accent_key = &""
		return
	ambience_accent_player.stream = _looped(source)
	ambience_accent_player.volume_db = float(AMBIENCE_ACCENT_VOLUME_DB.get(key, 0.0))
	_ambience_accent_key = key


func play_move() -> void:
	match _surface:
		&"metal":
			_play_random([&"footstep_metal_1", &"footstep_metal_2"], -5.0)
			if randf() < 0.18:
				_play_sfx(&"ember", -18.0)
		&"water":
			_play_random([&"footstep_water_1", &"footstep_water_2"], -5.0)
			_play_sfx(&"water_splash", -12.0)
		_:
			_play_random([&"footstep_stone_1", &"footstep_stone_2"], -5.0)
	_play_sfx(&"dust", -16.0)


func play_push() -> void:
	_play_sfx(&"push", -2.5)
	_play_sfx(&"push_scrape", -6.0, randf_range(0.94, 1.06))


func play_blocked() -> void:
	_play_sfx(&"blocked", -3.0)
	_play_sfx(&"box_impact", -5.0)


func play_door(opening := true) -> void:
	if opening:
		_play_sfx(&"door_unlock", -4.0)
		_play_sfx(&"door", -3.0)
	else:
		_play_sfx(&"door_close", -3.0)


func play_plate(active: bool) -> void:
	_play_sfx(&"plate_press" if active else &"plate_release", -4.5, 1.05 if active else 0.96)


func play_portal() -> void:
	_play_sfx(&"portal_activate", -4.0)
	_play_sfx(&"portal", -2.0)


func play_portal_reject() -> void:
	_play_sfx(&"portal_reject", -3.0)


func play_elevator() -> void:
	_play_sfx(&"elevator", -2.0)


func play_elevator_loop() -> void:
	if elevator_loop_player == null or not enabled or not GameState.sfx_enabled:
		return
	var source := SFX_STREAMS.get(&"elevator_loop") as AudioStreamWAV
	if source == null:
		return
	elevator_loop_player.stream = _looped(source)
	elevator_loop_player.volume_db = -8.0
	elevator_loop_player.play()


func stop_elevator_loop(play_stop := true) -> void:
	if elevator_loop_player != null and elevator_loop_player.playing:
		elevator_loop_player.stop()
	if play_stop:
		_play_sfx(&"elevator_stop", -3.0)


func play_bridge() -> void:
	_play_sfx(&"bridge", -3.0)
	_play_sfx(&"bridge_lock", -5.0)


func play_box_on_goal() -> void:
	_play_sfx(&"box_on_goal", -2.0)


func play_energy() -> void:
	_play_sfx(&"energy", -2.5)
	_play_sfx(&"core_pulse", -5.0)
	_play_sfx(&"spark", -8.0)


func play_fragment() -> void:
	_play_sfx(&"fragment", -2.0)


func play_win() -> void:
	_play_sfx(&"win", -1.5)
	await get_tree().create_timer(0.12).timeout
	_play_sfx(&"win_pulse", -2.0)


func play_undo() -> void:
	_play_sfx(&"undo", -3.0)


func play_reset() -> void:
	_play_sfx(&"reset", -3.0)


func play_ui_click() -> void:
	_play_sfx(&"ui_click", -5.0)


func play_ui_confirm() -> void:
	_play_sfx(&"ui_confirm", -4.0)


func play_ui_cancel() -> void:
	_play_sfx(&"ui_cancel", -4.0)


func play_ui_hover() -> void:
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		return
	_play_sfx(&"ui_hover", -12.0)


func play_ui_pause(opening: bool) -> void:
	_play_sfx(&"ui_pause_open" if opening else &"ui_pause_close", -5.0)


func play_ui_slider() -> void:
	_play_sfx(&"ui_slider", -10.0)


func play_ui_error() -> void:
	_play_sfx(&"ui_error", -4.0)


func play_ui_level_select() -> void:
	_play_sfx(&"ui_level_select", -4.0)


func play_ui_page(next := true) -> void:
	_play_sfx(&"ui_page_next" if next else &"ui_page_prev", -6.0)


func play_ui_save() -> void:
	_play_sfx(&"ui_save", -4.0)


func play_hologram() -> void:
	_play_sfx(&"hologram_activate", -2.0)


func play_ending_decision() -> void:
	_play_sfx(&"ending_decision", 0.0)


func play_ending_reveal() -> void:
	_play_sfx(&"ending_reveal", -1.0)


func play_memory_decode() -> void:
	_play_sfx(&"memory_decode", -3.0)


static func play_menu_sfx(host: Node, key: StringName, volume_db := -5.0) -> void:
	if host == null or not GameState.sfx_enabled:
		return
	if key == &"ui_hover" and (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
		return
	var stream := SFX_STREAMS.get(key) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = stream
	player.volume_db = volume_db
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


static func bind_button_sfx(host: Node, button: Button, click_key: StringName = &"ui_click") -> void:
	if button == null:
		return
	button.pressed.connect(func() -> void:
		play_menu_sfx(host, click_key, -5.0 if click_key != &"ui_error" else -4.0))
	if not OS.has_feature("mobile") and not DisplayServer.is_touchscreen_available():
		button.mouse_entered.connect(func() -> void:
			play_menu_sfx(host, &"ui_hover", -12.0))


func play_voice_blip(speaker: String) -> void:
	var upper := speaker.to_upper()
	var key := &"voice_system"
	var pitch := randf_range(0.96, 1.04)
	var vol := -4.0
	if "EVA" in upper:
		key = &"voice_eva"
		pitch = randf_range(0.98, 1.05)
		vol = -3.0
	elif "ELIAS" in upper:
		key = &"voice_elias"
		pitch = randf_range(0.92, 1.02)
		vol = -2.5
	elif "KIRO" in upper:
		key = &"voice_kiro"
		pitch = randf_range(0.95, 1.08)
		vol = -4.5
	_play_sfx(key, vol, pitch)
	_play_sfx(&"bleep_1" if randf() < 0.5 else &"bleep_2", vol - 8.0, pitch)


func play_voice_stream(stream: AudioStream, volume_db := -2.0) -> void:
	if not enabled or not GameState.sfx_enabled or voice_player == null or stream == null:
		return
	voice_player.stream = stream
	voice_player.volume_db = volume_db
	voice_player.play()


func stop_voice() -> void:
	if voice_player != null and voice_player.playing:
		voice_player.stop()


func update_core_resonance_layer(connected_cores: int, total_cores: int) -> void:
	if reactor_layer_player == null or not enabled or not GameState.sfx_enabled:
		return
	if total_cores <= 0 or connected_cores <= 0:
		var fade_out := create_tween()
		fade_out.tween_property(reactor_layer_player, "volume_db", -80.0, 0.6)
		fade_out.finished.connect(func() -> void:
			if reactor_layer_player.volume_db <= -70.0:
				reactor_layer_player.stop()
		)
		return
	
	var progress: float = clampf(float(connected_cores) / float(total_cores), 0.0, 1.0)
	var target_vol: float = lerpf(-14.0, -3.0, progress)
	var target_pitch: float = lerpf(0.95, 1.25, progress)
	
	if not reactor_layer_player.playing:
		reactor_layer_player.play()
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(reactor_layer_player, "volume_db", target_vol, 0.45)
	tween.tween_property(reactor_layer_player, "pitch_scale", target_pitch, 0.45)


func _play_random(keys: Array[StringName], volume_db := 0.0) -> void:
	if keys.is_empty():
		return
	_play_sfx(keys[randi() % keys.size()], volume_db)


func _play_sfx(key: StringName, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if not enabled or not GameState.sfx_enabled or sfx_players.is_empty():
		return
	var stream := SFX_STREAMS.get(key) as AudioStream
	if stream == null:
		return
	var player := sfx_players[_next_player]
	_next_player = (_next_player + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
