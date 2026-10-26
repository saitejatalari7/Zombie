extends SceneTree

func _init() -> void:
	var sec_scene: PackedScene = load("res://scenes/sectors/sector_1_residential.tscn")
	var node = sec_scene.instantiate()
	var counts := {}
	_analyze(node, counts)
	print("--- Sector 1 Node Type Breakdown ---")
	for k in counts.keys():
		print("  %-25s : %d" % [k, counts[k]])
	print("Total nodes: ", counts["_total"])
	quit(0)

func _analyze(n: Node, counts: Dictionary) -> void:
	var cls = n.get_class()
	counts[cls] = counts.get(cls, 0) + 1
	counts["_total"] = counts.get("_total", 0) + 1
	for ch in n.get_children():
		_analyze(ch, counts)
