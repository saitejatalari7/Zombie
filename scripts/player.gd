extends CharacterBody3D
class_name Player

signal health_changed(current: float, max_val: float)
signal super_blast_cooldown(ratio: float)
signal powerup_timer_changed(time_left: float, max_time: float)
signal powerup_activated(powerup_name: String, duration_or_ammo: float)
signal rocket_ammo_changed(current: int, max_val: int)
signal molotov_ammo_changed(current: int, max_val: int)
signal vault_state_changed(can_vault: bool)
signal auto_fire_toggled(enabled: bool)
signal died()
## Rounds left, magazine size, and reload progress (0 = not reloading, else 0..1 done)
signal ammo_changed(ammo: int, mag: int, reload_progress: float)

@export var move_speed: float = 5.4
@export var rifle_fire_rate: float = 0.11
@export var rifle_damage: float = 34.0
@export var super_blast_cooldown_time: float = 4.5
@export var auto_shoot_radius: float = 7.5 # Strict engagement radius (does not react outside this radius)
@export var bullet_count: int = 1 # Initial single-bullet firing (upgraded via hyper-burst or power-ups)

var range_ring: MeshInstance3D = null
var aim_arrow_indicator: AimTrajectoryArrow = null

var max_health: float = 100.0
var current_health: float = 100.0
var is_dead: bool = false

var can_fire_rifle: bool = true
var fire_timer: float = 0.0
# Magazine: the reload is the window hives and their defenders get to close in
const BASE_MAG_SIZE := 30
const RELOAD_TIME := 1.6
const IDLE_RELOAD_DELAY := 1.2   # nothing to shoot for this long and the mag is half empty: top up
var mag_size: int = BASE_MAG_SIZE
var mag_ammo: int = BASE_MAG_SIZE
var reload_timer: float = 0.0
var _idle_fire_time: float = 0.0
var super_blast_timer: float = 0.0

# Auto-fire and Twin-stick aiming
var auto_fire_enabled: bool = true  # one-thumb play by default; the HUD toggle turns it off
var mobile_aim_input: Vector2 = Vector2.ZERO
var sector_bounds: Rect2 = Rect2() # Dynamic sector boundary

# Dedicated 3-Charge Molotov System
var molotov_ammo: int = 3
var max_molotov_ammo: int = 3

# 15-Second Molotov Power-Up
var molotov_powerup_timer: float = 0.0
var molotov_powerup_max: float = 15.0
var is_molotov_active: bool = false
var molotov_shot_counter: int = 0
var molotov_cooldown: float = 0.0

# Phase 4 Mid-Game Power-Ups
var is_hyper_burst: bool = false
var hyper_burst_timer: float = 0.0
var hyper_burst_max: float = 15.0

var heavy_rocket_ammo: int = 0
var max_heavy_rocket_ammo: int = 3

var is_stim_active: bool = false
var stim_timer: float = 0.0
var stim_max: float = 12.0

var carrying_objective: bool = false
var objective_speed_mult: float = 1.0

# Operative skills (Crimson Berserker pair)
const SIPHON_FIRE_RATE_MULT := 0.8   # +25% fire rate (interval x 0.8) in fresh blood
const BERSERKER_KILLS_PER_MOLOTOV := 6
var has_blood_siphon: bool = false
var hemorrhage_rounds: bool = false   # read by Zombie.die() for wider death pools
var berserker_pair: bool = false
var in_blood: bool = false
var _blood_check_timer: float = 0.0
var _berserker_kills: int = 0

# Armory upgrades dynamic stats
var base_penetration: int = 1
var crit_chance: float = 0.0
var bonus_knockback: float = 1.0

# Crate Vault / Climb Mechanic
var can_vault: bool = false
var is_vaulting: bool = false
var vault_target_pos: Vector3 = Vector3.ZERO

# Shoulder Charge: the escape tool when the horde closes in (replaces the old always-on crowd shove)
const SHOULDER_CHARGE_COOLDOWN := 3.0
const SHOULDER_CHARGE_RADIUS := 2.2
var shoulder_charge_timer: float = 0.0

# Mobile/Virtual controls input vector
var mobile_move_input: Vector2 = Vector2.ZERO
var mobile_fire_pressed: bool = false
var mobile_jump_pressed: bool = false

# Jump physics
var jump_velocity: float = 9.2
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Visual nodes
@onready var visual_root: Node3D = $Visuals
@onready var rifle_mesh: Node3D = $Visuals/Rifle
@onready var muzzle_point: Marker3D = $Visuals/Rifle/Muzzle
@onready var launcher_muzzle: Marker3D = $Visuals/Launcher/Muzzle
@onready var torch_light: SpotLight3D = get_node_or_null("Visuals/TorchLight") as SpotLight3D
@onready var torch_ambient: OmniLight3D = get_node_or_null("TorchAmbient") as OmniLight3D
@onready var leg_left: Node3D = $Visuals.find_child("LegLeft", true, false) if has_node("Visuals") else null
@onready var leg_right: Node3D = $Visuals.find_child("LegRight", true, false) if has_node("Visuals") else null
@onready var arm_left: Node3D = $Visuals.find_child("ArmLeft", true, false) if has_node("Visuals") else null
@onready var arm_right: Node3D = $Visuals.find_child("ArmRight", true, false) if has_node("Visuals") else null

# Preloads
var bullet_projectile_scene := preload("res://scenes/bullet_projectile.tscn")
var shell_scene := preload("res://scenes/shell_casing.tscn")
var muzzle_scene := preload("res://scenes/muzzle_flash.tscn")
var rocket_scene := preload("res://scenes/rocket.tscn")
var molotov_scene := preload("res://scenes/molotov_projectile.tscn")
const AimTrajectoryArrow = preload("res://scripts/aim_trajectory_arrow.gd")

# Footprint tracking
var footprint_charges: int = 0
var distance_since_step: float = 0.0
var step_interval: float = 0.55
var left_foot_step: bool = false

# Reusable Muzzle Flash & Target Cache
var active_muzzle_flash: MuzzleFlash = null
var cached_target: Node3D = null
var target_cache_timer: float = 0.0

# Procedural run bobbing
var run_cycle: float = 0.0
# Leg rest positions from the model, so the stride animates around them (not a fixed height)
var leg_rest_left: Vector3 = Vector3.ZERO
var leg_rest_right: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Automatic Stair Climbing & Smooth slope gliding configuration
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(45.0)
	floor_stop_on_slope = true
	
	if leg_left:
		leg_rest_left = leg_left.position
	if leg_right:
		leg_rest_right = leg_right.position
	
	# Field Medbay outpost upgrade: bonus starting health
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		max_health += gm.get_medbay_health_bonus()
		current_health = max_health
	
	emit_signal("health_changed", current_health, max_health)
	emit_signal("super_blast_cooldown", 0.0)
	emit_signal("molotov_ammo_changed", molotov_ammo, max_molotov_ammo)
	emit_signal("vault_state_changed", false)
	emit_signal("auto_fire_toggled", auto_fire_enabled)
	
	# Initialize Flashlight & DayNightManager connection
	if torch_light == null:
		_build_torch()
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm:
		_on_lighting_mode_changed(dnm.is_night_mode())
		dnm.lighting_mode_changed.connect(_on_lighting_mode_changed)
	else:
		if torch_light: torch_light.visible = false
		if torch_ambient: torch_ambient.visible = false
	
	_apply_armory_upgrades()
	_apply_equipped_skills()
	
	# Instantiate reusable muzzle flash
	if muzzle_point and muzzle_scene:
		active_muzzle_flash = muzzle_scene.instantiate() as MuzzleFlash
		muzzle_point.add_child(active_muzzle_flash)
		active_muzzle_flash.position = Vector3.ZERO
		
	_setup_range_ring()
	_setup_aim_arrow()

## Weapon flashlight (a cone ahead of the operative) plus a soft glow around them, so the
## player and anything close stay readable at night. No shadows: cheap on mobile.
func _build_torch() -> void:
	var visuals := get_node_or_null("Visuals") as Node3D
	if visuals == null:
		return
	torch_light = SpotLight3D.new()
	torch_light.name = "TorchLight"
	torch_light.position = Vector3(0.0, 1.4, -0.3)
	torch_light.rotation_degrees = Vector3(-18.0, 0.0, 0.0)  # forward (-Z) and a little down
	torch_light.light_color = Color(1.0, 0.95, 0.82)
	torch_light.light_energy = 4.0
	torch_light.spot_range = 18.0
	torch_light.spot_angle = 34.0
	torch_light.spot_attenuation = 0.6
	torch_light.shadow_enabled = false
	visuals.add_child(torch_light)
	torch_ambient = OmniLight3D.new()
	torch_ambient.name = "TorchAmbient"
	torch_ambient.position = Vector3(0.0, 2.2, 0.0)
	torch_ambient.light_color = Color(0.85, 0.9, 1.0)
	torch_ambient.light_energy = 0.9
	torch_ambient.omni_range = 6.0
	torch_ambient.shadow_enabled = false
	add_child(torch_ambient)


func _on_lighting_mode_changed(is_night: bool) -> void:
	if torch_light:
		torch_light.visible = is_night
	if torch_ambient:
		torch_ambient.visible = is_night

func toggle_auto_fire() -> bool:
	auto_fire_enabled = not auto_fire_enabled
	emit_signal("auto_fire_toggled", auto_fire_enabled)
	if range_ring:
		range_ring.visible = auto_fire_enabled
	return auto_fire_enabled

func set_auto_fire(enabled: bool) -> void:
	auto_fire_enabled = enabled
	emit_signal("auto_fire_toggled", auto_fire_enabled)
	if range_ring:
		range_ring.visible = auto_fire_enabled

func _setup_range_ring() -> void:
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = auto_shoot_radius - 0.08
	ring_mesh.outer_radius = auto_shoot_radius
	ring_mesh.rings = 64
	ring_mesh.ring_segments = 4
	
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 0.85, 1.0, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mesh.material = mat
	
	range_ring = MeshInstance3D.new()
	range_ring.name = "AutoShootRangeRing"
	range_ring.mesh = ring_mesh
	range_ring.position = Vector3(0.0, 0.06, 0.0)
	range_ring.visible = auto_fire_enabled
	add_child(range_ring)

func _setup_aim_arrow() -> void:
	aim_arrow_indicator = AimTrajectoryArrow.new()
	aim_arrow_indicator.name = "AimTrajectoryArrow"
	aim_arrow_indicator.setup_player(self)
	add_child(aim_arrow_indicator)

func start_aiming_special(ability: String) -> bool:
	if not aim_arrow_indicator:
		return false
	if ability == "molotov" and molotov_ammo <= 0:
		return false
	if ability == "super_blast" and super_blast_timer > 0.0:
		return false
	
	var initial_dir := -transform.basis.z.normalized()
	var dist := 10.5
	if ability == "molotov":
		var cluster := find_densest_zombie_cluster(4.0, 16.0)
		if cluster != Vector3.ZERO and cluster.distance_to(global_position) > 1.0:
			initial_dir = (cluster - global_position).normalized()
			dist = clampf(cluster.distance_to(global_position), 4.0, 15.0)
	else:
		var target := get_best_target_with_los(14.0)
		if target:
			initial_dir = (target.global_position - global_position).normalized()
			dist = clampf(target.global_position.distance_to(global_position), 4.0, 15.0)
			
	aim_arrow_indicator.start_aiming(ability, initial_dir, dist)
	return true

func update_aim_special_vec(screen_vec: Vector2) -> void:
	if not aim_arrow_indicator or not aim_arrow_indicator.is_aiming:
		return
	if screen_vec.length() < 0.15:
		return
	var cam := get_viewport().get_camera_3d()
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	if cam:
		forward = -cam.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		right = cam.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
	var world_dir := (right * screen_vec.x + forward * (-screen_vec.y)).normalized()
	var dist := clampf(screen_vec.length() * 12.0, 3.5, 16.0)
	aim_arrow_indicator.update_aim(world_dir, dist)
	# Turn player towards aim direction
	rotation.y = atan2(-world_dir.x, -world_dir.z)

func update_aim_special_world(world_pos: Vector3) -> void:
	if not aim_arrow_indicator or not aim_arrow_indicator.is_aiming:
		return
	aim_arrow_indicator.update_aim_world_target(world_pos)
	var diff := world_pos - global_position
	diff.y = 0.0
	if diff.length_squared() > 0.01:
		rotation.y = atan2(-diff.x, -diff.z)

func release_aim_special() -> bool:
	if not aim_arrow_indicator or not aim_arrow_indicator.is_aiming:
		return false
	var ability := aim_arrow_indicator.current_ability
	var target_pt := aim_arrow_indicator.get_aim_target_world()
	var dir := aim_arrow_indicator.get_aim_direction()
	aim_arrow_indicator.stop_aiming()
	
	if ability == "molotov":
		return throw_molotov_at_target(target_pt)
	elif ability == "super_blast":
		return trigger_super_blast_directed(dir)
	return false

func cancel_aim_special() -> void:
	if aim_arrow_indicator:
		aim_arrow_indicator.stop_aiming()

func _apply_equipped_skills() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var eq: Array = gm.get_equipped_skills()
	has_blood_siphon = "blood_siphon" in eq
	hemorrhage_rounds = "hemorrhage_rounds" in eq
	berserker_pair = has_blood_siphon and hemorrhage_rounds

## Called by the spawner for every kill. Crimson Berserker: kills made while standing
## in blood build towards a free molotov charge.
func on_zombie_killed() -> void:
	if not berserker_pair or not in_blood or molotov_ammo >= max_molotov_ammo:
		return
	_berserker_kills += 1
	if _berserker_kills >= BERSERKER_KILLS_PER_MOLOTOV:
		_berserker_kills = 0
		refill_molotov(1)
		emit_signal("powerup_activated", "CRIMSON BERSERKER: +1 MOLOTOV", 0.0)

func _apply_armory_upgrades() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var active_w := "assault_carbine"
	var dmg_lv: int = gm.get_weapon_upgrade_level(active_w, "damage_knockback")
	var rate_lv: int = gm.get_weapon_upgrade_level(active_w, "fire_rate_mag")
	var pen_lv: int = gm.get_weapon_upgrade_level(active_w, "penetration")
	var crit_lv: int = gm.get_weapon_upgrade_level(active_w, "crit_autoaim")
	
	rifle_damage = 120.0 * (1.0 + float(dmg_lv) * 0.12)  # per round (the bullet used to ignore this)
	bonus_knockback = 1.0 + float(dmg_lv) * 0.15
	rifle_fire_rate = maxf(0.06, 0.11 * (1.0 - float(rate_lv) * 0.04))
	mag_size = BASE_MAG_SIZE + 3 * rate_lv  # Extended Drum: +3 rounds per level
	mag_ammo = mag_size
	base_penetration = 1 + pen_lv
	crit_chance = clampf(float(crit_lv) * 0.12, 0.0, 0.60)

func _physics_process(delta: float) -> void:
	if is_vaulting:
		return
		
	# Handle cooldowns
	if not can_fire_rifle:
		fire_timer -= delta
		if fire_timer <= 0.0:
			can_fire_rifle = true
	_tick_reload(delta)
	
	if shoulder_charge_timer > 0.0:
		shoulder_charge_timer = maxf(0.0, shoulder_charge_timer - delta)
	
	# Blood under the operative (skills); checked a few times a second, not every frame
	_blood_check_timer -= delta
	if _blood_check_timer <= 0.0:
		_blood_check_timer = 0.15
		in_blood = BloodManager.instance != null and BloodManager.instance.is_stepping_in_blood(global_position)
	
	if super_blast_timer > 0.0:
		super_blast_timer -= delta
		emit_signal("super_blast_cooldown", super_blast_timer / super_blast_cooldown_time)
	
	# Molotov Power-Up 15s countdown
	if molotov_cooldown > 0.0:
		molotov_cooldown = maxf(0.0, molotov_cooldown - delta)
	
	if molotov_powerup_timer > 0.0:
		molotov_powerup_timer = maxf(0.0, molotov_powerup_timer - delta)
		emit_signal("powerup_timer_changed", molotov_powerup_timer, molotov_powerup_max)
		if molotov_powerup_timer <= 0.0:
			is_molotov_active = false
			emit_signal("powerup_timer_changed", 0.0, molotov_powerup_max)
	
	# Hyper-Burst 15s countdown
	if hyper_burst_timer > 0.0:
		hyper_burst_timer = maxf(0.0, hyper_burst_timer - delta)
		emit_signal("powerup_timer_changed", hyper_burst_timer, hyper_burst_max)
		if hyper_burst_timer <= 0.0:
			is_hyper_burst = false
			emit_signal("powerup_timer_changed", 0.0, hyper_burst_max)
			
	# Cryo-Stim 12s countdown
	if stim_timer > 0.0:
		stim_timer = maxf(0.0, stim_timer - delta)
		if stim_timer <= 0.0:
			is_stim_active = false
	
	# Smooth rifle recoil recovery
	if rifle_mesh:
		rifle_mesh.position = rifle_mesh.position.lerp(Vector3(0.22, 0.9, -0.4), delta * 20.0)
		rifle_mesh.rotation.x = lerp_angle(rifle_mesh.rotation.x, 0.0, delta * 20.0)
	
	# Movement input (merges keyboard and mobile joystick)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if mobile_move_input.length() > 0.05:
		input_dir = mobile_move_input
	
	# Camera-relative projection: 2D screen input matches 3D camera orientation exactly
	var cam := get_viewport().get_camera_3d()
	var forward: Vector3
	var right: Vector3
	if cam:
		forward = -cam.global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		right = cam.global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
	else:
		forward = Vector3(0.0, 0.0, -1.0)
		right = Vector3(1.0, 0.0, 0.0)
	var move_dir := (right * input_dir.x + forward * (-input_dir.y)).normalized()
	
	var effective_speed: float = move_speed * (1.45 if is_stim_active else 1.0) * objective_speed_mult
	if move_dir.length() > 0.1:
		velocity.x = move_dir.x * effective_speed
		velocity.z = move_dir.z * effective_speed
		
		# Procedural athletic tactical run animation (replaces penguin waddle)
		run_cycle += delta * 15.0
		visual_root.position.y = absf(sin(run_cycle)) * 0.035
		visual_root.rotation.x = deg_to_rad(6.0)
		visual_root.rotation.z = 0.0
		
		# Alternating leg stride forward & back
		if leg_left and leg_right:
			var stride := sin(run_cycle)
			leg_left.rotation.x = stride * 0.65
			leg_right.rotation.x = -stride * 0.65
			leg_left.position.z = leg_rest_left.z - stride * 0.12
			leg_right.position.z = leg_rest_right.z + stride * 0.12
			leg_left.position.y = leg_rest_left.y + maxf(0.0, stride * 0.06)
			leg_right.position.y = leg_rest_right.y + maxf(0.0, -stride * 0.06)
		
		# Step & footprint check
		distance_since_step += velocity.length() * delta
		if distance_since_step >= step_interval:
			distance_since_step = 0.0
			_on_step_taken()
	else:
		# Quick stop - eliminate unwanted sliding
		velocity.x = move_toward(velocity.x, 0, effective_speed * delta * 25.0)
		velocity.z = move_toward(velocity.z, 0, effective_speed * delta * 25.0)
		visual_root.position.y = move_toward(visual_root.position.y, 0, delta * 2.0)
		visual_root.rotation.x = move_toward(visual_root.rotation.x, 0, delta * 15.0)
		visual_root.rotation.z = move_toward(visual_root.rotation.z, 0, delta * 15.0)
		
		# Return legs to resting stance
		if leg_left and leg_right:
			leg_left.rotation.x = move_toward(leg_left.rotation.x, 0.0, delta * 14.0)
			leg_right.rotation.x = move_toward(leg_right.rotation.x, 0.0, delta * 14.0)
			leg_left.position.z = move_toward(leg_left.position.z, leg_rest_left.z, delta * 3.0)
			leg_right.position.z = move_toward(leg_right.position.z, leg_rest_right.z, delta * 3.0)
			leg_left.position.y = move_toward(leg_left.position.y, leg_rest_left.y, delta * 3.0)
			leg_right.position.y = move_toward(leg_right.position.y, leg_rest_right.y, delta * 3.0)
	
	# Coyote time tracking
	if is_on_floor():
		coyote_timer = 0.14
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	
	if Input.is_action_just_pressed("jump") or mobile_jump_pressed:
		jump_buffer_timer = 0.2
		mobile_jump_pressed = false
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = jump_velocity
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
			visual_root.position.y = 0.12
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	
	# Aiming & Target Acquisition logic
	if target_cache_timer > 0.0:
		target_cache_timer -= delta
		
	var is_firing := Input.is_action_pressed("fire") or mobile_fire_pressed
	var nearest_target: Node3D = null
	
	# 1. Twin-Stick Manual Aiming (Landscape right stick)
	if mobile_aim_input.length() > 0.15:
		var manual_aim_dir := (right * mobile_aim_input.x + forward * (-mobile_aim_input.y)).normalized()
		_aim_at(global_position + manual_aim_dir, delta, 22.0)
		is_firing = true
	# 2. Auto-Shoot Toggle (Strictly limited to auto_shoot_radius, does NOT react or shoot beyond it)
	elif auto_fire_enabled:
		nearest_target = get_best_target_with_los(auto_shoot_radius)
		if nearest_target != null:
			var dist := global_position.distance_to(nearest_target.global_position)
			if dist <= auto_shoot_radius:
				_aim_at(nearest_target.global_position, delta, 22.0)
				var flat_dir := (nearest_target.global_position - global_position)
				flat_dir.y = 0.0
				flat_dir = flat_dir.normalized()
				var facing_dir := -transform.basis.z.normalized()
				if flat_dir.dot(facing_dir) > 0.65:
					is_firing = true
		else:
			is_firing = false
			if move_dir.length() > 0.1:
				_aim_at(global_position + move_dir, delta, 10.0)
	# 3. Manual Fire (Button pressed/held)
	elif is_firing:
		nearest_target = get_best_target_with_los(14.0)
		if nearest_target != null:
			_aim_at(nearest_target.global_position, delta, 18.0)
		elif move_dir.length() > 0.1:
			_aim_at(global_position + move_dir, delta, 10.0)
	# 4. Heading alignment
	elif move_dir.length() > 0.1:
		_aim_at(global_position + move_dir, delta, 10.0)
	
	move_and_slide()
	
	# Check for vault/climb opportunities in front of player
	_check_vault_opportunity()
	
	# Light collision nudge so the player isn't glued to a single zombie.
	# Deliberately weak: escaping a crowd is what the Shoulder Charge is for. Tanks don't budge.
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider and collider.is_in_group("zombies") and not collider.is_in_group("bosses") and collider.has_method("take_damage"):
			var shove_dir := -col.get_normal()
			shove_dir.y = 0.0
			collider.knockback_velocity += shove_dir.normalized() * 6.0
	
	# Dynamic sector boundary clamp
	if sector_bounds.size != Vector2.ZERO:
		global_position.x = clampf(global_position.x, sector_bounds.position.x, sector_bounds.end.x)
		global_position.z = clampf(global_position.z, sector_bounds.position.y, sector_bounds.end.y)
	
	# Check firing
	if is_firing and can_fire_rifle and reload_timer <= 0.0:
		fire_rifle(nearest_target)
		_idle_fire_time = 0.0
	else:
		_idle_fire_time += delta
		if reload_timer <= 0.0 and _idle_fire_time > IDLE_RELOAD_DELAY and mag_ammo < mag_size / 2:
			_start_reload()


func _start_reload() -> void:
	if reload_timer > 0.0:
		return
	reload_timer = RELOAD_TIME
	ammo_changed.emit(mag_ammo, mag_size, 0.001)
	AudioManager.play_sfx("gun_reload", -3.0)


func _tick_reload(delta: float) -> void:
	if reload_timer <= 0.0:
		return
	reload_timer -= delta
	if reload_timer <= 0.0:
		reload_timer = 0.0
		mag_ammo = mag_size
		ammo_changed.emit(mag_ammo, mag_size, 0.0)
	else:
		ammo_changed.emit(mag_ammo, mag_size, 1.0 - reload_timer / RELOAD_TIME)

func _check_vault_opportunity() -> void:
	if is_vaulting:
		return
	var space_state := get_world_3d().direct_space_state
	var chest_pos := global_position + Vector3(0, 0.7, 0)
	var forward_dir := -transform.basis.z.normalized()
	var query_fwd := PhysicsRayQueryParameters3D.create(chest_pos, chest_pos + forward_dir * 1.35, 1)
	var hit_fwd := space_state.intersect_ray(query_fwd)
	
	var detected: bool = false
	var landing: Vector3 = Vector3.ZERO
	
	if not hit_fwd.is_empty():
		# Raycast downwards over the obstacle to find its top surface
		var hit_pos: Vector3 = hit_fwd["position"]
		var test_top: Vector3 = hit_pos + (forward_dir * 0.45) + Vector3(0, 2.0, 0)
		var query_down := PhysicsRayQueryParameters3D.create(test_top, test_top + Vector3.DOWN * 2.2, 1)
		var hit_top := space_state.intersect_ray(query_down)
		
		if not hit_top.is_empty():
			var top_pos: Vector3 = hit_top["position"]
			var ledge_h: float = top_pos.y - global_position.y
			if ledge_h >= 0.35 and ledge_h <= 1.85:
				detected = true
				landing = top_pos + Vector3(0, 0.1, 0)
	
	if detected != can_vault:
		can_vault = detected
		vault_target_pos = landing
		emit_signal("vault_state_changed", can_vault)
	elif detected:
		vault_target_pos = landing

func trigger_vault() -> bool:
	if not can_vault or is_vaulting:
		return false
	
	is_vaulting = true
	velocity = Vector3.ZERO
	
	var start_pos := global_position
	var end_pos := vault_target_pos
	
	var tween := create_tween()
	# Smooth parabolic mantle onto crate/ledge
	tween.tween_method(func(t: float):
		var horiz := start_pos.lerp(end_pos, t)
		var vert_y := start_pos.y * (1.0 - t) + end_pos.y * t + sin(t * PI) * 0.45
		global_position = Vector3(horiz.x, vert_y, horiz.z)
	, 0.0, 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		global_position = end_pos
		is_vaulting = false
		can_vault = false
		emit_signal("vault_state_changed", false)
	)
	return true

## Knocks back and staggers every non-tank zombie within reach. Returns false on cooldown.
func trigger_shoulder_charge() -> bool:
	if shoulder_charge_timer > 0.0 or is_dead:
		return false
	shoulder_charge_timer = SHOULDER_CHARGE_COOLDOWN
	for z in get_tree().get_nodes_in_group("zombies"):
		if not is_instance_valid(z) or z.is_dead or z.is_in_group("bosses"):
			continue
		var diff: Vector3 = (z as Node3D).global_position - global_position
		diff.y = 0.0
		var d := diff.length()
		if d > SHOULDER_CHARGE_RADIUS or d < 0.001:
			continue
		var strength := 1.0 - (d / SHOULDER_CHARGE_RADIUS) * 0.5
		z.apply_stagger((diff / d) * 14.0 * strength, 0.45)
	visual_root.position.y = 0.12
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.15)
	return true

func has_zombie_within(radius: float) -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(z) and not z.is_dead and global_position.distance_to((z as Node3D).global_position) <= radius:
			return true
	return false

func find_densest_zombie_cluster(cluster_radius: float = 4.0, range_dist: float = 16.0) -> Vector3:
	var zombies := get_tree().get_nodes_in_group("zombies")
	var candidates: Array[Vector3] = []
	for z in zombies:
		if is_instance_valid(z) and z is Node3D and not z.get("is_dead"):
			var d := global_position.distance_to(z.global_position)
			if d <= range_dist:
				candidates.append(z.global_position)
	
	if candidates.is_empty():
		return global_position + (-transform.basis.z * 8.0)
	
	var best_pos := candidates[0]
	var max_count := 0
	
	for cand in candidates:
		var count := 0
		for other in candidates:
			if cand.distance_to(other) <= cluster_radius:
				count += 1
		if count > max_count:
			max_count = count
			best_pos = cand
			
	return best_pos

func throw_molotov() -> bool:
	var cluster_target := find_densest_zombie_cluster(4.0, 16.0)
	var target_pt: Vector3
	if cluster_target != Vector3.ZERO and cluster_target.distance_to(global_position) > 1.0:
		target_pt = cluster_target
	else:
		target_pt = global_position + (-transform.basis.z * 10.5)
	return throw_molotov_at_target(target_pt)

func throw_molotov_directed(dir: Vector3, dist: float = 10.5) -> bool:
	var target_pt := global_position + (dir.normalized() * dist)
	return throw_molotov_at_target(target_pt)

func throw_molotov_at_target(target_pt: Vector3) -> bool:
	if molotov_ammo <= 0:
		return false
	
	molotov_ammo -= 1
	emit_signal("molotov_ammo_changed", molotov_ammo, max_molotov_ammo)
	
	var molotov: MolotovProjectile = molotov_scene.instantiate() as MolotovProjectile
	get_parent().add_child(molotov)
	
	var spawn_pos := muzzle_point.global_position + Vector3(0, 0.4, 0)
	
	# Turn player towards target point
	var diff := target_pt - global_position
	diff.y = 0.0
	if diff.length_squared() > 0.01:
		rotation.y = atan2(-diff.x, -diff.z)
		
	molotov.init_target(spawn_pos, target_pt)
	AudioManager.play_sfx_varied("molotov_throw", -2.0)
	return true

func refill_molotov(amount: int = 3) -> void:
	molotov_ammo = clampi(molotov_ammo + amount, 0, max_molotov_ammo)
	emit_signal("molotov_ammo_changed", molotov_ammo, max_molotov_ammo)

func activate_hyper_burst(duration: float = 15.0) -> void:
	is_hyper_burst = true
	hyper_burst_timer = duration
	hyper_burst_max = duration
	AudioManager.play_sfx("hyper_burst_activate", -1.0)
	emit_signal("powerup_timer_changed", duration, duration)
	emit_signal("powerup_activated", "HYPER-BURST OVERDRIVE", duration)

func equip_heavy_rocket_launcher(ammo: int = 3) -> void:
	heavy_rocket_ammo = ammo
	max_heavy_rocket_ammo = ammo
	emit_signal("rocket_ammo_changed", heavy_rocket_ammo, max_heavy_rocket_ammo)
	emit_signal("powerup_activated", "HEAVY ROCKET LAUNCHER", float(ammo))

func activate_stim_boost(duration: float = 12.0) -> void:
	is_stim_active = true
	stim_timer = duration
	stim_max = duration
	current_health = minf(max_health, current_health + 50.0)
	emit_signal("health_changed", current_health, max_health)
	emit_signal("powerup_timer_changed", duration, duration)
	emit_signal("powerup_activated", "CRYO-STIM COCKTAIL", duration)

func set_carrying_objective(carrying: bool) -> void:
	carrying_objective = carrying
	objective_speed_mult = 0.85 if carrying else 1.0

func _aim_at(target_pos: Vector3, delta: float, turn_speed: float) -> void:
	var flat_target := Vector3(target_pos.x, global_position.y, target_pos.z)
	var dir := (flat_target - global_position).normalized()
	if dir.length() > 0.01:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * turn_speed)

func jump() -> void:
	jump_buffer_timer = 0.2

func fire_rifle(_primary_target: Node3D = null) -> void:
	can_fire_rifle = false
	var effective_fire_rate: float = rifle_fire_rate * (0.5 if is_hyper_burst else (0.75 if is_stim_active else 1.0))
	if has_blood_siphon and in_blood:
		effective_fire_rate *= SIPHON_FIRE_RATE_MULT
	fire_timer = effective_fire_rate
	AudioManager.play_sfx_throttled("gun_fire", 0.05, -5.0, 0.06)
	if not is_hyper_burst:  # overdrive rounds are free
		mag_ammo -= 1
		ammo_changed.emit(mag_ammo, mag_size, 0.0)
		if mag_ammo <= 0:
			_start_reload()
	
	# Reusable Muzzle flash
	if active_muzzle_flash:
		active_muzzle_flash.flash()
	
	# Rifle mechanical recoil kickback (zero recoil in hyper-burst)
	if rifle_mesh and not is_hyper_burst:
		rifle_mesh.position.z = -0.32
		rifle_mesh.rotation.x = deg_to_rad(-8.0)
	
	# Eject 1 brass shell casing flipping out to the right
	var shell: Node3D = shell_scene.instantiate()
	get_parent().add_child(shell)
	var casing_pos := muzzle_point.global_position - (transform.basis.z * 0.25) + (transform.basis.x * 0.14) + (Vector3.UP * 0.05)
	shell.init(casing_pos, transform.basis.x)
	
	# Bullet Spread System (1 focused center bullet initially; fan spread on Hyper-Burst or bullet_count upgrade)
	var base_forward := -transform.basis.z
	var spread_angles: Array[float] = [0.0]
	if is_hyper_burst or bullet_count >= 3:
		spread_angles = [-0.12, 0.0, 0.12]
	elif bullet_count == 2:
		spread_angles = [-0.07, 0.07]
		
	var pen: int = 3 if is_hyper_burst else base_penetration
	
	for angle in spread_angles:
		var bullet_dir := base_forward.rotated(Vector3.UP, angle).normalized()
		var spawn_pos := muzzle_point.global_position + (bullet_dir * 0.2)
		var is_crit: bool = (randf() < crit_chance) or is_hyper_burst
		
		var bullet: Node3D = bullet_projectile_scene.instantiate()
		bullet.set("damage", rifle_damage)
		get_parent().add_child(bullet)
		bullet.init(spawn_pos, bullet_dir, _primary_target, pen, is_hyper_burst, is_crit,
			global_position + Vector3(0.0, spawn_pos.y - global_position.y, 0.0), self)
	
func activate_molotov_powerup(duration: float = 15.0) -> void:
	molotov_powerup_timer = duration
	molotov_powerup_max = duration
	is_molotov_active = true
	molotov_shot_counter = 0
	emit_signal("powerup_timer_changed", molotov_powerup_timer, molotov_powerup_max)

func trigger_super_blast() -> bool:
	return trigger_super_blast_directed(-transform.basis.z)

func trigger_super_blast_directed(dir: Vector3) -> bool:
	if super_blast_timer > 0.0:
		return false
	
	var fire_dir := Vector3(dir.x, 0.0, dir.z).normalized()
	if fire_dir.length_squared() < 0.001:
		fire_dir = -transform.basis.z.normalized()
		
	# Turn player towards blast direction
	var target_yaw := atan2(-fire_dir.x, -fire_dir.z)
	rotation.y = target_yaw
	
	if heavy_rocket_ammo > 0:
		heavy_rocket_ammo -= 1
		emit_signal("rocket_ammo_changed", heavy_rocket_ammo, max_heavy_rocket_ammo)
		super_blast_timer = 1.0
		emit_signal("super_blast_cooldown", 1.0)
		_launch_single_rocket(fire_dir, 0.0, true)
		return true
	
	super_blast_timer = super_blast_cooldown_time
	emit_signal("super_blast_cooldown", 1.0)
	
	# Fire 3 rockets in quick staggered succession along fire_dir
	var angles := [-0.22, 0.0, 0.22]
	for i in range(3):
		get_tree().create_timer(i * 0.07).timeout.connect(func():
			_launch_single_rocket(fire_dir.rotated(Vector3.UP, angles[i]), angles[i] * 2.0, false)
		)
	
	# Cam trauma (controlled subtle thump)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.18)
	
	return true

func _launch_single_rocket(dir: Vector3, wobble: float, is_heavy: bool = false) -> void:
	if not is_instance_valid(self):
		return
	
	var r: Rocket = rocket_scene.instantiate()
	get_parent().add_child(r)
	r.global_position = launcher_muzzle.global_position
	r.setup(dir, wobble, is_heavy)
	AudioManager.play_sfx_varied("rocket_fire", -2.0, 0.06)
	
	# Launch flash
	var flash := muzzle_scene.instantiate()
	get_parent().add_child(flash)
	flash.global_position = launcher_muzzle.global_position

func _on_step_taken() -> void:
	left_foot_step = not left_foot_step
	AudioManager.play_sfx_varied("player_footstep", -15.0, 0.1)
	
	# Check if stepping in blood
	if BloodManager.instance and BloodManager.instance.is_stepping_in_blood(global_position):
		footprint_charges = 8
	
	if footprint_charges > 0:
		footprint_charges -= 1
		var foot_offset := transform.basis.x * (0.16 if left_foot_step else -0.16)
		var foot_pos := global_position + foot_offset
		var strength: float = float(footprint_charges) / 8.0
		if BloodManager.instance:
			BloodManager.instance.spawn_footprint(foot_pos, rotation.y, strength)

func get_best_target_with_los(max_dist: float) -> Node3D:
	# Check if cached target is still alive and in range
	if is_instance_valid(cached_target) and not cached_target.get("is_dead"):
		var ct_pos: Vector3 = cached_target.global_position
		var c_dx: float = ct_pos.x - global_position.x
		var c_dz: float = ct_pos.z - global_position.z
		if c_dx * c_dx + c_dz * c_dz <= max_dist * max_dist:
			if target_cache_timer > 0.0:
				return cached_target
	
	target_cache_timer = 0.08 # Update targeting at ~12 Hz instead of every frame
	var space_state := get_world_3d().direct_space_state
	var eye_pos := global_position + Vector3(0, 1.1, 0)
	var max_dist_sq := max_dist * max_dist
	var p_pos := global_position
	
	# Nearest visible threat wins. Runners and heavies count as a little closer than they
	# are (they're the dangerous ones), but a strict group order would keep shooting at a
	# far runner while a Brute stands on top of the player.
	var closest: Node3D = null
	var best_score := INF
	# "bosses" also holds the infestation nests, which are not in "zombies"
	var pool: Array = get_tree().get_nodes_in_group("zombies") + get_tree().get_nodes_in_group("bosses")
	for candidate in pool:
		if not is_instance_valid(candidate) or not (candidate is Node3D):
			continue
		if candidate.get("is_dead"):
			continue
		var c_pos: Vector3 = (candidate as Node3D).global_position
		var dx: float = c_pos.x - p_pos.x
		var dz: float = c_pos.z - p_pos.z
		var d_sq: float = dx * dx + dz * dz
		if d_sq > max_dist_sq:
			continue
		var score := d_sq
		if candidate.is_in_group("runners") or candidate.is_in_group("bosses"):
			score *= 0.6
		if score >= best_score:
			continue
		var target_pos: Vector3 = c_pos + Vector3(0, 0.9, 0)
		var query := PhysicsRayQueryParameters3D.create(eye_pos, target_pos, 1)
		# Exclude the candidate too: targets that are world solids (e.g. nests) would block their own ray
		var excl: Array[RID] = [self.get_rid()]
		if candidate is CollisionObject3D:
			excl.append((candidate as CollisionObject3D).get_rid())
		query.exclude = excl
		if space_state.intersect_ray(query).is_empty():
			best_score = score
			closest = candidate
	if closest != null:
		cached_target = closest
		return closest
	
	cached_target = null
	return null

func _get_nearest_zombie(max_dist: float) -> Node3D:
	var zombies := get_tree().get_nodes_in_group("zombies")
	var closest: Node3D = null
	var min_d := max_dist
	
	for z in zombies:
		if is_instance_valid(z) and z is Node3D:
			if "is_dead" in z and z.is_dead:
				continue
			var d := global_position.distance_to(z.global_position)
			if d < min_d:
				min_d = d
				closest = z
	return closest

func take_damage(amount: float, _impulse: Vector3 = Vector3.ZERO) -> void:
	if is_dead:
		return
	current_health = maxf(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)
	if current_health > 0.0:
		AudioManager.play_sfx_throttled("player_hurt", 0.45, -3.0, 0.08)
		AudioManager.haptic_light()
	
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.3)
	
	if BloodManager.instance:
		BloodManager.instance.spawn_splatter(global_position, Vector3.UP, 0.7)
	
	if current_health <= 0.0:
		# Player death
		AudioManager.play_sfx("player_death")
		is_dead = true
		set_physics_process(false)
		mobile_fire_pressed = false
		cancel_aim_special()
		emit_signal("died")
