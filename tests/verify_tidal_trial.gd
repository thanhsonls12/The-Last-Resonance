extends Node

const TRIAL = preload("res://src/core/tidal_trial.gd")
const SCENE = preload("res://scenes/game/tidal_trial.tscn")
const DIRECTIONS := {"U": Vector3i.FORWARD, "D": Vector3i.BACK, "L": Vector3i.LEFT, "R": Vector3i.RIGHT}
const ROUTE := "DRDDDRVVRRRRUULLU"
var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _ready() -> void:
	var store = preload("res://src/core/progress_store.gd")
	var save_path := "user://qa_tidal_trial_progress.json"
	var saved := {"version": 4, "unlocked": 1, "levels": {}, "echo_chamber": {"completed": true, "memory": true, "tidal_unlocked": true, "tidal_equipped": false}}
	check(store.write_progress(save_path, saved) == OK, "Trial reward uses the existing atomic progress writer")
	check(store.load_progress(save_path).echo_chamber == saved.echo_chamber, "Reward and cosmetic preference survive reload")
	saved.echo_chamber.tidal_equipped = "invalid"
	check(store.write_progress(save_path, saved) == ERR_FILE_CORRUPT, "Invalid reward data cannot replace a valid save")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(save_path + suffix)
	var trial := TRIAL.new()
	check(not trial.toggle_valve(), "Valve requires adjacent access")
	for action in ROUTE:
		if action == "V":
			check(trial.toggle_valve(), "Verified route operates the valve")
		else:
			check(not trial.move(DIRECTIONS[action]).is_empty(), "Verified route moves/pushes legally")
	check(trial.solved() and trial.memory_collected and trial.transported, "Route solves floating-core puzzle and optional memory")
	check(trial.undo() and not trial.solved(), "Undo restores the core before goal")
	while trial.undo():
		pass
	check(trial.logic.player == Vector3i(1,0,1) and not trial.high_water and not trial.memory_collected and not trial.transported, "Undo restores the entire water/memory history")
	trial.logic.player = Vector3i(2,0,5)
	trial.logic.blocks = {Vector3i(3,0,5): true}
	check(trial.move(Vector3i.RIGHT).is_empty(), "Lightweight crossing rejects a heavy core")
	trial.reset()
	trial.logic.player = Vector3i(3,0,5)
	trial.logic.blocks = {TRIAL.LEFT_DOCK: true}
	check(trial.toggle_valve() and trial.logic.blocks.has(TRIAL.RIGHT_DOCK), "Raising water transports core between docks")
	check(trial.logic.walls.has(TRIAL.CROSSING), "High water closes the dry crossing")
	check(trial.undo() and trial.logic.blocks.has(TRIAL.LEFT_DOCK) and not trial.logic.walls.has(TRIAL.CROSSING), "Undo reverses raft transport and flooded terrain")
	var campaign_before := GameState.current_level
	var records_before := GameState.level_records.duplicate(true)
	var reward_before := GameState.echo_chamber.duplicate(true)
	var game := SCENE.instantiate()
	game.persist_rewards = false
	add_child(game)
	for _frame in range(4):
		await get_tree().process_frame
	check(game.board.decor_nodes.size() == TRIAL.DATA.decorations.size(), "Trial dressing builds completely")
	for action in ROUTE:
		if action == "V":
			await game.valve()
		else:
			await game.move(DIRECTIONS[action])
		if game.hud.memory_panel.visible:
			game.hud.memory_panel.hide()
	check(game.trial.solved() and game.trial.memory_collected, "Playable scene solves through actual input actions")
	check(game.board.block_nodes.has(Vector3i(5,0,1)), "Rendered core follows raft and final push")
	check(GameState.current_level == campaign_before and GameState.level_records == records_before and GameState.echo_chamber == reward_before, "Trial QA does not change campaign progress or real rewards")
	game.free()
	print("Tidal trial checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
