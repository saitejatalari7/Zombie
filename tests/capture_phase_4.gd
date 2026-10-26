extends SceneTree

func _init() -> void:
	print("[Capture] Starting visual capture of Phase 4 Combat & Power-Ups...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait for sector to load
	for i in range(12):
		await process_frame
		
	var player: Player = root.get_tree().get_first_node_in_group("player") as Player
	var blood_mgr: BloodManager = BloodManager.instance
	
	if player and blood_mgr:
		var p_pos := player.global_position
		
		# 1. Stamp 6m massive blood crater
		blood_mgr.spawn_massive_blood_crater(p_pos + Vector3(0, 0, -4.0), 6.0)
		
		# 2. Spawn Military Crate
		var crate_scene := preload("res://scenes/military_crate.tscn")
		var crate: Node3D = crate_scene.instantiate()
		root_node.add_child(crate)
		crate.global_position = p_pos + Vector3(-3.2, 0, -2.5)
		
		# 3. Spawn Flight Recorder Case
		var case_scene := preload("res://scenes/objective_case.tscn")
		var case_inst: Node3D = case_scene.instantiate()
		root_node.add_child(case_inst)
		case_inst.global_position = p_pos + Vector3(3.2, 0, -2.5)
		
		# 4. Spawn Tactical Supply Beacons (Crimson, Orange, Cyan)
		var beacon_scene := preload("res://scenes/supply_beacon.tscn")
		
		var b1: TacticalSupplyBeacon = beacon_scene.instantiate()
		root_node.add_child(b1)
		b1.global_position = p_pos + Vector3(-2.0, 0, -5.5)
		b1.setup(TacticalSupplyBeacon.BeaconType.HYPER_BURST)
		
		var b2: TacticalSupplyBeacon = beacon_scene.instantiate()
		root_node.add_child(b2)
		b2.global_position = p_pos + Vector3(0.0, 0, -6.5)
		b2.setup(TacticalSupplyBeacon.BeaconType.HEAVY_ROCKET)
		
		var b3: TacticalSupplyBeacon = beacon_scene.instantiate()
		root_node.add_child(b3)
		b3.global_position = p_pos + Vector3(2.0, 0, -5.5)
		b3.setup(TacticalSupplyBeacon.BeaconType.CRYO_STIM)
		
		# 5. Activate Hyper-Burst on Player and HUD
		player.activate_hyper_burst(14.8)
		player.mobile_move_input = Vector2(0.3, -0.9)
		
	# Wait for lights, volumetric beams, and shaders to settle
	for i in range(25):
		await process_frame
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_phase_4_combat.png")
		print("Saved capture_phase_4_combat.png Size: ", img.get_size())
		
	quit(0)
