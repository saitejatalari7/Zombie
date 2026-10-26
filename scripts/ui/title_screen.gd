extends Control
## TitleScreen.gd
## First screen: the live outpost diorama behind a dark gradient, the logo,
## one big button, and the player's rank and currencies so progress is visible
## the moment the game opens.

const HUB_SCENE := "res://scenes/ui/hub_screen.tscn"
const DIORAMA_SCENE := preload("res://scenes/ui/outpost_diorama.tscn")


func _ready() -> void:
	AudioManager.play_music_track("menu")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UIKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Live 3D diorama
	var view := SubViewportContainer.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.add_child(DIORAMA_SCENE.instantiate())
	view.add_child(vp)
	add_child(view)

	# Dark at the top (logo) and bottom (button), clear in the middle
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.68, 1.0])
	grad.colors = PackedColorArray([Color(UIKit.BG, 0.96), Color(UIKit.BG, 0.5), Color(UIKit.BG, 0.12), Color(UIKit.BG, 0.94)])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0.5, 0.0)
	gtex.fill_to = Vector2(0.5, 1.0)
	gtex.width = 8
	gtex.height = 256
	var shade := TextureRect.new()
	shade.texture = gtex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	# Logo
	var logo := UIKit.vbox(0)
	logo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	logo.offset_top = 330
	logo.offset_left = 60
	logo.offset_right = -60
	add_child(logo)
	var l1 := UIKit.label("PROTOCOL", "DisplayLabel", UIKit.TEXT, 150)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_child(l1)
	var l2 := UIKit.label("CRIMSON", "DisplayLabel", UIKit.CRIMSON, 170)
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_child(l2)

	# Deploy button + progress line
	var bottom := UIKit.vbox(30)
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 140
	bottom.offset_right = -140
	bottom.offset_top = -480
	bottom.offset_bottom = -140
	add_child(bottom)
	var deploy := UIKit.button("Play", "", 180)
	deploy.add_theme_font_size_override("font_size", 76)
	deploy.pressed.connect(_on_deploy)
	bottom.add_child(deploy)
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		var stats := UIKit.hbox(36)
		stats.alignment = BoxContainer.ALIGNMENT_CENTER
		stats.add_child(UIKit.label("Level %d" % gm.clearance_level, "SubheadLabel", UIKit.TEXT_SOFT, 40))
		stats.add_child(UIKit.currency("coin", gm.survival_coins, UIKit.AMBER, 40))
		stats.add_child(UIKit.currency("core", gm.research_cores, UIKit.CRIMSON, 40))
		bottom.add_child(stats)

	# Settings gear
	var gear := Button.new()
	gear.theme_type_variation = "FlatButton"
	gear.icon = UIKit.icon_texture("gear")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(UIKit.MIN_TOUCH, UIKit.MIN_TOUCH)
	gear.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gear.offset_left = -UIKit.MARGIN - UIKit.MIN_TOUCH
	gear.offset_right = -UIKit.MARGIN
	gear.offset_top = UIKit.TOP_SAFE
	gear.offset_bottom = UIKit.TOP_SAFE + UIKit.MIN_TOUCH
	gear.modulate = UIKit.DIM
	gear.focus_mode = Control.FOCUS_NONE
	gear.pressed.connect(func(): SettingsScreen.open(self))
	add_child(gear)


func _on_deploy() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_confirm")
	get_tree().change_scene_to_file(HUB_SCENE)
