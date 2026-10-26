extends StaticBody3D
class_name WoodenBarricade

signal barricade_broken()

@export var max_health: float = 220.0
var current_health: float = 220.0
var is_broken: bool = false

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var planks_root: Node3D = $Planks

var impact_scene := preload("res://scenes/bullet_impact.tscn")

func _ready() -> void:
	add_to_group("destructible")
	current_health = max_health

func take_damage(amount: float, impulse: Vector3 = Vector3.ZERO) -> void:
	if is_broken:
		return
	
	current_health -= amount
	
	# Wood hit shake & splinter feedback
	var tween := create_tween()
	var shake_offset := Vector3(randf_range(-0.06, 0.06), 0, randf_range(-0.06, 0.06))
	tween.tween_property(planks_root, "position", shake_offset, 0.04)
	tween.tween_property(planks_root, "position", Vector3.ZERO, 0.06)
	
	if current_health <= 0.0:
		break_barricade(impulse)

func break_barricade(break_impulse: Vector3 = Vector3.ZERO) -> void:
	if is_broken:
		return
	is_broken = true
	emit_signal("barricade_broken")
	
	# Disable collision immediately so player and zombies can pass through
	collision_shape.set_deferred("disabled", true)
	
	# Explosive splinter shatter animation
	var dir := (break_impulse.normalized() if break_impulse.length() > 0.1 else Vector3.FORWARD)
	var tween := create_tween().set_parallel(true)
	
	var plank_nodes := planks_root.get_children()
	for p in plank_nodes:
		if p is Node3D:
			var rnd_yaw := randf_range(-1.2, 1.2)
			var rnd_dist := randf_range(1.5, 3.5)
			var target_p: Vector3 = p.position + (dir * rnd_dist) + Vector3(randf_range(-1, 1), randf_range(-0.5, 0.5), 0)
			tween.tween_property(p, "position", target_p, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(p, "rotation:y", rnd_yaw, 0.45)
			tween.tween_property(p, "scale", Vector3.ZERO, 0.55).set_delay(0.2)
	
	tween.chain().tween_callback(queue_free)
