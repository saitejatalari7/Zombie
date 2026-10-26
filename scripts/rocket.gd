extends Area3D
class_name Rocket

var speed: float = 22.0
var damage: float = 100.0
var blast_radius: float = 3.5
var direction: Vector3 = Vector3.FORWARD
var lifetime: float = 3.5
var age: float = 0.0
var wobble_seed: float = 0.0
var wobble_amount: float = 0.6

var is_heavy_launcher: bool = false

var explosion_scene := preload("res://scenes/rocket_explosion.tscn")

@onready var smoke_trail: GPUParticles3D = $SmokeTrail

func _ready() -> void:
	wobble_seed = randf_range(0.0, 100.0)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if smoke_trail:
		smoke_trail.emitting = true

func setup(p_direction: Vector3, p_wobble: float = 0.6, p_is_heavy: bool = false) -> void:
	direction = p_direction.normalized()
	wobble_amount = p_wobble
	is_heavy_launcher = p_is_heavy
	if is_heavy_launcher:
		speed = 28.0
		damage = 450.0
		blast_radius = 6.0
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	age += delta
	if age > lifetime:
		explode()
		return
	
	# Subtle sine-wave wobble for stylized mini-rocket feel
	var wobble_offset := transform.basis.x * sin(age * 18.0 + wobble_seed) * (wobble_amount * delta * 4.0)
	global_position += (direction * speed * delta) + wobble_offset

func _on_body_entered(_body: Node) -> void:
	explode()

func _on_area_entered(_area: Area3D) -> void:
	explode()

func explode() -> void:
	var hit_pos := global_position
	AudioManager.play_sfx_near("rocket_explode", hit_pos, 0.0 if is_heavy_launcher else -3.0, 0.05, 0.08)
	AudioManager.haptic_medium()
	
	# Spawn explosion VFX
	var expl: Node3D = explosion_scene.instantiate()
	get_parent().add_child(expl)
	expl.global_position = hit_pos
	if is_heavy_launcher:
		expl.scale = Vector3(2.0, 2.0, 2.0)
	
	# Blood splatters across nearby white geometry
	if BloodManager.instance:
		if is_heavy_launcher and BloodManager.instance.has_method("spawn_massive_blood_crater"):
			BloodManager.instance.spawn_massive_blood_crater(hit_pos, blast_radius)
		else:
			BloodManager.instance.spawn_blast_splatter(hit_pos, blast_radius, 8)
	
	# Screen shake
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.4 if is_heavy_launcher else 0.15)
	
	# Damage nearby zombies
	var tree := get_tree()
	if tree:
		var zombies := tree.get_nodes_in_group("zombies")
		for z in zombies:
			if is_instance_valid(z) and z is Node3D:
				var dist: float = hit_pos.distance_to(z.global_position)
				if dist <= blast_radius:
					var falloff: float = 1.0 - (dist / blast_radius)
					if z.has_method("take_damage"):
						var impulse_dir: Vector3 = (z.global_position - hit_pos).normalized()
						var impulse_force: Vector3
						if is_heavy_launcher:
							impulse_force = impulse_dir * (45.0 * falloff) + Vector3.UP * (10.0 * falloff)
						else:
							impulse_force = impulse_dir * (12.0 * falloff)
						z.take_damage(damage * falloff, impulse_force)
		
		# Also damage destructible gates/barricades in radius
		var destructibles := tree.get_nodes_in_group("destructible")
		for d in destructibles:
			if is_instance_valid(d) and d is Node3D:
				var dist: float = hit_pos.distance_to(d.global_position)
				if dist <= blast_radius:
					var falloff: float = 1.0 - (dist / blast_radius)
					if d.has_method("take_damage"):
						var impulse_dir: Vector3 = (d.global_position - hit_pos).normalized()
						var impulse_force: Vector3 = impulse_dir * ((30.0 if is_heavy_launcher else 15.0) * falloff)
						d.take_damage(damage * falloff, impulse_force)
	
	queue_free()
