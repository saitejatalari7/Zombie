extends SceneTree

func _init() -> void:
	print("[Capture] Starting premium studio showcase of Blender 3D character models...")
	
	var scene := Node3D.new()
	root.add_child(scene)
	
	# Sleek graphite studio floor
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	floor_mesh.mesh = plane
	var mat_floor := StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.06, 0.06, 0.08)
	mat_floor.roughness = 0.35
	mat_floor.metallic = 0.25
	floor_mesh.material_override = mat_floor
	scene.add_child(floor_mesh)
	
	# Pedestals for each character
	var pedestal_mat := StandardMaterial3D.new()
	pedestal_mat.albedo_color = Color(0.12, 0.12, 0.16)
	pedestal_mat.roughness = 0.4
	pedestal_mat.metallic = 0.5
	
	var positions: Array[Vector3] = [
		Vector3(-2.5, 0, 0),  # Operative
		Vector3(-0.85, 0, 0), # Shambler
		Vector3(0.85, 0, 0),  # Runner
		Vector3(2.7, 0, 0)    # Tank
	]
	
	for i in range(positions.size()):
		var pos := positions[i]
		var is_tank := (i == 3)
		var ped := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.95 if is_tank else 0.65
		cyl.bottom_radius = 1.0 if is_tank else 0.70
		cyl.height = 0.08
		ped.mesh = cyl
		ped.material_override = pedestal_mat
		ped.position = Vector3(pos.x, 0.04, pos.z)
		scene.add_child(ped)
		
		# Edge glowing ring
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = cyl.top_radius - 0.02
		torus.outer_radius = cyl.top_radius + 0.015
		ring.mesh = torus
		var ring_mat := StandardMaterial3D.new()
		ring_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		ring_mat.albedo_color = Color(0.2, 0.85, 1.0) if i == 0 else Color(0.92, 0.08, 0.15)
		ring.material_override = ring_mat
		ring.position = Vector3(pos.x, 0.082, pos.z)
		scene.add_child(ring)

	# Studio Lighting
	# Key Light (Warm daylight at 35°)
	var key_light := DirectionalLight3D.new()
	scene.add_child(key_light)
	key_light.rotation = Vector3(deg_to_rad(-36), deg_to_rad(30), 0)
	key_light.light_color = Color(1.0, 0.97, 0.94)
	key_light.light_energy = 1.5
	key_light.shadow_enabled = true
	
	# Fill Light (Cool ambient)
	var fill_light := DirectionalLight3D.new()
	scene.add_child(fill_light)
	fill_light.rotation = Vector3(deg_to_rad(-20), deg_to_rad(-65), 0)
	fill_light.light_color = Color(0.65, 0.78, 0.95)
	fill_light.light_energy = 0.7
	
	# Rim Backlight (Accentuates silhouettes from behind)
	var rim_light := DirectionalLight3D.new()
	scene.add_child(rim_light)
	rim_light.rotation = Vector3(deg_to_rad(-25), deg_to_rad(175), 0)
	rim_light.light_color = Color(1.0, 0.92, 0.85)
	rim_light.light_energy = 1.3
	
	# WorldEnvironment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.10, 0.10, 0.12)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_node.environment = env
	scene.add_child(env_node)
	
	# 1. Operative Player Model
	var player_scn := preload("res://assets/models/characters/player_operative.glb")
	var player: Node3D = player_scn.instantiate()
	scene.add_child(player)
	player.position = Vector3(-2.5, 0.08, 0)
	player.rotation.y = deg_to_rad(25) # 3/4 hero turn
	
	# Equip Assault Carbine in player's hands
	var carbine_scn := preload("res://assets/models/weapons/assault_carbine.glb")
	var carbine: Node3D = carbine_scn.instantiate()
	player.add_child(carbine)
	carbine.position = Vector3(0.20, 0.90, -0.30)
	carbine.rotation.y = deg_to_rad(-10)
	
	# 2. Zombie Shambler Model
	var shambler_scn := preload("res://assets/models/characters/zombie_shambler.glb")
	var shambler: Node3D = shambler_scn.instantiate()
	scene.add_child(shambler)
	shambler.position = Vector3(-0.85, 0.08, 0)
	shambler.rotation.y = deg_to_rad(-16)
	
	# 3. Zombie Runner Model
	var runner_scn := preload("res://assets/models/characters/zombie_runner.glb")
	var runner: Node3D = runner_scn.instantiate()
	scene.add_child(runner)
	runner.position = Vector3(0.85, 0.08, 0)
	runner.rotation.y = deg_to_rad(-22)
	
	# 4. Zombie Tank Model
	var tank_scn := preload("res://assets/models/characters/zombie_tank.glb")
	var tank: Node3D = tank_scn.instantiate()
	scene.add_child(tank)
	tank.position = Vector3(2.7, 0.08, 0)
	tank.rotation.y = deg_to_rad(-18)
	
	# Studio Camera framing all 4 characters
	var cam := Camera3D.new()
	scene.add_child(cam)
	cam.position = Vector3(0.1, 1.45, 5.0)
	cam.rotation = Vector3(deg_to_rad(-6.0), 0, 0)
	cam.fov = 46.0
	cam.current = true
	
	# Wait for render pipeline to settle
	for i in range(25):
		await process_frame
		
	print("=== FULL ROOT TREE DUMP ===")
	root.print_tree_pretty()
	print("===========================")
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://capture_characters_closeup.png")
		print("[SUCCESS] Saved capture_characters_closeup.png Size: ", img.get_size())
		
	quit(0)
