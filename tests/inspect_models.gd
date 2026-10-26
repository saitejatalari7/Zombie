@tool
extends SceneTree

func _init() -> void:
	print("--- INSPECTING CHARACTER GLBS ---")
	var glbs = [
		"res://assets/models/characters/player_operative.glb",
		"res://assets/models/characters/zombie_shambler.glb",
		"res://assets/models/characters/zombie_runner.glb",
		"res://assets/models/characters/zombie_tank.glb"
	]
	
	for path in glbs:
		print("\nLoading: ", path)
		var scn: PackedScene = load(path)
		if not scn:
			print("FAILED TO LOAD ", path)
			continue
		var inst: Node = scn.instantiate()
		print_hierarchy(inst, 0)
		inst.queue_free()
		
	quit(0)

func print_hierarchy(node: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth):
		indent += "  "
	var info = indent + "- " + node.name + " (" + node.get_class() + ")"
	if node is Node3D:
		info += " pos: " + str(node.position) + " rot: " + str(node.rotation) + " scale: " + str(node.scale)
	if node is MeshInstance3D:
		if node.mesh:
			info += " [Mesh: " + node.mesh.get_class() + ", surfs: " + str(node.mesh.get_surface_count()) + "]"
			for s in range(node.mesh.get_surface_count()):
				var mat = node.get_surface_override_material(s)
				if not mat:
					mat = node.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					info += " (mat" + str(s) + ": " + mat.resource_name + " col: " + str(mat.albedo_color) + ")"
				elif mat:
					info += " (mat" + str(s) + ": " + mat.get_class() + " " + mat.resource_name + ")"
	print(info)
	for child in node.get_children():
		print_hierarchy(child, depth + 1)
