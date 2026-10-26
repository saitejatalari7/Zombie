extends Node
## UiTheme.gd — Autoload
## Builds the project-wide Theme (bundled Barlow fonts, type sizes, button, panel,
## bar and slider styles) and installs it on the root window, so every Control in
## every scene inherits it. Colours and sizes come from UIKit.

var font_body: Font
var font_body_bold: Font
var font_display: Font
var font_display_heavy: Font
var theme: Theme


func _ready() -> void:
	font_body = load("res://assets/ui/fonts/Barlow-Medium.woff2")
	font_body_bold = load("res://assets/ui/fonts/Barlow-Bold.woff2")
	font_display = load("res://assets/ui/fonts/BarlowCondensed-Bold.woff2")
	font_display_heavy = load("res://assets/ui/fonts/BarlowCondensed-ExtraBold.woff2")
	theme = _build()
	get_tree().root.theme = theme


func _flat(bg: Color, border: Color = Color(0, 0, 0, 0), border_bottom: int = 0, margin_h: int = 28, margin_v: int = 16, radius: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	s.border_color = border
	s.border_width_bottom = border_bottom
	s.content_margin_left = margin_h
	s.content_margin_right = margin_h
	s.content_margin_top = margin_v
	s.content_margin_bottom = margin_v
	return s


func _button_styles(t: Theme, type: String, bg: Color, edge: Color, text: Color) -> void:
	var r := UIKit.RADIUS_BUTTON
	t.set_stylebox("normal", type, _flat(bg, edge, 10, 28, 16, r))
	t.set_stylebox("hover", type, _flat(bg.lightened(0.08), edge, 10, 28, 16, r))
	var pressed := _flat(bg.darkened(0.12), edge, 2, 28, 16, r)
	pressed.content_margin_top = 24  # sinks by the edge height
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("disabled", type, _flat(UIKit.PANEL_2, UIKit.NAV_BG, 10, 28, 16, r))
	t.set_constant("icon_max_width", type, 56)
	t.set_constant("h_separation", type, 14)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	t.set_color("font_color", type, text)
	t.set_color("font_hover_color", type, text)
	t.set_color("font_pressed_color", type, text)
	t.set_color("font_focus_color", type, text)
	t.set_color("font_disabled_color", type, UIKit.MUTED)


func _build() -> Theme:
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = UIKit.SIZE_BODY

	# Labels
	t.set_color("font_color", "Label", UIKit.TEXT)
	for v in [["DisplayLabel", font_display_heavy, UIKit.SIZE_DISPLAY],
			["HeadingLabel", font_display_heavy, UIKit.SIZE_HEADING],
			["SubheadLabel", font_display, UIKit.SIZE_BUTTON],
			["CaptionLabel", font_body_bold, UIKit.SIZE_CAPTION]]:
		t.set_type_variation(v[0], "Label")
		t.set_font("font", v[0], v[1])
		t.set_font_size("font_size", v[0], v[2])
	t.set_color("font_color", "CaptionLabel", UIKit.DIM)

	# Buttons: crimson primary by default, ghost and amber variants
	t.set_font("font", "Button", font_display_heavy)
	t.set_font_size("font_size", "Button", UIKit.SIZE_BUTTON)
	_button_styles(t, "Button", UIKit.CRIMSON, UIKit.CRIMSON_DARK, Color.WHITE)
	t.set_type_variation("GhostButton", "Button")
	_button_styles(t, "GhostButton", UIKit.PANEL_2, UIKit.NAV_BG, UIKit.TEXT)
	t.set_type_variation("AmberButton", "Button")
	_button_styles(t, "AmberButton", UIKit.AMBER, UIKit.AMBER_DARK, Color(0.10, 0.08, 0.02))
	t.set_color("icon_normal_color", "AmberButton", Color(0.10, 0.08, 0.02))
	t.set_color("icon_pressed_color", "AmberButton", Color(0.10, 0.08, 0.02))
	t.set_color("icon_hover_color", "AmberButton", Color(0.10, 0.08, 0.02))
	t.set_color("icon_disabled_color", "AmberButton", UIKit.MUTED)
	# Flat text-only button (nav tabs, "Back")
	t.set_type_variation("FlatButton", "Button")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "FlatButton", StyleBoxEmpty.new())
	t.set_color("font_color", "FlatButton", UIKit.DIM)
	t.set_color("font_hover_color", "FlatButton", UIKit.TEXT)
	t.set_color("font_pressed_color", "FlatButton", UIKit.CRIMSON)

	# Panels / cards
	var card := _flat(Color(UIKit.PANEL, 0.96), UIKit.LINE, 0, 36, 32, UIKit.RADIUS)
	card.set_border_width_all(2)
	card.shadow_color = Color(0, 0, 0, 0.35)
	card.shadow_size = 14
	card.shadow_offset = Vector2(0, 6)
	t.set_stylebox("panel", "PanelContainer", card)
	t.set_type_variation("AccentCard", "PanelContainer")
	var accent := card.duplicate() as StyleBoxFlat
	accent.border_color = UIKit.AMBER
	accent.border_width_left = 8
	t.set_stylebox("panel", "AccentCard", accent)
	t.set_type_variation("DangerCard", "PanelContainer")
	var danger := card.duplicate() as StyleBoxFlat
	danger.bg_color = Color(UIKit.CRIMSON, 0.12)
	danger.border_color = UIKit.CRIMSON
	danger.border_width_left = 8
	t.set_stylebox("panel", "DangerCard", danger)
	t.set_type_variation("SuccessCard", "PanelContainer")
	var success := card.duplicate() as StyleBoxFlat
	success.bg_color = Color(UIKit.GREEN, 0.12)
	success.border_color = UIKit.GREEN
	success.border_width_left = 8
	t.set_stylebox("panel", "SuccessCard", success)
	t.set_type_variation("NavPanel", "PanelContainer")
	var nav := _flat(UIKit.NAV_BG, UIKit.LINE, 0, 0, 0)
	nav.border_width_top = 2
	t.set_stylebox("panel", "NavPanel", nav)

	# Progress bars and sliders
	t.set_stylebox("background", "ProgressBar", _flat(UIKit.BAR_BG, Color(0, 0, 0, 0), 0, 0, 0, 12))
	t.set_stylebox("fill", "ProgressBar", _flat(UIKit.AMBER, Color(0, 0, 0, 0), 0, 0, 0, 12))
	t.set_font_size("font_size", "ProgressBar", UIKit.SIZE_CAPTION)
	var track := _flat(UIKit.BAR_BG, Color(0, 0, 0, 0), 0, 0, 12, 12)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", _flat(UIKit.AMBER, Color(0, 0, 0, 0), 0, 0, 12, 12))
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(UIKit.AMBER, Color(0, 0, 0, 0), 0, 0, 12, 12))

	# Scroll bars stay thin and quiet
	t.set_stylebox("scroll", "VScrollBar", _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 4, 0))
	t.set_stylebox("grabber", "VScrollBar", _flat(UIKit.LINE, Color(0, 0, 0, 0), 0, 4, 0, 4))
	return t
