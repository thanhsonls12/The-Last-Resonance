class_name Levels

## Catalogue and ordering only. Maps, decorations and story text live in the
## .tres resources so a level has exactly one source of truth.
const RESOURCE_LEVELS: Dictionary = {
	0: "res://resources/levels/level_01.tres",
	1: "res://resources/levels/level_02.tres",
	2: "res://resources/levels/level_03.tres",
	3: "res://resources/levels/level_04.tres",
}
const ALL: Array = [
	{"name": "Khởi động", "chapter": 1, "difficulty": 1},
	{"name": "Góc lưu trữ", "chapter": 1, "difficulty": 2},
	{"name": "Khu vực cấm", "chapter": 1, "difficulty": 3},
	{"name": "Khóa liên động", "chapter": 1, "difficulty": 4},
]


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
