extends SceneTree
## Stands a non-shooting, unkillable player at the spawn for 30 s and reports how many
## zombies reached them: a quick check that the flow field routes around every obstacle.
## godot --headless --path . --script res://tests/qa_zombie_reach.gd -- <contract_id>
var f := 0
func _process(_d: float) -> bool:
	f += 1
	if f == 1:
		var gm = root.get_node("/root/GameManager")
		for c in gm.CONTRACTS[1]:
			if c["id"] == OS.get_cmdline_user_args()[0]:
				gm.current_sector = 1
				gm.current_contract = c.duplicate()
		change_scene_to_file("res://scenes/main.tscn")
	if f == 30:
		var s = current_scene
		s.player.auto_fire_enabled = false
		s.player.max_health = 100000.0
		s.player.current_health = 100000.0
	if f == 1800:
		var s = current_scene
		var near := 0
		for z in get_nodes_in_group("zombies"):
			if z.global_position.distance_to(s.player.global_position) < 4.0:
				near += 1
		for z in get_nodes_in_group("zombies"):
			print("  zombie ", z.global_position.snapped(Vector3(0.1,0.1,0.1)), " d ", snappedf(z.global_position.distance_to(s.player.global_position), 0.1), " vel ", snappedf(z.velocity.length(), 0.1))
		print("damage taken in 30 s: ", 100000.0 - s.player.current_health, "  zombies within 4 m: ", near, " alive: ", s.spawner.alive_zombies)
		return true
	return false
