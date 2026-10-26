extends RefCounted
class_name UIKit
## UIKit.gd
## The game's UI design system in one place: colours, type sizes and small builders
## for the recurring components, so every screen is assembled the same way.
## Sizes are game pixels on the 1080 x 1920 portrait canvas.
## The Theme itself (fonts, button and panel styles) is built by the UiTheme autoload.

# ─── Colour: one job per colour ───────────────────────────────────────────────
const PANEL := Color(0.067, 0.067, 0.075)          # #111113
const PANEL_2 := Color(0.11, 0.11, 0.125)          # #1c1c20
const NAV_BG := Color(0.043, 0.043, 0.051)         # #0b0b0d
const LINE := Color(0.18, 0.18, 0.204)             # #2e2e34
const TEXT := Color(0.957, 0.957, 0.965)           # #f4f4f6
const TEXT_SOFT := Color(0.784, 0.784, 0.816)      # body copy on panels
const DIM := Color(0.604, 0.604, 0.643)            # #9a9aa4
const MUTED := Color(0.424, 0.424, 0.455)          # disabled / locked
const CRIMSON := Color(0.898, 0.035, 0.078)        # actions, danger
const CRIMSON_DARK := Color(0.561, 0.0, 0.035)
const AMBER := Color(1.0, 0.722, 0.0)              # coins, objectives, progress
const AMBER_DARK := Color(0.541, 0.392, 0.0)
const CYAN := Color(0.247, 0.878, 0.941)           # the player
const GREEN := Color(0.31, 0.82, 0.545)            # success, "ready"
const BAR_BG := Color(0.165, 0.165, 0.184)

# ─── Type scale (never below CAPTION) ─────────────────────────────────────────
const SIZE_DISPLAY := 96
const SIZE_HEADING := 64
const SIZE_BUTTON := 44
const SIZE_BODY := 36
const SIZE_CAPTION := 30

# ─── Layout ───────────────────────────────────────────────────────────────────
const MARGIN := 48
const TOP_SAFE := 96
const MIN_TOUCH := 120
const PRIMARY_HEIGHT := 150


static func icon_texture(icon_name: String) -> Texture2D:
	return load("res://assets/ui/icons/%s.svg" % icon_name) as Texture2D


## A tinted icon at a fixed pixel size.
static func icon(icon_name: String, px: int, color: Color = TEXT) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon_texture(icon_name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.modulate = color
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## variation: "", "DisplayLabel", "HeadingLabel", "SubheadLabel", "CaptionLabel"
static func label(text: String, variation: String = "", color: Color = TEXT, size: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.add_theme_color_override("font_color", color)
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func paragraph(text: String, color: Color = TEXT_SOFT, size: int = SIZE_BODY) -> Label:
	var l := label(text, "", color, size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## variation: "" (crimson primary), "GhostButton", "AmberButton"
static func button(text: String, variation: String = "", height: int = PRIMARY_HEIGHT) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_NONE
	return b


## variation: "" (default card) or "AccentCard" (amber left edge) / "DangerCard" (crimson edge)
static func card(variation: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	return p


static func vbox(separation: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expander() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func bar(fraction: float, fill: Color = AMBER, height: int = 18) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.max_value = 1.0
	pb.value = clampf(fraction, 0.0, 1.0)
	pb.custom_minimum_size = Vector2(0, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


## A row of level pips (e.g. 3 of 10 lit).
static func pips(lit: int, total: int, color: Color = AMBER) -> HBoxContainer:
	var row := hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(total):
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(30, 18)
		p.color = color if i < lit else BAR_BG
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(p)
	return row


## Icon + value, e.g. coins in the top bar.
static func currency(icon_name: String, value: int, color: Color, size: int = SIZE_BUTTON) -> HBoxContainer:
	var row := hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon(icon_name, size, color))
	row.add_child(label(fmt_int(value), "SubheadLabel", color, size))
	return row


## A full-screen dimmed overlay that swallows input (modals, briefing, debrief).
static func overlay(alpha: float = 0.9) -> ColorRect:
	var o := ColorRect.new()
	o.color = Color(0.039, 0.039, 0.047, alpha)
	o.set_anchors_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	return o


## Wraps a node in margins (game px).
static func pad(node: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.add_child(node)
	return m


## 1240 -> "1,240"
static func fmt_int(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## A short-lived message near the top of the screen.
static func toast(parent: Control, text: String, color: Color = AMBER, top: int = 300) -> void:
	var c := card("AccentCard")
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_CENTER_TOP)
	c.offset_left = -440
	c.offset_right = 440
	c.offset_top = top
	var l := paragraph(text, color, SIZE_BODY)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_child(l)
	parent.add_child(c)
	var tw := c.create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(c, "modulate:a", 0.0, 0.4)
	tw.tween_callback(c.queue_free)
