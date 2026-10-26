extends Control
## HubScreen.gd
## The outpost hub: top bar (rank, XP, currencies, settings), four tabs
## (Missions, Armory, Skills, Outpost) and the mission briefing before deploying.
## Built in code on the project theme (UiTheme / UIKit). Each tab is rebuilt from
## GameManager state whenever something changes, so the UI can't drift from the data.

enum Tab { MISSIONS, ARMORY, SKILLS, OUTPOST }

const TOP_BAR_H := 250
const NAV_H := 230
const MAIN_SCENE := "res://scenes/main.tscn"
const CARBINE_SCENE := preload("res://assets/models/weapons/assault_carbine.glb")
const SECTOR_NAMES := {1: "Quarantine Block", 2: "Transit Grid", 3: "Blackout Docks", 4: "Crimson Complex"}
const SECTOR_TAGLINES := {
	1: "Where the outbreak started. The medevac went down here, and so did the block.",
	2: "Rail yards and tunnels. Survivors are holding out in the terminal.",
	3: "No power, no light. Something big nests in the cranes.",
	4: "The lab that made Crimson. End it at the source.",
}
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
const NAV_ITEMS := [["Missions", "missions"], ["Armory", "armory"], ["Skills", "skills"], ["Outpost", "outpost"]]

var gm = null  # GameManager (untyped: its script members are looked up at runtime)
var current_tab: Tab = Tab.MISSIONS
var selected_sector: int = 1
var selected_contract: int = 0

var _top_bar: Control = null
var _content: Control = null
var _nav_row: HBoxContainer = null
var _weapon_pivot: Node3D = null
var _refresh_queued: bool = false
var _swipe_from: float = -1.0
var _sway_t: float = 0.0


func _ready() -> void:
	gm = get_node_or_null("/root/GameManager")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UIKit.BG
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
		UIKit.toast(self, "Refunded %d coins and %d cores for gear still in development" % [gm.pending_refund_sc, gm.pending_refund_rc])
		gm.pending_refund_sc = 0
		gm.pending_refund_rc = 0


func _process(delta: float) -> void:
	if current_tab == Tab.ARMORY and is_instance_valid(_weapon_pivot):
		# Gentle sway rather than a full spin, so the gun never turns end-on
		_sway_t += delta
		_weapon_pivot.rotation.y = sin(_sway_t * 0.7) * 0.5


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
	if not gm:
		return
	var row := UIKit.hbox(22)
	row.set_anchors_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = UIKit.MARGIN
	row.offset_right = -UIKit.MARGIN
	row.offset_top = UIKit.TOP_SAFE
	row.offset_bottom = UIKit.TOP_SAFE + 140
	_top_bar.add_child(row)

	# Level: a round amber badge, the bar shows progress to the next level
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UIKit.rounded(UIKit.AMBER, 60))
	badge.custom_minimum_size = Vector2(120, 120)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lvl := UIKit.label(str(gm.clearance_level), "HeadingLabel", Color(0.10, 0.08, 0.02), 64)
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(lvl)
	row.add_child(badge)

	var xp_col := UIKit.vbox(12)
	xp_col.alignment = BoxContainer.ALIGNMENT_CENTER
	xp_col.custom_minimum_size = Vector2(250, 0)
	xp_col.add_child(UIKit.label("Level %d" % gm.clearance_level, "SubheadLabel", UIKit.TEXT, 42))
	var need: int = gm.get_xp_for_next_level()
	xp_col.add_child(UIKit.bar(float(gm.clearance_xp) / float(maxi(need, 1)) if need > 0 else 1.0, UIKit.AMBER, 16))
	row.add_child(xp_col)

	row.add_child(UIKit.expander())

	var cur := UIKit.vbox(10)
	cur.alignment = BoxContainer.ALIGNMENT_CENTER
	var sc := UIKit.currency_pill("coin", gm.survival_coins, UIKit.AMBER)
	sc.size_flags_horizontal = Control.SIZE_SHRINK_END
	var rc := UIKit.currency_pill("core", gm.research_cores, UIKit.CRIMSON)
	rc.size_flags_horizontal = Control.SIZE_SHRINK_END
	cur.add_child(sc)
	cur.add_child(rc)
	row.add_child(cur)

	var gear := Button.new()
	gear.theme_type_variation = "FlatButton"
	gear.icon = UIKit.icon_texture("gear")
	gear.expand_icon = true
	gear.custom_minimum_size = Vector2(UIKit.MIN_TOUCH, UIKit.MIN_TOUCH)
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
		col.offset_top = 10
		col.offset_bottom = -30  # clear of the system gesture bar
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Active tab: the icon sits in a soft pill
		var pill := PanelContainer.new()
		pill.name = "Pill"
		pill.add_theme_stylebox_override("panel", UIKit.rounded(UIKit.PANEL_2, 46))
		pill.custom_minimum_size = Vector2(150, 92)
		pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := UIKit.icon(item[1], 60)
		ic.name = "Icon"
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pill.add_child(ic)
		col.add_child(pill)
		var lb := UIKit.label(item[0], "SubheadLabel", UIKit.DIM, 32)
		lb.name = "Label"
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lb)
		b.add_child(col)
		# "Something to spend here" badge
		var dot := Panel.new()
		dot.name = "Dot"
		var ds := UIKit.rounded(UIKit.CRIMSON, 15)
		ds.border_color = UIKit.NAV_BG
		ds.set_border_width_all(4)
		dot.add_theme_stylebox_override("panel", ds)
		dot.set_anchors_preset(Control.PRESET_CENTER_TOP)
		dot.offset_left = 44
		dot.offset_right = 74
		dot.offset_top = 14
		dot.offset_bottom = 44
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
		var pill := b.find_child("Pill", true, false) as CanvasItem
		pill.self_modulate = Color(1, 1, 1, 1.0 if active else 0.0)
		var ic := b.find_child("Icon", true, false) as CanvasItem
		ic.modulate = UIKit.CRIMSON if active else UIKit.DIM
		var lb := b.find_child("Label", true, false) as Label
		lb.add_theme_color_override("font_color", UIKit.TEXT if active else UIKit.DIM)
		var dot := b.get_node("Dot") as CanvasItem
		dot.visible = bool(ready_flags[i]) and not active


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
	var col := UIKit.vbox(24)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(UIKit.pad(col, UIKit.MARGIN, 24, UIKit.MARGIN, 40))
	(col.get_parent() as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return col


func _header(title: String, right: Control) -> HBoxContainer:
	var row := UIKit.hbox(16)
	var t := UIKit.label(title, "HeadingLabel")
	row.add_child(t)
	row.add_child(UIKit.expander())
	if right:
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(right)
	return row


# ─── Missions ─────────────────────────────────────────────────────────────────
## One big sector card (swipe or use the arrows), the sector's contracts as
## tappable rows, and a single PLAY button in thumb reach above the nav bar.
func _build_missions() -> void:
	var col := UIKit.vbox(24)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = UIKit.MARGIN
	col.offset_right = -UIKit.MARGIN
	col.offset_top = 16
	col.offset_bottom = -36
	_content.add_child(col)

	var sectors := _visible_sectors()
	if not (selected_sector in sectors):
		selected_sector = int(sectors[0])
	col.add_child(_sector_card(selected_sector))
	if sectors.size() > 1:
		col.add_child(_sector_pager(sectors))

	var open := _is_open(selected_sector)
	var contracts: Array = []
	if gm and open:
		contracts = gm.get_contracts(selected_sector)
		selected_contract = clampi(selected_contract, 0, contracts.size() - 1)
		col.add_child(UIKit.label("CONTRACTS", "CaptionLabel"))
		# The list scrolls on short screens; PLAY never moves out of thumb reach
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var list := UIKit.vbox(16)
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		for i in range(contracts.size()):
			list.add_child(_contract_row(contracts[i], i))
		col.add_child(scroll)
	else:
		col.add_child(UIKit.expander())
	var play := UIKit.button("Play", "", 180)
	play.add_theme_font_size_override("font_size", 76)
	play.disabled = contracts.is_empty()
	if not contracts.is_empty():
		play.pressed.connect(_show_briefing.bind(contracts[selected_contract]))
	col.add_child(play)


## Playable sectors, plus the first unreleased one as a "coming soon" teaser.
func _visible_sectors() -> Array:
	var out: Array = [1]
	if not gm:
		return out
	for s in range(2, 5):
		out.append(s)
		if not gm.is_sector_playable(s):
			break
	return out


func _is_open(s: int) -> bool:
	if not gm:
		return s == 1
	return gm.is_sector_playable(s) and s <= int(gm.highest_sector_unlocked)


func _sector_card(s: int) -> Control:
	var open := _is_open(s)
	var playable: bool = gm.is_sector_playable(s) if gm else s == 1
	var card := PanelContainer.new()
	var st := UIKit.rounded(UIKit.PANEL_2 if open else UIKit.PANEL, UIKit.RADIUS)
	st.border_color = UIKit.CRIMSON if open else UIKit.LINE
	st.set_border_width_all(3)
	st.set_content_margin_all(40)
	st.shadow_color = Color(0, 0, 0, 0.35)
	st.shadow_size = 14
	st.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", st)
	card.custom_minimum_size = Vector2(0, 400)
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_sector_card_input)

	var v := UIKit.vbox(18)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var top := UIKit.hbox(12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(UIKit.chip("SECTOR %d" % s, UIKit.CRIMSON if open else UIKit.DIM))
	if gm and gm.is_sector_cleared(s):
		top.add_child(UIKit.chip("CLEARED", UIKit.GREEN))
	v.add_child(top)
	var title := UIKit.label(String(SECTOR_NAMES.get(s, "Sector")).to_upper(), "DisplayLabel", UIKit.TEXT if open else UIKit.MUTED, 104)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title)
	v.add_child(UIKit.paragraph(String(SECTOR_TAGLINES.get(s, "")), UIKit.TEXT_SOFT if open else UIKit.DIM, 36))
	v.add_child(UIKit.expander())
	if open:
		var stats := UIKit.hbox(14)
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats.add_child(UIKit.chip("%d CONTRACTS" % gm.get_contracts(s).size(), UIKit.TEXT_SOFT))
		var intel: Vector2i = gm.get_intel_progress(s)
		if intel.y > 0:
			stats.add_child(UIKit.chip("INTEL %d / %d" % [intel.x, intel.y], UIKit.AMBER))
		v.add_child(stats)
	else:
		var lock := UIKit.hbox(18)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := UIKit.icon("lock", 52, UIKit.AMBER if playable else UIKit.MUTED)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock.add_child(ic)
		var why := "Coming in a future update"
		if playable and gm:
			why = "To unlock: " + gm.get_sector_unlock_hint(s)
		lock.add_child(UIKit.paragraph(why, UIKit.AMBER if playable else UIKit.DIM, 36))
		v.add_child(lock)
	return card


## Arrows and page dots under the sector card.
func _sector_pager(sectors: Array) -> Control:
	var row := UIKit.hbox(28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var idx := sectors.find(selected_sector)
	var prev := UIKit.button("", "GhostButton", 100, "chevron_left")
	prev.custom_minimum_size.x = 140
	prev.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prev.disabled = idx <= 0
	prev.pressed.connect(_step_sector.bind(-1))
	row.add_child(prev)
	var dots := UIKit.hbox(14)
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.custom_minimum_size.x = 260
	for i in range(sectors.size()):
		var d := Panel.new()
		var active := i == idx
		d.custom_minimum_size = Vector2(52 if active else 20, 20)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.add_theme_stylebox_override("panel", UIKit.rounded(UIKit.CRIMSON if active else UIKit.LINE, 10))
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(d)
	row.add_child(dots)
	var next := UIKit.button("", "GhostButton", 100, "chevron_right")
	next.custom_minimum_size.x = 140
	next.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next.disabled = idx >= sectors.size() - 1
	next.pressed.connect(_step_sector.bind(1))
	row.add_child(next)
	return row


func _step_sector(dir: int) -> void:
	var sectors := _visible_sectors()
	var idx := clampi(sectors.find(selected_sector) + dir, 0, sectors.size() - 1)
	if int(sectors[idx]) == selected_sector:
		return
	_click()
	selected_sector = int(sectors[idx])
	selected_contract = 0
	_refresh()


## Horizontal swipe on the sector card changes sector.
func _on_sector_card_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_swipe_from = mb.position.x
	elif _swipe_from >= 0.0:
		var dx := mb.position.x - _swipe_from
		_swipe_from = -1.0
		if absf(dx) > 120.0:
			_step_sector(-1 if dx > 0.0 else 1)


func _contract_row(c: Dictionary, i: int) -> Control:
	var selected := i == selected_contract
	var b := Button.new()
	b.theme_type_variation = "FlatButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 132)
	b.pressed.connect(_on_contract.bind(i))
	var bg := PanelContainer.new()
	var st := UIKit.rounded(UIKit.PANEL_2 if selected else UIKit.PANEL, 28)
	st.border_color = UIKit.CRIMSON if selected else UIKit.LINE
	st.set_border_width_all(4 if selected else 2)
	st.content_margin_left = 28
	st.content_margin_right = 32
	bg.add_theme_stylebox_override("panel", st)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UIKit.hbox(24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var num := PanelContainer.new()
	num.add_theme_stylebox_override("panel", UIKit.rounded(UIKit.CRIMSON if selected else UIKit.PANEL_2, 38))
	num.custom_minimum_size = Vector2(76, 76)
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := UIKit.label(str(i + 1), "SubheadLabel", UIKit.TEXT, 42)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.add_child(n)
	row.add_child(num)
	var info := UIKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UIKit.label(_short_title(c), "SubheadLabel", UIKit.TEXT if selected else UIKit.TEXT_SOFT, 44)
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.clip_text = true
	info.add_child(t)
	info.add_child(UIKit.label("%d steps" % _objective_lines(c).size(), "CaptionLabel"))
	row.add_child(info)
	var pay := UIKit.currency("coin", _payout(c), UIKit.AMBER, 40, "+")
	pay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pay)
	bg.add_child(row)
	b.add_child(bg)
	return b


func _on_contract(i: int) -> void:
	if i == selected_contract:
		return
	_click()
	selected_contract = i
	_refresh()


func _payout(c: Dictionary) -> int:
	if not gm:
		return 0
	var first_clear: bool = not gm.is_sector_cleared(selected_sector)
	return gm.get_contract_payout_sc(c) * (GameManager.FIRST_CLEAR_MULTIPLIER if first_clear else 1)


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
	lines.append("Hold the landing zone")
	return lines


# ─── Briefing (bottom sheet) ──────────────────────────────────────────────────
## Why you're going in, what to do, what you get. Tap outside to back out.
func _show_briefing(c: Dictionary) -> void:
	_click()
	var layer := Control.new()
	layer.name = "Briefing"
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var shade := UIKit.overlay(0.72)
	shade.gui_input.connect(_on_sheet_shade_input.bind(layer))
	layer.add_child(shade)

	var sheet := PanelContainer.new()
	var st := UIKit.rounded(UIKit.PANEL, 48)
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	st.border_color = UIKit.LINE
	st.border_width_top = 2
	st.content_margin_left = UIKit.MARGIN
	st.content_margin_right = UIKit.MARGIN
	st.content_margin_top = 28
	st.content_margin_bottom = 70
	sheet.add_theme_stylebox_override("panel", st)
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(sheet)
	var col := UIKit.vbox(28)
	sheet.add_child(col)

	var grab := Panel.new()
	grab.custom_minimum_size = Vector2(120, 10)
	grab.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grab.add_theme_stylebox_override("panel", UIKit.rounded(UIKit.LINE, 5))
	col.add_child(grab)

	col.add_child(UIKit.label("SECTOR %d  ·  %s" % [selected_sector, String(SECTOR_NAMES.get(selected_sector, "")).to_upper()], "CaptionLabel", UIKit.AMBER, 32))
	var title := UIKit.label(_short_title(c), "DisplayLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)

	var radio := UIKit.card("AccentCard")
	var rrow := UIKit.hbox(24)
	var ric := UIKit.icon("radio", 72, UIKit.AMBER)
	ric.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rrow.add_child(ric)
	var rcol := UIKit.vbox(10)
	rcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rcol.add_child(UIKit.label("OVERWATCH", "CaptionLabel", UIKit.AMBER))
	rcol.add_child(UIKit.paragraph(String(c.get("briefing", c.get("desc", ""))), UIKit.TEXT, 36))
	rrow.add_child(rcol)
	radio.add_child(rrow)
	col.add_child(radio)

	var steps := UIKit.vbox(14)
	var n := 1
	for line in _objective_lines(c):
		var r := UIKit.hbox(20)
		var dot := PanelContainer.new()
		dot.add_theme_stylebox_override("panel", UIKit.rounded(UIKit.PANEL_2, 28))
		dot.custom_minimum_size = Vector2(56, 56)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dn := UIKit.label(str(n), "SubheadLabel", UIKit.AMBER, 34)
		dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.add_child(dn)
		r.add_child(dot)
		var tl := UIKit.paragraph(line, UIKit.TEXT, 38)
		tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(tl)
		steps.add_child(r)
		n += 1
	col.add_child(steps)

	var rewards := UIKit.hbox(30)
	rewards.add_child(UIKit.label("REWARD", "CaptionLabel"))
	rewards.add_child(UIKit.currency("coin", _payout(c), UIKit.AMBER, 48, "+"))
	if int(c.get("payout_rc", 0)) > 0:
		rewards.add_child(UIKit.currency("core", int(c.get("payout_rc", 0)), UIKit.CRIMSON, 48, "+"))
	if gm and not gm.is_sector_cleared(selected_sector):
		rewards.add_child(UIKit.chip("FIRST CLEAR ×2", UIKit.GREEN))
	col.add_child(rewards)

	var start := UIKit.button("Start mission", "", 180)
	start.add_theme_font_size_override("font_size", 64)
	start.pressed.connect(_deploy.bind(c))
	col.add_child(start)

	layer.modulate.a = 0.0
	layer.create_tween().tween_property(layer, "modulate:a", 1.0, 0.15)


func _on_sheet_shade_input(event: InputEvent, layer: Control) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		layer.queue_free()


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
	col.add_child(_header("ARMORY", null))

	# 3D weapon viewer
	var frame := PanelContainer.new()
	var fs := UIKit.rounded(UIKit.PANEL_2, UIKit.RADIUS)
	frame.add_theme_stylebox_override("panel", fs)
	frame.clip_contents = true
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
	cam.transform = Transform3D(Basis(), Vector3(0.0, 0.7, 2.4)).looking_at(Vector3.ZERO, Vector3.UP)
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.4
	sun.transform = Transform3D(Basis(), Vector3(2, 4, 3)).looking_at(Vector3.ZERO, Vector3.UP)
	vp.add_child(sun)
	_weapon_pivot = Node3D.new()
	var gun := CARBINE_SCENE.instantiate() as Node3D
	_weapon_pivot.add_child(gun)
	_fit_model(gun, 1.7)
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
		var buy := UIKit.button("MAX" if maxed else UIKit.fmt_int(cost), "AmberButton", 130, "" if maxed else "coin")
		buy.custom_minimum_size.x = 260
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.disabled = maxed or gm.survival_coins < cost
		buy.pressed.connect(_on_upgrade_weapon.bind(weapon, track, cost))
		row.add_child(buy)
		card.add_child(row)
		col.add_child(card)


## Centres a model on its pivot and scales its longest side to `length` metres,
## so the viewer frames any weapon the same way. Lays the barrel along X.
func _fit_model(model: Node3D, length: float) -> void:
	var bounds := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := mi as MeshInstance3D
		if not mesh_inst.mesh:
			continue
		var xf := Transform3D()
		var n: Node = mesh_inst
		while n and n != model.get_parent():
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var box: AABB = xf * mesh_inst.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if first:
		return
	if bounds.size.z > bounds.size.x:
		model.rotate_y(PI * 0.5)  # barrel along Z: turn it side-on
		bounds = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3.ZERO) * bounds
	var longest := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	var k := length / maxf(longest, 0.001)
	model.scale *= k
	model.position = -bounds.get_center() * k


func _on_upgrade_weapon(weapon: String, track: String, cost: int) -> void:
	if gm and gm.upgrade_weapon(weapon, track, cost):
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_sfx"):
			am.play_sfx("ui_confirm")
	_queue_refresh()


# ─── Skills ───────────────────────────────────────────────────────────────────
func _build_skills() -> void:
	var col := _scroll_column()
	col.add_child(_header("SKILLS", null))
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
		var st := UIKit.rounded(UIKit.PANEL_2 if filled else UIKit.PANEL, 28)
		st.border_color = UIKit.CRIMSON if filled else UIKit.LINE
		st.set_border_width_all(4 if filled else 2)
		st.set_content_margin_all(28)
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
			action = UIKit.button("Unlocks at level %d" % int(data.get("level_req", 1)), "GhostButton", UIKit.MIN_TOUCH, "lock")
			action.disabled = true
		else:
			var cost := int(data.get("cost_rc", 0))
			action = UIKit.button("Unlock  %d" % cost, "AmberButton", UIKit.MIN_TOUCH, "core")
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
	col.add_child(_header("OUTPOST", null))
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
		if not maxed:
			var price := UIKit.hbox(30)
			price.add_child(UIKit.label("COST", "CaptionLabel"))
			price.add_child(UIKit.currency("coin", cost.x, UIKit.AMBER, 40))
			price.add_child(UIKit.currency("core", cost.y, UIKit.CRIMSON, 40))
			v.add_child(price)
		var b := UIKit.button("Max tier" if maxed else "Upgrade", "AmberButton", UIKit.MIN_TOUCH)
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
