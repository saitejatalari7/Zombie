extends SceneTree

func _init() -> void:
	print("[Capture] Starting visual capture of Sectors & Gameplay...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait for assets and shaders to settle
	for i in range(15):
		await process_frame
	
	# 1. Capture Sector 1 (Residential)
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_sector1_residential.png")
		print("Saved capture_sector1_residential.png Size: ", img.get_size())
	
	# 2. Switch to Sector 3 (Blackout Industrial)
	var gm = root.get_node_or_null("/root/GameManager")
	if gm:
		gm.current_sector = 3
	
	root_node.queue_free()
	await process_frame
	await process_frame
	
	var root_node_sec3 = main_scene.instantiate()
	root.add_child(root_node_sec3)
	
	for i in range(15):
		await process_frame
		
	var img_sec3: Image = root.get_viewport().get_texture().get_image()
	if img_sec3:
		img_sec3.save_png("res://capture_sector3_blackout.png")
		print("Saved capture_sector3_blackout.png Size: ", img_sec3.get_size())
		
	# 3. Switch to Landscape orientation
	var om = root.get_node_or_null("/root/OrientationManager")
	if om:
		om.set_landscape()
		
	for i in range(15):
		await process_frame
		
	var img_land: Image = root.get_viewport().get_texture().get_image()
	if img_land:
		img_land.save_png("res://capture_gameplay_landscape.png")
		print("Saved capture_gameplay_landscape.png Size: ", img_land.get_size())
	
	quit()
