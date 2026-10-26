extends StaticBody3D
class_name MilitaryCrate
## MilitaryCrate.gd
## Destructible crimson military supply crate modeled in Blender.
## Sustains bullet/blast damage and drops a guaranteed Tactical Supply Beacon upon destruction.

signal destroyed(pos: Vector3)

@export var max_health: float = 120.0
@export var forced_powerup_type: int = -1 # -1 for random, or 0, 1, 2 for specific BeaconType

var current_health: float = 120.0
var is_broken: bool = false

var beacon_scene := preload("res://scenes/supply_beacon.tscn")
var explosion_scene := preload("res://scenes/rocket_explosion.tscn")

@onready var visual_root: Node3D = $ModelRoot

func _ready() -> void:
	current_health = max_health
	add_to_group("destructible")

func take_damage(amount: float, _impulse: Vector3 = Vector3.ZERO) -> void:
	if is_broken:
		return
		
	current_health = maxf(0.0, current_health - amount)
	
	# Damage shake feedback
	if visual_root:
		var orig_x := visual_root.position.x
		var tween := create_tween()
		tween.tween_property(visual_root, "position:x", orig_x + randf_range(-0.08, 0.08), 0.04)
		tween.tween_property(visual_root, "position:x", orig_x, 0.04)
		
	if current_health <= 0.0:
		destroy_crate()

func destroy_crate() -> void:
	if is_broken:
		return
	is_broken = true
	
	var drop_pos := global_position
	
	# Spawn destruction explosion
	var expl: Node3D = explosion_scene.instantiate()
	get_parent().add_child(expl)
	expl.global_position = drop_pos + Vector3(0, 0.5, 0)
	expl.scale = Vector3(0.7, 0.7, 0.7)
	
	# Spawn guaranteed tactical supply beacon
	var beacon: TacticalSupplyBeacon = beacon_scene.instantiate()
	get_parent().add_child(beacon)
	beacon.global_position = drop_pos
	
	if forced_powerup_type >= 0:
		beacon.setup(forced_powerup_type as TacticalSupplyBeacon.BeaconType)
	else:
		var types := [
			TacticalSupplyBeacon.BeaconType.HYPER_BURST,
			TacticalSupplyBeacon.BeaconType.HEAVY_ROCKET,
			TacticalSupplyBeacon.BeaconType.CRYO_STIM
		]
		beacon.setup(types.pick_random())
		
	emit_signal("destroyed", drop_pos)
	queue_free()
