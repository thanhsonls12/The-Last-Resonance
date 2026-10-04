extends Node

const EXTERIOR = preload("res://src/view/sector_exterior.gd")
const QUALITY = preload("res://src/data/render_quality.gd")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	for mobile in [false, true]:
		QUALITY.set_mobile_override(mobile)
		for chapter in range(1, 5):
			var exterior := EXTERIOR.new()
			add_child(exterior)
			exterior.build({"min_x": 0, "max_x": 8, "min_z": 0, "max_z": 6}, chapter)
			var batches := 0
			var pieces := 0
			for child in exterior.get_children():
				check(child is GeometryInstance3D, "Exterior contains only batched scenery")
				if child is MultiMeshInstance3D:
					batches += 1
					pieces += child.multimesh.instance_count
					var bounds: AABB = child.multimesh.custom_aabb
					check(bounds.end.y < 0, "Chapter %d exterior stays below gameplay at every camera angle" % chapter)
					check(bounds.size.x < 30 and bounds.size.y < 6 and bounds.size.z < 30, "Rotated beams and pipes retain compact bounds")
			check(batches == 6 and exterior.get_child_count() <= 8, "Exterior keeps six batches and at most two reactor rings")
			check(pieces > 80, "Exterior retains support and maintenance detail on both quality profiles")
			var water := exterior.get_node_or_null("SanctuaryWaterBasin") as MeshInstance3D
			check((water != null) == (chapter == 3), "Only Sanctuary receives a water basin")
			if water:
				check(water.position.y < -1.0, "Water stays below floor and maintenance walk")
				check(water.mesh is PlaneMesh and water.material_override is ShaderMaterial, "Water uses a wave surface, not a flat colored box")
				var reduced_before := GameState.reduced_motion
				GameState.reduced_motion = false
				exterior._process(.5)
				var time_before: float = water.material_override.get_shader_parameter("water_time")
				check(time_before > 0.0, "Water animation advances")
				GameState.reduced_motion = true
				exterior._process(.5)
				check(is_equal_approx(time_before, water.material_override.get_shader_parameter("water_time")), "Reduced Motion freezes basin waves")
				GameState.reduced_motion = reduced_before
			var original_position: Vector3 = exterior.position
			exterior.resonate()
			exterior._process(.5)
			check(exterior.position == original_position, "Resonance does not move scenery over the puzzle")
			exterior.free()
	QUALITY.set_mobile_override(null)
	print("Sector exterior checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
