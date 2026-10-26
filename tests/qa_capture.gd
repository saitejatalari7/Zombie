extends SceneTree
## Renders one scene to a PNG. Run under xvfb with the opengl3 driver:
## godot --rendering-driver opengl3 --path . --script res://tests/qa_capture.gd -- <scene> <out.png> [frames]
var _frames := 0
var _target := 150
var _out := ""
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[1]
	if args.size() > 2:
		_target = int(args[2])
	root.size = Vector2i(540, 960)
	change_scene_to_file(args[0])
func _process(_d: float) -> bool:
	_frames += 1
	if _frames == _target:
		var img := root.get_texture().get_image()
		img.save_png(_out)
		print("saved ", _out)
		return true
	return false
