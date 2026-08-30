class_name EchoAudioManager
extends Node

const SFX_PLAYER_COUNT := 6
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
	&"blocked": preload("res://assets/audio/sfx/SFX_Box_Blocked.wav"),
	&"door": preload("res://assets/audio/sfx/SFX_Door_Open.wav"),
	&"portal": preload("res://assets/audio/sfx/SFX_Portal_Teleport.wav"),
	&"elevator": preload("res://assets/audio/sfx/SFX_Elevator_Start.wav"),
	&"bridge": preload("res://assets/audio/sfx/SFX_Bridge_Rotate.wav"),
	&"box_on_goal": preload("res://assets/audio/sfx/SFX_Box_OnGoal.wav"),
	&"energy": preload("res://assets/audio/sfx/SFX_Core_Insert.wav"),
	&"win": preload("res://assets/audio/sfx/SFX_Level_Complete_Stinger.wav"),
	&"win_pulse": preload("res://assets/audio/sfx/SFX_VFX_LevelComplete.wav"),
	&"undo": preload("res://assets/audio/sfx/SFX_Player_Undo.wav"),
	&"reset": preload("res://assets/audio/sfx/SFX_Player_Reset.wav"),
	&"ui_click": preload("res://assets/audio/sfx/SFX_UI_Click.wav"),
	&"ui_confirm": preload("res://assets/audio/sfx/SFX_UI_Confirm.wav"),
	&"ui_cancel": preload("res://assets/audio/sfx/SFX_UI_Cancel.wav"),
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

const LAYER_CORE_HUM = preload("res://assets/audio/sfx/SFX_VFX_Core_Hum_Loop.wav")

var sfx_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
var reactor_layer_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var _next_player := 0
var _ambience_key: StringName = &""
var _surface: StringName = &"stone"
var _last_sfx_enabled := true
var enabled := true


func _ready() -> void:
	for i in SFX_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		add_child(player)
		sfx_players.append(player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	add_child(ambience_player)
	
	reactor_layer_player = AudioStreamPlayer.new()
	reactor_layer_player.name = "ReactorLayerPlayer"
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
	add_child(voice_player)

	set_ambience(DEFAULT_AMBIENCE)


func _process(_delta: float) -> void:
	var audio_on := enabled and GameState.sfx_enabled
	if audio_on == _last_sfx_enabled:
		return
	_last_sfx_enabled = audio_on
	if audio_on:
		if ambience_player.stream:
			ambience_player.play()
	else:
		ambience_player.stop()


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
	if enabled and GameState.sfx_enabled:
		ambience_player.play()


func play_move() -> void:
	match _surface:
		&"metal":
			_play_random([&"footstep_metal_1", &"footstep_metal_2"], -5.0)
		&"water":
			_play_random([&"footstep_water_1", &"footstep_water_2"], -5.0)
		_:
			_play_random([&"footstep_stone_1", &"footstep_stone_2"], -5.0)


func play_push() -> void:
	_play_sfx(&"push", -2.5)


func play_blocked() -> void:
	_play_sfx(&"blocked", -3.0)


func play_door() -> void:
	_play_sfx(&"door", -3.0)


func play_plate(active: bool) -> void:
	_play_sfx(&"energy", -4.5, 1.35 if active else 0.82)


func play_portal() -> void:
	_play_sfx(&"portal", -2.0)


func play_elevator() -> void:
	_play_sfx(&"elevator", -2.0)


func play_bridge() -> void:
	_play_sfx(&"bridge", -3.0)


func play_box_on_goal() -> void:
	_play_sfx(&"box_on_goal", -2.0)


func play_energy() -> void:
	_play_sfx(&"energy", -2.5)


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
