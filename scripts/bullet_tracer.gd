extends Node3D
class_name BulletTracer

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func init(start_pos: Vector3, end_pos: Vector3) -> void:
	var dir := end_pos - start_pos
	var dist := dir.length()
	
	global_position = start_pos + (dir * 0.5)
	if dist > 0.001:
		look_at(end_pos, Vector3.UP)
		mesh_instance.scale = Vector3(1.0, 1.0, dist)
	
	var tween := create_tween()
	tween.tween_property(mesh_instance, "transparency", 1.0, 0.08)
	tween.tween_callback(queue_free)
