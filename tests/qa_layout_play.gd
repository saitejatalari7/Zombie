extends SceneTree
## Plays a contract in the game camera and screenshots the spawn and every story-step spot.
## godot --rendering-driver opengl3 --path . --script res://tests/qa_layout_play.gd -- <contract_id> <out_prefix>
var f := 0
var out := ""
var spots: Array = []
var shot := 0

func _initialize() -> void:
	out = OS.get_cmdline_user_args()[1]
	root.size = Vector2i(540, 960)

## Autoloads only exist once the tree runs, so the contract is set up on the first frame.
func _start() -> void:
	var gm = root.get_node("/root/GameManager")
	var wanted := OS.get_cmdline_user_args()[0]
	for s in gm.CONTRACTS:
		for c in gm.CONTRACTS[s]:
			if c["id"] == wanted:
				gm.current_sector = s
				gm.current_contract = c.duplicate()
	change_scene_to_file("res://scenes/main.tscn")

func _process(_d: float) -> bool:
	f += 1
	if f == 1:
		_start()
		return false
	var s = current_scene
	if f == 30:
		s.player.max_health = 100000.0
		s.player.current_health = 100000.0
		spots.append(s.player.global_position)
		for m in s.active_sector_node.get_marker_nodes("StepMarkers"):
			spots.append(m.global_position + Vector3(0.0, 0.3, 1.5))
		spots.append(s.active_sector_node.extraction_zone.global_position + Vector3(0.0, 0.3, 0.0))
	if f > 30 and (f - 30) % 90 == 0:
		root.get_texture().get_image().save_png("%s_%d.png" % [out, shot])
		shot += 1
		if shot >= spots.size():
			print("job status ok; shots ", shot)
			return true
		s.player.global_position = spots[shot]
		s.player.velocity = Vector3.ZERO
	return false
