extends Node
class_name ProceduralVegetation
## ProceduralVegetation.gd
## Procedurally generates dried grass bush clumps and distributes them
## using a single MultiMeshInstance3D (1 single draw call, zero FPS impact).
## Features arid straw khaki coloration, crossed-quad blade geometry,
## double-sided shading, and realistic raking sun shadow casting.

static func create_dried_grass_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.resource_name = "ProceduralDriedGrassMat"
	mat.albedo_color = Color(0.78, 0.68, 0.45, 1.0) # Arid straw / khaki
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Two-sided blades
	mat.roughness = 0.92
	mat.metallic_specular = 0.08
	return mat

static func generate_dried_grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var mat := create_dried_grass_material()
	st.set_material(mat)
	
	# Generate 5 intersecting vertical blades/quads in a radial cluster
	var blade_count := 5
	var rng := RandomNumberGenerator.new()
	rng.seed = 42819 # Fixed seed for consistent procedural geometry
	
	for b in range(blade_count):
		var base_angle: float = float(b) * (PI / float(blade_count)) + rng.randf_range(-0.12, 0.12)
		var dir := Vector2(cos(base_angle), sin(base_angle))
		var perp := Vector2(-dir.y, dir.x)
		
		var w_bottom: float = rng.randf_range(0.18, 0.24)
		var w_top: float = rng.randf_range(0.38, 0.48)
		var h: float = rng.randf_range(0.65, 0.95)
		var lean: Vector2 = dir * rng.randf_range(-0.08, 0.08)
		
		# 4 Vertices for each quad blade:
		# v0: bottom left, v1: bottom right, v2: top right, v3: top left
		var p0 := Vector3(-perp.x * w_bottom, 0.0, -perp.y * w_bottom)
		var p1 := Vector3(perp.x * w_bottom, 0.0, perp.y * w_bottom)
		var p2 := Vector3(perp.x * w_top + lean.x, h, perp.y * w_top + lean.y)
		var p3 := Vector3(-perp.x * w_top + lean.x, h, -perp.y * w_top + lean.y)
		
		var col_root := Color(0.42, 0.36, 0.22, 1.0) # Dark dried root
		var col_tip := Color(0.86, 0.76, 0.48, 1.0)  # Sun-bleached straw tip
		
		# Quad Normal
		var norm := Vector3(dir.x, 0.1, dir.y).normalized()
		
		# Triangle 1: p0 -> p1 -> p2
		st.set_normal(norm)
		st.set_color(col_root)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(p0)
		
		st.set_normal(norm)
		st.set_color(col_root)
		st.set_uv(Vector2(1.0, 0.0))
		st.add_vertex(p1)
		
		st.set_normal(norm)
		st.set_color(col_tip)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(p2)
		
		# Triangle 2: p0 -> p2 -> p3
		st.set_normal(norm)
		st.set_color(col_root)
		st.set_uv(Vector2(0.0, 0.0))
		st.add_vertex(p0)
		
		st.set_normal(norm)
		st.set_color(col_tip)
		st.set_uv(Vector2(1.0, 1.0))
		st.add_vertex(p2)
		
		st.set_normal(norm)
		st.set_color(col_tip)
		st.set_uv(Vector2(0.0, 1.0))
		st.add_vertex(p3)
		
	st.generate_tangents()
	return st.commit()

static func build_dried_grass_multimesh(instance_count: int = 160) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ProceduralDriedGrass"
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	var mesh := generate_dried_grass_mesh()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = instance_count
	
	# Generate realistic scattering positions along curbs, sidewalk crevices, walls, and debris
	var rng := RandomNumberGenerator.new()
	rng.seed = 98124
	
	var placed := 0
	
	# 1. Street 1 Curbs (Main North-South Avenue)
	for i in range(50):
		if placed >= instance_count:
			break
		var side: float = -3.8 if (i % 2 == 0) else 3.8
		var z: float = -32.0 + (float(i) * 1.3) + rng.randf_range(-0.4, 0.4)
		var x: float = side + rng.randf_range(-0.35, 0.35)
		_set_instance_transform(mm, placed, Vector3(x, 0.0, z), rng)
		placed += 1
		
	# 2. Street 2 Curbs (East Service Highway)
	for i in range(30):
		if placed >= instance_count:
			break
		var z_curb: float = -1.6 if (i % 2 == 0) else 3.6
		var x: float = 2.0 + (float(i) * 0.8) + rng.randf_range(-0.3, 0.3)
		var z: float = z_curb + rng.randf_range(-0.3, 0.3)
		_set_instance_transform(mm, placed, Vector3(x, 0.0, z), rng)
		placed += 1
		
	# 3. Upper Quarantine Terrace Curbs & Wall Baseboards (Elevated Y = 3.2m)
	for i in range(30):
		if placed >= instance_count:
			break
		var x: float = -22.0 + rng.randf_range(0.0, 13.0)
		var z: float = -32.0 + (float(i) * 1.0) + rng.randf_range(-0.4, 0.4)
		_set_instance_transform(mm, placed, Vector3(x, 3.2, z), rng)
		placed += 1
		
	# 4. Retaining Wall baseboards (Ground level Y = 0.0, X = -8.2)
	for i in range(20):
		if placed >= instance_count:
			break
		var z: float = -32.0 + (float(i) * 1.6) + rng.randf_range(-0.3, 0.3)
		_set_instance_transform(mm, placed, Vector3(-8.2 + rng.randf_range(0.1, 0.4), 0.0, z), rng)
		placed += 1
		
	# 5. Parking Lot & Barricade Corners
	for i in range(instance_count - placed):
		var x := rng.randf_range(8.0, 22.0)
		var z := rng.randf_range(16.0, 32.0)
		_set_instance_transform(mm, placed, Vector3(x, 0.0, z), rng)
		placed += 1
		
	mmi.multimesh = mm
	return mmi

static func _set_instance_transform(mm: MultiMesh, idx: int, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var t := Transform3D()
	var rot_y: float = rng.randf_range(0.0, TAU)
	var scale_factor: float = rng.randf_range(0.8, 1.35)
	var tilt_x: float = rng.randf_range(-0.06, 0.06)
	var tilt_z: float = rng.randf_range(-0.06, 0.06)
	
	var basis := Basis()
	basis = basis.rotated(Vector3.UP, rot_y)
	basis = basis.rotated(Vector3.RIGHT, tilt_x)
	basis = basis.rotated(Vector3.FORWARD, tilt_z)
	basis = basis.scaled(Vector3.ONE * scale_factor)
	
	t.basis = basis
	t.origin = pos
	mm.set_instance_transform(idx, t)
