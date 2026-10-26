extends SceneTree

func _init() -> void:
	var hub_scene: PackedScene = load("res://scenes/ui/outpost_hub.tscn")
	var root_node: Node = hub_scene.instantiate()
	root.add_child(root_node)
	
	for i in range(15):
		await process_frame
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_hub_portrait.png")
		print("Saved capture_hub_portrait.png: ", img.get_size())
		
	var om = root.get_node_or_null("OrientationManager")
	if om:
		om.set_landscape()
		for i in range(15):
			await process_frame
		var img_land: Image = root.get_viewport().get_texture().get_image()
		if img_land:
			img_land.save_png("res://capture_hub_landscape.png")
			print("Saved capture_hub_landscape.png: ", img_land.get_size())
			
	quit(0)
