extends Node

const QUALITY = preload("res://src/data/render_quality.gd")
var pulses: Array[Node3D] = []


func send_lock_pulse(routes: Array, parent: Node3D, active: bool) -> void:
	if GameState.reduced_motion or parent == null:
		return
	_prune_pulses()
	for route in routes:
		if pulses.size() >= (2 if QUALITY.is_mobile() else 3):
			break
		if route.size() < 2:
			continue
		var packet := Node3D.new()
		packet.name = "LockEnergyPacket"
		packet.position = route[0]
		parent.add_child(packet)
		var color := Color(.18, .95, .85) if active else Color(.90, .48, .12)
		var material := MeshFactory.mat(color, 1.7)
		MeshFactory.sphere(packet, Vector3(0, .035, 0), .055, material)
		MeshFactory.torus(packet, Vector3(0, .015, 0), .07, .10, material)
		for mesh in packet.get_children():
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pulses.append(packet)
		var tween := packet.create_tween()
		for i in range(1, route.size()):
			var distance: float = route[i-1].distance_to(route[i])
			if distance > .001:
				tween.tween_property(packet, "position", route[i], clampf(distance / 9.0, .05, .45))
		var fade := packet.create_tween()
		fade.tween_property(material, "emission_energy_multiplier", .8, .7)
		tween.tween_callback(packet.queue_free)


func start_sector(board: Node3D) -> void:
	if GameState.reduced_motion:
		return
	var origin: Vector3 = board.player_node.global_position
	for module in board.find_children("ModuleMotion", "Node3D", true, false):
		module.begin_startup(clampf(module.global_position.distance_to(origin) * .065, .05, .9))


func cancel_sector(board: Node3D) -> void:
	for module in board.find_children("ModuleMotion", "Node3D", true, false):
		module.cancel_startup()


func _prune_pulses() -> void:
	for i in range(pulses.size()-1, -1, -1):
		if not is_instance_valid(pulses[i]):
			pulses.remove_at(i)
		elif not pulses[i].is_visible_in_tree():
			pulses[i].queue_free()
			pulses.remove_at(i)


func _process(_delta: float) -> void:
	_prune_pulses()
	if GameState.reduced_motion:
		for packet in pulses:
			packet.queue_free()
		pulses.clear()
