extends SceneTree

const EXPECTED := {
	8: {
		"pass": "D1",
		"chapter": 3,
		"par": 46,
		"dressing": {
			# Later visual-polish pass moves the two low identity props inward so they
			# replace repeated pillars instead of adding more perimeter clutter.
			"sanctuary_broken_plinth_low": Vector3i(4, 0, 3),
			"sanctuary_bank_root": Vector3i(4, 0, 5),
		},
	},
	9: {
		"pass": "D1",
		"chapter": 3,
		"par": 42,
		"dressing": {
			"sanctuary_broken_plinth_low": Vector3i(8, 0, 2),
			"sanctuary_bank_root": Vector3i(10, 0, 5),
		},
	},
	11: {
		"pass": "D1",
		"chapter": 3,
		"par": 85,
		"dressing": {
			"archive_access_panel_broken": Vector3i(3, 1, 0),
			"archive_storage_tray_low": Vector3i(5, 1, 0),
			"sanctuary_bank_root": Vector3i(8, 1, 4),
		},
	},
	12: {
		"pass": "D2",
		"chapter": 4,
		"par": 40,
		"dressing": {
			"core_data_cabinet_low": Vector3i(3, 0, 0),
			"core_light_trim": Vector3i(5, 0, 0),
			"kit_wall_low_straight": Vector3i(4, 0, 7),
		},
	},
	14: {
		"pass": "D2",
		"chapter": 4,
		"par": 81,
		"dressing": {
			"core_data_cabinet_low": Vector3i(5, 0, 3),
			"core_light_trim": Vector3i(6, 0, 3),
		},
	},
	4: {
		"pass": "D3",
		"chapter": 2,
		"par": 57,
		"dressing": {
			"foundry_press": Vector3i(8, 0, 0),
			"foundry_pipe_support": Vector3i(4, 0, 1),
			"kit_wall_low_straight": Vector3i(7, 0, 7),
		},
	},
	6: {
		"pass": "D3",
		"chapter": 2,
		"par": 75,
		"dressing": {
			"foundry_gear": Vector3i(2, 0, 0),
			"foundry_pipe_valve": Vector3i(8, 0, 3),
			"kit_wall_low_straight": Vector3i(5, 0, 7),
		},
	},
	7: {
		"pass": "D3",
		"chapter": 2,
		"par": 87,
		"dressing": {
			"foundry_furnace": Vector3i(4, 0, 0),
			"foundry_pipe_valve": Vector3i(9, 0, 4),
			"kit_wall_low_straight": Vector3i(5, 0, 8),
		},
	},
	0: {
		"pass": "D4",
		"chapter": 1,
		"par": 12,
		"dressing": {
			"archive_access_panel_broken": Vector3i(4, 0, 2),
			"archive_storage_tray_low": Vector3i(7, 0, 5),
		},
	},
	2: {
		"pass": "D4",
		"chapter": 1,
		"par": 34,
		"dressing": {
			"archive_access_panel_broken": Vector3i(5, 0, 0),
			"archive_storage_tray_low": Vector3i(2, 0, 6),
		},
	},
	3: {
		"pass": "D4",
		"chapter": 1,
		"par": 53,
		"dressing": {
			"archive_access_panel_broken": Vector3i(4, 0, 1),
		},
	},
}

var failures := 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)


func _initialize() -> void:
	for level_index in EXPECTED:
		var spec: Dictionary = EXPECTED[level_index]
		var data: LevelData = Levels.get_data(level_index)
		check(data != null, "Level %d loads" % (level_index + 1))
		if data == null:
			continue
		check(data.chapter == int(spec.chapter), "Level %d stays in Chapter %d" % [level_index + 1, int(spec.chapter)])
		check(data.par_moves == int(spec.par), "Level %d keeps its verified par" % (level_index + 1))
		var logic := GameLogic.new()
		logic.load_level(data)
		for kind in (spec.dressing as Dictionary):
			var expected_position: Vector3i = spec.dressing[kind]
			var matches := []
			for deco in data.decorations:
				if deco is Dictionary and str(deco.get("type", "")) == str(kind):
					matches.append(deco)
			var pass_name := str(spec.pass)
			check(matches.size() == 1, "Level %d contains exactly one %s %s" % [level_index + 1, pass_name, kind])
			if matches.size() == 1:
				var actual: Variant = matches[0].get("grid_position", null)
				check(actual == expected_position, "Level %d %s stays at its reviewed %s anchor" % [level_index + 1, kind, pass_name])
			check(logic.walls.has(expected_position), "Level %d %s only replaces an authoritative wall visual" % [level_index + 1, kind])

	# L12 is deliberately a hybrid ruin/research space: the old K-7 lab frames
	# Elias while Sanctuary growth reclaims the room. Keep this exception explicit.
	var level12: LevelData = Levels.get_data(11)
	check(level12.sequential_floors and level12.maps.size() == 2, "Level 12 remains a two-floor sequential finale")
	check(level12.landmark == "elias_testament", "Level 12 keeps Elias Testament as its landmark")

	# L14 is the Chapter IV representative level. D2 intentionally leaves its
	# established composition untouched while extending the visual language to
	# L13 and only lightly dressing L15.
	var level14: LevelData = Levels.get_data(13)
	check(level14.sequential_floors and level14.maps.size() == 2, "Level 14 remains the two-floor Chapter IV representative")
	check(level14.landmark == "eva_conduit", "Level 14 keeps EVA Conduit as its landmark")
	var l14_identity := {}
	for deco in level14.decorations:
		if deco is Dictionary:
			var kind := str(deco.get("type", ""))
			if kind in ["core_data_cabinet_low", "core_light_trim"]:
				l14_identity[kind] = deco.get("grid_position", null)
	check(l14_identity.get("core_data_cabinet_low") == Vector3i(3, 1, 6), "Level 14 keeps its reviewed data cabinet")
	check(l14_identity.get("core_light_trim") == Vector3i(5, 1, 6), "Level 14 keeps its reviewed light trim")

	# L6 remains the Foundry representative. A later refinement replaced the
	# furnace accent with a modular corner, so the existing machine now carries
	# the presentation-only heat profile instead of restoring removed scenery.
	var level6: LevelData = Levels.get_data(5)
	check(level6.landmark == "k_series_mold", "Level 6 keeps K-Series Mold as its landmark")
	var l6_reviewed := {}
	for deco in level6.decorations:
		if deco is Dictionary:
			var kind := str(deco.get("type", ""))
			if kind in ["machine", "foundry_pipe_support", "foundry_maintenance_box", "kit_wall_low_corner"]:
				l6_reviewed[kind] = deco.get("grid_position", null)
	check(l6_reviewed.get("machine") == Vector3i(8, 0, 7), "Level 6 keeps its reviewed machine")
	check(l6_reviewed.get("foundry_pipe_support") == Vector3i(5, 0, 1), "Level 6 keeps its reviewed pipe support")
	check(l6_reviewed.get("foundry_maintenance_box") == Vector3i(5, 0, 7), "Level 6 keeps its reviewed maintenance box")
	check(l6_reviewed.get("kit_wall_low_corner") == Vector3i(4, 0, 7), "Level 6 keeps its reviewed low-wall corner")

	# L2 remains the Archive representative. D4 is deliberately sparse because
	# Chapter I already had the highest scenery density before the dressing pass.
	var level2: LevelData = Levels.get_data(1)
	check(level2.landmark == "terminal", "Level 2 keeps Terminal as its landmark")
	var l2_identity := {}
	for deco in level2.decorations:
		if deco is Dictionary:
			var kind := str(deco.get("type", ""))
			if kind in ["archive_access_panel_broken", "archive_storage_tray_low", "kit_wall_low_straight"]:
				l2_identity[kind] = deco.get("grid_position", null)
	check(l2_identity.get("archive_access_panel_broken") == Vector3i(2, 0, 3), "Level 2 keeps its reviewed broken access panel")
	check(l2_identity.get("archive_storage_tray_low") == Vector3i(3, 0, 3), "Level 2 keeps its reviewed storage tray")
	check(l2_identity.get("kit_wall_low_straight") == Vector3i(3, 0, 5), "Level 2 keeps its reviewed low wall")

	var level1: LevelData = Levels.get_data(0)
	check(level1.decorations.size() == 29, "Level 1 D4 replacements do not increase decoration density")
	check(level1.landmark == "holo", "Level 1 keeps Holo as its first-story landmark")

	print("Campaign D1/D2/D3/D4 dressing checks: ", failures, " failures")
	quit(1 if failures else 0)
