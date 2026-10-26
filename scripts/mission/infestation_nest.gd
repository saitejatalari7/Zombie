extends StaticBody3D
class_name InfestationNest
## InfestationNest.gd
## A Crimson hive: a pulsing growth that births the dead until it's burned out.
## Three sizes, each its own shape (rebuilt from a seed, so no two look alike):
##   S  pod cluster  — quick to burst, a trickle of shamblers
##   M  nest         — tendrils, defenders include runners
##   L  mound        — a spired mound; screams up runners and a heavy as it breaks
## Once shot it is "alerted": it births faster, and every 25% of its health lost it
## screams a burst of defenders. Bullets damage it (take_damage on a world collider),
## rockets hit it through "destructible", auto-aim finds it through "bosses".

signal destroyed()
signal hive_killed(size_class: String, hive: InfestationNest)

const SIZES := {
	"S": {"health": 2500.0, "radius": 0.9, "height": 1.3, "interval": 5.0, "alerted": 3.0, "nearby": 4,
		"burst": ["shambler", "shambler"]},
	"M": {"health": 6000.0, "radius": 1.5, "height": 2.0, "interval": 4.0, "alerted": 2.2, "nearby": 6,
		"burst": ["shambler", "runner", "shambler"]},
	"L": {"health": 14000.0, "radius": 2.4, "height": 3.4, "interval": 3.2, "alerted": 1.6, "nearby": 9,
		"burst": ["runner", "shambler", "runner", "shambler", "runner"]},
}

var size_class: String = "M"
## Sector toughness multiplier, set before the hive enters the tree
var hp_scale: float = 1.0
var max_health: float = 6000.0
var health: float = 6000.0
var is_dead: bool = false
var spawner: ZombieSpawner = null

var _cfg: Dictionary = {}
var _spawn_timer: float = 2.0
var _alerted: bool = false
var _next_burst: float = 0.75   # health fraction that triggers the next defender burst
var _heavy_sent: bool = false
var _age: float = 0.0
var _blobs: Array[MeshInstance3D] = []
var _blob_mat: StandardMaterial3D = null
var _bar_fill: MeshInstance3D = null
var _bar_root: Node3D = null


func _ready() -> void:
	add_to_group("destructible")
	add_to_group("bosses")
	add_to_group("hives")
	collision_layer = 1
	collision_mask = 0
	_cfg = SIZES.get(size_class, SIZES["M"])
	max_health = float(_cfg["health"]) * hp_scale
	health = max_health
	var r: float = _cfg["radius"]
	var h: float = _cfg["height"]

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = r * 0.85
	shape.height = h
	col.shape = shape
	col.position = Vector3(0.0, h * 0.5, 0.0)
	add_child(col)
	_build_look(r, h)
	_build_bar(h)


func _build_look(r: float, h: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(global_position.x * 73.0 + global_position.z * 131.0)) + size_class.unicode_at(0)
	rotation.y = rng.randf() * TAU

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.22, 0.04, 0.05)
	base_mat.roughness = 0.4
	_blob_mat = StandardMaterial3D.new()
	_blob_mat.albedo_color = Color(0.72, 0.0, 0.05)
	_blob_mat.roughness = 0.18
	_blob_mat.emission_enabled = true
	_blob_mat.emission = Color(0.6, 0.0, 0.04)
	_blob_mat.emission_energy_multiplier = 0.6

	# Fleshy footprint the growth sits in
	_add_mesh(_cyl(r * 0.75, r * 1.15, 0.3), base_mat, Vector3(0.0, 0.15, 0.0), false)
	match size_class:
		"S":
			# A clutch of pods
			for i in range(rng.randi_range(4, 6)):
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.1, r * 0.6)
				var pr := rng.randf_range(0.25, 0.45)
				_add_mesh(_sphere(pr), _blob_mat, Vector3(cos(a) * d, 0.25 + pr * 0.8, sin(a) * d), true)
		"M":
			# A swollen core with lobes and a few curled tendrils
			_add_mesh(_sphere(r * 0.45), _blob_mat, Vector3(0.0, h * 0.42, 0.0), true)
			for i in range(rng.randi_range(4, 6)):
				var a := float(i) / 5.0 * TAU + rng.randf_range(-0.3, 0.3)
				var lr := rng.randf_range(0.28, 0.45)
				_add_mesh(_sphere(lr), _blob_mat, Vector3(cos(a) * r * 0.5, 0.3 + lr * 0.6, sin(a) * r * 0.5), true)
			for i in range(3):
				var a := rng.randf() * TAU
				var t := MeshInstance3D.new()
				t.mesh = _cyl(0.0, 0.12, h * rng.randf_range(0.7, 1.0))
				t.material_override = base_mat
				t.position = Vector3(cos(a) * r * 0.55, h * 0.45, sin(a) * r * 0.55)
				t.rotation = Vector3(rng.randf_range(-0.5, 0.5), 0.0, rng.randf_range(-0.5, 0.5))
				add_child(t)
		_:
			# The mound: a spire of stacked sacs, a ring of lobes and bone-dark spikes
			var y := 0.3
			var sr := r * 0.42
			for i in range(3):
				_add_mesh(_sphere(sr), _blob_mat, Vector3(rng.randf_range(-0.15, 0.15), y + sr, rng.randf_range(-0.15, 0.15)), true)
				y += sr * 1.4
				sr *= 0.72
			for i in range(8):
				var a := float(i) / 8.0 * TAU
				var lr := rng.randf_range(0.4, 0.7)
				_add_mesh(_sphere(lr), _blob_mat, Vector3(cos(a) * r * 0.62, 0.25 + lr * 0.5, sin(a) * r * 0.62), true)
			for i in range(rng.randi_range(5, 7)):
				var a := rng.randf() * TAU
				var spike := MeshInstance3D.new()
				spike.mesh = _cyl(0.0, 0.2, rng.randf_range(1.2, 2.2))
				spike.material_override = base_mat
				spike.position = Vector3(cos(a) * r * 0.8, 0.7, sin(a) * r * 0.8)
				spike.rotation = Vector3(sin(a) * 0.6, 0.0, -cos(a) * 0.6)
				add_child(spike)


## Health bar floating over the hive (billboarded quads, unshaded).
func _build_bar(h: float) -> void:
	_bar_root = Node3D.new()
	_bar_root.position = Vector3(0.0, h + 0.9, 0.0)
	add_child(_bar_root)
	var width := 1.2 + float(_cfg["radius"])
	var bg := MeshInstance3D.new()
	var bgq := QuadMesh.new()
	bgq.size = Vector2(width + 0.1, 0.26)
	bg.mesh = bgq
	bg.material_override = _bar_mat(Color(0.05, 0.05, 0.06, 0.85), 0)
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(bg)
	_bar_fill = MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(width, 0.16)
	_bar_fill.mesh = fq
	_bar_fill.material_override = _bar_mat(Color(1.0, 0.2, 0.28), 1)
	_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar_root.add_child(_bar_fill)
	_bar_root.visible = false  # appears once the hive is hit


func _bar_mat(color: Color, priority: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.no_depth_test = true
	m.render_priority = priority
	return m


func _add_mesh(mesh: Mesh, mat: Material, pos: Vector3, pulses: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	if pulses:
		_blobs.append(mi)


func _sphere(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _cyl(top: float, bottom: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = 10
	return c


func _process(delta: float) -> void:
	if is_dead:
		return
	_age += delta
	var speed := 5.0 if _alerted else 3.0
	for i in range(_blobs.size()):
		var pulse := 1.0 + sin(_age * speed + float(i) * 1.7) * (0.12 if _alerted else 0.08)
		_blobs[i].scale = Vector3.ONE * pulse

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = float(_cfg["alerted"] if _alerted else _cfg["interval"])
		if spawner and _zombies_nearby() < int(_cfg["nearby"]):
			_spawn_one("runner" if _alerted and randf() < 0.3 else "shambler")


func _spawn_one(kind: String) -> void:
	var angle := randf() * TAU
	var dist := float(_cfg["radius"]) + 1.2
	spawner.spawn_zombie_at(global_position + Vector3(cos(angle), 0.0, sin(angle)) * dist, kind)


func _spawn_flanker(kind: String) -> bool:
	if FlowField.instance == null or spawner == null or not is_instance_valid(spawner.player):
		return false
	var pos = FlowField.instance.flank_point(spawner.player.global_position, 9.0, 12.0)
	if pos == null:
		return false
	spawner.spawn_zombie_at(pos, kind)
	return true


func _zombies_nearby() -> int:
	var count := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and not z.is_dead and global_position.distance_to((z as Node3D).global_position) < 9.0:
			count += 1
	return count


func take_damage(amount: float, _impulse: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	health -= amount
	if not _alerted:
		_alerted = true
		_spawn_timer = minf(_spawn_timer, 0.6)
		_bar_root.visible = true
	_blob_mat.emission_energy_multiplier = 2.5
	create_tween().tween_property(_blob_mat, "emission_energy_multiplier", 1.0, 0.15)
	var frac := maxf(health / max_health, 0.0)
	_bar_fill.scale.x = maxf(frac, 0.001)
	# Scream: a burst of defenders at every 25% lost
	while frac <= _next_burst and _next_burst > 0.0 and spawner:
		_next_burst -= 0.25
		# Half the scream comes out of the hive, half closes in on the shooter from the sides
		var k := 0
		for kind in _cfg["burst"]:
			if k % 2 == 1 and _spawn_flanker(String(kind)):
				pass
			else:
				_spawn_one(String(kind))
			k += 1
		if size_class == "L" and not _heavy_sent and frac <= 0.5:
			_heavy_sent = true
			_spawn_one("tank")
	if health <= 0.0:
		_die()


func _die() -> void:
	is_dead = true
	remove_from_group("bosses")
	remove_from_group("hives")
	var r: float = _cfg["radius"]
	if BloodManager.instance:
		BloodManager.instance.spawn_thick_viscous_blood(global_position, Vector3.UP)
		BloodManager.instance.spawn_splatter(global_position + Vector3(0.0, 0.05, 0.0), Vector3.UP, 2.5 * r, true)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.2 + 0.1 * r)
	destroyed.emit()
	hive_killed.emit(size_class, self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.3, 0.1, 1.3), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
