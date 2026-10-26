extends Node
## DayNightManager.gd — Global Autoload
## Manages Day Ops vs. Night/Blackout Ops lighting across all tactical sectors.
## Day: High-visibility white architecture, crisp pitch-black shadows (#0A0A0C).
## Night/Blackout: Ambient drops to #050507, directional sunlight drops to near-zero,
## streetlamps flicker with OmniLight3D, and the player's weapon tactical flashlight (SpotLight3D) activates.

signal lighting_mode_changed(is_night: bool)
signal streetlamp_flicker_tick(energy_multiplier: float)

enum LightingMode { DAY, NIGHT_BLACKOUT }

var current_mode: LightingMode = LightingMode.DAY:
	set(value):
		if current_mode != value:
			current_mode = value
			lighting_mode_changed.emit(is_night_mode())

# Lighting color constants from Design Doc Section 2 & 3.3
const DAY_SUN_COLOR := Color(1.0, 0.98, 0.95, 1.0)
const DAY_SUN_ENERGY := 1.95
const DAY_AMBIENT_COLOR := Color(0.60, 0.62, 0.68, 1.0)
const DAY_AMBIENT_ENERGY := 0.18
const DAY_BG_COLOR := Color(0.82, 0.84, 0.87, 1.0)

const NIGHT_SUN_COLOR := Color(0.08, 0.10, 0.18, 1.0)
const NIGHT_SUN_ENERGY := 0.04
const NIGHT_AMBIENT_COLOR := Color(0.02, 0.02, 0.03, 1.0) # #050507 near-zero
const NIGHT_AMBIENT_ENERGY := 0.06
const NIGHT_BG_COLOR := Color(0.02, 0.02, 0.03, 1.0)

# Flicker state
var _flicker_timer: float = 0.0
var _flicker_interval: float = 0.12
var _current_flicker_mult: float = 1.0

func _ready() -> void:
	print("[DayNightManager] Initialized. Default mode: DAY")

func _process(delta: float) -> void:
	if is_night_mode():
		_flicker_timer += delta
		if _flicker_timer >= _flicker_interval:
			_flicker_timer = 0.0
			_flicker_interval = randf_range(0.06, 0.28)
			# Random subtle to stark flickering for blackout hazard feel
			if randf() < 0.25:
				_current_flicker_mult = randf_range(0.15, 0.5)
			else:
				_current_flicker_mult = randf_range(0.85, 1.05)
			streetlamp_flicker_tick.emit(_current_flicker_mult)

func is_night_mode() -> bool:
	return current_mode == LightingMode.NIGHT_BLACKOUT

func set_day_mode() -> void:
	self.current_mode = LightingMode.DAY

func set_night_mode() -> void:
	self.current_mode = LightingMode.NIGHT_BLACKOUT

func set_sector_mode(sector_id: int, contract_is_night: bool = false) -> void:
	# Sector 3 is Blackout Industrial Zone — Night Ops Mandatory!
	if sector_id == 3 or contract_is_night:
		set_night_mode()
	else:
		set_day_mode()

## Applies lighting parameters directly to a given Environment and DirectionalLight3D
func apply_to_environment(env: Environment, sun: DirectionalLight3D) -> void:
	if not env and not sun:
		return
		
	if is_night_mode():
		if env:
			env.background_color = NIGHT_BG_COLOR
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = NIGHT_AMBIENT_COLOR
			env.ambient_light_energy = NIGHT_AMBIENT_ENERGY
		if sun:
			sun.light_color = NIGHT_SUN_COLOR
			sun.light_energy = NIGHT_SUN_ENERGY
			sun.shadow_enabled = true
	else:
		if env:
			env.background_color = DAY_BG_COLOR
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = DAY_AMBIENT_COLOR
			env.ambient_light_energy = DAY_AMBIENT_ENERGY
		if sun:
			sun.light_color = DAY_SUN_COLOR
			sun.light_energy = DAY_SUN_ENERGY
			sun.shadow_enabled = true
