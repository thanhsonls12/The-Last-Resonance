extends Node

class AutoDialogue extends DialogueBox:
	func _ready() -> void:
		hide()
	func play_dialogue(_lines: Array) -> void:
		_finish.call_deferred()
	func _finish() -> void:
		dialogue_finished.emit()

const DIRECTIONS := {"U": Vector3i(0,0,-1), "D": Vector3i(0,0,1), "L": Vector3i(-1,0,0), "R": Vector3i(1,0,0)}
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	for index in [1, 13]:
		var data := Levels.get_data(index)
		var logic := GameLogic.new()
		logic.load_level(data)
		var board := BoardView.new()
		add_child(board)
		board.chapter = data.chapter
		var dialogue := AutoDialogue.new()
		add_child(dialogue)
		var director := StoryDirector.new()
		director.setup(dialogue, board, null, func(): return logic.player)
		var events: Array[String] = []
		director.story_event_played.connect(func(key: String): events.append(key))
		for action in data.hint_route:
			var result := logic.try_move(DIRECTIONS[action])
			check(not result.is_empty(), "story route accepts " + action)
			await director.play_post_step_story(index, data.decorations, result, logic.player)
			# Calling the same beat twice must not duplicate its dialogue.
			await director.play_post_step_story(index, data.decorations, result, logic.player)
		check(logic.won, "story route completes level " + str(index + 1))
		var expected: Array = ["level_2_mara_terminal"] if index == 1 else ["level_14_eva_node_1", "level_14_eva_node_2", "level_14_eva_node_3", "level_14_eva_node_4"]
		check(events == expected, "story beats reachable once, in order: " + str(events))
		board.queue_free()
		dialogue.queue_free()
		await get_tree().process_frame
	print("Narrative events: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
