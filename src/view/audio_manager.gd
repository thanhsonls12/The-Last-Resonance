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
	&"energy": preload("res://assets/audio/sfx/SFX_Core_Insert.wav"),
	&"win": preload("res://assets/audio/sfx/SFX_Level_Complete_Stinger.wav"),
	&"win_pulse": preload("res://assets/audio/sfx/SFX_VFX_LevelComplete.wav"),
	&"undo": preload("res://assets/audio/sfx/SFX_Player_Undo.wav"),
	&"reset": preload("res://assets/audio/sfx/SFX_Player_Reset.wav"),
	&"ui_click": preload("res://assets/audio/sfx/SFX_UI_Click.wav"),
	&"ui_confirm": preload("res://assets/audio/sfx/SFX_UI_Confirm.wav"),
	&"ui_cancel": preload("res://assets/audio/sfx/SFX_UI_Cancel.wav"),
}

const AMBIENCE_STREAMS: Dictionary = {
	&"archive": preload("res://assets/audio/ambience/AMB_Archive_Base_Loop.wav"),
	&"foundry": preload("res://assets/audio/ambience/AMB_Foundry_Base_Loop.wav"),
	&"sanctuary": preload("res://assets/audio/ambience/AMB_Sanctuary_Base_Loop.wav"),
	&"core": preload("res://assets/audio/ambience/AMB_Core_Reactor_Loop.wav"),
}

var sfx_players: Array[AudioStreamPlayer] = []
var ambience_player: AudioStreamPlayer
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
