class_name AudioCatalog
extends RefCounted

## Asset/config registry only. Playback lifecycle stays in EchoAudioManager.

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
	&"ui_back": preload("res://assets/audio/sfx/SFX_UI_Back.wav"),
	&"ui_resume": preload("res://assets/audio/sfx/SFX_UI_Resume.wav"),
	&"ui_focus": preload("res://assets/audio/sfx/SFX_UI_Hover.wav"),
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
	&"hologram_activate": preload("res://assets/audio/sfx/SFX_Hologram_Activate.wav"),
	&"ending_decision": preload("res://assets/audio/sfx/SFX_Ending_Decision.wav"),
	&"ending_reveal": preload("res://assets/audio/sfx/SFX_Ending_Reveal.wav"),
	&"memory_decode": preload("res://assets/audio/sfx/SFX_Memory_Decode.wav"),
	&"level_start": preload("res://assets/audio/sfx/SFX_Level_Start.wav"),
	&"goal_lock": preload("res://assets/audio/sfx/SFX_Goal_Lock.wav"),
	&"checkpoint": preload("res://assets/audio/sfx/SFX_Checkpoint_Activate.wav"),
	&"door_locked": preload("res://assets/audio/sfx/SFX_Door_Locked.wav"),
	&"switch_on": preload("res://assets/audio/sfx/SFX_Switch_Toggle_On.wav"),
	&"switch_off": preload("res://assets/audio/sfx/SFX_Switch_Toggle_Off.wav"),
	&"terminal_on": preload("res://assets/audio/sfx/SFX_Terminal_On.wav"),
	&"terminal_error": preload("res://assets/audio/sfx/SFX_Terminal_Error.wav"),
	&"portal_charge": preload("res://assets/audio/sfx/SFX_Portal_Charge.wav"),
	&"conveyor_start": preload("res://assets/audio/sfx/SFX_Conveyor_Start.wav"),
	&"conveyor_loop": preload("res://assets/audio/sfx/SFX_Conveyor_Loop.wav"),
	&"conveyor_stop": preload("res://assets/audio/sfx/SFX_Conveyor_Stop.wav"),
	&"debris_rumble": preload("res://assets/audio/sfx/SFX_Debris_Rumble.wav"),
	&"player_interact": preload("res://assets/audio/sfx/SFX_Player_Interact.wav"),
	&"player_turn": preload("res://assets/audio/sfx/SFX_Player_Turn.wav"),
	&"player_push_start": preload("res://assets/audio/sfx/SFX_Player_Push_Start.wav"),
	&"player_success_beep": preload("res://assets/audio/sfx/SFX_Player_Success_Beep.wav"),
	&"player_robot_beep": preload("res://assets/audio/sfx/SFX_Player_Robot_Beep.wav"),
	&"player_robot_alert": preload("res://assets/audio/sfx/SFX_Player_Robot_Alert.wav"),
	&"player_low_battery": preload("res://assets/audio/sfx/SFX_Player_LowBattery.wav"),
	&"player_damage_glitch": preload("res://assets/audio/sfx/SFX_Player_Damage_Glitch.wav"),
}

const BGM_STREAMS: Dictionary = {
	&"menu": preload("res://assets/audio/music/bgm_menu.ogg"),
	&"gameplay": preload("res://assets/audio/music/bgm_gameplay_main.ogg"),
	&"ending": preload("res://assets/audio/music/bgm_ending.ogg"),
	&"chapter_1": preload("res://assets/audio/music/BGM_Candlepower.ogg"),
	&"chapter_2": preload("res://assets/audio/music/bgm_gameplay_main.ogg"),
	&"chapter_3": preload("res://assets/audio/music/BGM_Divider.ogg"),
	&"chapter_4": preload("res://assets/audio/music/BGM_Kaleetan_Full.ogg"),
}

## Chapter -> BGM key. Chapter II keeps the established main gameplay theme;
## the other three chapters get their own track so the campaign's escalation is
## audible instead of reusing one loop for all fifteen levels.
const CHAPTER_BGM: Dictionary = {
	1: &"chapter_1",
	2: &"chapter_2",
	3: &"chapter_3",
	4: &"chapter_4",
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
	&"archive": - 8.0,
	&"foundry": - 8.0,
	&"sanctuary": - 8.0,
	&"core": - 8.0,
}

const AMBIENCE_ACCENT_STREAMS: Dictionary = {
	&"archive": preload("res://assets/audio/ambience/AMB_Wind_Corridor_Loop.wav"),
	&"foundry": preload("res://assets/audio/ambience/AMB_Foundry_Furnace_Loop.wav"),
	&"sanctuary": preload("res://assets/audio/ambience/AMB_Water_Drip_Loop.wav"),
	&"core": preload("res://assets/audio/ambience/AMB_Wind_Corridor_Loop.wav"),
}

const AMBIENCE_ACCENT_VOLUME_DB: Dictionary = {
	&"archive": - 9.0,
	&"foundry": - 9.0,
	&"sanctuary": - 9.0,
	&"core": - 11.0,
}

const LAYER_CORE_HUM = preload("res://assets/audio/sfx/SFX_VFX_Core_Hum_Loop.wav")
