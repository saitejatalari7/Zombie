extends SectorBase
class_name LayoutSector
## LayoutSector.gd
## A sector whose geometry, collisions and markers are built from a layout plan
## by LayoutBuilder. The plan is a generated GDScript constant (PLAN) so it ships
## in every export. Building happens in _enter_tree so SectorBase's @onready
## lookups (PlayerSpawn, ExtractionZone, ZombieSpawners) find the built nodes.

@export var plan_source: GDScript

func _enter_tree() -> void:
	if get_node_or_null("LayoutCollision"):
		return  # already built (scene re-entered the tree)
	if not plan_source:
		push_error("[LayoutSector] No plan_source set on %s" % name)
		return
	var plan: Dictionary = plan_source.get_script_constant_map().get("PLAN", {})
	LayoutBuilder.build(plan, self)
	if plan.has("nav"):
		var field := FlowField.new()
		field.name = "FlowField"
		field.setup(plan["nav"])
		add_child(field)


func _ensure_procedural_vegetation() -> void:
	pass  # The grass scatter uses the old sector-1 coordinates; layout sectors place their own props
