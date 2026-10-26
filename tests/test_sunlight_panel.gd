extends SceneTree

func _init() -> void:
	print("[SunTest] Starting Sunlight Control UI verification...")
	var scene: PackedScene = load("res://scenes/main.tscn")
	if not scene:
		printerr("[SunTest] Failed to load main.tscn")
		quit(1)
		return
		
	var root_node = scene.instantiate()
	root.add_child(root_node)
	
	for i in range(15):
		await process_frame
		
	var panel: CanvasLayer = root_node.get_node_or_null("SunlightControlPanel")
	if not panel:
		printerr("[SunTest] SunlightControlPanel node not found in main.tscn!")
		quit(1)
		return
		
	print("[SunTest] Found SunlightControlPanel! Opening panel...")
	panel._on_toggle_pressed()
	
	for i in range(5):
		await process_frame
		
	var sun: DirectionalLight3D = root_node.get_node_or_null("DirectionalLight3D")
	var env: WorldEnvironment = root_node.get_node_or_null("WorldEnvironment")
	
	print("  Initial Sun rot: ", sun.rotation_degrees, " | Energy: ", sun.light_energy)
	
	# Test Golden Hour preset
	print("[SunTest] Testing Golden Hour preset...")
	panel.btn_preset_golden.emit_signal("pressed")
	
	for i in range(5):
		await process_frame
		
	print("  After Golden Hour: Sun rot = ", sun.rotation_degrees, " | Energy = ", sun.light_energy, " | Ambient = ", env.environment.ambient_light_energy)
	assert(is_equal_approx(sun.rotation_degrees.x, -28.0), "Pitch should be -28.0")
	assert(is_equal_approx(sun.rotation_degrees.y, 115.0), "Yaw should be 115.0")
	
	# Test High Noon preset
	print("[SunTest] Testing High Noon preset...")
	panel.btn_preset_noon.emit_signal("pressed")
	
	for i in range(5):
		await process_frame
		
	print("  After High Noon: Sun rot = ", sun.rotation_degrees, " | Energy = ", sun.light_energy, " | Ambient = ", env.environment.ambient_light_energy)
	assert(is_equal_approx(sun.rotation_degrees.x, -78.0), "Pitch should be -78.0")
	
	# Test Copy Values
	print("[SunTest] Testing Copy button...")
	panel._on_copy_pressed()
	print("  Code preview text: ", panel.code_preview.text)
	
	# Set to Default preset for visual capture
	panel.btn_preset_default.emit_signal("pressed")
	for i in range(15):
		await process_frame
		
	# Capture image of screen with the UI open
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_sunlight_panel.png")
		print("[SunTest] Successfully saved capture_sunlight_panel.png!")
		
	print("[SunTest] ALL SUNLIGHT CONTROL TESTS PASSED!")
	quit(0)
