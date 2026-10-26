extends SceneTree
## Renders a whole layout from the game's camera direction (orthographic) and from above.
## godot --rendering-driver opengl3 --path . --script res://tests/qa_layout_overview.gd -- <layout_id> <out_prefix>
var f := 0
var out := ""
var cam: Camera3D
var bounds: Rect2

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[1]
	root.size = Vector2i(1000, 1000)
	var world := Node3D.new()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.82, 0.84, 0.87)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.62, 0.68)
	env.environment.ambient_light_energy = 0.35
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, 106.0, 0.0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	world.add_child(sun)
	var sector: Node3D = load("res://scenes/sectors/sector_1_quarantine_block.tscn").instantiate()
	sector.set("layout_id", args[0])
	world.add_child(sector)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	root.add_child(world)
	bounds = sector.get("sector_bounds")

func _process(_d: float) -> bool:
	f += 1
	var c := Vector3(bounds.get_center().x, 0.0, bounds.get_center().y)
	if f == 2:
		# Game camera direction, whole map
		cam.size = maxf(bounds.size.x, bounds.size.y) * 1.25
		cam.global_position = c + Vector3(9.9, 33.0, 23.1).normalized() * 150.0
		cam.look_at(c, Vector3.UP)
	if f == 20:
		root.get_texture().get_image().save_png(out + "_iso.png")
		cam.size = maxf(bounds.size.x, bounds.size.y) * 1.1
		cam.global_position = c + Vector3(0.0, 150.0, 0.01)
		cam.look_at(c, Vector3.UP)
	if f == 40:
		root.get_texture().get_image().save_png(out + "_top.png")
		return true
	return false
