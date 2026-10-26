extends SceneTree

func _init() -> void:
	var sec_scene: PackedScene = load("res://scenes/sectors/sector_1_residential.tscn")
	var node = sec_scene.instantiate()
	var meshes := node.find_children("", "MeshInstance3D", true, false)
	var groups := {}
	for m in meshes:
		var prefix = m.name.split("_")[0]
		groups[prefix] = groups.get(prefix, 0) + 1
	print("--- Mesh Name Prefix Breakdown (Total %d) ---" % meshes.size())
	for k in groups.keys():
		print("  %-25s : %d" % [k, groups[k]])
	quit(0)
