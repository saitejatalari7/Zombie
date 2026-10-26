extends Node3D
class_name ObjectiveCase
## ObjectiveCase.gd
## High-value flight recorder case modeled in Blender with pulsing beacon LED.
## Picking it up secures mission critical data, applies a -15% movement encumbrance,
## and directs the player to reach extraction LZ.

signal case_secured(player: Player)

var age: float = 0.0
var is_secured: bool = false

@onready var beacon_light: OmniLight3D = get_node_or_null("OmniLight3D") as OmniLight3D
@onready var pickup_area: Area3D = $PickupArea

func _ready() -> void:
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)
	add_to_group("objectives")

func _process(delta: float) -> void:
	age += delta
	# Pulsing emergency beacon signal
	if beacon_light:
		beacon_light.light_energy = 1.0 + sin(age * 6.0) * 1.8

func _on_body_entered(body: Node) -> void:
	if is_secured:
		return
	if body is Player:
		secure_case(body as Player)

func secure_case(player: Player) -> void:
	is_secured = true
	player.set_carrying_objective(true)
	
	# Update HUD and GameManager
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_mission_status"):
		hud.set_mission_status("DATA SECURED - EVAC TO LZ", Color(1.0, 0.8, 0.1))
	elif hud and hud.has_method("show_powerup_banner"):
		hud.show_powerup_banner("FLIGHT RECORDER SECURED (-15% SPEED)")
		
	var gm = get_node_or_null("/root/GameManager")
	if gm and "collected_samples" in gm:
		gm.collected_samples += 1
		
	emit_signal("case_secured", player)
	
	# Small camera bump
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.12)
		
	queue_free()
