extends SceneTree
## Skips to a contract's hunt step and lets the real auto-fire fight the Brute.
## Reports time to kill and damage taken (the player is unkillable).
## godot --headless --path . --script res://tests/qa_brute_fight.gd -- <contract_id>
var f := 0
var t0 := 0.0
var started := false

func _process(delta: float) -> bool:
	f += 1
	if f == 1:
		var gm = root.get_node("/root/GameManager")
		for sec in gm.CONTRACTS:
			for c in gm.CONTRACTS[sec]:
				if c["id"] == OS.get_cmdline_user_args()[0]:
					gm.current_sector = sec
					gm.current_contract = c.duplicate()
		change_scene_to_file("res://scenes/main.tscn")
		return false
	var s = current_scene
	if f < 30 or s == null or s.job == null:
		return false
	var job = s.job
	var p = s.player
	if not started:
		while String(job._current().get("type", "")) != "hunt":
			job._next_step()
		p.max_health = 100000.0
		p.current_health = 100000.0
		for z in get_nodes_in_group("zombies"):
			if z != job._step_node:
				z.queue_free()
		s.spawner.max_active_zombies = 0
		p.global_position = job._step_node.global_position + Vector3(0.0, 0.3, 10.0)
		started = true
		print("brute hp ", job._step_node.max_health)
		return false
	t0 += delta
	if not is_instance_valid(job._step_node) or String(job._current().get("type", "")) != "hunt":
		print("brute killed in %.1f s, damage taken %.0f" % [t0, 100000.0 - p.current_health])
		return true
	if t0 > 120.0:
		print("brute NOT killed in 120 s; hp left ", job._step_node.current_health)
		return true
	return false
