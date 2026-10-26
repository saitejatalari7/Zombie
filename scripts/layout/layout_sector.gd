extends SectorBase
class_name LayoutSector
## LayoutSector.gd
## A sector whose geometry, collisions and markers are built from a layout plan
## by LayoutBuilder. The plan is a generated GDScript constant (PLAN) so it ships
## in every export. Building happens in _enter_tree so SectorBase's @onready
## lookups (PlayerSpawn, ExtractionZone, ZombieSpawners) find the built nodes.
## A sector has several layouts; the contract picks one through layout_id.

@export var plan_source: GDScript
## Set before the node enters the tree to build scripts/layout/plans/<layout_id>.gd
## instead of plan_source (the sector's default layout).
var layout_id: String = ""

func _enter_tree() -> void:
	if get_node_or_null("LayoutCollision"):
		return  # already built (scene re-entered the tree)
	if layout_id != "":
		var path := "res://scripts/layout/plans/%s.gd" % layout_id
		if ResourceLoader.exists(path):
			plan_source = load(path)
		else:
			push_warning("[LayoutSector] Unknown layout '%s'; using the default" % layout_id)
	if not plan_source:
		push_error("[LayoutSector] No plan_source set on %s" % name)
		return
	var plan: Dictionary = plan_source.get_script_constant_map().get("PLAN", {})
	var sec: Dictionary = plan.get("sector", {})
	if sec.has("bounds"):
		var b: Array = sec["bounds"]
		sector_bounds = Rect2(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
	LayoutBuilder.build(plan, self, is_night_sector)
	if plan.has("nav"):
		var field := FlowField.new()
		field.name = "FlowField"
		field.setup(plan["nav"])
		add_child(field)


func _ensure_procedural_vegetation() -> void:
	pass  # The grass scatter uses the old sector-1 coordinates; layout sectors place their own props
