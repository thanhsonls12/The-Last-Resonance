extends SceneTree

func _initialize() -> void:
	var path := "res://resources/mesh_libraries/echo_mesh_library.tres"
	var original_uid := ResourceLoader.get_resource_uid(path)
	var library := load(path) as MeshLibrary
	assert(library != null)
	var previous := {}
	for id in library.get_item_list():
		previous[id] = library.get_item_name(id)
	preload("res://src/data/chapter_props.gd").add_to_library(library)
	preload("res://src/data/modular_props.gd").add_to_library(library)
	for id in previous:
		assert(library.get_item_name(id) == previous[id], "Existing item ID changed")
	var error := ResourceSaver.save(library, path)
	assert(error == OK)
	if original_uid != ResourceUID.INVALID_ID:
		assert(ResourceSaver.set_uid(path, original_uid) == OK)
	print("Chapter props installed; existing item IDs preserved. Items: ", library.get_item_list().size())
	quit()
