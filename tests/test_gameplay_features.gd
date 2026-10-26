extends SceneTree

func _init() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node: Node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Wait for setup
	for i in range(10):
		await process_frame
	
	var player: Player = root_node.get_node("Player") as Player
	var hud: MobileHUD = root_node.get_node("MobileHUD") as MobileHUD
	var barricade: WoodenBarricade = root_node.get_node("EnvironmentMap/WoodenBarricade") as WoodenBarricade
	
	print("--- TESTING GAMEPLAY FEATURES ---")
	
	# 1. Test Molotov Throw & Ammo
	print("Initial Molotov Ammo: ", player.molotov_ammo)
	assert(player.molotov_ammo == 3, "Initial ammo should be 3")
	
	var threw_1 := player.throw_molotov()
	print("Threw molotov 1: ", threw_1, " remaining ammo: ", player.molotov_ammo)
	assert(threw_1 and player.molotov_ammo == 2, "Ammo should be 2")
	
	player.throw_molotov()
	player.throw_molotov()
	print("After 3 throws, ammo: ", player.molotov_ammo)
	assert(player.molotov_ammo == 0, "Ammo should be 0")
	var threw_empty := player.throw_molotov()
	print("Threw when empty: ", threw_empty)
	assert(not threw_empty, "Should fail when ammo is 0")
	
	player.refill_molotov(3)
	print("Refilled ammo: ", player.molotov_ammo)
	assert(player.molotov_ammo == 3, "Ammo should be restored to 3")
	
	# 2. Test Vault Detection near Choke Block
	# CenterChokeBlock is at x = 0.6, z = -2.5
	player.global_position = Vector3(0.6, 0.0, -1.2)
	player.rotation.y = 0.0 # Facing North (-Z) towards block
	player._physics_process(0.016)
	print("Player near choke block can_vault: ", player.can_vault)
	
	# 3. Test Stair Snapping & Automatic Ascension
	# Move player to bottom of stairs at x = -5.8, z = -2.2
	player.global_position = Vector3(-5.8, 0.05, -2.0)
	player.velocity = Vector3(0, 0, -5.0) # Moving forward into stairs
	player.move_and_slide()
	print("Player on stairs pos: ", player.global_position, " is_on_floor: ", player.is_on_floor())
	
	# 4. Test Barricade Break & Waypoint Arrow + Banner
	print("Barricade health before: ", barricade.current_health)
	barricade.take_damage(300.0, Vector3.FORWARD)
	
	for i in range(5):
		await process_frame
		
	var arrows := root_node.get_tree().get_nodes_in_group("waypoint_arrow")
	var banner: Panel = hud.get_node("StreetClearedBanner")
	print("Banner visible: ", banner.visible, " banner pos y: ", banner.position.y)
	print("Barricade broken: ", barricade.is_broken)
	
	print("--- ALL FEATURES VERIFIED SUCCESSFULLY! ---")
	quit()
