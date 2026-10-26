extends Area3D
class_name PowerupPickup

@onready var visual_root: Node3D = $VisualRoot
var cycle: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	cycle = randf_range(0, TAU)

func _physics_process(delta: float) -> void:
	cycle += delta * 3.5
	visual_root.position.y = 0.85 + sin(cycle) * 0.15
	visual_root.rotate_y(delta * 2.2)

func _on_body_entered(body: Node3D) -> void:
	if body and body.is_in_group("player"):
		if body.has_method("refill_molotov"):
			body.refill_molotov(3)
		if body.has_method("activate_molotov_powerup"):
			body.activate_molotov_powerup(15.0)
		
		# Pickup pop animation
		var tween := create_tween().set_parallel(true)
		tween.tween_property(visual_root, "scale", Vector3(1.8, 1.8, 1.8), 0.15)
		tween.tween_property(visual_root, "position:y", 1.8, 0.15)
		tween.chain().tween_callback(queue_free)
