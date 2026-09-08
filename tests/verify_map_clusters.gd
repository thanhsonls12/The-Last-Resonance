extends SceneTree

const CATALOG_PATH := "res://docs/MAP_CLUSTER_CATALOG.json"
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func pairs_to_cells(values: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for pair in values:
		result.append(Vector2i(int(pair[0]), int(pair[1])))
	return result


func _initialize() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	check(parsed is Array, "map-cluster catalog parses")
	if not parsed is Array:
		quit(1)
		return
	var catalog: Array = parsed
	check(catalog.size() == 4, "phase C contains exactly four reusable chapter clusters")
	var chapters := {}
	for entry in catalog:
		var spec: Dictionary = entry
		var scene_path := str(spec.scene)
		check(ResourceLoader.exists(scene_path), str(spec.id) + " scene exists")
		var packed := load(scene_path) as PackedScene
		check(packed != null, str(spec.id) + " scene loads")
		if packed == null:
			continue
		var cluster := packed.instantiate() as Node3D
		root.add_child(cluster)
		chapters[int(spec.chapter)] = true
		check(str(cluster.get_meta("cluster_id", "")) == str(spec.id), str(spec.id) + " metadata id")
		check(int(cluster.get_meta("chapter", 0)) == int(spec.chapter), str(spec.id) + " metadata chapter")
		check(str(cluster.get_meta("outward_face", "")) == str(spec.outward_face), str(spec.id) + " outward face")
		check(str(cluster.get_meta("visual_camera_review", "")) == "pending", str(spec.id) + " does not claim unperformed visual camera review")
		var footprint := Vector2i(int(spec.footprint_cells[0]), int(spec.footprint_cells[1]))
		check(cluster.get_meta("footprint_cells", Vector2i.ZERO) == footprint, str(spec.id) + " footprint metadata")
		var blocked := pairs_to_cells(spec.blocked_cells)
		var walkable := pairs_to_cells(spec.walkable_cells)
		check(not walkable.is_empty(), str(spec.id) + " records allowed walkable region")
		for cell in blocked:
			check(not walkable.has(cell), str(spec.id) + " blocked/walkable regions do not overlap")
		for cell in blocked + walkable:
			check(absi(cell.x) <= footprint.x / 2 and absi(cell.y) <= footprint.y / 2, str(spec.id) + " metadata cell stays inside footprint")
		# South is the default road-facing edge for all four phase-C clusters.
		for x in range(-1, 2):
			check(walkable.has(Vector2i(x, 1)), str(spec.id) + " keeps the south-facing approach clear")
		var components := cluster.get_node_or_null("Components") as Node3D
		check(components != null, str(spec.id) + " has editable Components node")
		if components != null:
			check(components.get_child_count() >= 3 and components.get_child_count() <= 5, str(spec.id) + " contains one main prop plus 2-4 details")
			check(components.get_child_count() == (spec.components as Array).size(), str(spec.id) + " catalog matches scene components")
			for child in components.get_children():
				var node := child as Node3D
				check(node != null and not node.scene_file_path.is_empty(), str(spec.id) + " components remain editable scene instances")
		check(cluster.find_children("*", "CollisionObject3D", true, false).is_empty(), str(spec.id) + " cluster introduces no gameplay collision")
		var bounds_size: Array = spec.measured_bounds_size
		check(float(bounds_size[0]) <= float(footprint.x) + 0.02, str(spec.id) + " measured X fits declared footprint")
		check(float(bounds_size[2]) <= float(footprint.y) + 0.02, str(spec.id) + " measured Z fits declared footprint")
		var yaw_values := []
		for yaw in (spec.geometry_checked_yaws as Array):
			yaw_values.append(int(yaw))
		check(yaw_values == [0, 90, 180, 270], str(spec.id) + " records four geometry-checked yaw orientations")
		cluster.free()
	check(chapters.size() == 4, "phase C covers all four chapters")
	check(ResourceLoader.exists("res://scenes/editor/map_cluster_gallery.tscn"), "map-cluster gallery exists")
	print("Map cluster checks: ", failures, " failures")
	quit(1 if failures else 0)
