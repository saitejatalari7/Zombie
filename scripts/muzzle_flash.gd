extends Node3D
class_name MuzzleFlash

@onready var light: OmniLight3D = get_node_or_null("OmniLight3D") as OmniLight3D
@onready var sparks: GPUParticles3D = $GPUParticles3D

var _tween: Tween = null

func _ready() -> void:
	if light:
		light.light_energy = 0.0

func flash() -> void:
	if sparks:
		sparks.restart()
	if light:
		if _tween and _tween.is_valid():
			_tween.kill()
		light.light_energy = 3.2
		_tween = create_tween()
		_tween.tween_property(light, "light_energy", 0.0, 0.05)
