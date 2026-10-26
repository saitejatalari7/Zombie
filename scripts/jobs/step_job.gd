extends MissionJob
class_name StepJob
## StepJob.gd
## A contract told as a short sequence of story steps; the LZ unlocks after the last.
## Step types (contract "steps" entries):
##   kill    — {count}: kill N hostiles (anywhere)
##   reach   — {marker, radius}: walk to a marker
##   search  — {marker, seconds}: stand at a marker while a bar fills (leaving pauses it)
##   defend  — {marker, seconds}: hold a wide zone while the bar fills; the horde surges
##   hives   — {sizes?}: burn out the sector's hives (GameManager.HIVE_PLAN), placed at
##             random "HiveSites" of the layout; every contract opens with one
##   destroy — {marker, size?}: destroy one hive at a marker
##   carry   — {marker}: pick up the flight-recorder case (slows you, runners hunt you)
##   hunt    — {marker, health, scale?, frenzy?}: a Crimson Brute (oversized heavy) waits
##             there; kill it. frenzy: the horde surges for the whole fight
## Markers are children of the sector's "StepMarkers" node, looked up by name.

const STEP_COLOR := Color(1.0, 0.72, 0.0)
const SEARCH_RADIUS := 2.2
const DEFEND_RADIUS := 6.0
const CASE_SCENE := preload("res://scenes/objective_case.tscn")
const BRUTE_SCENE := preload("res://scenes/zombie_tank.tscn")
const BRUTE_SCALE := 1.45

var steps: Array = []
var index: int = -1
var run_kills: int = 0
var _kills_at_step_start: int = 0
var _search_time: float = 0.0
var _marker_pos: Vector3 = Vector3.ZERO
var _step_node: Node3D = null  # nest or case for the current step
var _status_timer: float = 0.0
var _hives: Array[InfestationNest] = []
var _hives_total: int = 0

## A hive was burned out (for the HUD banner): size class and what it paid
signal hive_destroyed(size_class: String, reward: Dictionary)


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
			var nest := _make_hive(String(step.get("size", "M")), _marker_pos)
			nest.name = "Nest_" + marker
			nest.destroyed.connect(_on_step_object_done)
			_step_node = nest
		"hives":
			_place_hives(step)
		"carry":
			var case_node: ObjectiveCase = CASE_SCENE.instantiate()
			sector.add_child(case_node)
			case_node.global_position = _marker_pos
			case_node.case_secured.connect(func(_p: Player): _on_step_object_done())
			case_node.add_child(make_beacon(Color(STEP_COLOR, 0.3), 1.6))
			_step_node = case_node
		"hunt":
			var brute: Zombie = BRUTE_SCENE.instantiate()
			brute.name = String(step.get("boss_name", "CrimsonBrute"))
			var bscale := float(step.get("scale", BRUTE_SCALE))
			brute.max_health = float(step.get("health", 9000.0))
			brute.attack_damage = 34.0
			brute.stagger_duration = 0.0  # bullets don't stop it; molotovs and distance do
			brute.base_speed = 1.5
			brute.aggro_distance = 16.0
			sector.add_child(brute)
			brute.global_position = _marker_pos + Vector3(0.0, 0.2, 0.0)
			var vis := brute.get_node_or_null("Visuals") as Node3D
			if vis:
				vis.scale = Vector3.ONE * bscale
			# Body matches the bigger model, so point-blank shots spawn outside it and hit
			var col := brute.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col and col.shape is CapsuleShape3D:
				var cap := (col.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
				cap.radius *= bscale
				cap.height *= bscale
				col.shape = cap
				col.position.y *= bscale
			brute.attack_range = 1.6 * bscale
			if step.get("frenzy", false) and spawner:
				spawner.evac_frenzy = true  # cleared by _next_step when the boss dies
			brute.died.connect(_on_brute_died)
			_step_node = brute
		"defend":
			var zone := make_beacon(Color(STEP_COLOR, 0.22), DEFEND_RADIUS)
			sector.add_child(zone)
			zone.global_position = _marker_pos
			_step_node = zone

	if step.has("radio"):
		radio_message.emit(String(step["radio"]))
	_update_status()


func _on_brute_died(brute: Zombie) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and is_instance_valid(brute):
		gm.record_kill(brute.get_enemy_type())
	_next_step()


## Spawns a hive at a position, sized and scaled for this sector.
func _make_hive(size_class: String, pos: Vector3) -> InfestationNest:
	var gm = get_node_or_null("/root/GameManager")
	var hive := InfestationNest.new()
	hive.size_class = size_class
	hive.spawner = spawner
	if gm:
		hive.hp_scale = GameManager.HIVE_HP_SCALE[clampi(int(gm.current_sector), 0, 4)]
	hive.position = pos  # before entering the tree: its look is seeded from where it stands
	hive.hive_killed.connect(_on_hive_killed)
	sector.add_child(hive)
	return hive


## Places this run's hives: largest first, each at a random site that can hold its size,
## spread at least 14 m apart when the layout allows.
func _place_hives(step: Dictionary) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var sizes: Array = step.get("sizes", [])
	if sizes.is_empty() and gm:
		sizes = GameManager.HIVE_PLAN.get(int(gm.current_sector), ["M", "S"])
	var sites: Array = sector.get_marker_nodes("HiveSites")
	sites.shuffle()
	var used: Array[Vector3] = []
	for size_class in sizes:
		var pick: Node3D = null
		for strict in [true, false]:
			for site in sites:
				if not _site_fits(String(site.name), String(size_class)):
					continue
				var pos: Vector3 = (site as Node3D).global_position
				var far_enough := true
				for u in used:
					if strict and Vector2(u.x - pos.x, u.z - pos.z).length() < 14.0:
						far_enough = false
				if far_enough and not (pos in used):
					pick = site
					break
			if pick:
				break
		if pick == null:
			push_warning("[StepJob] No hive site left for a size %s hive" % size_class)
			continue
		used.append(pick.global_position)
		_hives.append(_make_hive(String(size_class), pick.global_position))
	_hives_total = _hives.size()
	if _hives_total == 0:
		_next_step.call_deferred()


## Site names carry the biggest hive they fit: HiveL_*, HiveM_*, HiveS_*.
func _site_fits(site_name: String, size_class: String) -> bool:
	var cap := "S"
	if site_name.begins_with("HiveL"):
		cap = "L"
	elif site_name.begins_with("HiveM"):
		cap = "M"
	return "SML".find(size_class) <= "SML".find(cap)


func _on_hive_killed(size_class: String, hive: InfestationNest) -> void:
	var gm = get_node_or_null("/root/GameManager")
	var reward: Dictionary = gm.record_hive(size_class) if gm else {}
	hive_destroyed.emit(size_class, reward)
	_hives.erase(hive)
	if String(_current().get("type", "")) == "hives":
		if _hives.is_empty():
			_next_step()
		else:
			_update_status()


func _nearest_hive() -> InfestationNest:
	var best: InfestationNest = null
	var best_d := INF
	for h in _hives:
		if is_instance_valid(h) and not h.is_dead:
			var d := _flat_dist(player.global_position, h.global_position)
			if d < best_d:
				best_d = d
				best = h
	return best


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
		"hives":
			detail = "  %d / %d" % [_hives_total - _hives.size(), _hives_total]
			var near := _nearest_hive()
			if near:
				detail += "  ·  %dm" % int(_flat_dist(player.global_position, near.global_position))
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
		"hives":
			var near := _nearest_hive()
			if near:
				return near.global_position
			return null
		"destroy", "carry", "hunt":
			if is_instance_valid(_step_node):
				return _step_node.global_position
			return null
	return _marker_pos


func get_locked_hint() -> String:
	var step := _current()
	return "First: " + String(step.get("title", "complete the objective")).capitalize()


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
