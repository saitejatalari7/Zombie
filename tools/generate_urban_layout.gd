extends SceneTree
## generate_urban_layout.gd
## Procedural generator that builds a complete 3-street urban alleyway diorama
## entirely from BoxMesh geometry in Godot — matching the Blender clay render.
## Run: Godot_console.exe -s tools/generate_urban_layout.gd

# ── Materials ──
var mat_clay: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_floor: StandardMaterial3D
var mat_curb: StandardMaterial3D

# ── Collections ──
var scene_root: Node3D
var streets_node: Node3D
var buildings_node: Node3D
var vehicles_node: Node3D
var props_node: Node3D
var poles_node: Node3D

func _init() -> void:
	print("[UrbanLayout] Starting procedural 3-street urban alleyway generation...")
	
	_create_materials()
	_create_scene_tree()
	_build_streets_and_ground()
	_build_staircases()
	_build_buildings()
	_build_vehicles()
	_build_utility_poles()
	_build_dead_trees()
	_build_props_and_rubble()
	_setup_camera_and_lighting()
	
	# Save scene
	var packed := PackedScene.new()
	packed.pack(scene_root)
	var err := ResourceSaver.save(packed, "res://scenes/sectors/sector_urban_layout.tscn")
	if err == OK:
		print("[UrbanLayout] Scene saved to res://scenes/sectors/sector_urban_layout.tscn")
	else:
		print("[UrbanLayout] ERROR saving scene: ", err)
	
	print("[UrbanLayout] Generation complete. Total children: ", _count_nodes(scene_root))
	quit(0)

func _count_nodes(node: Node) -> int:
	var count := 1
	for c in node.get_children():
		count += _count_nodes(c)
	return count

# ── MATERIALS ──

func _create_materials() -> void:
	mat_clay = StandardMaterial3D.new()
	mat_clay.albedo_color = Color(0.93, 0.93, 0.95, 1.0)
	mat_clay.roughness = 0.82
	mat_clay.metallic_specular = 0.08
	
	mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.22, 0.22, 0.24, 1.0)
	mat_dark.roughness = 0.92
	
	mat_floor = StandardMaterial3D.new()
	mat_floor.albedo_color = Color(0.88, 0.88, 0.90, 1.0)
	mat_floor.roughness = 0.88
	
	mat_curb = StandardMaterial3D.new()
	mat_curb.albedo_color = Color(0.96, 0.96, 0.97, 1.0)
	mat_curb.roughness = 0.78

# ── SCENE TREE ──

func _create_scene_tree() -> void:
	scene_root = Node3D.new()
	scene_root.name = "UrbanAlleywayLayout"
	
	streets_node = Node3D.new()
	streets_node.name = "Streets"
	scene_root.add_child(streets_node)
	streets_node.owner = scene_root
	
	buildings_node = Node3D.new()
	buildings_node.name = "Buildings"
	scene_root.add_child(buildings_node)
	buildings_node.owner = scene_root
	
	vehicles_node = Node3D.new()
	vehicles_node.name = "Vehicles"
	scene_root.add_child(vehicles_node)
	vehicles_node.owner = scene_root
	
	props_node = Node3D.new()
	props_node.name = "Props"
	scene_root.add_child(props_node)
	props_node.owner = scene_root
	
	poles_node = Node3D.new()
	poles_node.name = "Poles"
	scene_root.add_child(poles_node)
	poles_node.owner = scene_root

# ── HELPER: Create a box mesh instance ──

func _box(p_name: String, size: Vector3, pos: Vector3, parent: Node3D,
		mat: StandardMaterial3D = null, rot_y: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	if mat:
		mesh.material = mat
	else:
		mesh.material = mat_clay
	
	var inst := MeshInstance3D.new()
	inst.name = p_name
	inst.mesh = mesh
	inst.position = pos
	if rot_y != 0.0:
		inst.rotation.y = deg_to_rad(rot_y)
	
	parent.add_child(inst)
	inst.owner = scene_root
	return inst

func _cylinder(p_name: String, radius: float, height: float, pos: Vector3,
		parent: Node3D, mat: StandardMaterial3D = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	if mat:
		mesh.material = mat
	else:
		mesh.material = mat_clay
	
	var inst := MeshInstance3D.new()
	inst.name = p_name
	inst.mesh = mesh
	inst.position = pos
	
	parent.add_child(inst)
	inst.owner = scene_root
	return inst

# ── STREETS & GROUND ──
# Layout:
#   STREET 1 (Main N-S): runs along Z axis from z=-45 to z=+30
#   STREET 2 (East alley): branches east from T-junction at z=0
#   STREET 3 (Upper West): branches west from split-level stairs at z=+15, elevated +3.2m
#   All streets are 5.5–7m wide corridors

func _build_streets_and_ground() -> void:
	print("  [1/8] Building 3 streets and ground tiles...")
	
	# ── STREET 1: Main North-South Corridor ──
	# Lower section (z = -45 to z = 0)
	_box("Street1_Lower", Vector3(7.0, 0.3, 45.0), Vector3(0, -0.15, -22.5), streets_node, mat_floor)
	# Upper section (z = 0 to z = +30)
	_box("Street1_Upper", Vector3(7.0, 0.3, 30.0), Vector3(0, -0.15, 15.0), streets_node, mat_floor)
	
	# Sidewalk curbs - Street 1 West
	_box("Curb_S1_West_Lower", Vector3(0.35, 0.22, 44.0), Vector3(-3.5 - 0.175, 0.11, -23.0), streets_node, mat_curb)
	_box("Curb_S1_West_Upper", Vector3(0.35, 0.22, 12.0), Vector3(-3.5 - 0.175, 0.11, 6.0), streets_node, mat_curb)
	# Sidewalk curbs - Street 1 East
	_box("Curb_S1_East_Lower", Vector3(0.35, 0.22, 20.0), Vector3(3.5 + 0.175, 0.11, -35.0), streets_node, mat_curb)
	_box("Curb_S1_East_Upper", Vector3(0.35, 0.22, 12.0), Vector3(3.5 + 0.175, 0.11, 24.0), streets_node, mat_curb)
	
	# Sidewalk platforms (raised walkways next to buildings)
	_box("Sidewalk_S1_W", Vector3(2.5, 0.18, 42.0), Vector3(-4.75, 0.09, -24.0), streets_node, mat_curb)
	_box("Sidewalk_S1_E", Vector3(2.5, 0.18, 18.0), Vector3(4.75, 0.09, -36.0), streets_node, mat_curb)
	
	# ── STREET 2: East Alley (branches east from z=0) ──
	_box("Street2_EastAlley", Vector3(28.0, 0.3, 6.0), Vector3(17.5, -0.15, 0.0), streets_node, mat_floor)
	# Curbs
	_box("Curb_S2_North", Vector3(28.0, 0.22, 0.35), Vector3(17.5, 0.11, 3.0 + 0.175), streets_node, mat_curb)
	_box("Curb_S2_South", Vector3(28.0, 0.22, 0.35), Vector3(17.5, 0.11, -3.0 - 0.175), streets_node, mat_curb)
	# Sidewalk
	_box("Sidewalk_S2_N", Vector3(26.0, 0.18, 2.0), Vector3(18.5, 0.09, 4.2), streets_node, mat_curb)
	_box("Sidewalk_S2_S", Vector3(26.0, 0.18, 2.0), Vector3(18.5, 0.09, -4.2), streets_node, mat_curb)
	
	# ── STREET 3: Upper West Alley (elevated +3.2m, branches west from z=15) ──
	_box("Street3_UpperWest", Vector3(22.0, 0.3, 6.5), Vector3(-15.0, 3.05, 18.0), streets_node, mat_floor)
	# Retaining wall separating Street 3 from Street 1
	_box("RetainingWall_S3", Vector3(22.0, 3.2, 0.6), Vector3(-15.0, 1.6, 14.5), streets_node, mat_clay)
	# Curbs
	_box("Curb_S3_North", Vector3(20.0, 0.22, 0.35), Vector3(-16.0, 3.31, 21.25 + 0.175), streets_node, mat_curb)
	_box("Curb_S3_South", Vector3(20.0, 0.22, 0.35), Vector3(-16.0, 3.31, 14.75 - 0.175), streets_node, mat_curb)
	# Sidewalks
	_box("Sidewalk_S3_N", Vector3(20.0, 0.18, 2.0), Vector3(-16.0, 3.29, 22.5), streets_node, mat_curb)
	
	# ── T-JUNCTION INTERSECTION (Streets 1 & 2) ──
	_box("TJunction_Floor", Vector3(7.0, 0.3, 6.0), Vector3(3.5, -0.15, 0.0), streets_node, mat_floor)

func _build_staircases() -> void:
	print("  [2/8] Building split-level staircases...")
	
	# ── Staircase: Street 1 → Street 3 (climbing west at z=15) ──
	var num_steps := 16
	var total_rise := 3.2
	var step_rise := total_rise / float(num_steps)
	var step_run := 0.38
	var stair_width := 3.0
	
	for i in range(num_steps):
		var step_z := 12.0 + i * step_run * (-1.0)  # Steps going west = -X
		_box("Stair_S1toS3_%d" % i,
			Vector3(step_run, step_rise, stair_width),
			Vector3(-3.8 - i * step_run, float(i) * step_rise + step_rise * 0.5, 16.5),
			streets_node, mat_clay)
	
	# Landing at top
	_box("Stair_S1toS3_Landing", Vector3(1.5, 0.25, 3.5),
		Vector3(-3.8 - num_steps * step_run - 0.75, total_rise - 0.125, 16.5),
		streets_node, mat_curb)
	
	# Staircase retaining walls (flanking the stairs)
	_box("Stair_S1toS3_WallN", Vector3(num_steps * step_run + 2.0, 0.8, 0.3),
		Vector3(-3.8 - num_steps * step_run * 0.5, total_rise * 0.5 + 0.4, 18.2),
		streets_node, mat_clay)
	_box("Stair_S1toS3_WallS", Vector3(num_steps * step_run + 2.0, 0.8, 0.3),
		Vector3(-3.8 - num_steps * step_run * 0.5, total_rise * 0.5 + 0.4, 14.8),
		streets_node, mat_clay)
	
	# ── Small 4-step entrance flight (Building 4 entrance on Street 1) ──
	for i in range(4):
		var w := 2.2 - i * 0.12
		_box("EntrySteps_Bld4_%d" % i,
			Vector3(w, 0.16, 1.2 - i * 0.08),
			Vector3(3.8, 0.08 + i * 0.16, -18.0),
			streets_node, mat_clay)
	
	# ── Small 3-step flight at east end of Street 2 ──
	for i in range(3):
		_box("EntrySteps_EastEnd_%d" % i,
			Vector3(2.8, 0.16, 0.36),
			Vector3(31.0, 0.08 + i * 0.16, 0.0 + i * 0.38),
			streets_node, mat_clay)

# ── BUILDINGS ──

func _build_buildings() -> void:
	print("  [3/8] Generating monolithic buildings with window recesses...")
	
	# ═══════════════════════════════════════════════
	# STREET 1 — WEST SIDE BUILDINGS (left wall)
	# ═══════════════════════════════════════════════
	
	# B1: South-West corner building (2-story, 7.5m tall)
	_building("Bld_SW_1", Vector3(-9.5, 3.75, -35.0), Vector3(6.0, 7.5, 14.0),
		[[-1, -3.0, 4.8], [-1, 1.0, 4.8], [-1, -3.0, 2.2], [-1, 5.0, 4.8]],  # right-face windows
		[[-1, -1.0, 0.0]],  # right-face door
		true)  # parapet
	
	# B2: Mid-West building with exterior stairs (3-story, 11m tall)
	_building("Bld_MW_2", Vector3(-9.2, 5.5, -16.0), Vector3(5.8, 11.0, 12.0),
		[[-1, -2.5, 8.5], [-1, 2.0, 8.5], [-1, -2.5, 5.2], [-1, 2.0, 5.2], [-1, -2.5, 2.2]],
		[[-1, 0.5, 0.0]],
		true)
	# Exterior staircase wrapping up the right wall
	_build_exterior_stairs("ExtStairs_B2", Vector3(-6.1, 0.0, -22.0), 4.0, 20)
	# Rooftop AC unit
	_box("AC_B2_body", Vector3(0.95, 0.75, 0.80), Vector3(-8.5, 11.38, -18.0), buildings_node, mat_clay)
	_cylinder("AC_B2_fan", 0.28, 0.08, Vector3(-8.5, 11.79, -18.0), buildings_node, mat_clay)
	# Roof access box
	_box("RoofAccess_B2", Vector3(1.8, 1.6, 2.0), Vector3(-8.0, 11.8, -14.5), buildings_node, mat_clay)
	
	# B3: West building flanking upper street stairs
	_building("Bld_MW_3", Vector3(-9.0, 4.5, -2.0), Vector3(5.5, 9.0, 10.0),
		[[-1, -2.0, 6.5], [-1, 2.0, 6.5], [-1, -2.0, 3.5]],
		[[-1, 0.0, 0.0]],
		true)
	
	# B4: Upper-West building on Street 3 (elevated)
	_building("Bld_UW_4", Vector3(-22.0, 3.2 + 5.0, 18.0), Vector3(6.0, 10.0, 6.0),
		[[1, -1.0, 7.5], [1, 1.5, 7.5], [1, -1.0, 4.2]],
		[[1, 0.5, 0.0]],
		true)
	
	# B5: Far Upper-West on Street 3
	_building("Bld_UW_5", Vector3(-26.0, 3.2 + 4.5, 18.0), Vector3(4.5, 9.0, 6.5),
		[[1, -1.0, 6.5], [1, 1.5, 6.5]],
		[],
		true)
	
	# ═══════════════════════════════════════════════
	# STREET 1 — EAST SIDE BUILDINGS (right wall)
	# ═══════════════════════════════════════════════
	
	# B6: South-East corner building (2-story)
	_building("Bld_SE_6", Vector3(9.5, 3.75, -38.0), Vector3(6.0, 7.5, 10.0),
		[[1, -2.0, 4.8], [1, 2.0, 4.8], [1, -2.0, 2.2]],
		[[1, 0.0, 0.0]],
		true)
	
	# B7: Mid-East building (tall 3-story wall along Street 1)
	_building("Bld_ME_7", Vector3(9.5, 6.5, -24.0), Vector3(6.0, 13.0, 16.0),
		[[1, -4.0, 10.0], [1, 0.0, 10.0], [1, 4.0, 10.0],
		 [1, -4.0, 6.5], [1, 0.0, 6.5], [1, 4.0, 6.5],
		 [1, -2.0, 3.2], [1, 2.0, 3.2]],
		[[1, -2.0, 0.0]],
		true)
	
	# B8: East building at T-junction corner (faces both Street 1 & Street 2)
	_building("Bld_TE_8", Vector3(9.2, 5.0, -5.5), Vector3(5.5, 10.0, 7.0),
		[[1, -1.5, 7.5], [1, 1.5, 7.5], [1, -1.5, 4.2]],
		[],
		true)
	
	# B9: North-East building (above T-junction, along Street 1)
	_building("Bld_NE_9", Vector3(9.5, 5.5, 8.0), Vector3(6.0, 11.0, 10.0),
		[[1, -2.0, 8.5], [1, 2.0, 8.5], [1, -2.0, 5.0], [1, 2.0, 5.0]],
		[],
		true)
	
	# ═══════════════════════════════════════════════
	# STREET 2 — EAST ALLEY BUILDINGS (north & south walls)
	# ═══════════════════════════════════════════════
	
	# B10: Street 2 North wall - long warehouse-style building
	_building("Bld_S2N_10", Vector3(18.0, 4.5, 7.5), Vector3(16.0, 9.0, 5.0),
		[[0, -5.0, 6.5], [0, -1.5, 6.5], [0, 2.5, 6.5], [0, 6.0, 6.5],
		 [0, -5.0, 3.2], [0, 0.0, 3.2], [0, 5.0, 3.2]],
		[[0, -3.0, 0.0], [0, 3.0, 0.0]],
		true)
	
	# B11: Street 2 South wall - residential block
	_building("Bld_S2S_11", Vector3(16.0, 4.0, -7.0), Vector3(14.0, 8.0, 5.5),
		[[0, -4.0, 5.5], [0, 0.0, 5.5], [0, 4.0, 5.5],
		 [0, -2.0, 2.8], [0, 2.0, 2.8]],
		[[0, -1.0, 0.0]],
		true)
	
	# B12: East end of Street 2 - dead end building
	_building("Bld_S2E_12", Vector3(33.0, 5.0, 0.0), Vector3(4.0, 10.0, 10.0),
		[[1, -2.5, 7.5], [1, 2.5, 7.5], [1, -2.5, 4.2]],
		[],
		true)
	
	# ═══════════════════════════════════════════════
	# STREET 3 — UPPER WEST ALLEY (north & south)
	# ═══════════════════════════════════════════════
	
	# B13: Street 3 North wall
	_building("Bld_S3N_13", Vector3(-16.0, 3.2 + 5.0, 24.5), Vector3(14.0, 10.0, 4.5),
		[[0, -4.0, 7.5], [0, 0.0, 7.5], [0, 4.0, 7.5],
		 [0, -2.0, 4.2], [0, 2.0, 4.2]],
		[[0, -1.0, 0.0]],
		true)
	
	# B14: Street 3 South wall (sits on retaining wall)
	_building("Bld_S3S_14", Vector3(-14.0, 3.2 + 4.0, 12.2), Vector3(12.0, 8.0, 3.5),
		[[0, -3.5, 5.5], [0, 0.5, 5.5], [0, 4.5, 5.5]],
		[],
		true)
	
	# ═══════════════════════════════════════════════
	# CHAMFERED / ANGLED FACADE BUILDING (Image 1 special)
	# ═══════════════════════════════════════════════
	
	# Chamfered corner building at the intersection of Street 1 north and Street 3 approach
	_box("Bld_Chamfer_Main", Vector3(5.5, 12.0, 5.5), Vector3(-7.5, 6.0, 10.0), buildings_node, mat_clay)
	_box("Bld_Chamfer_Wing", Vector3(4.0, 12.0, 4.0), Vector3(-5.8, 6.0, 8.2), buildings_node, mat_clay, 45.0)
	# Chamfer doorway
	_box("Bld_Chamfer_Door", Vector3(1.1, 2.2, 0.25), Vector3(-5.2, 1.1, 7.5), buildings_node, mat_dark, 45.0)

# ── BUILDING HELPER ──

func _building(bname: String, center: Vector3, size: Vector3,
		windows: Array, doors: Array, parapet: bool) -> void:
	"""
	center = center of building base (y = half-height above ground)
	size = (width_x, height_y, depth_z)
	windows = [ [face, rel_offset, rel_z], ... ]
	  face: -1 = right (+X face), 1 = left (-X face), 0 = front (-Z face)
	doors = [ [face, rel_offset, ground_level], ... ]
	"""
	# Main body
	_box(bname, size, center, buildings_node, mat_clay)
	
	# Windows (recessed dark voids)
	var win_w := 0.95
	var win_h := 1.25
	var inset := 0.18
	for idx in range(windows.size()):
		var w: Array = windows[idx]
		var face: int = int(w[0])
		var off: float = float(w[1])
		var rz: float = float(w[2])
		
		var wpos := center
		wpos.y = center.y - size.y * 0.5 + rz
		
		if face == -1:  # Right face (+X)
			wpos.x = center.x + size.x * 0.5 - inset * 0.5
			wpos.z += off
			_box("%s_win_%d" % [bname, idx], Vector3(inset, win_h, win_w), wpos, buildings_node, mat_dark)
			# Sill
			_box("%s_sill_%d" % [bname, idx], Vector3(0.08, 0.06, win_w + 0.12),
				Vector3(wpos.x + 0.06, wpos.y - win_h * 0.5 - 0.03, wpos.z), buildings_node, mat_clay)
		elif face == 1:  # Left face (-X)
			wpos.x = center.x - size.x * 0.5 + inset * 0.5
			wpos.z += off
			_box("%s_win_%d" % [bname, idx], Vector3(inset, win_h, win_w), wpos, buildings_node, mat_dark)
			_box("%s_sill_%d" % [bname, idx], Vector3(0.08, 0.06, win_w + 0.12),
				Vector3(wpos.x - 0.06, wpos.y - win_h * 0.5 - 0.03, wpos.z), buildings_node, mat_clay)
		elif face == 0:  # Front face (-Z)
			wpos.z = center.z - size.z * 0.5 + inset * 0.5
			wpos.x += off
			_box("%s_win_%d" % [bname, idx], Vector3(win_w, win_h, inset), wpos, buildings_node, mat_dark)
			_box("%s_sill_%d" % [bname, idx], Vector3(win_w + 0.12, 0.06, 0.08),
				Vector3(wpos.x, wpos.y - win_h * 0.5 - 0.03, wpos.z - 0.06), buildings_node, mat_clay)
	
	# Doors
	var door_w := 1.1
	var door_h := 2.2
	for idx in range(doors.size()):
		var d: Array = doors[idx]
		var face: int = int(d[0])
		var off: float = float(d[1])
		
		var dpos := center
		dpos.y = center.y - size.y * 0.5 + door_h * 0.5
		
		if face == -1:
			dpos.x = center.x + size.x * 0.5 - 0.12
			dpos.z += off
			_box("%s_door_%d" % [bname, idx], Vector3(0.22, door_h, door_w), dpos, buildings_node, mat_dark)
		elif face == 1:
			dpos.x = center.x - size.x * 0.5 + 0.12
			dpos.z += off
			_box("%s_door_%d" % [bname, idx], Vector3(0.22, door_h, door_w), dpos, buildings_node, mat_dark)
		elif face == 0:
			dpos.z = center.z - size.z * 0.5 + 0.12
			dpos.x += off
			_box("%s_door_%d" % [bname, idx], Vector3(door_w, door_h, 0.22), dpos, buildings_node, mat_dark)
	
	# Parapet
	if parapet:
		var pt := 0.22
		var ph := 0.55
		var roof_y := center.y + size.y * 0.5 + ph * 0.5
		# North & South parapets
		_box("%s_par_N" % bname, Vector3(size.x, ph, pt), Vector3(center.x, roof_y, center.z + size.z * 0.5 - pt * 0.5), buildings_node, mat_clay)
		_box("%s_par_S" % bname, Vector3(size.x, ph, pt), Vector3(center.x, roof_y, center.z - size.z * 0.5 + pt * 0.5), buildings_node, mat_clay)
		_box("%s_par_E" % bname, Vector3(pt, ph, size.z - pt * 2), Vector3(center.x + size.x * 0.5 - pt * 0.5, roof_y, center.z), buildings_node, mat_clay)
		_box("%s_par_W" % bname, Vector3(pt, ph, size.z - pt * 2), Vector3(center.x - size.x * 0.5 + pt * 0.5, roof_y, center.z), buildings_node, mat_clay)

func _build_exterior_stairs(sname: String, start: Vector3, target_y: float, steps: int) -> void:
	var rise := target_y / float(steps)
	var tread := 0.32
	for i in range(steps):
		_box("%s_%d" % [sname, i],
			Vector3(1.05, rise, tread),
			Vector3(start.x, start.y + i * rise + rise * 0.5, start.z + i * tread),
			buildings_node, mat_clay)
	# Landing
	_box("%s_landing" % sname,
		Vector3(1.2, 0.2, 1.0),
		Vector3(start.x, target_y - 0.1, start.z + steps * tread + 0.5),
		buildings_node, mat_curb)

# ── VEHICLES ──

func _build_vehicles() -> void:
	print("  [4/8] Placing abandoned vehicles...")
	# 8 cars spread across all 3 streets
	_car("Car_S1_1", Vector3(-1.8, 0.0, -32.0), 22.0, false)   # Street 1 south
	_car("Car_S1_2", Vector3(1.5, 0.0, -28.0), -35.0, false)   # Street 1 south
	_car("Car_S1_3", Vector3(-2.0, 0.0, -12.0), 8.0, true)     # Street 1 mid hatchback
	_car("Car_S1_4", Vector3(1.2, 0.0, 5.0), -18.0, false)     # Street 1 near T-junction
	_car("Car_S2_1", Vector3(12.0, 0.0, 1.5), 6.0, false)      # Street 2 east
	_car("Car_S2_2", Vector3(22.0, 0.0, -1.2), -28.0, true)    # Street 2 east far
	_car("Car_S3_1", Vector3(-18.0, 3.2, 17.5), 14.0, false)   # Street 3 upper
	_car("Car_S3_2", Vector3(-12.5, 3.2, 19.0), -42.0, false)  # Street 3 upper

func _car(cname: String, pos: Vector3, rot_y: float, is_hatch: bool) -> void:
	var car_node := Node3D.new()
	car_node.name = cname
	car_node.position = pos
	car_node.rotation.y = deg_to_rad(rot_y)
	vehicles_node.add_child(car_node)
	car_node.owner = scene_root
	
	# Chassis
	_box("%s_chassis" % cname, Vector3(1.76, 0.52, 4.2), Vector3(0, 0.48, 0), car_node, mat_clay)
	# Cabin
	var cab_h := 0.58 if is_hatch else 0.56
	var cab_z := -0.2 if is_hatch else -0.15
	_box("%s_cabin" % cname, Vector3(1.52, cab_h, 2.2), Vector3(0, 0.96, cab_z), car_node, mat_clay)
	# Windshield (dark)
	_box("%s_windshield" % cname, Vector3(1.42, 0.48, 0.6), Vector3(0, 0.88, 0.95), car_node, mat_dark)
	# Rear window
	_box("%s_rearwin" % cname, Vector3(1.42, 0.45, 0.6), Vector3(0, 0.88, -1.25), car_node, mat_dark)
	# Side windows
	_box("%s_sidewin_L" % cname, Vector3(0.04, 0.40, 1.7), Vector3(-0.76, 0.98, -0.15), car_node, mat_dark)
	_box("%s_sidewin_R" % cname, Vector3(0.04, 0.40, 1.7), Vector3(0.76, 0.98, -0.15), car_node, mat_dark)
	# Bumpers
	_box("%s_bmpF" % cname, Vector3(1.8, 0.20, 0.20), Vector3(0, 0.38, 2.15), car_node, mat_clay)
	_box("%s_bmpR" % cname, Vector3(1.8, 0.20, 0.20), Vector3(0, 0.38, -2.15), car_node, mat_clay)
	# Side mirrors
	_box("%s_mirL" % cname, Vector3(0.16, 0.10, 0.12), Vector3(-0.84, 0.92, 0.75), car_node, mat_clay)
	_box("%s_mirR" % cname, Vector3(0.16, 0.10, 0.12), Vector3(0.84, 0.92, 0.75), car_node, mat_clay)
	# 4 Wheels
	for wpos in [Vector3(-0.82, 0.33, 1.25), Vector3(0.82, 0.33, 1.25),
				 Vector3(-0.82, 0.33, -1.25), Vector3(0.82, 0.33, -1.25)]:
		_cylinder("%s_whl" % cname, 0.33, 0.24, wpos, car_node, mat_clay)

# ── UTILITY POLES ──

func _build_utility_poles() -> void:
	print("  [5/8] Erecting utility poles...")
	var pole_positions := [
		Vector3(-5.5, 0.0, -30.0),   # Street 1 south
		Vector3(5.0, 0.0, -18.0),    # Street 1 mid
		Vector3(-5.2, 0.0, 2.0),     # Street 1 near T-junction
		Vector3(15.0, 0.0, 4.5),     # Street 2
		Vector3(-14.0, 3.2, 22.0),   # Street 3
	]
	for i in range(pole_positions.size()):
		_utility_pole("Pole_%d" % i, pole_positions[i])

func _utility_pole(pname: String, pos: Vector3) -> void:
	var h := 8.2
	# Mast
	_cylinder("%s_mast" % pname, 0.12, h, Vector3(pos.x, pos.y + h * 0.5, pos.z), poles_node, mat_clay)
	# Crossarms
	_box("%s_arm1" % pname, Vector3(1.65, 0.12, 0.12), Vector3(pos.x, pos.y + h - 0.4, pos.z), poles_node, mat_clay)
	_box("%s_arm2" % pname, Vector3(1.45, 0.12, 0.12), Vector3(pos.x, pos.y + h - 1.0, pos.z), poles_node, mat_clay)
	# Insulator pegs
	for ix in [-0.55, -0.2, 0.2, 0.55]:
		_cylinder("%s_ins" % pname, 0.04, 0.14, Vector3(pos.x + ix, pos.y + h - 0.3, pos.z), poles_node, mat_clay)

# ── DEAD TREES ──

func _build_dead_trees() -> void:
	print("  [6/8] Growing dead bare trees...")
	var tree_positions := [
		Vector3(-5.8, 0.0, -36.0),   # Street 1 south
		Vector3(5.5, 0.0, -10.0),    # Street 1 mid
		Vector3(-2.0, 0.0, 8.0),     # Near staircase
		Vector3(25.0, 0.0, 3.5),     # Street 2 east
		Vector3(-20.0, 3.2, 22.5),   # Street 3 upper
	]
	for i in range(tree_positions.size()):
		_dead_tree("Tree_%d" % i, tree_positions[i], 4.5 + randf() * 2.0)

func _dead_tree(tname: String, pos: Vector3, height: float) -> void:
	# Trunk
	_cylinder("%s_trunk" % tname, 0.18, height * 0.7,
		Vector3(pos.x, pos.y + height * 0.35, pos.z), props_node, mat_clay)
	
	# Main branches (4 directions)
	var branch_y := pos.y + height * 0.65
	var seed_offset := int(pos.x * 7 + pos.z * 13)
	for b in range(4):
		var angle := (float(b) / 4.0) * TAU + float(seed_offset % 10) * 0.1
		var reach := 1.2 + float((seed_offset + b) % 5) * 0.3
		var bx := cos(angle) * reach
		var bz := sin(angle) * reach
		var by := 0.5 + float((seed_offset + b * 3) % 4) * 0.25
		
		# Branch as angled cylinder approximation (thin box)
		var branch_len := Vector3(bx, by, bz).length()
		var mid := Vector3(pos.x + bx * 0.5, branch_y + by * 0.5, pos.z + bz * 0.5)
		_box("%s_b%d" % [tname, b], Vector3(0.08, 0.08, branch_len),
			mid, props_node, mat_clay, rad_to_deg(angle))
		
		# Sub-twigs
		var twig_end := Vector3(pos.x + bx, branch_y + by, pos.z + bz)
		for tw in range(2):
			var ta := angle + float(tw) * 1.2 - 0.6
			var tr := 0.5 + float(tw) * 0.3
			var twig_len := tr
			var tmid := Vector3(twig_end.x + cos(ta) * tr * 0.5, twig_end.y + 0.2, twig_end.z + sin(ta) * tr * 0.5)
			_box("%s_tw%d%d" % [tname, b, tw], Vector3(0.04, 0.04, twig_len),
				tmid, props_node, mat_clay, rad_to_deg(ta))

# ── PROPS & RUBBLE ──

func _build_props_and_rubble() -> void:
	print("  [7/8] Scattering props, crates, pallets, rubble, and barriers...")
	
	# Stacked crates near staircase
	_crate_cluster("Crates_S1", Vector3(-4.5, 0.0, 4.0))
	_crate_cluster("Crates_S2", Vector3(28.0, 0.0, -2.5))
	
	# Wooden pallets
	_pallet("Pallet_1", Vector3(-5.0, 0.0, -8.0), 18.0)
	_pallet("Pallet_2", Vector3(4.2, 0.0, -20.0), -25.0)
	_pallet("Pallet_3", Vector3(20.0, 0.0, 2.5), 42.0)
	
	# Jersey barriers (concrete traffic barriers)
	_box("Barrier_1", Vector3(0.5, 0.8, 2.0), Vector3(1.8, 0.4, -25.0), props_node, mat_clay, 12.0)
	_box("Barrier_2", Vector3(0.5, 0.8, 2.0), Vector3(-1.8, 0.4, -25.0), props_node, mat_clay, -8.0)
	_box("Barrier_3", Vector3(0.5, 0.8, 2.0), Vector3(8.0, 0.4, -2.5), props_node, mat_clay, 90.0)
	_box("Barrier_4", Vector3(0.5, 0.8, 2.0), Vector3(-15.0, 3.6, 15.5), props_node, mat_clay, 5.0)
	
	# Rubble scatter near cars
	_rubble_scatter("Rubble_Car1", Vector3(-1.8, 0.0, -32.0), 10)
	_rubble_scatter("Rubble_Car2", Vector3(1.5, 0.0, -28.0), 12)
	_rubble_scatter("Rubble_TJunction", Vector3(5.0, 0.0, 0.0), 8)
	_rubble_scatter("Rubble_S3", Vector3(-18.0, 3.2, 17.5), 6)

func _crate_cluster(cname: String, pos: Vector3) -> void:
	var boxes_data := [
		[Vector3(0.8, 0.7, 0.8), Vector3(0, 0.35, 0), 6.0],
		[Vector3(0.75, 0.65, 0.75), Vector3(0.05, 1.03, 0.05), -8.0],
		[Vector3(0.6, 0.55, 0.6), Vector3(0.8, 0.28, 0.1), 14.0],
		[Vector3(0.5, 0.5, 0.7), Vector3(0.75, 0.78, 0.08), -12.0],
		[Vector3(0.7, 0.6, 0.7), Vector3(-0.75, 0.30, -0.1), 4.0],
	]
	for i in range(boxes_data.size()):
		var bd: Array = boxes_data[i]
		var sz: Vector3 = bd[0]
		var off: Vector3 = bd[1]
		var ry: float = bd[2]
		_box("%s_box%d" % [cname, i], sz, pos + off, props_node, mat_clay, ry)

func _pallet(pname: String, pos: Vector3, rot_y: float) -> void:
	# 3 runners
	for rx in [-0.45, 0.0, 0.45]:
		_box("%s_run" % pname, Vector3(0.08, 0.09, 1.1),
			Vector3(pos.x + rx, pos.y + 0.045, pos.z), props_node, mat_clay, rot_y)
	# 4 deck slats
	for dy in [-0.4, -0.13, 0.13, 0.4]:
		_box("%s_slat" % pname, Vector3(1.0, 0.025, 0.13),
			Vector3(pos.x, pos.y + 0.10, pos.z + dy), props_node, mat_clay, rot_y)

func _rubble_scatter(rname: String, center: Vector3, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 17 + center.z * 31)
	for i in range(count):
		var dist := rng.randf_range(0.3, 2.0)
		var ang := rng.randf_range(0, TAU)
		var rx := center.x + cos(ang) * dist
		var rz := center.z + sin(ang) * dist
		var sz := Vector3(rng.randf_range(0.1, 0.25), rng.randf_range(0.06, 0.14), rng.randf_range(0.12, 0.28))
		_box("%s_%d" % [rname, i], sz, Vector3(rx, center.y + sz.y * 0.5, rz), props_node, mat_clay, rng.randf_range(0, 360))

# ── CAMERA & LIGHTING ──

func _setup_camera_and_lighting() -> void:
	print("  [8/8] Setting up camera and directional lighting...")
	
	# WorldEnvironment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.88, 0.89, 0.91, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76, 1.0)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.4
	
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	scene_root.add_child(world_env)
	world_env.owner = scene_root
	
	# Directional Sun Light
	var sun := DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.light_color = Color(1.0, 0.99, 0.97, 1.0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.shadow_bias = 0.01
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_split_1 = 0.35
	sun.directional_shadow_blend_splits = false
	sun.directional_shadow_max_distance = 65.0
	# Sun angle: from upper-right, casting diagonal shadows
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(42.0), 0)
	scene_root.add_child(sun)
	sun.owner = scene_root
	
	# Camera
	var cam := Camera3D.new()
	cam.name = "LayoutCamera"
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 44.0
	cam.far = 250.0
	cam.look_at_from_position(Vector3(-28.0, 32.0, -32.0), Vector3(3.0, 2.0, -4.0), Vector3.UP)
	scene_root.add_child(cam)
	cam.owner = scene_root
