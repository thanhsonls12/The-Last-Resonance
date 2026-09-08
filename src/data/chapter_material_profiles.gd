class_name ChapterMaterialProfiles
extends RefCounted

const RENDER_QUALITY = preload("res://src/data/render_quality.gd")

## Subtle, runtime-only palette variants for imported map scenery.
## The source GLB materials stay untouched; every StandardMaterial3D is duplicated
## before the profile is applied so a shared imported material cannot leak between
## chapters or scenes.
const PROFILES := {
	1: {"name": &"archive", "tint": Color(0.33, 0.48, 0.68), "accent": Color(0.10, 0.82, 1.0), "strength": 0.13, "metallic": 0.58, "roughness": 0.46, "emission_floor": 0.18, "weather_seed": 17, "weather_dark": 0.88, "mobile_surface_limit": 10},
	2: {"name": &"foundry", "tint": Color(0.70, 0.22, 0.055), "accent": Color(1.0, 0.30, 0.055), "strength": 0.16, "metallic": 0.70, "roughness": 0.52, "emission_floor": 0.20, "weather_seed": 43, "weather_dark": 0.80, "mobile_surface_limit": 12},
	3: {"name": &"sanctuary", "tint": Color(0.03, 0.45, 0.42), "accent": Color(0.16, 0.88, 0.82), "strength": 0.15, "metallic": 0.28, "roughness": 0.64, "emission_floor": 0.16, "weather_seed": 71, "weather_dark": 0.86, "mobile_surface_limit": 8},
	4: {"name": &"central_core", "tint": Color(0.14, 0.38, 0.62), "accent": Color(0.30, 0.78, 0.88), "strength": 0.18, "metallic": 0.76, "roughness": 0.38, "emission_floor": 0.24, "weather_seed": 97, "weather_dark": 0.90, "mobile_surface_limit": 10},
}

const DESKTOP_WEATHERING_SIZE := 32
const MOBILE_WEATHERING_SIZE := 16
static var _weathering_textures: Dictionary = {}


static func profile_for(chapter: int) -> Dictionary:
	return PROFILES.get(chapter, PROFILES[1])


static func apply(node: Node, chapter: int, mobile_override: Variant = null) -> int:
	var profile := profile_for(chapter)
	var mobile_mode := _is_mobile_runtime() if mobile_override == null else bool(mobile_override)
	var cache_key := "%d:%s" % [chapter, "mobile" if mobile_mode else "desktop"]
	if not _weathering_textures.has(cache_key):
		_weathering_textures[cache_key] = _build_weathering_texture(profile, mobile_mode)
	var detail_budget: Array = [int(profile["mobile_surface_limit"])] if mobile_mode else [-1]
	return _apply_node(node, profile, _weathering_textures[cache_key], mobile_mode, detail_budget)


static func _is_mobile_runtime() -> bool:
	return RENDER_QUALITY.is_mobile()


static func _build_weathering_texture(profile: Dictionary, mobile_mode := false) -> ImageTexture:
	var texture_size := MOBILE_WEATHERING_SIZE if mobile_mode else DESKTOP_WEATHERING_SIZE
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)
	var seed: int = int(profile["weather_seed"])
	var dark_value: float = float(profile["weather_dark"])
	for y in texture_size:
		for x in texture_size:
			var hash := absi((x * 92821 + y * 68917 + seed * 31337 + x * y * 97) % 100)
			var value := dark_value
			if hash < 5:
				value = dark_value - 0.11
			elif hash < 17:
				value = dark_value - 0.045
			image.set_pixel(x, y, Color(value, value, value, 1.0))
	return ImageTexture.create_from_image(image)


static func _apply_node(node: Node, profile: Dictionary, weathering: Texture2D, mobile_mode: bool, detail_budget: Array) -> int:
	var changed := 0
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			for surface in mesh_instance.mesh.get_surface_count():
				var source := mesh_instance.get_active_material(surface)
				if not source is StandardMaterial3D:
					continue
				var material := source.duplicate() as StandardMaterial3D
				material.albedo_color = material.albedo_color.lerp(profile["tint"], float(profile["strength"]))
				material.metallic = clampf(lerpf(material.metallic, float(profile["metallic"]), 0.35), 0.0, 1.0)
				material.roughness = clampf(lerpf(material.roughness, float(profile["roughness"]), 0.30), 0.05, 1.0)
				if not mobile_mode or int(detail_budget[0]) > 0:
					material.detail_enabled = true
					material.detail_albedo = weathering
					material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
					material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
					if mobile_mode:
						detail_budget[0] = int(detail_budget[0]) - 1
				if material.emission_enabled:
					material.emission = material.emission.lerp(profile["accent"], 0.42)
					material.emission_energy_multiplier = maxf(material.emission_energy_multiplier, float(profile["emission_floor"]))
				mesh_instance.set_surface_override_material(surface, material)
				changed += 1
	for child in node.get_children():
		changed += _apply_node(child, profile, weathering, mobile_mode, detail_budget)
	return changed
