extends Control
class_name VirtualJoystick
## Floating thumbstick. It rests at its home spot; a touch anywhere in the HUD's stick zone
## brings the base under the thumb, so the player never has to find the stick by eye.
## Driven by MobileHUD's touch router (begin / move / end, canvas coordinates): Godot's GUI
## only routes the first finger, and the stick must work alongside fire and abilities.

signal joystick_vector(vec: Vector2)

@export var max_distance: float = 90.0
## Base opacity while idle, so the resting stick doesn't cover the street
const IDLE_ALPHA := 0.55

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false
var _home: Vector2 = Vector2.ZERO  # base position (local) when idle

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home = base.position
	modulate.a = IDLE_ALPHA
	_reset_knob()

func _base_center_global() -> Vector2:
	return base.global_position + base.size * 0.5

func _reset_knob() -> void:
	knob.position = (base.size - knob.size) * 0.5
	output_vector = Vector2.ZERO
	joystick_vector.emit(Vector2.ZERO)

## Thumb down at a canvas position: the base jumps there.
func begin(pos: Vector2) -> void:
	is_active = true
	modulate.a = 1.0
	base.global_position = pos - base.size * 0.5
	_reset_knob()

func move(pos: Vector2) -> void:
	if not is_active:
		return
	var diff := pos - _base_center_global()
	if diff.length() > max_distance:
		diff = diff.normalized() * max_distance
	knob.position = (base.size - knob.size) * 0.5 + diff
	output_vector = diff / max_distance
	joystick_vector.emit(output_vector)

func end() -> void:
	is_active = false
	modulate.a = IDLE_ALPHA
	base.position = _home
	_reset_knob()
