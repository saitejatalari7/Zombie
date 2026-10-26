extends Node3D
class_name WaypointArrow

@export var bob_height: float = 0.35
@export var bob_speed: float = 3.5

var initial_y: float = 0.0
var cycle: float = 0.0
var player: Node3D = null

@onready var visual_root: Node3D = $VisualRoot

func _ready() -> void:
	add_to_group("waypoint_arrow")
	initial_y = position.y
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	cycle += delta * bob_speed
	visual_root.position.y = sin(cycle) * bob_height
	
	# Check if player has passed through the unlocked gate
	if is_instance_valid(player):
		if player.global_position.z < -16.0:
			fade_out()

func fade_out() -> void:
	set_physics_process(false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual_root, "scale", Vector3.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
