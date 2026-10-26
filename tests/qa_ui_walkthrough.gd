extends SceneTree
## Screenshots every hub tab, the briefing, pause and both debriefs into <out_dir>:
## godot --rendering-driver opengl3 --path . --script res://tests/qa_ui_walkthrough.gd -- <out_dir>
var out := ""
var f := 0
var step := 0
var shots: Array = []
func _initialize() -> void:
	out = OS.get_cmdline_user_args()[0]
	root.size = Vector2i(540, 960)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png(out + "/qa_" + name + ".png")
	print("shot ", name)
func _process(_d: float) -> bool:
	f += 1
	if f % 30 != 0:
		return false
	var s = current_scene
	var st := step
	step += 1
	match st:
		0:
			var gm = root.get_node("/root/GameManager")
			gm.survival_coins = 1500
			gm.research_cores = 6
			change_scene_to_file("res://scenes/ui/hub_screen.tscn")
		1: s.current_tab = 1; s._refresh()
		2: _shot("armory"); s.current_tab = 2; s._refresh()
		3: _shot("skills"); s.current_tab = 3; s._refresh()
		4: _shot("outpost"); s.current_tab = 0; s._refresh()
		5: s._show_briefing(root.get_node("/root/GameManager").get_contracts(1)[0])
		6: _shot("briefing"); root.get_node("/root/GameManager").current_sector = 1; change_scene_to_file("res://scenes/main.tscn")
		8: s.hud.toggle_pause()
		9: _shot("pause"); s.hud.resume_game()
		10: s._extract()
		11: _shot("debrief_win"); paused = false; reload_current_scene()
		13: s._resolve_death()
		14: _shot("debrief_dead"); return true
	return false
