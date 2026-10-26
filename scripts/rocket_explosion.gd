extends Node3D
class_name RocketExplosion

@onready var shockwave_mesh: MeshInstance3D = $ShockwaveMesh
@onready var spark_particles: GPUParticles3D = $SparkParticles
@onready var blast_light: OmniLight3D = get_node_or_null("BlastLight") as OmniLight3D

func _ready() -> void:
	# Shockwave expansion tween
	shockwave_mesh.scale = Vector3(0.1, 0.1, 0.1)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(shockwave_mesh, "scale", Vector3(4.5, 0.1, 4.5), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(shockwave_mesh, "transparency", 1.0, 0.35)
	if blast_light:
		tween.tween_property(blast_light, "light_energy", 0.0, 0.25)
	
	if spark_particles:
		spark_particles.emitting = true
	
	get_tree().create_timer(1.2).timeout.connect(queue_free)
