extends CanvasLayer
## LoadingScreen.gd — Global Scene Transitioner & Studio Splash
## Registered as an Autoload (layer = 128) so it seamlessly overlays any scene.
## Uses Godot 4 ResourceLoader.load_threaded_request() for non-blocking async loads.
## Implements Studio Splash, Rotating 3D wireframe silhouette, and monospaced military HUD.

# ─── Signals ───────────────────────────────────────────────────────────────────
signal transition_started(target_scene: String)
signal loading_progress(progress: float)
signal transition_finished()

# ─── Node References ──────────────────────────────────────────────────────────
@onready var root_control: Control = $RootControl
@onready var splash_layer: Control = %SplashLayer
@onready var studio_label: Label = %StudioLabel
@onready var loading_layer: Control = %LoadingLayer
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var status_label: Label = %StatusLabel
@onready var tip_label: Label = %TipLabel

# ─── State ─────────────────────────────────────────────────────────────────────
var _target_scene_path: String = ""
var _is_loading: bool = false
var _visual_progress: float = 0.0
var _status_timer: float = 0.0
var _current_status_idx: int = 0

# ─── Tactical Military Readouts (Design Doc Section 3.1) ──────────────────────
const STATUS_MESSAGES: Array[String] = [
	"INITIALIZING NAVMESH...",
	"COMPILING FLUID/DECAL SHADERS...",
	"SPAWNING SECTOR GEOMETRY [42%]...",
	"ESTABLISHING TACTICAL COMMS LINK...",
	"CALIBRATING HORDE AGGRESSION MATRICES...",
	"CALCULATING EXTRACTION LZ WAYPOINTS...",
	"SPAWNING SECTOR GEOMETRY [89%]...",
	"FINALIZING ASYNC ASSET BUFFERS...",
]

const TACTICAL_TIPS: Array[String] = [
	"RUNNER-CLASS HOSTILES TRACK BLOOD FOOTPRINTS. TREAD CAREFULLY.",
	"MOLOTOV COCKTAILS ARE MOST EFFECTIVE IN NARROW CHOKEPOINTS.",
	"UPGRADE THE HELIPAD AT THE OUTPOST TO REDUCE EXTRACTION TIME.",
	"NIGHT OPS REQUIRE TACTICAL FLASHLIGHT DISCIPLINE — SWEEP CORNERS.",
	"ESCORT VIPS STAY CLOSE TO YOUR PATH. CLEAR REAR FLANKS FREQUENTLY.",
	"RESEARCH CORES (RC) ARE HARVESTED FROM BIO-LABS AND CRIMSON BOSSES.",
	"PAIR SYNERGISTIC OPERATIVE SKILLS FOR EXPONENTIAL MULTIPLIERS.",
	"CARRYING HEAVY FLIGHT RECORDERS ENFORCES ONE-HANDED SHOOTING.",
	"BURNING ZOMBIES SPREAD CRIMSON FIRE TO ADJACENT HORDE MEMBERS.",
	"CRIMSON BOSSES CRUSH LIGHT COVER. MAINTAIN MINIMUM ENGAGEMENT DISTANCE.",
	"OVERPRESSURE ROUNDS KNOCK SHAMBLERS BACKWARD INTO SOLID WALLS.",
	"PIERCING CORES ALLOW ASSAULT ROUNDS TO PUNCTURE MULTIPLE TARGETS.",
	"DYING FORFEITS 70% OF UNBANKED SCAVENGED LOOT. EXTRACT EARLY IF WOUNDED.",
]

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Hide overlay completely on initial startup
	visible = false
	root_control.visible = false
	root_control.modulate = Color(1, 1, 1, 0)
	splash_layer.visible = false
	loading_layer.visible = false


func _process(delta: float) -> void:
	if not _is_loading:
		return
	
	# Poll async loader status
	var progress_arr: Array = []
	var status := ResourceLoader.load_threaded_get_status(_target_scene_path, progress_arr)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var raw_progress: float = progress_arr[0] if progress_arr.size() > 0 else 0.0
			_visual_progress = lerpf(_visual_progress, raw_progress, delta * 5.0)
			_update_ui_progress(_visual_progress)
			_update_status_ticker(delta)
			loading_progress.emit(_visual_progress)
		
		ResourceLoader.THREAD_LOAD_LOADED:
			_update_ui_progress(1.0)
			_is_loading = false
			var packed_scene := ResourceLoader.load_threaded_get(_target_scene_path) as PackedScene
			_complete_transition(packed_scene)
		
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_is_loading = false
			if status_label:
				status_label.text = "CRITICAL ERROR: ASYNC LOAD ABORTED"
			push_error("[LoadingScreen] Threaded load failed for: %s" % _target_scene_path)


# ─── Public API ────────────────────────────────────────────────────────────────
## Global async scene transition. Call from anywhere:
## LoadingScreen.transition_to_scene("res://scenes/main.tscn")
func transition_to_scene(target_scene_path: String) -> void:
	if _is_loading:
		return
	_start_transition(target_scene_path)


## Plays the studio splash sequence with haptic pulse (Design Doc Section 3.1)
func play_studio_splash(on_finished_callback: Callable = Callable()) -> void:
	root_control.visible = true
	splash_layer.visible = true
	loading_layer.visible = false
	root_control.modulate = Color(1, 1, 1, 1)
	splash_layer.modulate = Color(1, 1, 1, 0)
	
	var am = get_node_or_null("/root/AudioManager")
	
	var tween := create_tween()
	# Fade in studio logo
	tween.tween_property(splash_layer, "modulate:a", 1.0, 0.6)
	tween.tween_callback(func():
		if am and am.has_method("haptic_light"):
			am.haptic_light()
	)
	# Hold for 1.0 second
	tween.tween_interval(1.0)
	# Fade out
	tween.tween_property(splash_layer, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		splash_layer.visible = false
		root_control.visible = false
		if on_finished_callback.is_valid():
			on_finished_callback.call()
	)


# ─── Internal Transition Flow ──────────────────────────────────────────────────
func _start_transition(target_path: String) -> void:
	_target_scene_path = target_path
	_is_loading = true
	_visual_progress = 0.0
	_status_timer = 0.0
	_current_status_idx = 0
	
	transition_started.emit(target_path)
	
	# Prepare UI
	visible = true
	splash_layer.visible = false
	loading_layer.visible = true
	root_control.visible = true
	
	if tip_label:
		tip_label.text = TACTICAL_TIPS[randi() % TACTICAL_TIPS.size()]
	if status_label:
		status_label.text = STATUS_MESSAGES[0]
	if progress_bar:
		progress_bar.value = 0.0
	
	# Start threaded request
	ResourceLoader.load_threaded_request(target_path, "", false, ResourceLoader.CACHE_MODE_REUSE)
	
	# Fade in black overlay
	var tween := create_tween()
	tween.tween_property(root_control, "modulate:a", 1.0, 0.25)


func _update_ui_progress(progress: float) -> void:
	if progress_bar:
		progress_bar.value = progress * 100.0


func _update_status_ticker(delta: float) -> void:
	_status_timer += delta
	if _status_timer >= 0.7:
		_status_timer = 0.0
		_current_status_idx = (_current_status_idx + 1) % STATUS_MESSAGES.size()
		if status_label:
			status_label.text = STATUS_MESSAGES[_current_status_idx]


func _complete_transition(packed_scene: PackedScene) -> void:
	if status_label:
		status_label.text = "TACTICAL INSERTION READY [100%]"
	
	# Brief pause so the player sees 100% completion
	await get_tree().create_timer(0.3).timeout
	
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	
	# Fade out overlay
	var tween := create_tween()
	tween.tween_property(root_control, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		visible = false
		root_control.visible = false
		loading_layer.visible = false
		transition_finished.emit()
	)
