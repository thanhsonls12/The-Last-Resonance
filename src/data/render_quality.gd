class_name RenderQuality
extends RefCounted

## Centralized runtime tier for mobile rendering. Gameplay geometry and puzzle
## state are never removed; only background effects and expensive light paths are
## reduced on mobile hardware.
static var _mobile_override: Variant = null


static func set_mobile_override(value: Variant) -> void:
	_mobile_override = value


static func is_mobile() -> bool:
	if _mobile_override != null:
		return bool(_mobile_override)
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


static func background_fx_enabled() -> bool:
	return not is_mobile()


static func local_lights_enabled() -> bool:
	return not is_mobile()


static func mobile_color_pools_enabled() -> bool:
	return is_mobile()


static func mobile_color_pool_budget() -> int:
	return 3 if is_mobile() else 0


static func shadows_enabled() -> bool:
	return not is_mobile()


static func glow_enabled() -> bool:
	return not is_mobile()


static func ambient_boost() -> float:
	return 1.16 if is_mobile() else 1.0


static func key_boost() -> float:
	return 1.04 if is_mobile() else 1.0


static func fill_boost() -> float:
	return 1.18 if is_mobile() else 1.0


static func wash_boost() -> float:
	return 1.12 if is_mobile() else 1.0


static func tonemap_exposure() -> float:
	return 1.10 if is_mobile() else 1.05


static func particle_amount(amount: int) -> int:
	if not is_mobile():
		return amount
	return maxi(2, ceili(float(amount) * 0.42))


## Environment dynamics are deliberately retained on mobile, but transform
## amplitudes are reduced so the presentation stays alive without adding more
## particles/lights or creating distracting motion on a small screen.
static func environment_motion_scale() -> float:
	return 0.62 if is_mobile() else 1.0


static func environment_emission_scale() -> float:
	return 0.72 if is_mobile() else 1.0


static func ring_segments() -> int:
	return 8 if is_mobile() else 12


static func ring_rings() -> int:
	return 18 if is_mobile() else 32
