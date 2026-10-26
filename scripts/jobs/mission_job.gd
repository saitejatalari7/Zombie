extends Node
class_name MissionJob
## MissionJob.gd
## Base class for contract objectives. Main owns the shared mission flow
## (LZ, evac, debrief, death); a job only decides when the LZ unlocks and
## what the HUD objective pill says. Add a job type: subclass this and
## register its id in create().

signal objective_met()
signal status_changed(text: String, color: Color)

var contract: Dictionary = {}
var sector: SectorBase = null
var player: Player = null
var met: bool = false


## Loaded by path so this base class doesn't reference its own subclasses.
const JOB_SCRIPTS: Dictionary = {
	"kill_quota": "res://scripts/jobs/kill_quota_job.gd",
	"asset_recovery": "res://scripts/jobs/asset_recovery_job.gd",
}


static func create(job_id: String) -> MissionJob:
	var path: String = JOB_SCRIPTS.get(job_id, JOB_SCRIPTS["kill_quota"])
	return load(path).new() as MissionJob


func setup(p_contract: Dictionary, p_sector: SectorBase, p_player: Player) -> void:
	contract = p_contract
	sector = p_sector
	player = p_player


## Called once the job is in the tree and the run has started.
func start() -> void:
	pass


func on_run_kills_changed(_run_kills: int) -> void:
	pass


## Where the objective arrow should point before the LZ unlocks, or null for no arrow.
func get_target_position() -> Variant:
	return null


## Second line of the "LZ LOCKED" banner.
func get_locked_hint() -> String:
	return "Complete the objective before evac"


func _complete() -> void:
	if met:
		return
	met = true
	objective_met.emit()


## Translucent light column + ground pad used to mark objectives and the LZ.
static func make_beacon(color: Color, pad_radius: float = 3.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Beacon"
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.6
	beam_mesh.bottom_radius = 0.6
	beam_mesh.height = 14.0
	beam_mesh.material = mat
	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 7.0, 0.0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(beam)

	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = pad_radius
	pad_mesh.bottom_radius = pad_radius
	pad_mesh.height = 0.04
	pad_mesh.material = mat
	var pad := MeshInstance3D.new()
	pad.mesh = pad_mesh
	pad.position = Vector3(0.0, 0.05, 0.0)
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(pad)
	return root
