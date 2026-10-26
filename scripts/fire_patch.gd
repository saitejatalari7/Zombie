extends Area3D
class_name FirePatch

@export var duration: float = 8.0
var burn_duration: float:
	get: return duration
	set(v): duration = v
@export var damage_per_tick: float = 45.0
@export var tick_interval: float = 0.25

static var active_patches: Array[FirePatch] = []
const MAX_ACTIVE_PATCHES: int = 3

var elapsed: float = 0.0
var tick_timer: float = 0.0
var dying: bool = false
var _crackle: AudioStreamPlayer = null

@onready var particles: GPUParticles3D = $FireParticles
@onready var light: OmniLight3D = get_node_or_null("FireLight") as OmniLight3D

func _ready() -> void:
	# Keep fire patch pool tight to prevent particle/light overdraw
	if active_patches.size() >= MAX_ACTIVE_PATCHES:
		var oldest: FirePatch = active_patches.pop_front()
		if is_instance_valid(oldest) and not oldest.dying:
			oldest._fade_out()
	active_patches.append(self)
	_crackle = AudioManager.attach_loop(self, "fire_loop", -40.0)
	if _crackle:
		create_tween().tween_property(_crackle, "volume_db", -8.0, 0.4)
	
	# Burn scorched ground mark if BloodManager exists
	if BloodManager.instance:
		BloodManager.instance.spawn_splatter(global_position + Vector3(0, 0.05, 0), Vector3.UP, 1.8, true)

func _exit_tree() -> void:
	active_patches.erase(self)

func _physics_process(delta: float) -> void:
	elapsed += delta
	tick_timer += delta
	
	# Light flicker
	if light and not dying:
		light.light_energy = 3.2 + sin(elapsed * 24.0) * 0.6 + cos(elapsed * 38.0) * 0.4
	
	if tick_timer >= tick_interval and not dying:
		tick_timer = 0.0
		_apply_burn_damage()
	
	if elapsed >= duration and not dying:
		_fade_out()

func _apply_burn_damage() -> void:
	var bodies := get_overlapping_bodies()
	for b in bodies:
		if is_instance_valid(b) and b != self:
			if b is Player:
				continue
			if b.has_method("take_damage"):
				var push_away := (b.global_position - global_position).normalized() * 3.0
				b.take_damage(damage_per_tick, push_away)
			if b.has_method("ignite"):
				b.ignite()

func _fade_out() -> void:
	dying = true
	if particles:
		particles.emitting = false
	if _crackle:
		create_tween().tween_property(_crackle, "volume_db", -40.0, 0.9)
	var tween := create_tween()
	if light and is_instance_valid(light):
		tween.tween_property(light, "light_energy", 0.0, 1.0)
	else:
		tween.tween_interval(0.5)
	tween.tween_callback(queue_free)
