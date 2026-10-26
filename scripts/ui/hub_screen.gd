extends Control
## HubScreen.gd
## The outpost hub: top bar (rank, XP, currencies, settings), four tabs
## (Missions, Armory, Skills, Outpost) and the mission briefing before deploying.
## Built in code on the project theme (UiTheme / UIKit). Each tab is rebuilt from
## GameManager state whenever something changes, so the UI can't drift from the data.

enum Tab { MISSIONS, ARMORY, SKILLS, OUTPOST }

const TOP_BAR_H := 270
const NAV_H := 240
const MAIN_SCENE := "res://scenes/main.tscn"
const CARBINE_SCENE := preload("res://assets/models/weapons/assault_carbine.glb")
const SECTOR_NAMES := {1: "QUARANTINE BLOCK", 2: "TRANSIT GRID", 3: "BLACKOUT DOCKS", 4: "CRIMSON COMPLEX"}
const TRACK_INFO := {
	"damage_knockback": "+12% damage per level",
	"fire_rate_mag": "+4% fire rate per level",
	"penetration": "+1 enemy pierced per level",
	"crit_autoaim": "+12% crit chance per level",
}
const FACILITY_INFO := {
	"comms_array": ["COMMS ARRAY", "+15% contract payouts per tier"],
	"medbay": ["FIELD MEDBAY", "+20 starting health per tier"],
	"helipad": ["TACTICAL HELIPAD", "-3 s evac hold per tier"],
}
const NAV_ITEMS := [["MISSIONS", "missions"], ["ARMORY", "armory"], ["SKILLS", "skills"], ["OUTPOST", "outpost"]]

var gm = null  # GameManager (untyped: its script members are looked up at runtime)
var current_tab: Tab = Tab.MISSIONS
var selected_sector: int = 1
var selected_contract: int = 0

var _top_bar: Control = null
var _content: Control = null
var _nav_row: HBoxContainer = null
var _weapon_pivot: Node3D = null
var _refresh_queued: bool = false


func _ready() -> void:
	gm = get_node_or_null("/root/GameManager")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UIKit.PANEL
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_top_bar = Control.new()
	_top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top_bar.offset_bottom = TOP_BAR_H
	add_child(_top_bar)

	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = TOP_BAR_H
	_content.offset_bottom = -NAV_H
	add_child(_content)

	_build_nav()

	if gm:
		gm.coins_changed.connect(_queue_refresh.unbind(1))
		gm.research_cores_changed.connect(_queue_refresh.unbind(1))
		gm.clearance_level_changed.connect(_queue_refresh.unbind(1))
		gm.clearance_xp_changed.connect(_queue_refresh.unbind(2))
		selected_sector = clampi(gm.current_sector, 1, 4)
		if not gm.is_sector_playable(selected_sector):
			selected_sector = 1
		match String(gm.pending_hub_tab):
			"armory":
				current_tab = Tab.ARMORY
			"skills":
				current_tab = Tab.SKILLS
			"outpost":
				current_tab = Tab.OUTPOST
		gm.pending_hub_tab = ""
	_refresh()

	if gm and (gm.pending_refund_sc > 0 or gm.pending_refund_rc > 0):
		UIKit.toast(self, "Refunded %d SC + %d RC for gear still in development" % [gm.pending_refund_sc, gm.pending_refund_rc])
		gm.pending_refund_sc = 0
		gm.pending_refund_rc = 0


func _process(delta: float) -> void:
	if current_tab == Tab.ARMORY and is_instance_valid(_weapon_pivot):
		_weapon_pivot.rotate_y(delta * 0.8)


func _queue_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		call_deferred("_refresh")


func _refresh() -> void:
	_refresh_queued = false
	_build_top_bar()
	_update_nav()
	for c in _content.get_children():
		c.queue_free()
	_weapon_pivot = null
	match current_tab:
		Tab.MISSIONS:
			_build_missions()
		Tab.ARMORY:
			_build_armory()
		Tab.SKILLS:
			_build_skills()
		Tab.OUTPOST:
			_build_outpost()


func _click() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_click")


# ─── Top bar ──────────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	for c in _top_bar.get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = UIKit.NAV_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_top_bar.add_child(bg)
	var line := ColorRect.new()
	line.color = UIKit.LINE
	line.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	line.offset_top = -2
	_top_bar.add_child(line)
	if not gm:
		return

	var row := UIKit.hbox(20)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = UIKit.MARGIN
	row.offset_right = -UIKit.MARGIN
	row.offset_top = 110
	row.offset_bottom = 230
	_top_bar.add_child(row)

	# Rank badge
	var badge := PanelContainer.new()
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = UIKit.AMBER
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.custom_minimum_size = Vector2(120, 120)
	var badge_col := UIKit.vbox(-6)
	badge_col.alignment = BoxContainer.ALIGNMENT_CENTER
	var b1 := UIKit.label("CLR", "SubheadLabel", Color(0.07, 0.07, 0.07), 26)
	b1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b2 := UIKit.label("%02d" % gm.clearance_level, "HeadingLabel", Color(0.07, 0.07, 0.07), 58)
	b2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_col.add_child(b1)
	badge_col.add_child(b2)
	badge.add_child(badge_col)
	row.add_child(badge)

	# XP
	var xp_col := UIKit.vbox(8)
	xp_col.alignment = BoxContainer.ALIGNMENT_CENTER
	xp_col.custom_minimum_size = Vector2(300, 0)
	var need: int = gm.get_xp_for_next_level()
	xp_col.add_child(UIKit.label("%d / %d XP" % [gm.clearance_xp, need] if need > 0 else "MAX CLEARANCE", "CaptionLabel"))
	xp_col.add_child(UIKit.bar(float(gm.clearance_xp) / float(maxi(need, 1)) if need > 0 else 1.0))
	row.add_child(xp_col)

	row.add_child(UIKit.expander())

	# Currencies
	var cur := UIKit.vbox(6)
	cur.alignment = BoxContainer.ALIGNMENT_CENTER
	var sc := UIKit.currency("coin", gm.survival_coins, UIKit.AMBER)
	sc.alignment = BoxContainer.ALIGNMENT_END
	var rc := UIKit.currency("core", gm.research_cores, UIKit.CRIMSON)
	rc.alignment = BoxContainer.ALIGNMENT_END
	cur.add_child(sc)
	cur.add_child(rc)
	row.add_child(cur)

	var gear := Button.new()
	gear.theme_type_variation = "FlatButton"
	gear.icon = UIKit.icon_texture("gear")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(110, 110)
	gear.modulate = UIKit.DIM
	gear.focus_mode = Control.FOCUS_NONE
	gear.pressed.connect(_open_settings)
	row.add_child(gear)


func _open_settings() -> void:
	_click()
	var s := SettingsScreen.open(self)
	s.closed.connect(_queue_refresh)


# ─── Bottom navigation ────────────────────────────────────────────────────────
func _build_nav() -> void:
	var nav := PanelContainer.new()
	nav.theme_type_variation = "NavPanel"
	nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav.offset_top = -NAV_H
	add_child(nav)
	_nav_row = UIKit.hbox(0)
	nav.add_child(_nav_row)
	for i in range(NAV_ITEMS.size()):
		var item: Array = NAV_ITEMS[i]
		var b := Button.new()
		b.theme_type_variation = "FlatButton"
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, NAV_H)
		b.pressed.connect(_on_nav.bind(i))
		var col := UIKit.vbox(8)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := UIKit.icon(item[1], 70)
		ic.name = "Icon"
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(ic)
		var lb := UIKit.label(item[0], "SubheadLabel", UIKit.DIM, UIKit.SIZE_CAPTION)
		lb.name = "Label"
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lb)
		b.add_child(col)
		var bar := ColorRect.new()
		bar.name = "ActiveBar"
		bar.color = UIKit.CRIMSON
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
		bar.offset_bottom = 8
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bar)
		var dot := Panel.new()
		dot.name = "Dot"
		var ds := StyleBoxFlat.new()
		ds.bg_color = UIKit.GREEN
		ds.set_corner_radius_all(11)
		dot.add_theme_stylebox_override("panel", ds)
		dot.set_anchors_preset(Control.PRESET_CENTER_TOP)
		dot.offset_left = 40
		dot.offset_right = 62
		dot.offset_top = 40
		dot.offset_bottom = 62
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(dot)
		_nav_row.add_child(b)


func _update_nav() -> void:
	if not _nav_row:
		return
	var ready_flags := [false, false, false, false]
	if gm:
		ready_flags = [false, gm.can_afford_armory_upgrade(), gm.can_afford_skill(), gm.can_afford_outpost_upgrade()]
	for i in range(_nav_row.get_child_count()):
		var b := _nav_row.get_child(i)
		var active := i == int(current_tab)
		var col := UIKit.CRIMSON if active else UIKit.DIM
		(b.find_child("Icon", true, false) as CanvasItem).modulate = col
		(b.find_child("Label", true, false) as Label).add_theme_color_override("font_color", col)
		(b.get_node("ActiveBar") as CanvasItem).visible = active
		(b.get_node("Dot") as CanvasItem).visible = bool(ready_flags[i]) and not active


func _on_nav(index: int) -> void:
	if index == int(current_tab):
		return
	_click()
	current_tab = Tab.values()[index]
	_refresh()


## A scrollable column filling the content area (Armory, Skills, Outpost).
func _scroll_column() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var col := UIKit.vbox(20)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(UIKit.pad(col, UIKit.MARGIN, 40, UIKit.MARGIN, 40))
	(col.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return col


func _header(title: String, right: Control) -> HBoxContainer:
	var row := UIKit.hbox(16)
	var t := UIKit.label(title, "HeadingLabel")
	row.add_child(t)
	row.add_child(UIKit.expander())
	if right:
		row.add_child(right)
	return row


# ─── Missions ─────────────────────────────────────────────────────────────────
func _build_missions() -> void:
	var col := UIKit.vbox(24)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = UIKit.MARGIN
	col.offset_right = -UIKit.MARGIN
	col.offset_top = 40
	col.offset_bottom = -40
	_content.add_child(col)

	# Sector strip
	var strip_scroll := ScrollContainer.new()
	strip_scroll.custom_minimum_size = Vector2(0, 160)
	strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var strip := UIKit.hbox(16)
	strip_scroll.add_child(strip)
	col.add_child(strip_scroll)
	for s in range(1, 5):
		strip.add_child(_sector_tile(s))

	if not gm:
		return
	var contracts: Array = gm.get_contracts(selected_sector)
	selected_contract = clampi(selected_contract, 0, contracts.size() - 1)
	var c: Dictionary = contracts[selected_contract]

	# Contract card
	var card := UIKit.card()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(card)
	var body := UIKit.vbox(22)
	card.add_child(body)
	var head := UIKit.hbox(16)
	head.add_child(UIKit.label("CONTRACT %d / %d" % [selected_contract + 1, contracts.size()], "CaptionLabel", UIKit.AMBER))
	head.add_child(UIKit.expander())
	head.add_child(UIKit.label(String(c.get("threat", "")).replace("THREAT: ", "THREAT · "), "CaptionLabel"))
	body.add_child(head)
	var title := UIKit.label(_short_title(c), "HeadingLabel", UIKit.TEXT, 70)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(title)
	body.add_child(UIKit.paragraph(String(c.get("desc", "")), UIKit.TEXT_SOFT, 34))
	var steps := UIKit.vbox(12)
	var n := 1
	for line in _objective_lines(c):
		var r := UIKit.hbox(16)
		var num := UIKit.label(str(n), "SubheadLabel", UIKit.AMBER, 36)
		num.custom_minimum_size = Vector2(44, 0)
		r.add_child(num)
		r.add_child(UIKit.paragraph(line, UIKit.TEXT, 34))
		steps.add_child(r)
		n += 1
	body.add_child(steps)
	body.add_child(UIKit.expander())
	var first_clear: bool = not gm.is_sector_cleared(selected_sector)
	var payout: int = gm.get_contract_payout_sc(c) * (GameManager.FIRST_CLEAR_MULTIPLIER if first_clear else 1)
	var rewards := UIKit.hbox(30)
	rewards.add_child(UIKit.label("+%s SC" % UIKit.fmt_int(payout), "SubheadLabel", UIKit.AMBER))
	rewards.add_child(UIKit.label("+%d RC" % int(c.get("payout_rc", 0)), "SubheadLabel", UIKit.CRIMSON))
	if first_clear:
		var fc := UIKit.label("FIRST CLEAR ×2", "CaptionLabel", UIKit.GREEN)
		fc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rewards.add_child(fc)
	body.add_child(rewards)

	# Actions
	var actions := UIKit.hbox(20)
	if contracts.size() > 1:
		var next := UIKit.button("Next ›", "GhostButton")
		next.custom_minimum_size.x = 220
		next.pressed.connect(_on_next_contract)
		actions.add_child(next)
	var deploy := UIKit.button("Deploy")
	deploy.add_theme_font_size_override("font_size", 56)
	deploy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deploy.pressed.connect(_show_briefing.bind(c))
	actions.add_child(deploy)
	col.add_child(actions)


func _sector_tile(s: int) -> Control:
	var playable: bool = gm.is_sector_playable(s) if gm else s == 1
	var unlocked: bool = gm != null and s <= int(gm.highest_sector_unlocked)
	var selected := s == selected_sector
	var tile := Button.new()
	tile.theme_type_variation = "FlatButton"
	tile.focus_mode = Control.FOCUS_NONE
	tile.custom_minimum_size = Vector2(440, 150)
	tile.disabled = not (playable and unlocked)
	tile.pressed.connect(_on_sector.bind(s))
	var bg := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = UIKit.PANEL_2 if (playable and unlocked) else Color(0.086, 0.086, 0.098)
	st.border_color = UIKit.CRIMSON if selected else UIKit.LINE
	st.set_border_width_all(4 if selected else 2)
	st.set_content_margin_all(18)
	bg.add_theme_stylebox_override("panel", st)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UIKit.vbox(4)
	var top := UIKit.hbox(8)
	top.add_child(UIKit.label("SEC-%02d" % s, "SubheadLabel", UIKit.CRIMSON if selected else UIKit.DIM, UIKit.SIZE_CAPTION))
	top.add_child(UIKit.expander())
	if not (playable and unlocked):
		top.add_child(UIKit.icon("lock", 36, UIKit.MUTED))
	v.add_child(top)
	var sub: String
	if not playable:
		sub = "CLASSIFIED"
	elif not unlocked:
		sub = gm.get_sector_unlock_hint(s).to_upper() if gm else "LOCKED"
	else:
		sub = SECTOR_NAMES.get(s, "SECTOR")
	var name_label := UIKit.label(sub, "SubheadLabel", UIKit.TEXT if (playable and unlocked) else UIKit.MUTED, 36 if (playable and unlocked) else 28)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(name_label)
	bg.add_child(v)
	tile.add_child(bg)
	return tile


func _on_sector(s: int) -> void:
	_click()
	selected_sector = s
	selected_contract = 0
	_refresh()


func _on_next_contract() -> void:
	_click()
	selected_contract += 1
	if gm and selected_contract >= gm.get_contracts(selected_sector).size():
		selected_contract = 0
	_refresh()


func _short_title(c: Dictionary) -> String:
	var t := String(c.get("title", "CONTRACT"))
	var parts := t.split(": ", false, 1)
	return parts[parts.size() - 1]


func _objective_lines(c: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	match String(c.get("job", "kill_quota")):
		"steps":
			for st in c.get("steps", []):
				lines.append(String(st.get("title", "")).capitalize())
		"asset_recovery":
			lines.append("Recover the flight recorder")
		_:
			lines.append("Eliminate %d hostiles" % int(c.get("kills_required", 25)))
	lines.append("Hold the LZ")
	return lines


# ─── Briefing ─────────────────────────────────────────────────────────────────
func _show_briefing(c: Dictionary) -> void:
	_click()
	var layer := Control.new()
	layer.name = "Briefing"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	layer.add_child(UIKit.overlay(0.94))
	var col := UIKit.vbox(30)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = UIKit.MARGIN
	col.offset_right = -UIKit.MARGIN
	col.offset_top = UIKit.TOP_SAFE + 100
	col.offset_bottom = -100
	layer.add_child(col)

	col.add_child(UIKit.label("MISSION BRIEFING  ·  SEC-%02d" % selected_sector, "CaptionLabel", UIKit.AMBER, 34))
	var title := UIKit.label(_short_title(c), "DisplayLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)

	var radio := UIKit.card("AccentCard")
	var rrow := UIKit.hbox(26)
	rrow.add_child(UIKit.icon("radio", 80, UIKit.AMBER))
	var rcol := UIKit.vbox(10)
	rcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rcol.add_child(UIKit.label("OVERWATCH", "CaptionLabel", UIKit.AMBER))
	rcol.add_child(UIKit.paragraph(String(c.get("briefing", c.get("desc", ""))), UIKit.TEXT, 38))
	rrow.add_child(rcol)
	radio.add_child(rrow)
	col.add_child(radio)

	col.add_child(UIKit.label("OBJECTIVES", "CaptionLabel"))
	var n := 1
	for line in _objective_lines(c):
		col.add_child(UIKit.paragraph("%d  ·  %s" % [n, line], UIKit.TEXT, 36))
		n += 1
	if gm:
		var intel: Vector2i = gm.get_intel_progress(selected_sector)
		if intel.y > 0:
			col.add_child(UIKit.label("Intel found %d / %d" % [intel.x, intel.y], "CaptionLabel"))

	col.add_child(UIKit.expander())
	var start := UIKit.button("Start mission", "", 170)
	start.add_theme_font_size_override("font_size", 60)
	start.pressed.connect(_deploy.bind(c))
	col.add_child(start)
	var back := UIKit.button("Back", "FlatButton", UIKit.MIN_TOUCH)
	back.pressed.connect(layer.queue_free)
	col.add_child(back)


func _deploy(c: Dictionary) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("ui_confirm")
		if am.has_method("haptic_medium"):
			am.haptic_medium()
	if gm:
		gm.current_sector = selected_sector
		gm.current_contract = c.duplicate()
		gm.current_contract["sector"] = selected_sector
	var dnm = get_node_or_null("/root/DayNightManager")
	if dnm:
		dnm.set_sector_mode(selected_sector)
	var ls = get_node_or_null("/root/LoadingScreen")
	if ls and ls.has_method("transition_to_scene"):
		ls.transition_to_scene(MAIN_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_SCENE)


# ─── Armory ───────────────────────────────────────────────────────────────────
func _build_armory() -> void:
	var col := _scroll_column()
	col.add_child(_header("ARMORY", UIKit.currency("coin", gm.survival_coins if gm else 0, UIKit.AMBER)))

	# 3D weapon viewer
	var frame := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = UIKit.PANEL_2
	frame.add_theme_stylebox_override("panel", fs)
	frame.custom_minimum_size = Vector2(0, 420)
	col.add_child(frame)
	var view := SubViewportContainer.new()
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(view)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	view.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.transform = Transform3D(Basis(), Vector3(0.45, 0.6, 2.2)).looking_at(Vector3(0.0, 0.1, 0.0), Vector3.UP)
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.4
	sun.transform = Transform3D(Basis(), Vector3(2, 4, 3)).looking_at(Vector3.ZERO, Vector3.UP)
	vp.add_child(sun)
	_weapon_pivot = Node3D.new()
	_weapon_pivot.add_child(CARBINE_SCENE.instantiate())
	vp.add_child(_weapon_pivot)
	var caption := UIKit.hbox(16)
	caption.size_flags_vertical = Control.SIZE_SHRINK_END
	caption.add_child(UIKit.pad(UIKit.label("ARC-15 CARBINE", "SubheadLabel", UIKit.TEXT, 52), 30, 0, 0, 24))
	caption.add_child(UIKit.expander())
	caption.add_child(UIKit.pad(UIKit.label("2 more weapons coming", "CaptionLabel"), 0, 0, 30, 30))
	frame.add_child(caption)

	if not gm:
		return
	var weapon: String = GameManager.IMPLEMENTED_WEAPONS[0]
	for track in GameManager.UPGRADE_TRACKS:
		var lv: int = gm.get_weapon_upgrade_level(weapon, track)
		var maxed: bool = lv >= GameManager.MAX_WEAPON_UPGRADE_LEVEL
		var cost: int = (lv + 1) * GameManager.WEAPON_UPGRADE_COST_STEP
		var card := UIKit.card()
		var row := UIKit.hbox(20)
		var info := UIKit.vbox(12)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UIKit.label(String(GameManager.UPGRADE_TRACK_NAMES.get(track, track)), "SubheadLabel", UIKit.TEXT, 40))
		info.add_child(UIKit.label(TRACK_INFO.get(track, ""), "CaptionLabel"))
		info.add_child(UIKit.pips(lv, GameManager.MAX_WEAPON_UPGRADE_LEVEL))
		row.add_child(info)
		var buy := UIKit.button("MAX" if maxed else "%s SC" % UIKit.fmt_int(cost), "AmberButton", 130)
		buy.custom_minimum_size.x = 250
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.disabled = maxed or gm.survival_coins < cost
		buy.pressed.connect(_on_upgrade_weapon.bind(weapon, track, cost))
		row.add_child(buy)
		card.add_child(row)
		col.add_child(card)


func _on_upgrade_weapon(weapon: String, track: String, cost: int) -> void:
	if gm and gm.upgrade_weapon(weapon, track, cost):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_confirm")
	_queue_refresh()


# ─── Skills ───────────────────────────────────────────────────────────────────
func _build_skills() -> void:
	var col := _scroll_column()
	col.add_child(_header("SKILLS", UIKit.currency("core", gm.research_cores if gm else 0, UIKit.CRIMSON)))
	if not gm:
		return
	var eq: Array = gm.get_equipped_skills()

	var slots := UIKit.hbox(20)
	for i in range(2):
		var id: String = eq[i]
		var filled := id != ""
		var slot := Button.new()
		slot.theme_type_variation = "FlatButton"
		slot.focus_mode = Control.FOCUS_NONE
		slot.custom_minimum_size = Vector2(0, 170)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.disabled = not filled
		slot.pressed.connect(_on_unequip.bind(i))
		var bg := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = UIKit.PANEL_2 if filled else Color(0.086, 0.086, 0.098)
		st.border_color = UIKit.CRIMSON if filled else UIKit.LINE
		st.set_border_width_all(4 if filled else 2)
		st.set_content_margin_all(20)
		bg.add_theme_stylebox_override("panel", st)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := UIKit.vbox(4)
		v.add_child(UIKit.label("SLOT %d" % (i + 1), "CaptionLabel"))
		var nm: String = String(GameManager.SKILLS_DATA[id]["name"]) if filled and GameManager.SKILLS_DATA.has(id) else "EMPTY"
		v.add_child(UIKit.label(nm, "SubheadLabel", UIKit.TEXT if filled else UIKit.MUTED, 40))
		bg.add_child(v)
		slot.add_child(bg)
		slots.add_child(slot)
	col.add_child(slots)

	var pair_active: bool = "blood_siphon" in eq and "hemorrhage_rounds" in eq
	var pair := UIKit.card("DangerCard")
	var pv := UIKit.vbox(8)
	pv.add_child(UIKit.label("PAIR ACTIVE: CRIMSON BERSERKER" if pair_active else "PAIR: CRIMSON BERSERKER", "SubheadLabel", UIKit.CRIMSON, 36))
	pv.add_child(UIKit.paragraph("Every 6 kills made while standing in blood restores a molotov." if pair_active
		else "Equip Blood Siphon and Hemorrhage Rounds together: every 6 kills in blood restores a molotov.", UIKit.TEXT, 32))
	pair.add_child(pv)
	col.add_child(pair)

	for skill_id in GameManager.IMPLEMENTED_SKILLS:
		var data: Dictionary = GameManager.SKILLS_DATA.get(skill_id, {})
		var equipped: bool = skill_id in eq
		var unlocked: bool = gm.is_skill_unlocked(skill_id)
		var card := UIKit.card("DangerCard" if equipped else "")
		var v := UIKit.vbox(14)
		v.add_child(UIKit.label(String(data.get("name", skill_id)), "SubheadLabel", UIKit.TEXT, 44))
		v.add_child(UIKit.paragraph(String(data.get("desc", "")), UIKit.TEXT_SOFT, 34))
		var action: Button
		if equipped:
			action = UIKit.button("Equipped · tap to remove", "GhostButton", UIKit.MIN_TOUCH)
			action.pressed.connect(_on_unequip.bind(eq.find(skill_id)))
		elif unlocked:
			action = UIKit.button("Equip", "", UIKit.MIN_TOUCH)
			action.pressed.connect(_on_equip.bind(skill_id))
		elif gm.clearance_level < int(data.get("level_req", 1)):
			action = UIKit.button("Requires CLR-LV.%02d" % int(data.get("level_req", 1)), "GhostButton", UIKit.MIN_TOUCH)
			action.disabled = true
		else:
			var cost := int(data.get("cost_rc", 0))
			action = UIKit.button("Unlock · %d RC" % cost, "AmberButton", UIKit.MIN_TOUCH)
			action.disabled = gm.research_cores < cost
			action.pressed.connect(_on_unlock_skill.bind(skill_id, cost))
		v.add_child(action)
		card.add_child(v)
		col.add_child(card)

	var teaser := UIKit.card()
	var tr := UIKit.hbox(20)
	tr.add_child(UIKit.icon("lock", 56, UIKit.MUTED))
	tr.add_child(UIKit.label("MORE SKILL PAIRS IN SECTOR 02", "SubheadLabel", UIKit.MUTED, 36))
	teaser.add_child(tr)
	col.add_child(teaser)


func _on_unequip(slot: int) -> void:
	if gm and slot >= 0:
		gm.unequip_skill(slot)
	_click()
	_queue_refresh()


func _on_equip(skill_id: String) -> void:
	if not gm:
		return
	var eq: Array = gm.get_equipped_skills()
	gm.equip_skill(0 if eq[0] == "" else (1 if eq[1] == "" else 0), skill_id)
	_click()
	_queue_refresh()


func _on_unlock_skill(skill_id: String, cost: int) -> void:
	if gm and gm.spend_research_cores(cost):
		gm.unlock_skill(skill_id)
		var eq: Array = gm.get_equipped_skills()
		if eq[0] == "" or eq[1] == "":
			gm.equip_skill(0 if eq[0] == "" else 1, skill_id)
	_queue_refresh()


# ─── Outpost ──────────────────────────────────────────────────────────────────
func _build_outpost() -> void:
	var col := _scroll_column()
	var cur := UIKit.hbox(24)
	if gm:
		cur.add_child(UIKit.currency("coin", gm.survival_coins, UIKit.AMBER))
		cur.add_child(UIKit.currency("core", gm.research_cores, UIKit.CRIMSON))
	col.add_child(_header("OUTPOST", cur))
	if not gm:
		return
	for facility in GameManager.OUTPOST_FACILITIES:
		var info: Array = FACILITY_INFO.get(facility, [facility, ""])
		var lv: int = gm.get_outpost_level(facility)
		var maxed: bool = lv >= GameManager.MAX_OUTPOST_UPGRADE_LEVEL
		var cost: Vector2i = gm.get_outpost_upgrade_cost(facility)
		var card := UIKit.card()
		var v := UIKit.vbox(14)
		v.add_child(UIKit.label(String(info[0]), "SubheadLabel", UIKit.TEXT, 44))
		v.add_child(UIKit.label(String(info[1]), "CaptionLabel"))
		v.add_child(UIKit.label(_facility_now(facility, lv), "", UIKit.AMBER, 34))
		v.add_child(UIKit.pips(lv, GameManager.MAX_OUTPOST_UPGRADE_LEVEL))
		var b := UIKit.button("Max tier" if maxed else "Upgrade · %s SC + %d RC" % [UIKit.fmt_int(cost.x), cost.y], "AmberButton", UIKit.MIN_TOUCH)
		b.disabled = maxed or gm.survival_coins < cost.x or gm.research_cores < cost.y
		b.pressed.connect(_on_upgrade_facility.bind(facility))
		v.add_child(b)
		card.add_child(v)
		col.add_child(card)


func _facility_now(facility: String, lv: int) -> String:
	match facility:
		"comms_array":
			return "Now: +%d%% contract payouts" % (lv * 15)
		"medbay":
			return "Now: +%d starting health" % (lv * 20)
		"helipad":
			return "Now: evac hold %d s" % int(gm.get_evac_hold_time())
	return ""


func _on_upgrade_facility(facility: String) -> void:
	if not gm:
		return
	var cost: Vector2i = gm.get_outpost_upgrade_cost(facility)
	if gm.upgrade_outpost(facility, cost.x, cost.y):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_confirm")
	_queue_refresh()
