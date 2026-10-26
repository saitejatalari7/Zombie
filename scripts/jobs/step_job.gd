extends MissionJob
class_name StepJob
## StepJob.gd
## A contract told as a short sequence of story steps; the LZ unlocks after the last.
## Step types (contract "steps" entries):
##   kill    — {count}: kill N hostiles (anywhere)
##   reach   — {marker, radius}: walk to a marker
##   search  — {marker, seconds}: stand at a marker while a bar fills (leaving pauses it)
##   defend  — {marker, seconds}: hold a wide zone while the bar fills; the horde surges
##   destroy — {marker}: destroy an InfestationNest that keeps spawning zombies
##   carry   — {marker}: pick up the flight-recorder case (slows you, runners hunt you)
## Markers are children of the sector's "StepMarkers" node, looked up by name.

const STEP_COLOR := Color(1.0, 0.72, 0.0)
const SEARCH_RADIUS := 2.2
const DEFEND_RADIUS := 6.0
const CASE_SCENE := preload("res://scenes/objective_case.tscn")

var steps: Array = []
var index: int = -1
var run_kills: int = 0
var _kills_at_step_start: int = 0
var _search_time: float = 0.0
var _marker_pos: Vector3 = Vector3.ZERO
var _step_node: Node3D = null  # nest or case for the current step
var _status_timer: float = 0.0


func start() -> void:
	steps = contract.get("steps", [])
	_next_step()


func _current() -> Dictionary:
	return steps[index] if index >= 0 and index < steps.size() else {}


func _next_step() -> void:
	progress_changed.emit(0.0, false)
	if spawner:
		spawner.evac_frenzy = false  # a defend step's surge ends with the step
	if String(_current().get("type", "")) == "defend" and is_instance_valid(_step_node):
		_step_node.queue_free()
	index += 1
	_step_node = null
	_search_time = 0.0
	if index >= steps.size():
		_complete()
		return
	var step := _current()
	var marker := String(step.get("marker", ""))
	if marker != "":
		var node := sector.get_node_or_null("StepMarkers/" + marker) as Node3D
		if node:
			_marker_pos = node.global_position
		else:
			push_warning("[StepJob] Step marker '%s' not found; skipping step" % marker)
			_next_step()
			return

	match String(step.get("type", "")):
		"kill":
			_kills_at_step_start = run_kills
		"destroy":
			var nest := InfestationNest.new()
			nest.name = "Nest_" + marker
			nest.spawner = spawner
			sector.add_child(nest)
			nest.global_position = _marker_pos
			nest.destroyed.connect(_on_step_object_done)
			_step_node = nest
		"carry":
			var case_node: ObjectiveCase = CASE_SCENE.instantiate()
			sector.add_child(case_node)
			case_node.global_position = _marker_pos
			case_node.case_secured.connect(func(_p: Player): _on_step_object_done())
			case_node.add_child(make_beacon(Color(STEP_COLOR, 0.3), 1.6))
			_step_node = case_node
		"defend":
			var zone := make_beacon(Color(STEP_COLOR, 0.22), DEFEND_RADIUS)
			sector.add_child(zone)
			zone.global_position = _marker_pos
			_step_node = zone

	if step.has("radio"):
		radio_message.emit(String(step["radio"]))
	_update_status()


func _on_step_object_done() -> void:
	_next_step()


func _process(delta: float) -> void:
	if met or index < 0 or index >= steps.size() or not is_instance_valid(player):
		return
	var step := _current()
	match String(step.get("type", "")):
		"reach":
			if _flat_dist(player.global_position, _marker_pos) <= float(step.get("radius", 3.0)):
				_next_step()
				return
		"search", "defend":
			var seconds := float(step.get("seconds", 3.0))
			var radius := DEFEND_RADIUS if String(step.get("type", "")) == "defend" else SEARCH_RADIUS
			var inside := (_flat_dist(player.global_position, _marker_pos) <= radius
				and absf(player.global_position.y - _marker_pos.y) < 1.5)
			if String(step.get("type", "")) == "defend" and spawner:
				spawner.evac_frenzy = inside  # the surge comes while you hold
			if inside:
				_search_time += delta
				if _search_time >= seconds:
					_next_step()
					return
			if _search_time > 0.0:
				progress_changed.emit(_search_time / seconds, inside)
	_status_timer -= delta
	if _status_timer <= 0.0:
		_status_timer = 0.2
		_update_status()


func on_run_kills_changed(kills: int) -> void:
	run_kills = kills
	if met:
		return
	var step := _current()
	if String(step.get("type", "")) == "kill":
		if run_kills - _kills_at_step_start >= int(step.get("count", 10)):
			_next_step()
		else:
			_update_status()


func _update_status() -> void:
	var step := _current()
	if step.is_empty():
		return
	var title := String(step.get("title", "OBJECTIVE"))
	var detail := ""
	match String(step.get("type", "")):
		"kill":
			detail = "  %d / %d" % [run_kills - _kills_at_step_start, int(step.get("count", 10))]
		"defend":
			if _flat_dist(player.global_position, _marker_pos) <= DEFEND_RADIUS:
				detail = "  HOLD %ds" % int(ceil(float(step.get("seconds", 20.0)) - _search_time))
			else:
				detail = "  ·  %dm" % int(_flat_dist(player.global_position, _marker_pos))
		"search":
			if _search_time > 0.0 and _flat_dist(player.global_position, _marker_pos) <= SEARCH_RADIUS:
				detail = "  SEARCHING..."
			else:
				detail = "  ·  %dm" % int(_flat_dist(player.global_position, _marker_pos))
		_:
			var target: Variant = get_target_position()
			if target != null:
				detail = "  ·  %dm" % int(_flat_dist(player.global_position, target))
	status_changed.emit("%d/%d  %s%s" % [index + 1, steps.size() + 1, title, detail], STEP_COLOR)


func get_target_position() -> Variant:
	var step := _current()
	match String(step.get("type", "")):
		"kill", "":
			return null
		"destroy", "carry":
			if is_instance_valid(_step_node):
				return _step_node.global_position
			return null
	return _marker_pos


func get_locked_hint() -> String:
	var step := _current()
	return "First: " + String(step.get("title", "complete the objective")).capitalize()


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
