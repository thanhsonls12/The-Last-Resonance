extends Node3D

const TRIAL = preload("res://src/core/tidal_trial.gd")
const VIEW = preload("res://src/view/tidal_trial_view.gd")
const HUD = preload("res://src/ui/tidal_trial_hud.gd")
@export var persist_rewards := true
var trial = TRIAL.new()
var board := BoardView.new()
var view = VIEW.new()
var hud = HUD.new()
var camera := EchoCameraController.new()
var audio := EchoAudioManager.new()
var busy := false
var _reward_state := -1


func _ready() -> void:
	var environment := SceneEnvironmentController.new()
	add_child(environment)
	environment.apply_chapter(3, .22)
	add_child(board)
	add_child(camera)
	camera.setup()
	add_child(audio)
	audio.set_ambience_for_chapter(3)
	audio.set_bgm_for_chapter(3)
	add_child(hud)
	hud.build({"move": move, "valve": valve, "undo": undo, "restart": restart, "back": back, "cosmetic": toggle_cosmetic})
	rebuild()


func rebuild() -> void:
	board.chapter = 3
	board.power_level = .22
	board.build(trial.logic, TRIAL.DATA.decorations)
	view.build(board, TRIAL.DATA)
	view.sync(trial)
	camera.focus_cells(trial.logic.floors, 0, false)
	hud.update(trial, busy)


func _unhandled_input(event: InputEvent) -> void:
	if hud.memory_panel.visible:
		return
	for action in {"move_left": Vector3i.LEFT, "move_right": Vector3i.RIGHT, "move_up": Vector3i.FORWARD, "move_down": Vector3i.BACK}:
		if event.is_action_pressed(action):
			move({"move_left": Vector3i.LEFT, "move_right": Vector3i.RIGHT, "move_up": Vector3i.FORWARD, "move_down": Vector3i.BACK}[action])
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		var arrows := {KEY_LEFT: Vector3i.LEFT, KEY_RIGHT: Vector3i.RIGHT, KEY_UP: Vector3i.FORWARD, KEY_DOWN: Vector3i.BACK}
		if arrows.has(event.keycode):
			move(arrows[event.keycode])
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_E:
			valve()
		elif event.keycode == KEY_Z:
			undo()
		elif event.keycode == KEY_ESCAPE:
			back()


func move(direction: Vector3i) -> void:
	if busy:
		return
	var had_memory: bool = trial.memory_collected
	var result: Dictionary = trial.move(direction)
	if result.is_empty():
		hud.update(trial, false)
		return
	busy = true
	hud.update(trial, true)
	board.face_player(direction)
	board.play_player_animation(&"Push" if result.pushed else &"Walk")
	board.play_step_weight(result.pushed, .18)
	audio.play_move()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(board.player_node, "position", board.player_target(trial.logic.player, trial.logic.blocks), .18)
	if result.pushed:
		var core: Node3D = board.block_nodes[result.pushed_from]
		board.block_nodes.erase(result.pushed_from)
		board.block_nodes[result.pushed_to] = core
		tween.tween_property(core, "position", board.world_position(result.pushed_to) + Vector3(0,.45,0), .18)
		audio.play_push()
	await tween.finished
	board.play_player_animation(&"Idle")
	board.void_environment.react_to_step(board.world_position(trial.logic.player))
	view.memory.visible = not trial.memory_collected
	busy = false
	_commit_reward()
	hud.update(trial, false)
	if trial.memory_collected and not had_memory:
		audio.play_interact()
		hud.memory_panel.popup_centered(Vector2i(600, 220))


func valve() -> void:
	if busy:
		return
	var had_core: bool = trial.logic.blocks.has(TRIAL.LEFT_DOCK)
	if not trial.toggle_valve():
		hud.update(trial, false)
		return
	busy = true
	hud.update(trial, true)
	audio.play_switch(trial.high_water)
	board.play_player_animation(&"Interact")
	if had_core and trial.high_water:
		var core: Node3D = board.block_nodes[TRIAL.LEFT_DOCK]
		board.block_nodes.erase(TRIAL.LEFT_DOCK)
		board.block_nodes[TRIAL.RIGHT_DOCK] = core
	await view.sync(trial, true).finished
	board.play_player_animation(&"Idle")
	busy = false
	hud.update(trial, false)


func undo() -> void:
	if not busy and trial.undo():
		audio.play_undo()
		rebuild()


func restart() -> void:
	if busy:
		return
	trial.reset()
	_reward_state = -1
	rebuild()


func _commit_reward() -> void:
	if not trial.solved():
		return
	var state := 1 if trial.memory_collected else 0
	if state == _reward_state:
		return
	_reward_state = state
	if persist_rewards:
		GameState.complete_tidal_trial(trial.memory_collected)
	board.set_sector_powered(true)
	audio.play_goal_lock()
	if trial.memory_collected:
		board.set_kiro_powered(true, true)


func toggle_cosmetic() -> void:
	GameState.equip_tidal_cosmetic(not bool(GameState.echo_chamber.get("tidal_equipped", false)))
	board.set_kiro_powered(true, true)
	hud.update(trial, busy)


func back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")
