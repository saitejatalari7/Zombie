extends StaticBody3D
class_name InfestationNest
## InfestationNest.gd
## A pulsing crimson growth that keeps spawning shamblers until it's destroyed.
## Bullets damage it (take_damage on a world collider), rockets hit it through the
## "destructible" group, and auto-aim targets it through the "bosses" group.

signal destroyed()

const SPAWN_INTERVAL := 4.0
const MAX_NEARBY := 6  # stop spawning while this many zombies are already close

var max_health: float = 600.0
var health: float = 600.0
var is_dead: bool = false
var spawner: ZombieSpawner = null

var _spawn_timer: float = 2.0
var _age: float = 0.0
var _blobs: Array[MeshInstance3D] = []
var _blob_mat: StandardMaterial3D = null


func _ready() -> void:
	add_to_group("destructible")
	add_to_group("bosses")
	collision_layer = 1
	collision_mask = 0
	health = max_health

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.1
	shape.height = 1.6
	col.shape = shape
	col.position = Vector3(0.0, 0.8, 0.0)
	add_child(col)

	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.22, 0.04, 0.05)
	base_mat.roughness = 0.4
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 1.0
	base_mesh.bottom_radius = 1.5
	base_mesh.height = 0.35
	base.mesh = base_mesh
	base.material_override = base_mat
	base.position = Vector3(0.0, 0.17, 0.0)
	add_child(base)

	_blob_mat = StandardMaterial3D.new()
	_blob_mat.albedo_color = Color(0.72, 0.0, 0.05)
	_blob_mat.roughness = 0.18
	_blob_mat.emission_enabled = true
	_blob_mat.emission = Color(0.6, 0.0, 0.04)
	_blob_mat.emission_energy_multiplier = 0.6
	var offsets := [Vector3(0.0, 0.75, 0.0), Vector3(0.55, 0.5, 0.3), Vector3(-0.5, 0.45, -0.25), Vector3(0.1, 0.4, -0.6)]
	var radii := [0.6, 0.38, 0.42, 0.3]
	for i in range(offsets.size()):
		var blob := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radii[i]
		sphere.height = radii[i] * 2.0
		blob.mesh = sphere
		blob.material_override = _blob_mat
		blob.position = offsets[i]
		add_child(blob)
		_blobs.append(blob)


func _process(delta: float) -> void:
	if is_dead:
		return
	_age += delta
	for i in range(_blobs.size()):
		var pulse := 1.0 + sin(_age * 3.0 + float(i) * 1.7) * 0.08
		_blobs[i].scale = Vector3.ONE * pulse

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		if spawner and _zombies_nearby() < MAX_NEARBY:
			var angle := randf() * TAU
			spawner.spawn_zombie_at(global_position + Vector3(cos(angle), 0.0, sin(angle)) * 2.2)


func _zombies_nearby() -> int:
	var count := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and not z.is_dead and global_position.distance_to((z as Node3D).global_position) < 8.0:
			count += 1
	return count


func take_damage(amount: float, _impulse: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	health -= amount
	_blob_mat.emission_energy_multiplier = 2.5
	create_tween().tween_property(_blob_mat, "emission_energy_multiplier", 0.6, 0.15)
	if health <= 0.0:
		_die()


func _die() -> void:
	is_dead = true
	remove_from_group("bosses")
	if BloodManager.instance:
		BloodManager.instance.spawn_thick_viscous_blood(global_position, Vector3.UP)
		BloodManager.instance.spawn_splatter(global_position + Vector3(0.0, 0.05, 0.0), Vector3.UP, 3.5, true)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.25)
	destroyed.emit()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.3, 0.1, 1.3), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
