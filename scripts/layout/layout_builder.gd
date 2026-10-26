extends RefCounted
class_name LayoutBuilder
## LayoutBuilder.gd
## Turns a layout plan (see tools/level_design/) into a playable sector.
## Every solid is an axis-aligned box: its mesh and its collider come from the
## same numbers, so what you see is exactly what you collide with (no convex hulls).
## Meshes are merged per material to keep draw calls low on mobile.
## This is the build half of the procedural generator: a generator only has to
## produce a plan in the same format.

const RAIL_HEIGHT := 0.8
const BLOCKER_HEIGHT := 2.2
const STAIR_STEPS := 16

const PROP_SCENES := {
	"car_a": "res://assets/models/props/wrecked_car_a.glb",
	"car_b": "res://assets/models/props/wrecked_car_b.glb",
	"car_c": "res://assets/models/props/wrecked_car_c.glb",
	"jersey": "res://assets/models/environment/jersey_barrier.glb",
	"pole": "res://assets/models/props/power_pole.glb",
	"lamp": "res://assets/models/props/streetlamp.glb",
	"tree_a": "res://assets/models/props/dead_tree_a.glb",
	"tree_b": "res://assets/models/props/dead_tree_b.glb",
	"crate": "res://assets/models/props/military_crate.glb",
}
## Tall, thin props only get a trunk collider instead of their full bounds
const THIN_PROPS := ["pole", "lamp", "tree_a", "tree_b"]

var _root: Node3D
var _body: StaticBody3D
var _tools: Dictionary = {}       # material key -> SurfaceTool
var _materials: Dictionary = {}   # material key -> Material
var _box_meshes: Dictionary = {}  # size -> BoxMesh (reused for identical sizes)


static func build(plan: Dictionary, root: Node3D) -> void:
	var builder := LayoutBuilder.new()
	builder._build(plan, root)


func _build(plan: Dictionary, root: Node3D) -> void:
	_root = root
	_init_materials()
	_body = StaticBody3D.new()
	_body.name = "LayoutCollision"
	root.add_child(_body)

	_build_ground()
	for f in plan.get("floors", []):
		_build_floor(f)
	for s in plan.get("stairs", []):
		_build_stairs(s)
	for b in plan.get("blocks", []):
		_build_block(b)
	for seg in plan.get("barriers", []):
		_build_barrier(seg)
	_commit_meshes()
	_build_props(plan.get("props", []))
	_build_markers(plan.get("markers", {}), plan.get("marker_names", {}))


# ─── Materials ────────────────────────────────────────────────────────────────
func _init_materials() -> void:
	_materials["clay"] = load("res://assets/materials/mat_white_clay.tres")
	_materials["street"] = load("res://assets/materials/mat_street_floor.tres")
	_materials["wall"] = load("res://assets/materials/mat_grey_wall.tres")
	_materials["ground"] = _color_mat(Color(0.80, 0.80, 0.83))
	_materials["paving"] = _color_mat(Color(0.88, 0.88, 0.90))
	_materials["window"] = _color_mat(Color(0.18, 0.18, 0.20), 0.92)
	_materials["container"] = _color_mat(Color(0.55, 0.58, 0.62), 0.7)
	_materials["container_top"] = _color_mat(Color(0.44, 0.47, 0.51), 0.7)
	_materials["planter"] = _color_mat(Color(0.78, 0.78, 0.81))
	_materials["soil"] = _color_mat(Color(0.36, 0.35, 0.34), 0.95)
	_materials["sandbag"] = _color_mat(Color(0.64, 0.62, 0.57), 0.95)
	_materials["rail"] = _color_mat(Color(0.30, 0.31, 0.35), 0.6)
	_materials["stripe"] = _color_mat(Color(0.72, 0.0, 0.04), 0.5)


func _color_mat(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m


# ─── Geometry helpers ─────────────────────────────────────────────────────────
## Adds a visible box (merged into the material's mesh). Center is in world/sector space.
func _box(mat_key: String, size: Vector3, center: Vector3) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
		return
	var key := "%.3f,%.3f,%.3f" % [size.x, size.y, size.z]
	if not _box_meshes.has(key):
		var bm := BoxMesh.new()
		bm.size = size
		_box_meshes[key] = bm
	if not _tools.has(mat_key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tools[mat_key] = st
	(_tools[mat_key] as SurfaceTool).append_from(_box_meshes[key], 0, Transform3D(Basis(), center))


## Adds a box collider with the exact same dimensions as its visual.
func _collider(size: Vector3, center: Vector3) -> void:
	if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
		return
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = center
	_body.add_child(col)


func _solid(mat_key: String, size: Vector3, center: Vector3) -> void:
	_box(mat_key, size, center)
	_collider(size, center)


func _commit_meshes() -> void:
	for mat_key in _tools:
		var st: SurfaceTool = _tools[mat_key]
		var mi := MeshInstance3D.new()
		mi.name = "Layout_" + mat_key
		mi.mesh = st.commit()
		mi.material_override = _materials[mat_key]
		if mat_key in ["ground", "paving", "street", "soil"]:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # flat: shadows only cost
		_root.add_child(mi)
	_tools.clear()


# ─── Ground, floors, stairs ───────────────────────────────────────────────────
func _build_ground() -> void:
	# Huge slab so the camera never sees past the edge of the world
	_box("ground", Vector3(400.0, 0.2, 400.0), Vector3(0.0, -0.11, 0.0))
	_collider(Vector3(400.0, 1.0, 400.0), Vector3(0.0, -0.5, 0.0))


func _build_floor(f: Dictionary) -> void:
	var x0: float = f["x0"]
	var x1: float = f["x1"]
	var z0: float = f["z0"]
	var z1: float = f["z1"]
	var y: float = f["y"]
	var size_xz := Vector2(x1 - x0, z1 - z0)
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	if y > 0.01:
		# Raised floor (terrace): a solid mass from the ground up to the walking surface
		_box("clay", Vector3(size_xz.x, y, size_xz.y), Vector3(cx, y * 0.5, cz))
		_collider(Vector3(size_xz.x, y, size_xz.y), Vector3(cx, y * 0.5, cz))
	else:
		# Ground-level floors are paint on the ground slab (the ground collider is the floor)
		var mat_key := "street" if String(f["name"]) == "Avenue" else "paving"
		_box(mat_key, Vector3(size_xz.x, 0.03, size_xz.y), Vector3(cx, -0.01, cz))


func _build_stairs(s: Dictionary) -> void:
	var x0: float = s["x0"]
	var x1: float = s["x1"]
	var z0: float = s["z0"]
	var z1: float = s["z1"]
	var y0: float = s["y0"]
	var y1: float = s["y1"]
	var run := (z1 - z0) / float(STAIR_STEPS)
	var rise := (y1 - y0) / float(STAIR_STEPS)
	var w := x1 - x0
	var cx := (x0 + x1) * 0.5
	# Visible steps (climbing toward -Z)
	for i in range(STAIR_STEPS):
		var top := y0 + rise * float(i + 1)
		_box("clay", Vector3(w, top - y0, run), Vector3(cx, y0 + (top - y0) * 0.5, z1 - run * (float(i) + 0.5)))
	# One smooth ramp collider under the steps so nothing snags on step edges
	var ramp := ConvexPolygonShape3D.new()
	ramp.points = PackedVector3Array([
		Vector3(x0, y0, z1), Vector3(x1, y0, z1),
		Vector3(x0, y1, z0), Vector3(x1, y1, z0),
		Vector3(x0, y0, z0), Vector3(x1, y0, z0),
	])
	var col := CollisionShape3D.new()
	col.shape = ramp
	_body.add_child(col)


# ─── Blocks (buildings, walls, planters, containers, ...) ─────────────────────
func _build_block(b: Dictionary) -> void:
	var h: float = b["height"]
	if h <= 0.01:
		return
	var x0: float = b["x0"]
	var x1: float = b["x1"]
	var z0: float = b["z0"]
	var z1: float = b["z1"]
	var base: float = b["base"]
	var kind: String = b["kind"]
	var size := Vector3(x1 - x0, h, z1 - z0)
	var center := Vector3((x0 + x1) * 0.5, base + h * 0.5, (z0 + z1) * 0.5)
	var top := base + h

	match kind:
		"building", "shed":
			_solid("clay", size, center)
			_parapet(x0, x1, z0, z1, top, 0.5 if kind == "building" else 0.3)
			if kind == "building" and h > 4.0:
				_window_bands(x0, x1, z0, z1, base, top)
		"containers":
			_solid("container", size, center)
			_box("container_top", Vector3(size.x + 0.04, 0.12, size.z + 0.04), Vector3(center.x, top - 0.06, center.z))
			if h > 3.5:  # seam between the two stacked rows
				_box("container_top", Vector3(size.x + 0.04, 0.08, size.z + 0.04), Vector3(center.x, base + h * 0.5, center.z))
		"planter":
			_solid("planter", size, center)
			_box("soil", Vector3(size.x - 0.3, 0.05, size.z - 0.3), Vector3(center.x, top + 0.01, center.z))
		"cover":
			_solid("sandbag", size, center)
		"bus":
			_solid("clay", size, center)
			_box("window", Vector3(size.x + 0.06, 0.9, size.z - 1.0), Vector3(center.x, base + h * 0.62, center.z))
			_box("stripe", Vector3(size.x + 0.08, 0.18, size.z + 0.02), Vector3(center.x, base + h * 0.3, center.z))
		"retaining":
			_solid("clay", size, center)
		_:
			_solid("wall", size, center)


func _parapet(x0: float, x1: float, z0: float, z1: float, top: float, ph: float) -> void:
	var t := 0.25
	var w := x1 - x0
	var d := z1 - z0
	var y := top + ph * 0.5
	_box("clay", Vector3(w, ph, t), Vector3((x0 + x1) * 0.5, y, z0 + t * 0.5))
	_box("clay", Vector3(w, ph, t), Vector3((x0 + x1) * 0.5, y, z1 - t * 0.5))
	_box("clay", Vector3(t, ph, d - 2.0 * t), Vector3(x0 + t * 0.5, y, (z0 + z1) * 0.5))
	_box("clay", Vector3(t, ph, d - 2.0 * t), Vector3(x1 - t * 0.5, y, (z0 + z1) * 0.5))


## Dark recessed window strips on all four faces, one per storey.
func _window_bands(x0: float, x1: float, z0: float, z1: float, base: float, top: float) -> void:
	var w := x1 - x0
	var d := z1 - z0
	var y := base + 2.2
	while y < top - 1.2:
		_box("window", Vector3(w * 0.86, 1.1, 0.08), Vector3((x0 + x1) * 0.5, y, z0))
		_box("window", Vector3(w * 0.86, 1.1, 0.08), Vector3((x0 + x1) * 0.5, y, z1))
		_box("window", Vector3(0.08, 1.1, d * 0.86), Vector3(x0, y, (z0 + z1) * 0.5))
		_box("window", Vector3(0.08, 1.1, d * 0.86), Vector3(x1, y, (z0 + z1) * 0.5))
		y += 3.0


# ─── Barriers: railings at drop-offs, invisible blockers on top of low walls ──
func _build_barrier(seg: Dictionary) -> void:
	var x0: float = seg["x0"]
	var x1: float = seg["x1"]
	var z0: float = seg["z0"]
	var z1: float = seg["z1"]
	var y: float = seg["y"]
	var along_x := absf(z1 - z0) < 0.001
	var length := (x1 - x0) if along_x else (z1 - z0)
	if length <= 0.01:
		return
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var thin := 0.08
	if String(seg["kind"]) == "rail":
		var rail_size := Vector3(length, 0.06, thin) if along_x else Vector3(thin, 0.06, length)
		_box("rail", rail_size, Vector3(cx, y + RAIL_HEIGHT, cz))
		_box("rail", rail_size, Vector3(cx, y + RAIL_HEIGHT * 0.5, cz))
		var p := 0.0
		while p <= length + 0.001:  # posts every 2 m
			var post_pos := Vector3(x0 + p, y + RAIL_HEIGHT * 0.5, cz) if along_x else Vector3(cx, y + RAIL_HEIGHT * 0.5, z0 + p)
			_box("rail", Vector3(0.07, RAIL_HEIGHT, 0.07), post_pos)
			p += 2.0
	# Invisible collider tall enough that the player can't jump over (jump apex ~1.7 m)
	var col_size := Vector3(length, BLOCKER_HEIGHT, 0.2) if along_x else Vector3(0.2, BLOCKER_HEIGHT, length)
	_collider(col_size, Vector3(cx, y + BLOCKER_HEIGHT * 0.5, cz))


# ─── Props ─────────────────────────────────────────────────────────────────────
func _build_props(props: Array) -> void:
	var holder := Node3D.new()
	holder.name = "LayoutProps"  # not "Props": SectorBase would wrap those in convex hulls
	_root.add_child(holder)
	var counts := {}
	for p in props:
		var type: String = p["type"]
		if not PROP_SCENES.has(type):
			push_warning("[LayoutBuilder] Unknown prop type: %s" % type)
			continue
		var scene := load(PROP_SCENES[type]) as PackedScene
		if not scene:
			continue
		var node := scene.instantiate() as Node3D
		counts[type] = int(counts.get(type, 0)) + 1
		node.name = "%s_%d" % [type, counts[type]]
		var pos: Array = p["pos"]
		node.position = Vector3(pos[0], pos[1], pos[2])
		node.rotation_degrees.y = float(p["yaw"])
		holder.add_child(node)
		_add_prop_collider(node, type in THIN_PROPS)


## Box collider fitted to the prop's own meshes (or just its trunk for tall thin props).
func _add_prop_collider(prop: Node3D, thin: bool) -> void:
	var bounds := AABB()
	var first := true
	for mi in prop.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		if not mesh_inst.mesh:
			continue
		# Mesh transform relative to the prop (walks the parent chain; works before entering the tree)
		var local_xform := Transform3D()
		var n: Node = mesh_inst
		while n and n != prop:
			if n is Node3D:
				local_xform = (n as Node3D).transform * local_xform
			n = n.get_parent()
		var box: AABB = local_xform * mesh_inst.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if first:
		return
	var body := StaticBody3D.new()
	body.name = "PropCollider"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	if thin:
		shape.size = Vector3(0.4, bounds.size.y, 0.4)
		col.position = Vector3(0.0, bounds.get_center().y, 0.0)
	else:
		shape.size = bounds.size
		col.position = bounds.get_center()
	col.shape = shape
	body.add_child(col)
	prop.add_child(body)


# ─── Markers (spawns, objectives, LZ) ─────────────────────────────────────────
func _build_markers(markers: Dictionary, names: Dictionary) -> void:
	for group in markers:
		var points: Array = markers[group]
		if group == "PlayerSpawn":
			var spawn := Marker3D.new()
			spawn.name = "PlayerSpawn"
			spawn.position = _vec(points[0])
			_root.add_child(spawn)
		elif group == "ExtractionZone":
			var lz := Area3D.new()
			lz.name = "ExtractionZone"
			lz.position = _vec(points[0])
			var col := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(6.0, 4.0, 6.0)
			col.shape = shape
			col.position = Vector3(0.0, 1.0, 0.0)
			lz.add_child(col)
			_root.add_child(lz)
		else:
			var holder := Node3D.new()
			holder.name = group
			_root.add_child(holder)
			var group_names: Array = names.get(group, [])
			for i in range(points.size()):
				var m := Marker3D.new()
				m.name = group_names[i] if i < group_names.size() else "%s%d" % [group, i + 1]
				m.position = _vec(points[i])
				if group == "BloodDecor":
					m.set_meta("size", 2.6)
					m.set_meta("heavy", true)
				holder.add_child(m)


func _vec(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
