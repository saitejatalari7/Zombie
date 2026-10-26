extends SceneTree
## build_sector1_level.gd
## Rebuilds Sector 01: Residential Quarantine to 100% fulfill URBAN_LAYOUT_PROCEDURAL_RULES.md:
## 1. Zero foreground occlusion (Stepped elevation: low ≤2.4m buildings and 1.2m walls in +X/+Z).
## 2. 3 interconnecting streets: Main Avenue, East Service Alley, Upper Quarantine Terrace with split-level stairs.
## 3. Total edge-to-edge enclosure (140m ground base, perimeter cordons: blast gate, jackknifed bus, container stack).
## 4. Full StaticBody3D collision on all structures, props, and retaining walls.
## 5. Player spawn, Extraction zone, and 7 tactical zombie spawn markers.

var root_node: Node3D
var nav_region: NavigationRegion3D
var arch_node: Node3D
var road_node: Node3D
var props_node: Node3D
var cordons_node: Node3D
var spawners_node: Node3D

const ProceduralVegetation = preload("res://scripts/procedural_vegetation.gd")

var mat_clay: StandardMaterial3D
var mat_floor: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_curb: StandardMaterial3D
var mat_hazard: StandardMaterial3D
var mat_car_blue: StandardMaterial3D

func _init() -> void:
	print("[BuildSector1] Starting level construction according to URBAN_LAYOUT_PROCEDURAL_RULES.md...")
	
	_setup_materials()
	_create_scene_skeleton()
	_build_ground_and_roads()
	_build_split_level_stairs()
	_build_background_architecture()
	_build_foreground_architecture()
	_build_cordons_and_containment()
	_build_vehicles_and_chokepoints()
	_build_utility_poles_and_trees()
	_build_props_and_clutter()
	_build_procedural_vegetation()
	_setup_spawners_and_markers()
	
	# Pack and save scene
	var packed := PackedScene.new()
	var err_pack := packed.pack(root_node)
	if err_pack != OK:
		printerr("[BuildSector1] Failed to pack scene: ", err_pack)
		quit(1)
		return
		
	var target_path := "res://scenes/sectors/sector_1_residential.tscn"
	var err_save := ResourceSaver.save(packed, target_path)
	if err_save == OK:
		print("[BuildSector1] SUCCESS! Saved level to: ", target_path)
	else:
		printerr("[BuildSector1] ERROR saving scene: ", err_save)
		quit(1)
		return
		
	print("[BuildSector1] Rebuild complete. Total nodes: ", _count_nodes(root_node))
	quit(0)

func _count_nodes(n: Node) -> int:
	var c := 1
	for child in n.get_children():
		c += _count_nodes(child)
	return c

# ── 1. MATERIALS ──
func _setup_materials() -> void:
	mat_clay = load("res://assets/materials/mat_white_clay.tres") as StandardMaterial3D
	if not mat_clay:
		mat_clay = StandardMaterial3D.new()
		mat_clay.albedo_color = Color(0.88, 0.88, 0.90, 1.0)
		mat_clay.roughness = 0.82
		
	mat_floor = load("res://assets/materials/mat_street_floor.tres") as StandardMaterial3D
	if not mat_floor:
		mat_floor = StandardMaterial3D.new()
		mat_floor.albedo_color = Color(0.78, 0.78, 0.80, 1.0)
		mat_floor.roughness = 0.88
		
	mat_dark = load("res://assets/materials/mat_zombie_body.tres") as StandardMaterial3D
	if not mat_dark:
		mat_dark = StandardMaterial3D.new()
		mat_dark.albedo_color = Color(0.18, 0.18, 0.20, 1.0)
		mat_dark.roughness = 0.92
		
	mat_curb = StandardMaterial3D.new()
	mat_curb.albedo_color = Color(0.92, 0.92, 0.94, 1.0)
	mat_curb.roughness = 0.75
	
	mat_hazard = StandardMaterial3D.new()
	mat_hazard.albedo_color = Color(0.85, 0.65, 0.15, 1.0)
	mat_hazard.roughness = 0.50
	
	mat_car_blue = load("res://assets/materials/mat_car_blue.tres") as StandardMaterial3D
	if not mat_car_blue:
		mat_car_blue = StandardMaterial3D.new()
		mat_car_blue.albedo_color = Color(0.12, 0.36, 0.78, 1.0)
		mat_car_blue.metallic = 0.45
		mat_car_blue.roughness = 0.32

# ── 2. SCENE SKELETON ──
func _create_scene_skeleton() -> void:
	root_node = Node3D.new()
	root_node.name = "Sector1Residential"
	var sec_script = load("res://scripts/sector_base.gd")
	if sec_script:
		root_node.set_script(sec_script)
	root_node.set("sector_id", 1)
	root_node.set("sector_name", "SECTOR 01: RESIDENTIAL QUARANTINE")
	root_node.set("is_night_sector", false)
	root_node.set("sector_bounds", Rect2(-35, -55, 70, 110))
	
	# Note: WorldEnvironment and DirectionalLight3D are managed centrally by main.tscn
	# and DayNightManager. Removing duplicate lights & environments eliminates 2x shadow passes and SSAO conflicts!
	
	# NavigationRegion3D
	nav_region = NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_radius = 0.35
	nav_mesh.agent_max_climb = 0.45
	nav_mesh.agent_max_slope = 45.0
	nav_region.navigation_mesh = nav_mesh
	root_node.add_child(nav_region)
	nav_region.owner = root_node
	
	# Subgroups
	arch_node = Node3D.new()
	arch_node.name = "Architecture"
	nav_region.add_child(arch_node)
	arch_node.owner = root_node
	
	road_node = Node3D.new()
	road_node.name = "RoadTiles"
	nav_region.add_child(road_node)
	road_node.owner = root_node
	
	props_node = Node3D.new()
	props_node.name = "Props"
	nav_region.add_child(props_node)
	props_node.owner = root_node
	
	cordons_node = Node3D.new()
	cordons_node.name = "Cordons"
	nav_region.add_child(cordons_node)
	cordons_node.owner = root_node
	
	spawners_node = Node3D.new()
	spawners_node.name = "ZombieSpawners"
	root_node.add_child(spawners_node)
	spawners_node.owner = root_node

# ── HELPER: Set owner recursively on all children ──
func _set_owner_recursive(node: Node, new_owner: Node) -> void:
	node.owner = new_owner
	for child in node.get_children():
		_set_owner_recursive(child, new_owner)

# ── HELPER: Create Collidable Box (StaticBody3D + CollisionShape3D + MeshInstance3D) ──
func _collidable_box(p_name: String, size: Vector3, pos: Vector3, parent: Node3D,
		mat: StandardMaterial3D = null, rot_y_deg: float = 0.0) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = p_name
	sb.position = pos
	if rot_y_deg != 0.0:
		sb.rotation_degrees.y = rot_y_deg
	parent.add_child(sb)
	sb.owner = root_node
		
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = shape
	sb.add_child(cs)
	cs.owner = root_node
	
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat if mat else mat_clay
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	mi.mesh = mesh
	sb.add_child(mi)
	mi.owner = root_node
	
	return sb

# ── HELPER: Collision-Only Box (StaticBody3D + CollisionShape3D, NO Mesh — 0 draw calls!) ──
func _collider_box(p_name: String, size: Vector3, pos: Vector3, parent: Node3D, rot_y_deg: float = 0.0) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = p_name
	sb.position = pos
	if rot_y_deg != 0.0:
		sb.rotation_degrees.y = rot_y_deg
	parent.add_child(sb)
	sb.owner = root_node
		
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	cs.shape = shape
	sb.add_child(cs)
	cs.owner = root_node
	return sb

# ── HELPER: Visual Mesh Box (No Collision, e.g. for detail trims/curbs) ──
func _mesh_box(p_name: String, size: Vector3, pos: Vector3, parent: Node3D,
		mat: StandardMaterial3D = null, rot_y_deg: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = p_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat if mat else mat_clay
	mi.mesh = mesh
	mi.position = pos
	if rot_y_deg != 0.0:
		mi.rotation_degrees.y = rot_y_deg
	parent.add_child(mi)
	mi.owner = root_node
	return mi

# ── 3. GROUND BASE & 3-STREET LAYOUT ──
func _build_ground_and_roads() -> void:
	print("  [1/9] Building 140m ground base and 3-street corridors...")
	
	# Massive 140m x 140m foundation slab — prevents ANY skybox void from ever showing!
	_collidable_box("GroundBase", Vector3(140.0, 0.4, 140.0), Vector3(0.0, -0.2, 0.0), nav_region, mat_floor)
	
	# ── STREET 1: Main Commercial Avenue (Z = +35 to Z = -5) ──
	# Lower Street Floor (7.0m wide corridor)
	_mesh_box("Street1_Floor", Vector3(7.0, 0.04, 40.0), Vector3(0.0, 0.02, 15.0), road_node, mat_floor)
	# Sidewalk curbs
	_collidable_box("Curb_S1_West", Vector3(0.35, 0.22, 38.0), Vector3(-3.5 - 0.175, 0.11, 15.0), road_node, mat_curb)
	_collidable_box("Curb_S1_East", Vector3(0.35, 0.22, 28.0), Vector3(3.5 + 0.175, 0.11, 20.0), road_node, mat_curb)
	# Sidewalk walkways
	_mesh_box("Sidewalk_S1_W", Vector3(2.5, 0.18, 38.0), Vector3(-4.9, 0.09, 15.0), road_node, mat_curb)
	_mesh_box("Sidewalk_S1_E", Vector3(2.5, 0.18, 28.0), Vector3(4.9, 0.09, 20.0), road_node, mat_curb)
	
	# ── STREET 2: East Service Alley (branches east at Z = +2.5 to +7.5) ──
	# Street 2 Floor (5.0m wide alley, runs from X = +3.5 to X = +28.0)
	_mesh_box("Street2_Floor", Vector3(24.5, 0.04, 5.0), Vector3(15.75, 0.02, 5.0), road_node, mat_floor)
	# Curbs
	_collidable_box("Curb_S2_North", Vector3(24.0, 0.22, 0.35), Vector3(15.5, 0.11, 7.5 + 0.175), road_node, mat_curb)
	_collidable_box("Curb_S2_South", Vector3(24.0, 0.22, 0.35), Vector3(15.5, 0.11, 2.5 - 0.175), road_node, mat_curb)
	
	# ── STREET 3: Upper Quarantine Terrace (elevated +3.2m, Z = -5.8 to -36.5) ──
	# 100% SOLID Raised Mesa Plateau — ZERO HOLLOW SPACE under ANY part of the floor!
	# North Main Terrace (Z = -14.5 to -36.5, width 26m, height 3.4m: Y = -0.2 to +3.2m)
	_collidable_box("Street3_UpperMesa_North", Vector3(26.0, 3.4, 22.0), Vector3(-3.0, 1.5, -25.5), road_node, mat_floor)
	
	# West Mesa Flank (Z = -5.8 to -14.5, left of the stairs, width 13.8m, height 3.4m: Y = -0.2 to +3.2m)
	_collidable_box("Street3_UpperMesa_WestFlank", Vector3(13.8, 3.4, 8.7), Vector3(-9.1, 1.5, -10.15), road_node, mat_floor)
	
	# East Mesa Flank (Z = -5.8 to -14.5, right of the stairs, width 7.8m, height 3.4m: Y = -0.2 to +3.2m)
	_collidable_box("Street3_UpperMesa_EastFlank", Vector3(7.8, 3.4, 8.7), Vector3(6.1, 1.5, -10.15), road_node, mat_floor)
	
	# Retaining Walls facing Lower Street (Flanking the stairs at Z = -5.8)
	# West Retaining Wall
	_collidable_box("RetainingWall_West", Vector3(13.8, 3.2, 0.6), Vector3(-9.1, 1.6, -5.8), arch_node, mat_clay)
	_collidable_box("Retaining_Parapet_West", Vector3(13.8, 0.8, 0.3), Vector3(-9.1, 3.6, -5.5), arch_node, mat_curb)
	
	# East Retaining Wall
	_collidable_box("RetainingWall_East", Vector3(7.8, 3.2, 0.6), Vector3(6.1, 1.6, -5.8), arch_node, mat_clay)
	_collidable_box("Retaining_Parapet_East", Vector3(7.8, 0.8, 0.3), Vector3(6.1, 3.6, -5.5), arch_node, mat_curb)

# ── 4. SPLIT-LEVEL STREET STAIRS & SOLID COLLISION WEDGE ──
func _build_split_level_stairs() -> void:
	print("  [2/9] Building split-level street staircase with 100% SOLID collision wedge...")
	
	var num_steps := 18
	var total_rise := 3.2
	var step_rise := total_rise / float(num_steps)
	var step_run := 0.50
	var stair_width := 4.4
	var hw := stair_width * 0.5
	var start_z := -5.5
	var stair_len := float(num_steps) * step_run # 9.0m
	var end_z := start_z - stair_len            # -14.5m
	var mid_z := start_z - stair_len * 0.5       # -10.0m
	
	# 1. 100% Solid Convex Collision Wedge (Starts at Y=0.0 at ground, climbs to Y=3.2m at terrace!)
	# Bottom extends to Y=-0.2 (below floor base) — ZERO HOLLOW SPACE UNDERNEATH!
	var pts := PackedVector3Array([
		Vector3(-hw, -0.2, start_z),      # 0: bottom front left
		Vector3( hw, -0.2, start_z),      # 1: bottom front right
		Vector3(-hw,  0.0, start_z),      # 2: top front left (flush with ground!)
		Vector3( hw,  0.0, start_z),      # 3: top front right (flush with ground!)
		Vector3(-hw, -0.2, end_z),        # 4: bottom back left
		Vector3( hw, -0.2, end_z),        # 5: bottom back right
		Vector3(-hw, total_rise, end_z),  # 6: top back left (meets Upper Mesa!)
		Vector3( hw, total_rise, end_z),  # 7: top back right (meets Upper Mesa!)
	])
	
	var ramp_sb := StaticBody3D.new()
	ramp_sb.name = "Stair_Collision_Wedge"
	road_node.add_child(ramp_sb)
	ramp_sb.owner = root_node
	
	var ramp_shape := ConvexPolygonShape3D.new()
	ramp_shape.points = pts
	var ramp_cs := CollisionShape3D.new()
	ramp_cs.name = "CollisionShape3D"
	ramp_cs.shape = ramp_shape
	ramp_sb.add_child(ramp_cs)
	ramp_cs.owner = root_node
	
	# 2. Visual Step Meshes (MultiMesh: combines all 18 steps into 1 single draw call!)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var step_box := BoxMesh.new()
	step_box.size = Vector3(stair_width, step_rise, step_run)
	step_box.material = mat_clay
	mm.mesh = step_box
	mm.instance_count = num_steps
	for i in range(num_steps):
		var sz := start_z - float(i) * step_run - step_run * 0.5
		var sy := float(i) * step_rise + step_rise * 0.5
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0.0, sy, sz)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Stair_VisualSteps_MultiMesh"
	mmi.multimesh = mm
	road_node.add_child(mmi)
	mmi.owner = root_node
			
	# 3. Flanking Stair Stringer Walls / Handrails (Height 3.8m, guarding the sides)
	_collidable_box("StairWall_West", Vector3(0.35, 3.8, stair_len + 0.4),
		Vector3(-hw - 0.175, 2.0, mid_z), arch_node, mat_clay)
	_collidable_box("StairWall_East", Vector3(0.35, 3.8, stair_len + 0.4),
		Vector3(hw + 0.175, 2.0, mid_z), arch_node, mat_clay)

# ── 5. BACKGROUND ARCHITECTURE (-X, -Z: TALL MONOLITHIC CANYON) ──
func _build_background_architecture() -> void:
	print("  [3/9] Building background monolithic structures (3 to 4 stories, 9m-14m tall)...")
	
	# B1: West Building 1 (with external staircase wrapping along the facade)
	# Size: 6.8m wide, 11.5m tall, 12.0m deep. Positioned on West side of Street 1 Lower.
	_detailed_building("Bld_West_Stairs", Vector3(-9.8, 5.75, 18.0), Vector3(6.5, 11.5, 12.0),
		[[-1, -3.0, 8.5], [-1, 2.0, 8.5], [-1, -3.0, 5.2], [-1, 2.0, 5.2]],  # Right face (+X) windows
		[[-1, 0.0, 0.0], [-1, 3.0, 3.8]])  # Ground door + 2nd floor door at top of stairs!
		
	# Exterior staircase wrapping up B1 to 2nd floor door
	_build_exterior_stairs("B1_ExtStairs", Vector3(-6.2, 0.0, 22.0), 3.8, 18)
	# Rooftop AC chiller unit
	_build_ac_unit("AC_B1", Vector3(-9.0, 11.85, 16.0))
	_mesh_box("RoofAccess_B1", Vector3(1.8, 1.8, 2.0), Vector3(-8.5, 12.4, 20.5), arch_node, mat_clay)
	
	# B2: West Building 2 (Mid-West Residential Block, 10m tall)
	_detailed_building("Bld_West_Res", Vector3(-9.8, 5.0, 4.0), Vector3(6.5, 10.0, 10.0),
		[[-1, -2.5, 7.5], [-1, 2.0, 7.5], [-1, -2.5, 4.2], [-1, 2.0, 4.2]],
		[[-1, -1.0, 0.0]])
	_build_ac_unit("AC_B2", Vector3(-9.2, 10.35, 2.5))
	
	# B3: 45° Chamfered Facade Building (Corner of Street 1 and Upper Terrace)
	# Features an iconic diagonal sliced facade catching sunlight!
	_collidable_box("Bld_Chamfer_Main", Vector3(7.5, 12.5, 7.5), Vector3(-10.5, 6.25, -8.0), arch_node, mat_clay)
	_collidable_box("Bld_Chamfer_Wedge", Vector3(4.5, 12.5, 4.5), Vector3(-7.5, 6.25, -6.0), arch_node, mat_clay, 45.0)
	# Recessed doorway on chamfer
	_mesh_box("Door_Chamfer", Vector3(1.1, 2.2, 0.25), Vector3(-6.8, 1.1, -5.3), arch_node, mat_dark, 45.0)
	
	# B4: Street 2 North Wall (Warehouse Facade, 9m tall)
	_detailed_building("Bld_S2_Warehouse", Vector3(16.0, 4.5, 11.5), Vector3(18.0, 9.0, 5.0),
		[[0, -6.0, 6.5], [0, -2.0, 6.5], [0, 2.0, 6.5], [0, 6.0, 6.5]],  # Front face (-Z) windows
		[[0, -4.0, 0.0], [0, 4.0, 0.0]])  # Roll-up warehouse doors
	_build_ac_unit("AC_Warehouse", Vector3(14.0, 9.35, 11.0))
	
	# B5: Far Upper Terrace High-Rise Silhouettes (Backdrop walls sealing the horizon)
	_collidable_box("Backdrop_NW_1", Vector3(12.0, 16.0, 6.0), Vector3(-14.0, 8.0, -32.0), arch_node, mat_clay)
	_collidable_box("Backdrop_NW_2", Vector3(10.0, 18.0, 8.0), Vector3(-22.0, 9.0, -24.0), arch_node, mat_clay)
	_collidable_box("Backdrop_NE_1", Vector3(14.0, 15.0, 6.0), Vector3(12.0, 7.5, -32.0), arch_node, mat_clay)

# ── 6. FOREGROUND ARCHITECTURE (+X, +Z: LOW-PROFILE ≤2.4m — ZERO OCCLUSION) ──
func _build_foreground_architecture() -> void:
	print("  [4/9] Building low-profile foreground structures (max 2.4m — ZERO sightline blockage)...")
	
	# 1. Low Concrete Retaining Wall along East Sidewalk (height 1.2m, length 24m)
	# Player and camera have a 100% UNHINDERED view right over this wall!
	_collidable_box("ForeWall_East_Retaining", Vector3(0.4, 1.2, 24.0), Vector3(6.5, 0.6, 20.0), arch_node, mat_clay)
	_mesh_box("ForeWall_East_Cap", Vector3(0.55, 0.12, 24.2), Vector3(6.5, 1.26, 20.0), arch_node, mat_curb)
	
	# 2. Open Parking Apron & Staging Lot (X = +7.0 to +22.0, Z = +14.0 to +32.0)
	_mesh_box("Parking_Floor", Vector3(15.0, 0.05, 18.0), Vector3(14.5, 0.02, 23.0), road_node, mat_floor)
	_collidable_box("Parking_Curb_S", Vector3(15.0, 0.22, 0.35), Vector3(14.5, 0.11, 32.0), road_node, mat_curb)
	_collidable_box("Parking_Curb_E", Vector3(0.35, 0.22, 18.0), Vector3(22.0, 0.11, 23.0), road_node, mat_curb)
	
	# 3. Single-Story Flat-Roof Garage / Utility Annex (Height strictly 2.4m!)
	# Set far back at X = +15.5, Z = +17.0 so it never covers Street 1.
	_collidable_box("Garage_Body", Vector3(6.5, 2.4, 6.0), Vector3(15.5, 1.2, 17.0), arch_node, mat_clay)
	# Flat roof parapet (0.35m lip)
	_mesh_box("Garage_Parapet_N", Vector3(6.7, 0.35, 0.2), Vector3(15.5, 2.57, 14.0), arch_node, mat_curb)
	_mesh_box("Garage_Parapet_S", Vector3(6.7, 0.35, 0.2), Vector3(15.5, 2.57, 20.0), arch_node, mat_curb)
	_mesh_box("Garage_Parapet_W", Vector3(0.2, 0.35, 6.0), Vector3(12.25, 2.57, 17.0), arch_node, mat_curb)
	# Roll-up door (dark void)
	_mesh_box("Garage_Door", Vector3(0.2, 2.0, 3.2), Vector3(12.15, 1.0, 17.0), arch_node, mat_dark)
	
	# 4. Low Street 2 South Divider (Separating East alley from parking lot)
	# Height 1.3m — keeps East alley feeling like a tight corridor while keeping 100% visibility!
	_collidable_box("S2_South_Wall", Vector3(16.0, 1.3, 0.4), Vector3(14.5, 0.65, 1.2), arch_node, mat_clay)

# ── HELPER: Spawn GLB Scene with recursive owner ──
func _spawn_glb(packed: PackedScene, p_name: String, pos: Vector3, parent: Node3D, rot_y_deg: float = 0.0) -> Node3D:
	if not packed:
		return null
	var inst := packed.instantiate() as Node3D
	inst.name = p_name
	inst.position = pos
	if rot_y_deg != 0.0:
		inst.rotation_degrees.y = rot_y_deg
	parent.add_child(inst)
	_set_owner_recursive(inst, root_node)
	return inst

# ── 7. CORDONS & PERIMETER ENCLOSURE (ZERO VOID) ──
func _build_cordons_and_containment() -> void:
	print("  [5/9] Erecting lore-accurate quarantine cordons sealing all exits...")
	
	# ── NORTH EXIT (Z = -36.0): Heavy Concrete Quarantine Blast-Gate ──
	_collidable_box("BlastGate_Wall_L", Vector3(8.0, 5.5, 1.2), Vector3(-6.0, 5.0, -36.0), cordons_node, mat_clay)
	_collidable_box("BlastGate_Wall_R", Vector3(8.0, 5.5, 1.2), Vector3(6.0, 5.0, -36.0), cordons_node, mat_clay)
	# Sealed Steel Blast Door (Height 4.5m, Width 5.0m)
	_collidable_box("BlastDoor_Steel", Vector3(5.0, 4.5, 0.4), Vector3(0.0, 4.5, -36.0), cordons_node, mat_dark)
	# Hazard warning strip over blast gate
	_mesh_box("BlastDoor_HazardStrip", Vector3(5.2, 0.4, 0.45), Vector3(0.0, 6.9, -35.9), cordons_node, mat_hazard)
	
	# ── SOUTH EXIT (Z = +35.0): Jackknifed Transit Bus & Concrete Jersey Barriers ──
	# Transit Bus blocking 75% of the street
	var bus_packed = load("res://assets/models/props/transit_bus.glb") as PackedScene
	_spawn_glb(bus_packed, "Cordon_TransitBus", Vector3(-1.0, 0.0, 34.5), cordons_node, -22.0)
	# Bus collision box (invisible collider — 0 draw calls!)
	_collider_box("Col_Bus", Vector3(3.0, 3.2, 10.5), Vector3(-1.0, 1.6, 34.5), cordons_node, -22.0)
	
	# Concrete Jersey Barriers flanking the bus
	var barrier_packed = load("res://assets/models/environment/jersey_barrier.glb") as PackedScene
	for i in range(4):
		var bx := 2.5 + float(i) * 1.6
		_spawn_glb(barrier_packed, "Barrier_%d" % i, Vector3(bx, 0.0, 33.5), cordons_node)
		_collider_box("Col_Barrier_%d" % i, Vector3(1.5, 1.1, 0.6), Vector3(bx, 0.55, 33.5), cordons_node)
		
	# ── EAST EXIT (X = +28.0): Stacked Shipping Containers ──
	var cont_packed = load("res://assets/models/environment/shipping_container_stack.glb") as PackedScene
	_spawn_glb(cont_packed, "Containers_East", Vector3(27.5, 0.0, 5.0), cordons_node)
	_collider_box("Col_Containers_East", Vector3(4.0, 5.4, 6.0), Vector3(27.5, 2.7, 5.0), cordons_node)

# ── 8. VEHICLES & TACTICAL CHOKEPOINTS ──
func _build_vehicles_and_chokepoints() -> void:
	print("  [6/9] Positioning abandoned vehicles to form tactical funnels...")
	
	var car_a = load("res://assets/models/props/wrecked_car_a.glb") as PackedScene
	var car_b = load("res://assets/models/props/wrecked_car_b.glb") as PackedScene
	var car_c = load("res://assets/models/props/wrecked_car_c.glb") as PackedScene
	
	# Chokepoint 1: Street 1 Lower (Z = +22.0) — Forces player & horde into narrow 2.8m lane
	var c1 = _spawn_glb(car_a, "Car_Choke_1", Vector3(-1.8, 0.0, 22.0), props_node, 28.0)
	_apply_car_blue(c1)
	_collider_box("Col_Car1", Vector3(2.0, 1.4, 4.4), Vector3(-1.8, 0.7, 22.0), props_node, 28.0)
	
	# Chokepoint 2: Street 1 Mid (Z = +9.0) — Sedan angled near East curb
	var c2 = _spawn_glb(car_b, "Car_Choke_2", Vector3(1.6, 0.0, 9.0), props_node, -18.0)
	_apply_car_blue(c2)
	_collider_box("Col_Car2", Vector3(2.0, 1.4, 4.4), Vector3(1.6, 0.7, 9.0), props_node, -18.0)
	
	# Chokepoint 3: East Service Alley (X = +14.0, Z = +5.0)
	var c3 = _spawn_glb(car_c, "Car_Alley_3", Vector3(14.0, 0.0, 4.2), props_node, 85.0)
	_apply_car_blue(c3)
	_collider_box("Col_Car3", Vector3(4.4, 1.4, 2.0), Vector3(14.0, 0.7, 4.2), props_node, 85.0)
	
	# Parking Lot Props (Foreground open parking area)
	var c4 = _spawn_glb(car_a, "Car_Parking_1", Vector3(11.0, 0.0, 26.0), props_node, -45.0)
	_apply_car_blue(c4)
	_collider_box("Col_ParkCar1", Vector3(2.0, 1.4, 4.4), Vector3(11.0, 0.7, 26.0), props_node, -45.0)
	
	# Upper Terrace Vehicle (Z = -20.0, elevated +3.2m)
	var c5 = _spawn_glb(car_b, "Car_UpperTerrace", Vector3(-4.0, 3.2, -20.0), props_node, 40.0)
	_apply_car_blue(c5)
	_collider_box("Col_CarUpper", Vector3(2.0, 1.4, 4.4), Vector3(-4.0, 3.9, -20.0), props_node, 40.0)
	
	# ── 6 ABANDONED TRANSIT BUSES (Tactical Cover & Chokepoints) ──
	var bus_packed = load("res://assets/models/props/transit_bus.glb") as PackedScene
	
	# Bus 2: North Quarantine Exit (Z = -31.5) — Angled near blast gate creating slalom entry
	_spawn_glb(bus_packed, "TransitBus_North_2", Vector3(1.8, 0.0, -31.5), props_node, 15.0)
	_collider_box("Col_Bus_North", Vector3(3.0, 3.2, 10.5), Vector3(1.8, 1.6, -31.5), props_node, 15.0)
	
	# Bus 3: East Highway Entrance (X = +20.5, Z = +4.0) — Forces horde into tight alley funnel
	_spawn_glb(bus_packed, "TransitBus_East_3", Vector3(20.5, 0.0, 4.0), props_node, 82.0)
	_collider_box("Col_Bus_East", Vector3(3.0, 3.2, 10.5), Vector3(20.5, 1.6, 4.0), props_node, 82.0)
	
	# Bus 4: Street 1 Mid-block Chokepoint (Z = -11.0) — Narrowing main avenue
	_spawn_glb(bus_packed, "TransitBus_Mid_4", Vector3(-2.2, 0.0, -11.0), props_node, -8.0)
	_collider_box("Col_Bus_Mid", Vector3(3.0, 3.2, 10.5), Vector3(-2.2, 1.6, -11.0), props_node, -8.0)
	
	# Bus 5: Upper Quarantine Terrace Evacuation Bus (Z = -18.0, Y = +3.2m) — Elevated depot cover
	_spawn_glb(bus_packed, "TransitBus_Terrace_5", Vector3(-14.5, 3.2, -18.0), props_node, 34.0)
	_collider_box("Col_Bus_Terrace", Vector3(3.0, 3.2, 10.5), Vector3(-14.5, 4.8, -18.0), props_node, 34.0)
	
	# Bus 6: South-East Parking Lot / Terminal Barricade (X = +12.5, Z = +29.0)
	_spawn_glb(bus_packed, "TransitBus_Terminal_6", Vector3(12.5, 0.0, 29.0), props_node, -55.0)
	_collider_box("Col_Bus_Terminal", Vector3(3.0, 3.2, 10.5), Vector3(12.5, 1.6, 29.0), props_node, -55.0)

func _apply_car_blue(car_node: Node) -> void:
	if not car_node:
		return
	for m in car_node.find_children("*", "MeshInstance3D", true, false):
		if m is MeshInstance3D:
			var mn := m.name.to_lower()
			if not ("whl" in mn or "wheel" in mn or "windshield" in mn or "glass" in mn or "rearwin" in mn or "sidewin" in mn):
				m.material_override = mat_car_blue

func _build_procedural_vegetation() -> void:
	print("  [8.5/9] Scattering procedural dried grass bushes along curbs and walls...")
	var grass_mmi = ProceduralVegetation.build_dried_grass_multimesh(160)
	props_node.add_child(grass_mmi)
	_set_owner_recursive(grass_mmi, root_node)

# ── 9. UTILITY POLES & TREES ──
func _build_utility_poles_and_trees() -> void:
	print("  [7/9] Erecting utility poles with catenary wires and bare dead trees...")
	
	var pole_packed = load("res://assets/models/props/power_pole.glb") as PackedScene
	var tree_a = load("res://assets/models/props/dead_tree_a.glb") as PackedScene
	var tree_b = load("res://assets/models/props/dead_tree_b.glb") as PackedScene
	
	# Pole 1: Street 1 Lower West Curb
	_spawn_glb(pole_packed, "PowerPole_1", Vector3(-3.8, 0.0, 26.0), props_node)
	_collider_box("Col_Pole1", Vector3(0.5, 8.5, 0.5), Vector3(-3.8, 4.25, 26.0), props_node)
	
	# Pole 2: Street 1 T-Junction East Corner
	_spawn_glb(pole_packed, "PowerPole_2", Vector3(3.8, 0.0, 1.5), props_node)
	_collider_box("Col_Pole2", Vector3(0.5, 8.5, 0.5), Vector3(3.8, 4.25, 1.5), props_node)
	
	# Pole 3: Upper Terrace West Edge
	_spawn_glb(pole_packed, "PowerPole_3", Vector3(-3.8, 3.2, -18.0), props_node)
	_collider_box("Col_Pole3", Vector3(0.5, 8.5, 0.5), Vector3(-3.8, 7.45, -18.0), props_node)
	
	# Bare Dead Trees
	_spawn_glb(tree_a, "DeadTree_1", Vector3(-5.2, 0.0, 12.0), props_node)
	_collider_box("Col_Tree1", Vector3(0.6, 6.0, 0.6), Vector3(-5.2, 3.0, 12.0), props_node)
	
	_spawn_glb(tree_b, "DeadTree_2", Vector3(7.5, 0.0, 30.0), props_node)
	_collider_box("Col_Tree2", Vector3(0.6, 5.5, 0.6), Vector3(7.5, 2.75, 30.0), props_node)
	
	_spawn_glb(tree_a, "DeadTree_3", Vector3(6.5, 3.2, -22.0), props_node)
	_collider_box("Col_Tree3", Vector3(0.6, 6.0, 0.6), Vector3(6.5, 6.2, -22.0), props_node)

# ── 10. CLUTTER, PALLETS & CRATES ──
func _build_props_and_clutter() -> void:
	print("  [8/9] Scattering wooden pallets, supply crates, and rubble...")
	
	var crate_packed = load("res://assets/models/props/military_crate.glb") as PackedScene
	
	# Military supply crate at T-junction nook (Objective / Loot pickup!)
	_spawn_glb(crate_packed, "MilitaryCrate_1", Vector3(-2.8, 0.0, 2.5), props_node, 15.0)
	_collider_box("Col_Crate1", Vector3(1.2, 1.0, 1.2), Vector3(-2.8, 0.5, 2.5), props_node, 15.0)
	
	# Supply crate on Upper Terrace
	_spawn_glb(crate_packed, "MilitaryCrate_2", Vector3(3.5, 3.2, -26.0), props_node)
	_collider_box("Col_Crate2", Vector3(1.2, 1.0, 1.2), Vector3(3.5, 3.7, -26.0), props_node)
	
	# Pallets in alley
	_collidable_box("Pallet_1", Vector3(1.2, 0.15, 1.2), Vector3(-4.5, 0.1, 15.0), props_node, mat_clay, 22.0)
	_collidable_box("Pallet_2", Vector3(1.2, 0.15, 1.2), Vector3(-4.3, 0.25, 15.1), props_node, mat_clay, 10.0)
	
	# Concrete Rubble Scatter around car chokepoint (MultiMesh: combines all 8 into 1 single draw call!)
	var r_mm := MultiMesh.new()
	r_mm.transform_format = MultiMesh.TRANSFORM_3D
	var r_mesh := BoxMesh.new()
	r_mesh.size = Vector3(0.25, 0.12, 0.25)
	r_mesh.material = mat_clay
	r_mm.mesh = r_mesh
	r_mm.instance_count = 8
	for i in range(8):
		var rx := -1.8 + randf_range(-1.2, 1.2)
		var rz := 22.0 + randf_range(-1.5, 1.5)
		var basis := Basis(Vector3.UP, deg_to_rad(randf_range(0, 360)))
		r_mm.set_instance_transform(i, Transform3D(basis, Vector3(rx, 0.06, rz)))
	var r_mmi := MultiMeshInstance3D.new()
	r_mmi.name = "Rubble_MultiMesh"
	r_mmi.multimesh = r_mm
	props_node.add_child(r_mmi)
	r_mmi.owner = root_node

# ── 11. SPAWNERS, PLAYER SPAWN, & EXTRACTION ──
func _setup_spawners_and_markers() -> void:
	print("  [9/9] Configuring PlayerSpawn, ExtractionZone, and 7 ZombieSpawners...")
	
	# Player Spawn (South entrance of Street 1, clear sightlines)
	var p_spawn := Marker3D.new()
	p_spawn.name = "PlayerSpawn"
	p_spawn.position = Vector3(0.0, 0.3, 27.0)
	root_node.add_child(p_spawn)
	p_spawn.owner = root_node
	
	# Extraction Zone (Upper Quarantine Depot at Z = -28.0)
	var ez := Area3D.new()
	ez.name = "ExtractionZone"
	ez.position = Vector3(0.0, 3.2, -28.0)
	
	var c_mesh := CylinderMesh.new()
	c_mesh.top_radius = 3.5
	c_mesh.bottom_radius = 3.5
	c_mesh.height = 0.15
	c_mesh.material = mat_clay
	var ez_mi := MeshInstance3D.new()
	ez_mi.name = "MeshInstance3D"
	ez_mi.mesh = c_mesh
	ez.add_child(ez_mi)
	ez_mi.owner = root_node
	
	var ez_shape := BoxShape3D.new()
	ez_shape.size = Vector3(7.0, 3.0, 7.0)
	var ez_cs := CollisionShape3D.new()
	ez_cs.name = "CollisionShape3D"
	ez_cs.shape = ez_shape
	ez_cs.position.y = 1.5
	ez.add_child(ez_cs)
	ez_cs.owner = root_node
	
	root_node.add_child(ez)
	ez.owner = root_node
	
	# 7 Tactical Zombie Spawners
	var spawner_defs := [
		["SpawnSouthCordon", Vector3(0.0, 0.3, 33.0)],
		["SpawnWestStairNook", Vector3(-6.2, 0.3, 16.0)],
		["SpawnEastAlleyEntrance", Vector3(9.0, 0.3, 5.0)],
		["SpawnEastAlleyFar", Vector3(22.0, 0.3, 5.0)],
		["SpawnMidStreetCarChoke", Vector3(-1.5, 0.3, 2.0)],
		["SpawnUpperDepotTerrace", Vector3(-8.0, 3.5, -22.0)],
		["SpawnNorthBlastGate", Vector3(0.0, 3.5, -34.0)],
	]
	
	for sd in spawner_defs:
		var s_name: String = sd[0]
		var s_pos: Vector3 = sd[1]
		var sm := Marker3D.new()
		sm.name = s_name
		sm.position = s_pos
		spawners_node.add_child(sm)
		sm.owner = root_node

# ── BUILDING HELPERS ──
func _detailed_building(bname: String, center: Vector3, size: Vector3,
		windows: Array, doors: Array) -> void:
	# Main block with collision
	_collidable_box(bname, size, center, arch_node, mat_clay)
	
	# Parapet lip on roof
	var ph := 0.55
	var pt := 0.25
	var ry := center.y + size.y * 0.5 + ph * 0.5
	_mesh_box("%s_par_N" % bname, Vector3(size.x, ph, pt), Vector3(center.x, ry, center.z + size.z * 0.5 - pt * 0.5), arch_node, mat_curb)
	_mesh_box("%s_par_S" % bname, Vector3(size.x, ph, pt), Vector3(center.x, ry, center.z - size.z * 0.5 + pt * 0.5), arch_node, mat_curb)
	_mesh_box("%s_par_E" % bname, Vector3(pt, ph, size.z - pt * 2.0), Vector3(center.x + size.x * 0.5 - pt * 0.5, ry, center.z), arch_node, mat_curb)
	_mesh_box("%s_par_W" % bname, Vector3(pt, ph, size.z - pt * 2.0), Vector3(center.x - size.x * 0.5 + pt * 0.5, ry, center.z), arch_node, mat_curb)
	
	# Recessed windows (dark voids)
	var win_w := 0.95
	var win_h := 1.25
	var inset := 0.18
	for i in range(windows.size()):
		var w: Array = windows[i]
		var face: int = int(w[0])
		var off: float = float(w[1])
		var rz: float = float(w[2])
		var wpos := center
		wpos.y = center.y - size.y * 0.5 + rz
		
		if face == -1: # +X face (Right)
			wpos.x = center.x + size.x * 0.5 - inset * 0.5
			wpos.z += off
			_mesh_box("%s_w%d" % [bname, i], Vector3(inset, win_h, win_w), wpos, arch_node, mat_dark)
			_mesh_box("%s_ws%d" % [bname, i], Vector3(0.08, 0.06, win_w + 0.12),
				Vector3(wpos.x + 0.06, wpos.y - win_h * 0.5 - 0.03, wpos.z), arch_node, mat_clay)
		elif face == 0: # -Z face (Front)
			wpos.z = center.z - size.z * 0.5 + inset * 0.5
			wpos.x += off
			_mesh_box("%s_w%d" % [bname, i], Vector3(win_w, win_h, inset), wpos, arch_node, mat_dark)
			_mesh_box("%s_ws%d" % [bname, i], Vector3(win_w + 0.12, 0.06, 0.08),
				Vector3(wpos.x, wpos.y - win_h * 0.5 - 0.03, wpos.z - 0.06), arch_node, mat_clay)
				
	# Doors
	for i in range(doors.size()):
		var d: Array = doors[i]
		var face: int = int(d[0])
		var off: float = float(d[1])
		var elev: float = float(d[2]) if d.size() > 2 else 0.0
		var dpos := center
		dpos.y = center.y - size.y * 0.5 + 1.1 + elev
		if face == -1:
			dpos.x = center.x + size.x * 0.5 - 0.12
			dpos.z += off
			_mesh_box("%s_d%d" % [bname, i], Vector3(0.22, 2.2, 1.1), dpos, arch_node, mat_dark)
		elif face == 0:
			dpos.z = center.z - size.z * 0.5 + 0.12
			dpos.x += off
			_mesh_box("%s_d%d" % [bname, i], Vector3(1.1, 2.2, 0.22), dpos, arch_node, mat_dark)

func _build_exterior_stairs(sname: String, start: Vector3, target_y: float, steps: int) -> void:
	var rise := target_y / float(steps)
	var run := 0.32
	var width := 1.05
	var total_len := float(steps) * run
	var mid_z := start.z - total_len * 0.5
	# Solid foundation plinth sealing entire under-stair space down to Y=0!
	_collidable_box("%s_Plinth" % sname, Vector3(width, target_y * 0.5, total_len),
		Vector3(start.x, target_y * 0.25, mid_z), arch_node, mat_clay)
	# Solid landing platform down to Y=0
	_collidable_box("%s_land" % sname, Vector3(width + 0.4, target_y, 1.4),
		Vector3(start.x, target_y * 0.5, start.z - steps * run - 0.7), arch_node, mat_clay)
	for i in range(steps):
		var spos := Vector3(start.x, float(i) * rise + rise * 0.5, start.z - float(i) * run)
		_collidable_box("%s_s%d" % [sname, i], Vector3(width, rise, run), spos, arch_node, mat_clay)

func _build_ac_unit(ac_name: String, pos: Vector3) -> void:
	_mesh_box("%s_box" % ac_name, Vector3(1.1, 0.8, 0.9), pos, arch_node, mat_clay)
	# Fan cylinder
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.32
	cyl.bottom_radius = 0.32
	cyl.height = 0.10
	cyl.material = mat_clay
	var cmi := MeshInstance3D.new()
	cmi.name = "%s_fan" % ac_name
	cmi.mesh = cyl
	cmi.position = Vector3(pos.x, pos.y + 0.45, pos.z)
	arch_node.add_child(cmi)
	cmi.owner = root_node
