extends Area3D
class_name IntelPickup
## IntelPickup.gd
## An optional intel document (lore + a research core). Walk over it to read it.

signal collected(intel_id: String)

var intel_id: String = ""
var _age: float = 0.0
var _visual: Node3D = null


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.1
	col.shape = shape
	col.position = Vector3(0.0, 0.5, 0.0)
	add_child(col)

	_visual = Node3D.new()
	add_child(_visual)
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.96, 0.96, 0.97)
	paper.emission_enabled = true
	paper.emission = Color(0.9, 0.9, 1.0)
	paper.emission_energy_multiplier = 0.4
	var folder := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.42, 0.06, 0.3)
	folder.mesh = box
	folder.material_override = paper
	_visual.add_child(folder)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.77, 0.0, 0.05)
	var stripe := MeshInstance3D.new()
	var stripe_box := BoxMesh.new()
	stripe_box.size = Vector3(0.44, 0.07, 0.06)
	stripe.mesh = stripe_box
	stripe.material_override = stripe_mat
	_visual.add_child(stripe)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_age += delta
	_visual.position.y = 0.55 + sin(_age * 2.5) * 0.08
	_visual.rotation.y += delta * 1.2


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		AudioManager.play_sfx("intel_pickup", -1.0)
		collected.emit(intel_id)
		queue_free()
