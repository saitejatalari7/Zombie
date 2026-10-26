extends SceneTree
func _init():
	print("--- ROOT CHILDREN ---")
	for c in root.get_children():
		print("CHILD: ", c.name, " CLASS: ", c.get_class())
	quit(0)
