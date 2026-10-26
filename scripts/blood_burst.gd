extends Node3D
class_name BloodBurst

@onready var particles: GPUParticles3D = $GPUParticles3D

func emit_burst(pos: Vector3) -> void:
	global_position = pos
	if particles:
		particles.restart()
