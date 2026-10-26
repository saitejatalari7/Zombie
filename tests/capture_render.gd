extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait 12 frames for spawner, blood decals, and camera to fully settle
	for i in range(12):
		await process_frame
	
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://test_render.png")
		print("Saved test_render.png successfully! Size: ", img.get_size())
	else:
		print("Failed to get image from viewport")
	
	quit()
