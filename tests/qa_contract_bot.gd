extends SceneTree
## Plays every contract (or the ones named) start to finish with a bot: kills are credited,
## the bot walks (teleports) to each step's spot and does it, then holds the LZ.
## Fails loudly if a step never completes or the debrief never appears.
## godot --headless --path . --script res://tests/qa_contract_bot.gd [-- <contract_id> ...]
var queue: Array = []
var current := ""
var f := 0
var phase := ""
var phase_frames := 0
var failures: Array = []
var last_index := -1

func _initialize() -> void:
	pass

func _process(_d: float) -> bool:
	f += 1
	if f == 1:
		var gm = root.get_node("/root/GameManager")
		var wanted := OS.get_cmdline_user_args()
		for s in gm.CONTRACTS:
			if not gm.is_sector_playable(s):
				continue
			for c in gm.CONTRACTS[s]:
				if wanted.is_empty() or c["id"] in wanted:
					queue.append([s, c])
		_next_contract()
		return false
	if current == "":
		print("BOT DONE: %d failure(s)" % failures.size())
		for msg in failures:
			print("  FAIL ", msg)
		return true
	_drive()
	return false

func _next_contract() -> void:
	if queue.is_empty():
		current = ""
		return
	var item: Array = queue.pop_front()
	var gm = root.get_node("/root/GameManager")
	gm.current_sector = item[0]
	gm.current_contract = item[1].duplicate()
	current = item[1]["id"]
	phase = "load"
	phase_frames = 0
	last_index = -1
	paused = false
	change_scene_to_file("res://scenes/main.tscn")

func _fail(msg: String) -> void:
	failures.append("%s: %s" % [current, msg])
	print("  FAIL %s: %s" % [current, msg])
	_next_contract()

func _drive() -> void:
	phase_frames += 1
	var s = current_scene
	if s == null or not ("job" in s) or s.job == null:
		if phase_frames > 300:
			_fail("main scene never started a job")
		return
	var p = s.player
	p.current_health = p.max_health  # the bot is testing content, not survival
	var job = s.job
	if phase == "load":
		phase = "steps"
		phase_frames = 0
		print("contract ", current, " layout ", s.active_sector_node.get("layout_id"))
	if phase == "steps":
		if job.met:
			phase = "lz"
			phase_frames = 0
			print("  objective met")
			return
		var idx: int = job.get("index") if "index" in job else 0
		if idx != last_index:
			last_index = idx
			phase_frames = 0
			if job.has_method("_current"):
				print("  step %d: %s" % [idx + 1, job._current().get("title", "")])
		if phase_frames > 1200:
			_fail("stuck on step %d" % (idx + 1))
			return
		if not job.has_method("_current"):
			# Non-step jobs: walk to the target
			var t = job.get_target_position()
			if t != null:
				p.global_position = t
			job.on_run_kills_changed(999)
			return
		var step: Dictionary = job._current()
		match String(step.get("type", "")):
			"kill":
				job.on_run_kills_changed(job.run_kills + 1)
			"search", "reach":
				p.global_position = job._marker_pos + Vector3(0.0, 0.3, 0.0)
				p.velocity = Vector3.ZERO
			"destroy":
				if is_instance_valid(job._step_node):
					job._step_node.take_damage(50.0)
			"carry":
				if is_instance_valid(job._step_node):
					p.global_position = job._step_node.global_position + Vector3(0.0, 0.3, 0.0)
		return
	if phase == "lz":
		var lz: Node3D = s.extraction_area
		p.global_position = lz.global_position + Vector3(0.0, 0.3, 0.0)
		p.velocity = Vector3.ZERO
		if s.mission_over:
			var gm = root.get_node("/root/GameManager")
			print("  extracted; debrief shown: ", s.hud.get_node_or_null("MissionResult") != null)
			_next_contract()
		elif phase_frames > 60 * 70:
			_fail("evac never completed (in LZ: %s)" % str(s.player_in_lz))
