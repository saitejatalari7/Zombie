extends RefCounted
class_name UIKit
## UIKit.gd
## The game's UI design system in one place: colours, type sizes and small builders
## for the recurring components, so every screen is assembled the same way.
## Sizes are game pixels on the 1080 x 1920 portrait canvas.
## The Theme itself (fonts, button and panel styles) is built by the UiTheme autoload.

# ─── Colour: one job per colour ───────────────────────────────────────────────
# Warm-neutral charcoal rather than pure black, so panels read as soft surfaces.
const BG := Color(0.078, 0.086, 0.110)             # #14161c screen background
const PANEL := Color(0.114, 0.125, 0.161)          # #1d2029 cards
const PANEL_2 := Color(0.153, 0.169, 0.212)        # #272b36 raised / selected
const NAV_BG := Color(0.063, 0.071, 0.090)         # #101217
const LINE := Color(0.204, 0.224, 0.275)           # #343946
const TEXT := Color(0.961, 0.965, 0.980)           # #f5f6fa
const TEXT_SOFT := Color(0.788, 0.800, 0.839)      # body copy on panels
const DIM := Color(0.561, 0.580, 0.639)            # #8f94a3 secondary
const MUTED := Color(0.400, 0.420, 0.478)          # disabled / locked
const CRIMSON := Color(1.0, 0.200, 0.278)          # #ff3347 actions
const CRIMSON_DARK := Color(0.690, 0.094, 0.165)
const AMBER := Color(1.0, 0.773, 0.192)            # #ffc531 coins, progress
const AMBER_DARK := Color(0.690, 0.490, 0.0)
const CYAN := Color(0.310, 0.847, 0.941)           # the player
const GREEN := Color(0.290, 0.871, 0.502)          # #4ade80 success, "ready"
const BAR_BG := Color(0.200, 0.216, 0.263)

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
const RADIUS := 32          # cards
const RADIUS_BUTTON := 36   # chunky, friendly buttons


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
static func button(text: String, variation: String = "", height: int = PRIMARY_HEIGHT, icon_name: String = "") -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	if icon_name != "":
		b.icon = icon_texture(icon_name)
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
	bg.set_corner_radius_all(height / 2)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(height / 2)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fg)
	pb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pb


## A row of level pips (e.g. 3 of 10 lit).
static func pips(lit: int, total: int, color: Color = AMBER) -> HBoxContainer:
	var row := hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(total):
		var p := Panel.new()
		p.custom_minimum_size = Vector2(34, 16)
		p.add_theme_stylebox_override("panel", rounded(color if i < lit else BAR_BG, 8))
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(p)
	return row


## Icon + value, e.g. coins in the top bar.
static func currency(icon_name: String, value: int, color: Color, size: int = SIZE_BUTTON, prefix: String = "") -> HBoxContainer:
	var row := hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := icon(icon_name, size, color)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	row.add_child(label(prefix + fmt_int(value), "SubheadLabel", color if prefix != "" else TEXT, size))
	return row


## A currency value in a dark rounded pill (top bars).
static func currency_pill(icon_name: String, value: int, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var st := rounded(NAV_BG, 40)
	st.content_margin_left = 18
	st.content_margin_right = 30
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(currency(icon_name, value, color, 46))
	return p


## A flat rounded StyleBox (pills, badges, segments).
static func rounded(bg: Color, radius: int = RADIUS) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(radius)
	st.anti_aliasing = true
	return st


## A small coloured chip with text, e.g. "FIRST CLEAR x2".
static func chip(text: String, color: Color, size: int = SIZE_CAPTION) -> PanelContainer:
	var p := PanelContainer.new()
	var st := rounded(Color(color, 0.16), 28)
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(label(text, "CaptionLabel", color, size))
	return p


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
