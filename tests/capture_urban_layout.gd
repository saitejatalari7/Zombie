extends SceneTree

func _init() -> void:
	print("[Capture] Starting visual capture of Godot 3-Street Urban Layout Diorama (Portrait)...")
	var scene: PackedScene = load("res://scenes/sectors/sector_urban_layout.tscn")
	if not scene:
		printerr("Failed to load res://scenes/sectors/sector_urban_layout.tscn")
		quit(1)
		return
		
	var root_node: Node3D = scene.instantiate() as Node3D
	root.add_child(root_node)
	
	for i in range(5):
		await process_frame
		
	# Force portrait mode
	var om = root.get_node_or_null("/root/OrientationManager")
	if om:
		om.set_portrait()
	else:
		DisplayServer.window_set_size(Vector2i(540, 960))
		root.size = Vector2i(1080, 1920)
		
	for i in range(5):
		await process_frame
		
	var cam: Camera3D = root_node.get_node_or_null("LayoutCamera") as Camera3D
	if cam:
		cam.current = true
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 30.0
		# Align camera directly down the street canyon looking toward the stairs and T-junction
		cam.look_at_from_position(Vector3(-18.0, 26.0, -32.0), Vector3(1.5, 3.0, -8.0), Vector3.UP)
		
	for i in range(30):
		await process_frame
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_urban_layout_portrait.png")
		print("[Capture] Successfully saved capture_urban_layout_portrait.png! Size: ", img.get_size())
	else:
		printerr("[Capture] Failed to get viewport image!")
		
	quit(0)
