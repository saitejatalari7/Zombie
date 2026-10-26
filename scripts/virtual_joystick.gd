extends Control
class_name VirtualJoystick

signal joystick_vector(vec: Vector2)

@export var max_distance: float = 90.0

@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

var touch_id: int = -1
var output_vector: Vector2 = Vector2.ZERO
var is_active: bool = false
var base_center: Vector2 = Vector2.ZERO

func _ready() -> void:
	base_center = base.size * 0.5
	_reset_knob()

func _reset_knob() -> void:
	knob.position = base_center - (knob.size * 0.5)
	output_vector = Vector2.ZERO
	emit_signal("joystick_vector", Vector2.ZERO)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			is_active = true
			_update_knob_position(event.position)
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			is_active = false
			_reset_knob()
	
	elif event is InputEventScreenDrag and event.index == touch_id:
		_update_knob_position(event.position)
	
	# Mouse fallback for testing on PC
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_active = true
				_update_knob_position(event.position)
			else:
				is_active = false
				_reset_knob()
	
	elif event is InputEventMouseMotion and is_active:
		_update_knob_position(event.position)

func _update_knob_position(pos: Vector2) -> void:
	var local_pos := pos - base.global_position
	var diff := local_pos - base_center
	var dist := diff.length()
	
	if dist > max_distance:
		diff = diff.normalized() * max_distance
	
	knob.position = base_center + diff - (knob.size * 0.5)
	output_vector = diff / max_distance
	emit_signal("joystick_vector", output_vector)
