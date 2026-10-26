extends SceneTree

func _init() -> void:
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var root_node: Node = menu_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(10):
		await process_frame
	
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://test_menu_render.png")
		print("Saved test_menu_render.png successfully! Size: ", img.get_size())
	
	quit()
