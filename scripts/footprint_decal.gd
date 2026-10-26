extends Decal
class_name FootprintDecal

var lifetime: float = 8.0
var age: float = 0.0
var current_strength: float = 1.0

func _ready() -> void:
	add_to_group("blood_footprints")
	texture_albedo = preload("res://assets/textures/blood_footprint.png")
	size = Vector3(0.32, 0.5, 0.5)

func setup(heading_yaw: float, strength: float = 1.0) -> void:
	current_strength = strength
	rotation.y = heading_yaw
	modulate = Color(0.9, 0.05, 0.1, clampf(strength, 0.15, 0.95))

func _process(delta: float) -> void:
	age += delta
	current_strength = maxf(0.0, current_strength - delta * 0.25)
	if age > lifetime:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.5)
		tween.tween_callback(queue_free)
		set_process(false)
