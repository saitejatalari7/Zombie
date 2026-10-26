extends Control
class_name ObjectivePointer
## ObjectivePointer.gd
## Shows where the current mission goal is. Off-screen: an arrow pinned to the
## screen edge pointing at it, with the distance. On-screen: a bobbing marker
## above the goal. Main calls point_at() every frame (or clear()).

const EDGE_MARGIN := 70.0
const TOP_MARGIN := 250.0     # keep clear of the mission pill / evac bar
const BOTTOM_MARGIN := 140.0
const ON_SCREEN_LIFT := 60.0  # px above the goal when it's visible

var _color: Color = Color(1.0, 0.72, 0.0)
var _angle: float = 0.0
var _on_screen: bool = false
var _bob: float = 0.0
var _label: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.06))
	_label.add_theme_constant_override("outline_size", 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = false


## world_pos: the goal; from: the player's position (for the distance readout).
func point_at(world_pos: Vector3, from: Vector3, color: Color) -> void:
	var cam := get_viewport().get_camera_3d()
	if not cam:
		clear()
		return
	_color = color
	var rect := get_viewport().get_visible_rect()
	var screen := cam.unproject_position(world_pos + Vector3(0.0, 1.2, 0.0))
	var behind := cam.is_position_behind(world_pos)
	var inner := Rect2(
		Vector2(EDGE_MARGIN, TOP_MARGIN),
		rect.size - Vector2(EDGE_MARGIN * 2.0, TOP_MARGIN + BOTTOM_MARGIN)
	)
	_on_screen = not behind and inner.has_point(screen)

	if _on_screen:
		_bob += get_process_delta_time() * 5.0
		position = screen - Vector2(0.0, ON_SCREEN_LIFT + sin(_bob) * 8.0)
		_angle = PI * 0.5  # pointing down at the goal
	else:
		# Pin to the edge of the inner rect along the direction from screen centre
		var center := inner.get_center()
		var dir := (screen - center)
		if behind:
			dir = -dir
		if dir.length_squared() < 0.001:
			dir = Vector2.UP
		dir = dir.normalized()
		var half := inner.size * 0.5
		var edge_t := minf(
			half.x / maxf(absf(dir.x), 0.0001),
			half.y / maxf(absf(dir.y), 0.0001)
		)
		position = center + dir * edge_t
		_angle = dir.angle()

	var dist := Vector2(world_pos.x - from.x, world_pos.z - from.z).length()
	_label.text = "%dm" % int(dist)
	_label.add_theme_color_override("font_color", color)
	_label.size = Vector2(160.0, 40.0)
	# Distance sits on the inside of the arrow so it never leaves the screen
	var label_offset := Vector2(0.0, -70.0) if _on_screen else -Vector2.from_angle(_angle) * 62.0
	_label.position = label_offset - _label.size * 0.5
	visible = true
	queue_redraw()


func clear() -> void:
	visible = false


func _draw() -> void:
	# Arrow head pointing along _angle, drawn around this control's origin
	var fwd := Vector2.from_angle(_angle)
	var side := fwd.orthogonal()
	var tip := fwd * 26.0
	var back_l := -fwd * 14.0 + side * 18.0
	var back_r := -fwd * 14.0 - side * 18.0
	var outline := Color(0.05, 0.05, 0.06, 0.9)
	draw_colored_polygon(PackedVector2Array([tip * 1.18, back_l * 1.22, back_r * 1.22]), outline)
	draw_colored_polygon(PackedVector2Array([tip, back_l, back_r]), _color)
	if not _on_screen:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(_color, 0.55), 3.0)
