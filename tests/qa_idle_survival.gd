extends SceneTree
## Difficulty probe: an idle player (auto-fire on, unkillable, damage counted) at the spawn
## for 60 s with the normal horde. Prints damage taken and kills.
## godot --headless --path . --script res://tests/qa_idle_survival.gd -- <contract_id>
var f := 0
var t := 0.0
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
	if f < 30 or s == null or s.player == null:
		return false
	if f == 30:
		s.player.max_health = 100000.0
		s.player.current_health = 100000.0
	t += delta
	if t >= 60.0:
		print("60 s idle: damage taken %.0f, kills %d" % [100000.0 - s.player.current_health, s.spawner.total_kills])
		return true
	return false
