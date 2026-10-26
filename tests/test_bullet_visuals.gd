extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait for setup
	for i in range(8):
		await process_frame
	
	# Fire rifle
	var player: Node3D = root.get_node("Main/Player")
	if player and player.has_method("fire_rifle"):
		player.fire_rifle()
	
	# Advance 4 frames to capture bullets mid-flight and shell casings in air
	for i in range(4):
		await process_frame
	
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://test_bullet_render.png")
		print("Saved test_bullet_render.png successfully!")
	
	quit()
