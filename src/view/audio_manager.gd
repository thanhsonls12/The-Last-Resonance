class_name EchoAudioManager
extends Node

const SFX_PLAYER_COUNT := 8
const DEFAULT_AMBIENCE := &"archive"

const SFX_STREAMS: Dictionary = {
	&"move": preload("res://assets/audio/sfx/SFX_Player_Servo.wav"),
	&"footstep_stone_1": preload("res://assets/audio/sfx/SFX_Player_Footstep_Stone_01.wav"),
	&"footstep_stone_2": preload("res://assets/audio/sfx/SFX_Player_Footstep_Stone_02.wav"),
	&"footstep_metal_1": preload("res://assets/audio/sfx/SFX_Player_Footstep_Metal_01.wav"),
	&"footstep_metal_2": preload("res://assets/audio/sfx/SFX_Player_Footstep_Metal_02.wav"),
	&"footstep_water_1": preload("res://assets/audio/sfx/SFX_Player_Footstep_Water_01.wav"),
	&"footstep_water_2": preload("res://assets/audio/sfx/SFX_Player_Footstep_Water_02.wav"),
	&"push": preload("res://assets/audio/sfx/SFX_Player_Push_Impact.wav"),
	&"push_scrape": preload("res://assets/audio/sfx/SFX_Box_Scrape.wav"),
	&"blocked": preload("res://assets/audio/sfx/SFX_Box_Blocked.wav"),
	&"box_impact": preload("res://assets/audio/sfx/SFX_Box_Impact.wav"),
	&"plate_press": preload("res://assets/audio/sfx/SFX_PressurePlate_Press.wav"),
	&"plate_release": preload("res://assets/audio/sfx/SFX_PressurePlate_Release.wav"),
	&"door": preload("res://assets/audio/sfx/SFX_Door_Open.wav"),
	&"door_close": preload("res://assets/audio/sfx/SFX_Door_Close.wav"),
	&"door_unlock": preload("res://assets/audio/sfx/SFX_Door_Unlock.wav"),
	&"portal": preload("res://assets/audio/sfx/SFX_Portal_Teleport.wav"),
	&"portal_activate": preload("res://assets/audio/sfx/SFX_Portal_Activate.wav"),
	&"portal_reject": preload("res://assets/audio/sfx/SFX_Portal_Reject.wav"),
	&"elevator": preload("res://assets/audio/sfx/SFX_Elevator_Start.wav"),
	&"elevator_loop": preload("res://assets/audio/sfx/SFX_Elevator_Loop.wav"),
	&"elevator_stop": preload("res://assets/audio/sfx/SFX_Elevator_Stop.wav"),
	&"bridge": preload("res://assets/audio/sfx/SFX_Bridge_Rotate.wav"),
	&"bridge_lock": preload("res://assets/audio/sfx/SFX_Bridge_Lock.wav"),
	&"box_on_goal": preload("res://assets/audio/sfx/SFX_Box_OnGoal.wav"),
	&"energy": preload("res://assets/audio/sfx/SFX_Core_Insert.wav"),
	&"core_pulse": preload("res://assets/audio/sfx/SFX_VFX_Core_Pulse.wav"),
	&"fragment": preload("res://assets/audio/sfx/SFX_MemoryFragment_Collect.wav"),
	&"dust": preload("res://assets/audio/sfx/SFX_VFX_Dust_Puff.wav"),
	&"spark": preload("res://assets/audio/sfx/SFX_VFX_Spark.wav"),
	&"water_splash": preload("res://assets/audio/sfx/SFX_VFX_Water_Splash.wav"),
	&"ember": preload("res://assets/audio/sfx/SFX_VFX_Ember_Crackle.wav"),
	&"steam": preload("res://assets/audio/sfx/SFX_VFX_Steam_Hiss.wav"),
	&"win": preload("res://assets/audio/sfx/SFX_Level_Complete_Stinger.wav"),
	&"win_pulse": preload("res://assets/audio/sfx/SFX_VFX_LevelComplete.wav"),
	&"undo": preload("res://assets/audio/sfx/SFX_Player_Undo.wav"),
	&"reset": preload("res://assets/audio/sfx/SFX_Player_Reset.wav"),
	&"ui_click": preload("res://assets/audio/sfx/SFX_UI_Click.wav"),
	&"ui_confirm": preload("res://assets/audio/sfx/SFX_UI_Confirm.wav"),
	&"ui_cancel": preload("res://assets/audio/sfx/SFX_UI_Cancel.wav"),
	&"ui_hover": preload("res://assets/audio/sfx/SFX_UI_Hover.wav"),
	&"ui_pause_open": preload("res://assets/audio/sfx/SFX_UI_Pause_Open.wav"),
	&"ui_pause_close": preload("res://assets/audio/sfx/SFX_UI_Pause_Close.wav"),
	&"ui_slider": preload("res://assets/audio/sfx/SFX_UI_Slider_Tick.wav"),
	&"ui_error": preload("res://assets/audio/sfx/SFX_UI_Error.wav"),
	&"ui_level_select": preload("res://assets/audio/sfx/SFX_UI_Level_Select.wav"),
	&"ui_page_next": preload("res://assets/audio/sfx/SFX_UI_Page_Next.wav"),
	&"ui_page_prev": preload("res://assets/audio/sfx/SFX_UI_Page_Previous.wav"),
	&"ui_save": preload("res://assets/audio/sfx/SFX_UI_Save_Complete.wav"),
	&"bleep_1": preload("res://assets/audio/sfx/SFX_Player_Dialogue_Bleep_01.wav"),
	&"bleep_2": preload("res://assets/audio/sfx/SFX_Player_Dialogue_Bleep_02.wav"),
	&"voice_eva": preload("res://assets/audio/sfx/SFX_Voice_EVA.wav"),
	&"voice_elias": preload("res://assets/audio/sfx/SFX_Voice_Elias.wav"),
	&"voice_kiro": preload("res://assets/audio/sfx/SFX_Voice_Kiro.wav"),
	&"voice_system": preload("res://assets/audio/sfx/SFX_Voice_System.wav"),
}

const AMBIENCE_STREAMS: Dictionary = {
	&"archive": preload("res://assets/audio/ambience/AMB_Archive_Base_Loop.wav"),
	&"foundry": preload("res://assets/audio/ambience/AMB_Foundry_Base_Loop.wav"),
	&"sanctuary": preload("res://assets/audio/ambience/AMB_Sanctuary_Base_Loop.wav"),
	&"core": preload("res://assets/audio/ambience/AMB_Core_Reactor_Loop.wav"),
}

const AMBIENCE_DETAIL_STREAMS: Dictionary = {
	&"archive": preload("res://assets/audio/ambience/AMB_Electrical_Hum_Loop.wav"),
	&"foundry": preload("res://assets/audio/ambience/AMB_Machinery_Distant_Loop.wav"),
	&"sanctuary": preload("res://assets/audio/ambience/AMB_Water_Current_Loop.wav"),
	&"core": preload("res://assets/audio/ambience/AMB_Electrical_Hum_Loop.wav"),
}

const AMBIENCE_DETAIL_VOLUME_DB: Dictionary = {
	&"archive": -24.0,
	&"foundry": -21.0,
	&"sanctuary": -22.0,
	&"core": -25.0,
}

const AMBIENCE_ACCENT_STREAMS: Dictionary = {
	&"archive": preload("res://assets/audio/ambience/AMB_Wind_Corridor_Loop.wav"),
	&"foundry": preload("res://assets/audio/ambience/AMB_Foundry_Furnace_Loop.wav"),
	&"sanctuary": preload("res://assets/audio/ambience/AMB_Water_Drip_Loop.wav"),
}

const AMBIENCE_ACCENT_VOLUME_DB: Dictionary = {
	&"archive": -30.0,
	&"foundry": -28.0,
	&"sanctuary": -32.0,
}

const LAYER_CORE_HUM = preload("res://assets/audio/sfx/SFX_VFX_Core_Hum_Loop.wav")

var sfx_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var ambience_detail_player: AudioStreamPlayer
var ambience_accent_player: AudioStreamPlayer
var elevator_loop_player: AudioStreamPlayer
var reactor_layer_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var _next_player := 0
var _ambience_key: StringName = &""
var _ambience_detail_key: StringName = &""
var _ambience_accent_key: StringName = &""
var _surface: StringName = &"stone"
var _last_sfx_enabled := true
var _music_bus := -1
var _sfx_bus := -1
var enabled := true


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
	ambience_player.bus = &"Music"
	add_child(ambience_player)
	ambience_detail_player = AudioStreamPlayer.new()
	ambience_detail_player.name = "AmbienceDetailPlayer"
	ambience_detail_player.bus = &"Music"
	add_child(ambience_detail_player)
	ambience_accent_player = AudioStreamPlayer.new()
	ambience_accent_player.name = "AmbienceAccentPlayer"
	ambience_accent_player.bus = &"Music"
	add_child(ambience_accent_player)
	elevator_loop_player = AudioStreamPlayer.new()
	elevator_loop_player.name = "ElevatorLoopPlayer"
	elevator_loop_player.bus = &"SFX"
	add_child(elevator_loop_player)

	reactor_layer_player = AudioStreamPlayer.new()
	reactor_layer_player.name = "ReactorLayerPlayer"
	reactor_layer_player.bus = &"Music"
	if LAYER_CORE_HUM is AudioStreamWAV:
		var hum_stream := LAYER_CORE_HUM.duplicate() as AudioStreamWAV
		hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		reactor_layer_player.stream = hum_stream
	else:
		reactor_layer_player.stream = LAYER_CORE_HUM
	reactor_layer_player.volume_db = -80.0
	add_child(reactor_layer_player)

	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = &"SFX"
	add_child(voice_player)

	if not GameState.settings_changed.is_connected(_apply_audio_settings):
		GameState.settings_changed.connect(_apply_audio_settings)
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
		AudioServer.set_bus_mute(master_bus, not enabled or not GameState.sfx_enabled)
	AudioServer.set_bus_volume_db(_music_bus, _volume_to_db(GameState.music_volume))
	AudioServer.set_bus_volume_db(_sfx_bus, _volume_to_db(GameState.sfx_volume))


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
	else:
		ambience_player.stop()
		ambience_detail_player.stop()
		ambience_accent_player.stop()
		stop_elevator_loop()


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


func set_ambience(key: StringName) -> void:
	if ambience_player == null or _ambience_key == key:
		return
	var stream := AMBIENCE_STREAMS.get(key) as AudioStreamWAV
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience_player.stream = stream
	ambience_player.volume_db = -14.0
	_ambience_key = key
	_set_ambience_detail(key)
	_set_ambience_accent(key)
	if enabled and GameState.sfx_enabled:
		ambience_player.play()
		if ambience_detail_player.stream:
			ambience_detail_player.play()
		if ambience_accent_player.stream:
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
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience_detail_player.stream = stream
	ambience_detail_player.volume_db = float(AMBIENCE_DETAIL_VOLUME_DB.get(key, -24.0))
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
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	ambience_accent_player.stream = stream
	ambience_accent_player.volume_db = float(AMBIENCE_ACCENT_VOLUME_DB.get(key, -30.0))
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
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elevator_loop_player.stream = stream
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
	var target_vol: float = lerpf(-24.0, -10.0, progress)
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
