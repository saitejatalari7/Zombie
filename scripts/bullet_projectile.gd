extends Node3D
class_name BulletProjectile
## BulletProjectile.gd
## High-velocity kinetic bullet with multi-target penetration,
## hyper-burst crimson tracers, crit multipliers, and wall blood splatters.

@export var speed: float = 68.0
@export var damage: float = 120.0
@export var max_lifetime: float = 0.55

var direction: Vector3 = Vector3.FORWARD
var target_claimed: Node3D = null
var distance_traveled: float = 0.0
var max_distance: float = 32.0
var age: float = 0.0

var penetration: int = 1
var is_hyper_burst: bool = false
var is_crit: bool = false
var hit_entities: Array[Node3D] = []

var impact_scene := preload("res://scenes/bullet_impact.tscn")

func init(spawn_pos: Vector3, shoot_dir: Vector3, p_target: Node3D = null, p_penetration: int = 1, p_is_hyper: bool = false, p_is_crit: bool = false) -> void:
	global_position = spawn_pos
	direction = shoot_dir.normalized()
	target_claimed = p_target
	penetration = p_penetration
	is_hyper_burst = p_is_hyper
	is_crit = p_is_crit
	
	if is_hyper_burst:
		speed = 82.0
		# Tint mesh or tracer to crimson
		var mesh_inst: MeshInstance3D = find_child("MeshInstance3D", true, false)
		if mesh_inst:
			mesh_inst.modulate = Color(1.0, 0.08, 0.15, 1.0)
	
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	age += delta
	if age > max_lifetime:
		queue_free()
		return
	
	var step_distance := speed * delta
	var current_pos := global_position
	var next_pos := current_pos + (direction * step_distance)
	
	# Raycast check for collision
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(current_pos, next_pos)
	query.collision_mask = 3 # Layer 1 (Environment) + Layer 2 (Zombies)
	
	var exclude_rids: Array[RID] = []
	for e in hit_entities:
		if is_instance_valid(e) and e.has_method("get_rid"):
			exclude_rids.append(e.get_rid())
	query.exclude = exclude_rids
	
	var result := space.intersect_ray(query)
	
	if result:
		var collider: Object = result.collider
		if collider and collider.is_in_group("zombies"):
			_on_hit_zombie(collider as Node3D, result.position)
			global_position = result.position + (direction * 0.15)
			if penetration <= 0:
				return
		else:
			_on_hit_world(result.position, result.normal, collider)
			return
	
	# Continue flight
	global_position = next_pos
	distance_traveled += step_distance
	if distance_traveled >= max_distance:
		queue_free()

func _on_hit_zombie(zombie: Node3D, hit_pos: Vector3) -> void:
	if hit_entities.has(zombie):
		return
	hit_entities.append(zombie)
	
	var final_damage := damage * (2.0 if is_crit else 1.0)
	var knockback_force := direction * (35.0 if is_hyper_burst else 22.0)
	
	if zombie.has_method("take_damage"):
		zombie.take_damage(final_damage, knockback_force)
	
	# Spawn impact spark burst from pool
	if BloodManager.instance:
		BloodManager.instance.spawn_impact(hit_pos, -direction)
	
	penetration -= 1
	if penetration <= 0:
		queue_free()

func _on_hit_world(hit_pos: Vector3, normal: Vector3, collider: Object) -> void:
	if collider and collider.has_method("take_damage"):
		collider.take_damage(damage, direction * 20.0)
	
	# Spawn impact spark burst from pool
	if BloodManager.instance:
		BloodManager.instance.spawn_impact(hit_pos, normal)
	
	queue_free()
