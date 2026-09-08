class_name ScoreRules
extends RefCounted


static func thresholds(par_moves: int, difficulty: int, three_star_override := 0, two_star_override := 0) -> Dictionary:
	if par_moves <= 0:
		return {"three_star_max": 0, "two_star_max": 0}
	var three_multiplier := 1.20
	var two_multiplier := 1.50
	if difficulty == 3:
		three_multiplier = 1.35
		two_multiplier = 1.75
	elif difficulty >= 4:
		three_multiplier = 1.50
		two_multiplier = 2.00
	var three_star_max := int(floor(par_moves * three_multiplier))
	var two_star_max := int(floor(par_moves * two_multiplier))
	if three_star_override > 0:
		three_star_max = three_star_override
	if two_star_override > 0:
		two_star_max = two_star_override
	three_star_max = maxi(par_moves, three_star_max)
	two_star_max = maxi(three_star_max, two_star_max)
	return {"three_star_max": three_star_max, "two_star_max": two_star_max}


static func evaluate_run(actual_moves: int, hint_penalty: int, level: LevelData) -> Dictionary:
	var limits := thresholds(
		level.par_moves, level.difficulty,
		level.three_star_moves_override, level.two_star_moves_override)
	var score_moves := maxi(0, actual_moves) + maxi(0, hint_penalty)
	var stars := 1
	if level.par_moves > 0 and score_moves <= int(limits.three_star_max):
		stars = 3
	elif level.par_moves > 0 and score_moves <= int(limits.two_star_max):
		stars = 2
	return {
		"actual_moves": maxi(0, actual_moves),
		"hint_penalty": maxi(0, hint_penalty),
		"score_moves": score_moves,
		"stars": stars,
		"perfect": level.par_moves > 0 and actual_moves <= level.par_moves and hint_penalty == 0,
		"par_moves": level.par_moves,
		"difficulty": level.difficulty,
		"three_star_max": int(limits.three_star_max),
		"two_star_max": int(limits.two_star_max),
	}


static func is_better_run(candidate: Dictionary, current: Dictionary) -> bool:
	if current.is_empty():
		return true
	var candidate_rank := [
		-int(candidate.get("stars", 0)),
		-int(bool(candidate.get("perfect", false))),
		int(candidate.get("score_moves", 0)),
		int(candidate.get("actual_moves", 0)),
		int(candidate.get("hint_penalty", 0)),
		int(candidate.get("pushes", 0)),
	]
	var current_rank := [
		-int(current.get("stars", 0)),
		-int(bool(current.get("perfect", false))),
		int(current.get("score_moves", 0)),
		int(current.get("actual_moves", 0)),
		int(current.get("hint_penalty", 0)),
		int(current.get("pushes", 0)),
	]
	for i in candidate_rank.size():
		if candidate_rank[i] != current_rank[i]:
			return candidate_rank[i] < current_rank[i]
	return false
