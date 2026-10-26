extends Camera3D
class_name IsometricCameraFollow

@export var target: Node3D
@export var smooth_speed: float = 7.0
## Same viewing angle as the original (18, 60, 42) at 55 percent of the distance, so
## characters read on a phone. Level layouts depend only on this direction, not the distance.
@export var offset: Vector3 = Vector3(9.9, 33.0, 23.1)

var trauma: float = 0.0
var max_shake_offset: float = 0.10
var max_shake_roll: float = 0.008
var noise_seed: float = 0.0

func _ready() -> void:
	noise_seed = randf_range(0.0, 1000.0)
	call_deferred("_snap_to_target")

func _snap_to_target() -> void:
	if not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node3D
	if is_instance_valid(target):
		global_position = target.global_position + offset
		look_at(target.global_position + Vector3(0.0, 0.6, -2.2), Vector3.UP)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0] as Node3D
		return
	
	var desired_pos := target.global_position + offset
	global_position = global_position.lerp(desired_pos, delta * smooth_speed)
	look_at(target.global_position + Vector3(0.0, 0.6, -2.2), Vector3.UP)
	
	# Trauma decay & screen shake (quick recovery, subtle punch)
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 3.0)
		var shake := trauma * trauma
		noise_seed += delta * 30.0
		
		var shake_x := sin(noise_seed * 1.3) * max_shake_offset * shake
		var shake_y := cos(noise_seed * 1.7) * max_shake_offset * shake
		h_offset = shake_x
		v_offset = shake_y
		rotation.z += sin(noise_seed * 2.1) * max_shake_roll * shake
	else:
		h_offset = 0.0
		v_offset = 0.0

func add_trauma(amount: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and not gm.saved_screen_shake:
		return
	trauma = clampf(trauma + amount, 0.0, 1.0)
