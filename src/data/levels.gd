class_name Levels

## Catalogue and ordering only. Maps, decorations and story text live in the
## .tres resources so a level has exactly one source of truth.
const RESOURCE_LEVELS: Dictionary = {
	0: "res://resources/levels/level_01.tres",
	1: "res://resources/levels/level_02.tres",
	2: "res://resources/levels/level_03.tres",
	3: "res://resources/levels/level_04.tres",
	4: "res://resources/levels/level_05.tres",
	5: "res://resources/levels/level_06.tres",
	6: "res://resources/levels/level_07.tres",
	7: "res://resources/levels/level_08.tres",
}
const ALL: Array = [
	{"name": "Khởi động", "chapter": 1, "difficulty": 1},
	{"name": "Góc lưu trữ", "chapter": 1, "difficulty": 2},
	{"name": "Khu vực cấm", "chapter": 1, "difficulty": 3},
	{"name": "Khóa liên động", "chapter": 1, "difficulty": 4},
	{"name": "Dây chuyền thức tỉnh", "chapter": 2, "difficulty": 2},
	{"name": "Khuôn đúc K-Series", "chapter": 2, "difficulty": 3},
	{"name": "Khoang niêm phong", "chapter": 2, "difficulty": 4},
	{"name": "Trái tim Foundry", "chapter": 2, "difficulty": 5},
]
const CHAPTER_FINAL_LEVELS := {1: 3, 2: 7, 3: 9}


static func get_data(index: int) -> LevelData:
	if index < 0 or index >= ALL.size():
		return null
	var res_path: String = str(RESOURCE_LEVELS.get(index, ""))
	if res_path != "" and ResourceLoader.exists(res_path):
		var loaded := load(res_path) as LevelData
		if loaded != null:
			return loaded
	push_error("Level %d has no usable resource at '%s'" % [index + 1, res_path])
	return LevelData.from_dict(index, ALL[index])


static func is_chapter_final(index: int) -> bool:
	var data := get_data(index)
	return data != null and int(CHAPTER_FINAL_LEVELS.get(data.chapter, -1)) == index


static func is_campaign_final(index: int) -> bool:
	return index == ALL.size() - 1


static func reconciled_unlocked(records: Dictionary, stored_unlocked: int) -> int:
	var result := stored_unlocked
	for i in ALL.size():
		var record: Variant = records.get(str(i), {})
		if record is Dictionary and bool(record.get("completed", false)):
			result = maxi(result, mini(i + 2, ALL.size()))
	return clampi(result, 1, maxi(1, ALL.size()))
