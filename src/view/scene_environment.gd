class_name SceneEnvironmentController
extends Node

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")
const CHAPTER_VISUALS_PATHS := {
	1: "res://resources/visuals/chapter_01.tres",
	2: "res://resources/visuals/chapter_02.tres",
	3: "res://resources/visuals/chapter_03.tres",
	4: "res://resources/visuals/chapter_04.tres",
}

var environment: Environment
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var wash_light: DirectionalLight3D
var _power_tween: Tween


func _ready() -> void:
	_build_environment()


func cancel_transitions() -> void:
	if _power_tween != null and _power_tween.is_valid():
		_power_tween.kill()
	_power_tween = null


func apply_chapter(chapter: int, power_level := 0.0) -> void:
	if environment == null or key_light == null or fill_light == null or wash_light == null:
		return
	var profile := _chapter_visuals(chapter)
	var lift := clampf(power_level, 0.0, 1.0)
	environment.background_color = profile.background.lightened(0.01) if RENDER_QUALITY.is_mobile() else profile.background
	environment.ambient_light_color = profile.ambient
	environment.ambient_light_energy = lerpf(profile.ambient_range.x, profile.ambient_range.y, lift) * RENDER_QUALITY.ambient_boost()
	environment.fog_light_color = profile.fog.lerp(profile.fog_awake, lift)
	environment.fog_light_energy = lerpf(profile.fog_energy_range.x, profile.fog_energy_range.y, lift)
	key_light.light_color = profile.key
	key_light.light_energy = lerpf(profile.key_range.x, profile.key_range.y, lift) * RENDER_QUALITY.key_boost()
	fill_light.light_color = profile.fill
	fill_light.light_energy = lerpf(profile.fill_range.x, profile.fill_range.y, lift) * RENDER_QUALITY.fill_boost()
	wash_light.light_color = profile.wash
	wash_light.light_energy = lerpf(profile.wash_range.x, profile.wash_range.y, lift) * RENDER_QUALITY.wash_boost()


func power_up(chapter: int) -> void:
	if environment == null or key_light == null or fill_light == null:
		return
	var profile := _chapter_visuals(chapter)
	var powered := profile.powered
	cancel_transitions()
	_power_tween = create_tween().set_parallel(true)
	_power_tween.tween_property(environment, "ambient_light_energy", powered.x * RENDER_QUALITY.ambient_boost(), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_power_tween.tween_property(environment, "fog_light_color", profile.fog_awake, 0.9)
	_power_tween.tween_property(key_light, "light_energy", powered.y * RENDER_QUALITY.key_boost(), 0.9)
	_power_tween.tween_property(fill_light, "light_energy", powered.z * RENDER_QUALITY.fill_boost(), 0.9)


func play_blackout(audio, guard: Callable, reduced_motion: bool) -> void:
	if environment == null or (guard.is_valid() and not bool(guard.call())):
		return
	var fade_time := 0.06 if reduced_motion else 0.14
	var hold_time := 0.04 if reduced_motion else 0.12
	var restore_time := 0.08 if reduced_motion else 0.24
	var ambient_before := environment.ambient_light_energy
	var key_before := key_light.light_energy if key_light != null else 0.0
	var fill_before := fill_light.light_energy if fill_light != null else 0.0
	var wash_before := wash_light.light_energy if wash_light != null else 0.0
	var ambience_before: float = float(audio.ambience_player.volume_db) if audio != null and audio.ambience_player != null else -14.0
	var detail_before: float = float(audio.ambience_detail_player.volume_db) if audio != null and audio.ambience_detail_player != null else -22.0
	var accent_before: float = float(audio.ambience_accent_player.volume_db) if audio != null and audio.ambience_accent_player != null else -30.0

	var blackout := create_tween().set_parallel(true)
	blackout.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	blackout.tween_property(environment, "ambient_light_energy", 0.025, fade_time)
	if key_light != null:
		blackout.tween_property(key_light, "light_energy", 0.015, fade_time)
	if fill_light != null:
		blackout.tween_property(fill_light, "light_energy", 0.0, fade_time)
	if wash_light != null:
		blackout.tween_property(wash_light, "light_energy", 0.0, fade_time)
	if audio != null and audio.ambience_player != null:
		blackout.tween_property(audio.ambience_player, "volume_db", -42.0, fade_time)
	if audio != null and audio.ambience_detail_player != null:
		blackout.tween_property(audio.ambience_detail_player, "volume_db", -48.0, fade_time)
	if audio != null and audio.ambience_accent_player != null:
		blackout.tween_property(audio.ambience_accent_player, "volume_db", -52.0, fade_time)
	await blackout.finished
	if guard.is_valid() and not bool(guard.call()):
		return
	await get_tree().create_timer(hold_time).timeout
	if guard.is_valid() and not bool(guard.call()):
		return

	var restore := create_tween().set_parallel(true)
	restore.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	restore.tween_property(environment, "ambient_light_energy", ambient_before, restore_time)
	if key_light != null:
		restore.tween_property(key_light, "light_energy", key_before, restore_time)
	if fill_light != null:
		restore.tween_property(fill_light, "light_energy", fill_before, restore_time)
	if wash_light != null:
		restore.tween_property(wash_light, "light_energy", wash_before, restore_time)
	if audio != null and audio.ambience_player != null:
		restore.tween_property(audio.ambience_player, "volume_db", ambience_before, restore_time)
	if audio != null and audio.ambience_detail_player != null:
		restore.tween_property(audio.ambience_detail_player, "volume_db", detail_before, restore_time)
	if audio != null and audio.ambience_accent_player != null:
		restore.tween_property(audio.ambience_accent_player, "volume_db", accent_before, restore_time)
	await restore.finished


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.002, 0.003, 0.006)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.14, 0.20, 0.31)
	env.ambient_light_energy = 0.68
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = RENDER_QUALITY.tonemap_exposure()
	env.glow_enabled = RENDER_QUALITY.glow_enabled()
	env.glow_intensity = 0.28
	env.glow_bloom = 0.015
	env.glow_hdr_threshold = 1.5
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.fog_enabled = not RENDER_QUALITY.is_mobile()
	env.fog_light_color = Color(0.06, 0.10, 0.18)
	env.fog_density = 0.009
	env.fog_sky_affect = 0.0
	world.environment = env
	environment = env
	add_child(world)

	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-64, -36, 0)
	key_light.light_angular_distance = 1.2
	key_light.shadow_bias = 0.035
	key_light.shadow_normal_bias = 0.6
	key_light.shadow_enabled = RENDER_QUALITY.shadows_enabled()
	key_light.directional_shadow_max_distance = 28.0 if RENDER_QUALITY.is_mobile() else 48.0
	add_child(key_light)

	fill_light = DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(22, 142, 0)
	fill_light.shadow_enabled = false
	add_child(fill_light)

	wash_light = DirectionalLight3D.new()
	wash_light.rotation_degrees = Vector3(-22, 148, 0)
	wash_light.shadow_enabled = false
	add_child(wash_light)


func _chapter_visuals(chapter: int) -> ChapterVisuals:
	var path: String = CHAPTER_VISUALS_PATHS.get(chapter, CHAPTER_VISUALS_PATHS[1])
	return load(path) as ChapterVisuals
