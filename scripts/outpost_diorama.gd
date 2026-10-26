extends Node3D
## OutpostDiorama.gd
## Controls the live 3D background diorama for the Outpost Hub.
## Adjusts isometric camera framing based on portrait vs landscape orientation.
## Implements subtle ambient camera drift to make the hub feel alive.

@onready var camera: Camera3D = %Camera3D
@onready var diorama_root: Node3D = %DioramaRoot
@onready var sun: DirectionalLight3D = %SunLight

var _base_cam_pos: Vector3
var _drift_timer: float = 0.0

func _ready() -> void:
	if camera:
		_base_cam_pos = camera.position
	
	var om = get_node_or_null("/root/OrientationManager")
	if om:
		om.orientation_changed.connect(_on_orientation_changed)
		_apply_camera_framing(om.is_portrait)

func _process(delta: float) -> void:
	_drift_timer += delta * 0.4
	# Subtle atmospheric drift
	if camera:
		camera.position.x = _base_cam_pos.x + sin(_drift_timer) * 0.35
		camera.position.z = _base_cam_pos.z + cos(_drift_timer * 0.7) * 0.25

func _on_orientation_changed(is_portrait: bool) -> void:
	_apply_camera_framing(is_portrait)

func _apply_camera_framing(is_portrait: bool) -> void:
	if not camera:
		return
	if is_portrait:
		camera.fov = 55.0
		_base_cam_pos = Vector3(10.5, 12.0, 10.5)
	else:
		camera.fov = 42.0
		_base_cam_pos = Vector3(8.5, 9.5, 8.5)
	camera.position = _base_cam_pos
	camera.look_at(Vector3(0, 1.0, 0), Vector3.UP)
