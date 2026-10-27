extends SceneTree
## Drives the in-run HUD with simulated multi-finger touches, the way a phone sends them:
## thumb on the stick (right), second finger on fire / molotov (left), then lets go.
## Prints PASS/FAIL per check and saves a screenshot of the controls held down.
## godot --rendering-driver opengl3 --path . --script res://tests/qa_touch_controls.gd -- <out_dir>
var f := 0
var hud = null  # untyped: naming game classes here compiles them before autoloads exist
var player = null
var fails := 0
var out := ""
var start_pos := Vector3.ZERO

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	change_scene_to_file("res://scenes/main.tscn")

func _check(name: String, ok: bool, detail: String = "") -> void:
	print("%s %s %s" % ["PASS" if ok else "FAIL", name, detail])
	if not ok:
		fails += 1

## Touch events arrive in window pixels; the HUD works in the 1080 x 1920 canvas.
func _to_window(canvas_pos: Vector2) -> Vector2:
	return root.get_final_transform() * canvas_pos

func _touch(idx: int, canvas_pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = _to_window(canvas_pos)
	e.pressed = pressed
	Input.parse_input_event(e)

func _drag(idx: int, canvas_pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = _to_window(canvas_pos)
	Input.parse_input_event(e)

func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func _process(_d: float) -> bool:
	f += 1
	if f == 40:
		hud = current_scene.get_node("MobileHUD")
		player = current_scene.get_node("Player")
		var view := root.get_visible_rect().size
		_check("stick rests on the right", _center(hud.joystick.base).x > view.x * 0.5)
		_check("fire on the left", _center(hud.fire_button).x < view.x * 0.5)
		start_pos = player.global_position
		# Thumb lands in the stick zone and pushes up
		_touch(0, Vector2(800, 1500), true)
	elif f == 42:
		_drag(0, Vector2(800, 1380))
	elif f == 44:
		_check("stick drives the player", player.mobile_move_input.y < -0.9, str(player.mobile_move_input))
		# Second finger on fire while the stick is held
		_touch(1, _center(hud.fire_button), true)
	elif f == 46:
		_check("fire with the stick held", player.mobile_fire_pressed)
		_drag(1, _center(hud.fire_button) + Vector2(100, 0))
	elif f == 48:
		_check("fire drag aims", player.mobile_aim_input.x > 0.5, str(player.mobile_aim_input))
		_touch(1, _center(hud.fire_button), false)
	elif f == 50:
		_check("fire released", not player.mobile_fire_pressed)
		_check("stick still held", player.mobile_move_input.length() > 0.9)
		_touch(1, _center(hud.molotov_button), true)
	elif f == 52:
		_check("molotov aims with the stick held", hud.is_molotov_aiming or player.molotov_ammo <= 0)
		var img := root.get_texture().get_image()
		img.save_png(out.path_join("qa_touch_controls.png"))
		_touch(1, _center(hud.molotov_button), false)
		_touch(0, Vector2(800, 1380), false)
	elif f == 56:
		_check("stick released", player.mobile_move_input == Vector2.ZERO)
		_check("player walked", player.global_position.distance_to(start_pos) > 0.5,
			"%.2f m" % player.global_position.distance_to(start_pos))
		print("TOUCH QA DONE: %d failure(s)" % fails)
		return true
	return false
