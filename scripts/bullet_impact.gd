extends Node3D
class_name BulletImpact

@onready var particles: GPUParticles3D = $GPUParticles3D

func setup(impact_pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	emit_impact(impact_pos, normal)

func emit_impact(impact_pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	global_position = impact_pos
	if normal.length() > 0.1:
		if normal.abs().dot(Vector3.UP) < 0.99:
			look_at(impact_pos + normal, Vector3.UP)
		else:
			look_at(impact_pos + normal, Vector3.FORWARD)
	
	if particles:
		particles.restart()
