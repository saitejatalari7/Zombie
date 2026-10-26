extends Node3D
class_name TacticalSupplyBeacon
## TacticalSupplyBeacon.gd
## High-visibility tactical beacon dropped from red military crates or air drops.
## Emits a vertical volumetric light column and bestows mid-game combat power-ups.

enum BeaconType { HYPER_BURST, HEAVY_ROCKET, CRYO_STIM }

@export var beacon_type: BeaconType = BeaconType.HYPER_BURST

var age: float = 0.0
var is_collected: bool = false

@onready var light_beam: MeshInstance3D = $LightBeam
@onready var beacon_core: MeshInstance3D = $CoreMesh
@onready var beacon_light: OmniLight3D = get_node_or_null("OmniLight3D") as OmniLight3D
@onready var pickup_area: Area3D = $PickupArea

func _ready() -> void:
	if pickup_area:
		pickup_area.body_entered.connect(_on_body_entered)
	_apply_visual_theme()

func setup(p_type: BeaconType) -> void:
	beacon_type = p_type
	_apply_visual_theme()

func _apply_visual_theme() -> void:
	var color: Color
	match beacon_type:
		BeaconType.HYPER_BURST:
			color = Color(1.0, 0.06, 0.18, 0.85) # Crimson
		BeaconType.HEAVY_ROCKET:
			color = Color(1.0, 0.6, 0.05, 0.85) # Amber Orange
		BeaconType.CRYO_STIM:
			color = Color(0.1, 0.9, 1.0, 0.85) # Cyan Blue
			
	if light_beam and light_beam.mesh:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(color.r, color.g, color.b, 0.35)
		light_beam.material_override = mat
		
	if beacon_core:
		var mat_core := StandardMaterial3D.new()
		mat_core.albedo_color = Color(0.1, 0.1, 0.12, 1.0)
		mat_core.emission_enabled = true
		mat_core.emission = color
		mat_core.emission_energy_multiplier = 3.5
		beacon_core.material_override = mat_core
		
	if beacon_light:
		beacon_light.light_color = color
		beacon_light.light_energy = 2.4

func _process(delta: float) -> void:
	age += delta
	# Subtle spin and hover
	rotate_y(delta * 1.8)
	if beacon_core:
		beacon_core.position.y = 0.5 + sin(age * 3.5) * 0.12
	if light_beam:
		# Pulsing intensity
		var pulse: float = 0.85 + sin(age * 5.0) * 0.15
		light_beam.scale.x = pulse
		light_beam.scale.z = pulse

func _on_body_entered(body: Node) -> void:
	if is_collected:
		return
	if body is Player:
		collect(body as Player)

func collect(player: Player) -> void:
	is_collected = true
	match beacon_type:
		BeaconType.HYPER_BURST:
			player.activate_hyper_burst(15.0)
		BeaconType.HEAVY_ROCKET:
			player.equip_heavy_rocket_launcher(3)
		BeaconType.CRYO_STIM:
			player.activate_stim_boost(12.0)
			
	# Camera impulse / shockwave
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.18)
		
	# Floating notification popup if HUD exists
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_powerup_banner"):
		var title: String
		match beacon_type:
			BeaconType.HYPER_BURST: title = "HYPER-BURST OVERDRIVE (15S)"
			BeaconType.HEAVY_ROCKET: title = "HEAVY ROCKET LAUNCHER (3 RDS)"
			BeaconType.CRYO_STIM: title = "CRYO-STIM COCKTAIL (+50 HP / SPEED)"
		hud.show_powerup_banner(title)
		
	queue_free()
