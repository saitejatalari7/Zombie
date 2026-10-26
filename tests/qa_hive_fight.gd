extends SceneTree
## Real auto-fire against this run's hives: the bot stands 7 m from the biggest live hive
## (unkillable, but damage is counted) and lets auto-aim fight the hive and its defenders.
## Reports the time each hive took, damage taken and kills.
## godot --headless --path . --script res://tests/qa_hive_fight.gd -- <contract_id>
var f := 0
var t := 0.0
var t_hive := 0.0
var target: Node3D = null

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
	if f < 40 or s == null or s.job == null:
		return false
	var p = s.player
	if f == 40:
		p.max_health = 100000.0
		p.current_health = 100000.0
		for h in get_nodes_in_group("hives"):
			print("hive %s hp %.0f at %s" % [h.size_class, h.max_health, str(h.global_position.snapped(Vector3(1, 1, 1)))])
	t += delta
	t_hive += delta
	if not is_instance_valid(target) or target.is_dead:
		if target != null:
			print("  %s hive down in %.1f s (total %.1f s, damage taken %.0f, kills %d)" % [target.size_class, t_hive, t, 100000.0 - p.current_health, s.spawner.total_kills])
		target = null
		var best_hp := -1.0
		for h in get_nodes_in_group("hives"):
			if not h.is_dead and h.max_health > best_hp:
				best_hp = h.max_health
				target = h
		if target == null:
			print("all hives down in %.1f s" % t)
			return true
		t_hive = 0.0
		p.global_position = _stand_spot(target)
		p.velocity = Vector3.ZERO
	if t > 300.0:
		print("timeout; hive hp left %.0f" % target.health)
		return true
	return false


## A spot 6-7 m from the hive, on floor at the hive's level, with a clear shot at it.
func _stand_spot(hive: Node3D) -> Vector3:
	var space := (hive as Node3D).get_world_3d().direct_space_state
	for dist: float in [7.0, 6.0, 5.0]:
		for i in range(8):
			var a := float(i) / 8.0 * TAU + PI * 0.5
			var probe: Vector3 = hive.global_position + Vector3(cos(a), 0.0, sin(a)) * dist
			var down := PhysicsRayQueryParameters3D.create(probe + Vector3(0, 30, 0), probe - Vector3(0, 4, 0), 1)
			var hit := space.intersect_ray(down)
			if hit.is_empty() or absf(hit.position.y - hive.global_position.y) > 0.6:
				continue
			var eye: Vector3 = hit.position + Vector3(0, 1.1, 0)
			var los := PhysicsRayQueryParameters3D.create(eye, hive.global_position + Vector3(0, 0.8, 0), 1)
			var seen := space.intersect_ray(los)
			if not seen.is_empty() and seen.collider == hive:
				return hit.position + Vector3(0, 0.3, 0)
	return hive.global_position + Vector3(0.0, 0.3, 7.0)
