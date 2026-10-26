extends MissionJob
class_name AssetRecoveryJob
## Asset Recovery: the flight recorder spawns at a random "ObjectiveSpawns" marker.
## Picking it up unlocks the LZ; while carried it slows the player (ObjectiveCase)
## and runners hunt the carrier instead of following blood trails (Zombie).

const CASE_SCENE := preload("res://scenes/objective_case.tscn")
const OBJECTIVE_COLOR := Color(1.0, 0.72, 0.0)

var case_node: ObjectiveCase = null
var _status_timer: float = 0.0


func start() -> void:
	var spots := sector.get_marker_nodes("ObjectiveSpawns")
	var pos: Vector3
	if spots.is_empty():
		push_warning("[AssetRecoveryJob] Sector has no ObjectiveSpawns markers; placing the case 20 m ahead of the player")
		pos = player.global_position + Vector3(0.0, 0.0, -20.0)
	else:
		pos = spots[randi() % spots.size()].global_position

	case_node = CASE_SCENE.instantiate()
	sector.add_child(case_node)
	case_node.global_position = pos
	case_node.case_secured.connect(_on_case_secured)
	case_node.add_child(make_beacon(Color(OBJECTIVE_COLOR, 0.3), 1.6))
	_update_status()


func _process(delta: float) -> void:
	if met:
		return
	_status_timer -= delta
	if _status_timer <= 0.0:
		_status_timer = 0.25
		_update_status()


func _update_status() -> void:
	if not is_instance_valid(case_node) or not is_instance_valid(player):
		return
	var dist := player.global_position.distance_to(case_node.global_position)
	status_changed.emit("RECOVER THE FLIGHT RECORDER  ◆ %dm" % int(dist), OBJECTIVE_COLOR)


func _on_case_secured(_p: Player) -> void:
	_complete()


func get_locked_hint() -> String:
	return "Recover the flight recorder before evac"
