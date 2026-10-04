extends Node

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	for index in [4, 6, 10, 11, 13]:
		var data: LevelData = Levels.get_data(index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var board := BoardView.new()
		board.chapter = data.chapter
		add_child(board)
		board.build(logic, data.decorations)
		for cell in board.door_nodes:
			var model := board.door_nodes[cell].get_node("DoorModel") as Node3D
			check(model.scene_file_path == "res://assets/models/baked/Door.glb", "door GLB active")
			check(model.find_child("Door_Panel", true, false) != null, "moving panel retained")
			check(model.find_child("Door_TopBeam", true, false) == null, "frame detached from moving panel")
		for cell in board.bridge_nodes:
			check(board.bridge_nodes[cell].get_node("BridgeModel").scene_file_path == "res://assets/models/baked/Bridge.glb", "bridge GLB active")
			check(board.bridge_rail_nodes[cell].get_child_count() == 4, "authored rails bound to retract root")
		for cell in board.elevator_nodes:
			check(board.elevator_nodes[cell].get_node("ElevatorModel").scene_file_path == "res://assets/models/baked/Elevator.glb", "elevator GLB active")
		check(logic.moves == 0, "presentation keeps puzzle state")
		board.free()
	print("Authored mechanism checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
