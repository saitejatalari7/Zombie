extends Control
class_name RoundButtonSkin
## RoundButtonSkin.gd
## Draws a round HUD button (fill, ring, icon, label and a cooldown sweep) over
## an existing TextureButton, so the button keeps its input wiring and only the
## look changes. Set the properties; it redraws itself.

var fill: Color = Color(0.067, 0.067, 0.075, 0.88):
	set(v):
		fill = v
		queue_redraw()
var ring: Color = Color(0, 0, 0, 0):
	set(v):
		ring = v
		queue_redraw()
var ring_width: float = 0.0:
	set(v):
		ring_width = v
		queue_redraw()
var icon: Texture2D = null:
	set(v):
		icon = v
		queue_redraw()
var icon_color: Color = Color.WHITE:
	set(v):
		icon_color = v
		queue_redraw()
var text: String = "":
	set(v):
		text = v
		queue_redraw()
var text_color: Color = Color.WHITE:
	set(v):
		text_color = v
		queue_redraw()
## 0 = ready, 1 = just used (dark sweep covering the button)
var cooldown: float = 0.0:
	set(v):
		cooldown = clampf(v, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	draw_circle(c, r, fill)
	if ring_width > 0.0 and ring.a > 0.0:
		draw_arc(c, r - ring_width * 0.5, 0.0, TAU, 64, ring, ring_width, true)
	if cooldown > 0.01:
		var pts := PackedVector2Array([c])
		var steps := 40
		for i in range(steps + 1):
			var a := -PI * 0.5 + TAU * cooldown * float(i) / float(steps)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.55))
	var has_text := text != ""
	if icon:
		var isz := r * (0.72 if has_text else 0.9)
		var icenter := c - Vector2(0.0, r * 0.16 if has_text else 0.0)
		draw_texture_rect(icon, Rect2(icenter - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false, icon_color)
	if has_text:
		var font := get_theme_font("font", "Button")
		var fs := int(clampf(r * 0.3, 22.0, 34.0))
		var y := c.y + r * 0.52
		draw_string(font, Vector2(c.x - r, y), text, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, text_color)
