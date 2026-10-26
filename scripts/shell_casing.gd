extends Node3D
class_name ShellCasing

var velocity: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO
var bounces: int = 0
var max_bounces: int = 2
var settled: bool = false
var lifetime: float = 1.6
var age: float = 0.0

func init(spawn_pos: Vector3, eject_dir: Vector3) -> void:
	global_position = spawn_pos
	# Eject to right and upward with random jitter
	velocity = (eject_dir.normalized() * randf_range(2.2, 3.8)) + (Vector3.UP * randf_range(2.6, 4.0))
	velocity += Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
	angular_velocity = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(18.0, 32.0)

func _physics_process(delta: float) -> void:
	age += delta
	if age > lifetime:
		queue_free()
		return
	
	if settled:
		set_physics_process(false)
		return
	
	velocity.y -= 22.0 * delta
	global_position += velocity * delta
	rotate_x(angular_velocity.x * delta)
	rotate_y(angular_velocity.y * delta)
	rotate_z(angular_velocity.z * delta)
	
	# Floor collision
	if global_position.y <= 0.03:
		global_position.y = 0.03
		bounces += 1
		if bounces <= max_bounces:
			velocity.y = -velocity.y * 0.42
			velocity.x *= 0.65
			velocity.z *= 0.65
			angular_velocity *= 0.5
		else:
			settled = true
			rotation.x = deg_to_rad(90.0) # lay flat
			velocity = Vector3.ZERO
			set_physics_process(false)
