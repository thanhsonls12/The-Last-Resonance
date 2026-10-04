extends RefCounted

var board: BoardView
var raft: Node3D
var crossing: Node3D
var memory: Node3D
var wheel: Node3D
var water_nodes: Array[Node3D] = []
var valve_animation: AnimationPlayer


func _model(kind: String, parent: Node3D, position: Vector3) -> Node3D:
	var model := (load("res://assets/models/echo_expansion/%s.glb" % kind) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * .5
	model.position = position
	parent.add_child(model)
	return model


func build(target: BoardView, data: LevelData) -> void:
	board = target
	water_nodes.clear()
	for i in data.decorations.size():
		if bool(data.decorations[i].get("water_gap", false)):
			water_nodes.append(board.decor_nodes[i])
	raft = Node3D.new()
	raft.name = "TidalRaft"
	board.add_child(raft)
	_model("tidal_raft", raft, Vector3.ZERO)
	crossing = Node3D.new()
	crossing.name = "LightweightCrossing"
	crossing.position = Vector3(4, .15, 5)
	board.add_child(crossing)
	_model("dry_crossing", crossing, Vector3.ZERO)
	wheel = _model("tidal_valve", board, Vector3(3, .60, 6))
	valve_animation = wheel.find_child("AnimationPlayer", true, false) as AnimationPlayer
	memory = _model("memory_echo", board, Vector3(7, .154, 3))
	var memory_animation := memory.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if memory_animation and not GameState.reduced_motion:
		memory_animation.get_animation("Resonate").loop_mode = Animation.LOOP_LINEAR
		memory_animation.play("Resonate")
	for info in [[Vector3(3, 1.35, 6), "VAN NƯỚC"], [Vector3(3, .65, 2), "BẾN TRÁI"], [Vector3(4, .55, 5), "ĐƯỜNG CẠN"]]:
		var label := Label3D.new()
		label.position = info[0]
		label.text = info[1]
		label.font_size = 22
		label.pixel_size = .006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.modulate = Color(.65, .88, .81)
		board.add_child(label)


func sync(trial, animated := false) -> Tween:
	crossing.visible = not trial.high_water
	memory.visible = not trial.memory_collected
	var raft_target := Vector3(5 if trial.high_water else 3, .30 if trial.high_water else .15, 2)
	var duration := .01 if GameState.reduced_motion or not animated else .8
	var tween := board.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(raft, "position", raft_target, duration)
	for water in water_nodes:
		tween.tween_property(water, "position:y", .10 if trial.high_water else -.13, duration)
	if board.void_environment:
		var basin := board.void_environment.get_node("SanctuaryWaterBasin") as Node3D
		tween.tween_property(basin, "position:y", -.94 if trial.high_water else -1.48, duration)
	if animated:
		if valve_animation:
			valve_animation.speed_scale = 1.0 / duration
			if trial.high_water:
				valve_animation.play("ValveTurn")
			else:
				valve_animation.play_backwards("ValveTurn")
	for cell in board.block_nodes:
		var lift := .18 if trial.high_water and cell == Vector3i(5, 0, 2) else 0.0
		tween.tween_property(board.block_nodes[cell], "position", board.world_position(cell) + Vector3(0, .45 + lift, 0), duration)
	return tween
