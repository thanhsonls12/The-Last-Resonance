extends SceneTree

const PROFILES = preload("res://src/data/chapter_material_profiles.gd")
const SAMPLE = preload("res://assets/models/baked/Foundry-Furnace.glb")
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func material_snapshot(root: Node) -> Array:
	var result: Array = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh:
			var mesh_instance := node as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface)
				if material is StandardMaterial3D:
					var standard := material as StandardMaterial3D
					result.append({"resource": standard, "albedo": standard.albedo_color, "metallic": standard.metallic, "roughness": standard.roughness})
		for child in node.get_children():
			stack.append(child)
	return result


func detail_count(snapshot: Array) -> int:
	var count := 0
	for item in snapshot:
		if item.resource.detail_enabled and item.resource.detail_albedo != null:
			count += 1
	return count


func _initialize() -> void:
	check(PROFILES.PROFILES.size() == 4, "four chapter profiles")
	var baseline := SAMPLE.instantiate() as Node3D
	var baseline_materials := material_snapshot(baseline)
	check(not baseline_materials.is_empty(), "sample contains StandardMaterial3D")
	for chapter in range(1, 5):
		var instance := SAMPLE.instantiate() as Node3D
		var changed := PROFILES.apply(instance, chapter)
		check(changed == baseline_materials.size(), "all sample surfaces receive chapter %d profile" % chapter)
		var tinted := material_snapshot(instance)
		var different := false
		for i in tinted.size():
			if not tinted[i].albedo.is_equal_approx(baseline_materials[i].albedo) or not is_equal_approx(tinted[i].roughness, baseline_materials[i].roughness):
				different = true
		check(different, "chapter %d changes the visual material" % chapter)
		for item in tinted:
			check(item.resource != baseline_materials[0].resource, "chapter %d duplicates source materials" % chapter)
			check(item.resource.detail_enabled and item.resource.detail_albedo != null, "chapter %d adds weathering detail" % chapter)
		instance.free()
	var mobile_instance := SAMPLE.instantiate() as Node3D
	var mobile_changed := PROFILES.apply(mobile_instance, 2, true)
	var mobile_snapshot := material_snapshot(mobile_instance)
	check(mobile_changed == baseline_materials.size(), "mobile profile still updates every source surface")
	check(detail_count(mobile_snapshot) <= int(PROFILES.PROFILES[2]["mobile_surface_limit"]), "mobile weathering respects per-model surface budget")
	for item in mobile_snapshot:
		if item.resource.detail_enabled:
			check(item.resource.detail_albedo.get_width() == PROFILES.MOBILE_WEATHERING_SIZE, "mobile weathering uses compact texture")
	mobile_instance.free()
	baseline.free()
	print("Material profile checks: ", failures, " failures")
	quit(1 if failures else 0)
