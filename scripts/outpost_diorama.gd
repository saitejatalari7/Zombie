extends Node3D
## OutpostDiorama.gd
## Controls the live 3D background diorama for the Outpost Hub.
## Implements subtle ambient camera drift to make the hub feel alive.

@onready var camera: Camera3D = %Camera3D
@onready var diorama_root: Node3D = %DioramaRoot
@onready var sun: DirectionalLight3D = %SunLight

var _base_cam_pos: Vector3
var _drift_timer: float = 0.0

func _ready() -> void:
	if camera:
		_base_cam_pos = camera.position
	
	_apply_camera_framing()

func _process(delta: float) -> void:
	_drift_timer += delta * 0.4
	# Subtle atmospheric drift
	if camera:
		camera.position.x = _base_cam_pos.x + sin(_drift_timer) * 0.35
		camera.position.z = _base_cam_pos.z + cos(_drift_timer * 0.7) * 0.25

func _apply_camera_framing() -> void:
	if not camera:
		return
	# Portrait: fit the pad to the screen width so the whole outpost reads behind the logo
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 50.0
	_base_cam_pos = Vector3(15.0, 17.0, 15.0)
	camera.position = _base_cam_pos
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
