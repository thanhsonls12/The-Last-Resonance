extends Node

const KINDS := ["tidal_valve", "tidal_raft", "dry_crossing", "mote", "kiro_tidal_pack", "restoration_station", "memory_echo"]
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	for kind in KINDS:
		var model := (load("res://assets/models/echo_expansion/%s.glb" % kind) as PackedScene).instantiate() as Node3D
		add_child(model)
		var triangles := 0
		for part in model.find_children("*", "MeshInstance3D", true, false):
			for surface in part.mesh.get_surface_count():
				var arrays: Array = part.mesh.surface_get_arrays(surface)
				triangles += arrays[Mesh.ARRAY_INDEX].size() / 3 if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size() / 3
		check(triangles < 8000, "Authored %s keeps a modest triangle budget" % kind)
		if kind in ["mote", "tidal_valve", "restoration_station", "memory_echo"]:
			check(model.find_child("AnimationPlayer", true, false) != null, "Authored model exports native animation")
			var expected: Array = {"mote": ["Hover", "Perch"], "tidal_valve": ["ValveTurn"], "restoration_station": ["Restore"], "memory_echo": ["Resonate"]}[kind]
			var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			for clip in expected:
				check(player.has_animation(clip), "Blender exports clip %s" % clip)
		model.free()
	var record := GameState.echo_chamber.duplicate(true)
	GameState.echo_chamber = {"tidal_unlocked": true, "tidal_equipped": true, "memory": true}
	var hub := (load("res://scenes/game/restoration_station.tscn") as PackedScene).instantiate()
	hub.persist_changes = false
	add_child(hub)
	await get_tree().process_frame
	check(hub.board._actors._tidal_attachment is BoneAttachment3D, "Armor follows Kiro torso bone")
	check(hub.board.drone.get_node_or_null("MoteModel") != null, "Companion uses Blender Mote")
	hub.board.drone._last_target = hub.board.player_node.global_position
	hub.board.drone._process_follow(3.5)
	check(hub.board.drone._perched, "Mote perches after Kiro rests")
	hub.board.drone.set_hint_focus(Vector3(2, 0, 2), true)
	check(not hub.board.drone._perched and hub.board.drone._mode == &"hint", "Hint unfolds wings and guides Mote to the marked cell")
	hub.board.drone.set_hint_focus(Vector3.ZERO, false)
	hub.show_memory()
	check(hub.info.text.contains("Người giữ van"), "Restoration station reads earned memory")
	await hub.restore_kiro()
	check(not hub._busy and hub.board.player_node.position.is_equal_approx(hub.board.player_target(Vector3i(3, 0, 4), {})), "Restoration returns Kiro to his resting position")
	hub.call_mote()
	hub.board.drone._process_celebrate(3.0)
	check(hub.board.drone._mode == &"follow", "Mote celebration finishes and returns to follow")
	hub.free()
	GameState.echo_chamber = record
	print("Echo expansion checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
