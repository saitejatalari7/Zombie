extends SceneTree

func _init() -> void:
	print("[PerfProfile] Profiling main.tscn performance...")
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	
	# Warm up for 60 frames to finish shader compilation & loading
	for i in range(60):
		await process_frame
		
	var times: Array[float] = []
	for i in range(120):
		var t_start := Time.get_ticks_usec()
		await process_frame
		var dt := (Time.get_ticks_usec() - t_start) / 1000.0 # ms
		times.append(dt)
		
	var avg_time := 0.0
	var max_time := 0.0
	var min_time := 99999.0
	for t in times:
		avg_time += t
		if t > max_time: max_time = t
		if t < min_time: min_time = t
	avg_time /= times.size()
	
	var real_fps := 1000.0 / avg_time
	var min_fps := 1000.0 / max_time
	var max_fps := 1000.0 / min_time
	
	print("[PerfProfile] Real Benchmark: Avg Frame Time: %.2f ms (%.1f FPS) | Best: %.2f ms (%.1f FPS) | Worst: %.2f ms (%.1f FPS)" % [
		avg_time, real_fps, min_time, max_fps, max_time, min_fps
	])
		

	
	# Node count and rendering metrics
	var total_nodes := _count(root_node)
	print("[PerfProfile] Total nodes in scene tree: ", total_nodes)
	
	var r := RenderingServer
	print("[PerfProfile] Objects in frame: ", r.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
	print("[PerfProfile] Total primitives: ", r.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	print("[PerfProfile] Draw calls in frame: ", r.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	
	# Check active lights & environments
	var lights := root_node.find_children("", "DirectionalLight3D", true, false)
	print("[PerfProfile] Directional lights found: ", lights.size())
	for l in lights:
		print("  Light: ", l.name, " parent: ", l.get_parent().name, " shadows: ", l.shadow_enabled, " splits: ", l.directional_shadow_mode)
		
	var envs := root_node.find_children("", "WorldEnvironment", true, false)
	print("[PerfProfile] World environments found: ", envs.size())
	for e in envs:
		print("  Env: ", e.name, " parent: ", e.get_parent().name, " SSAO: ", e.environment.ssao_enabled if e.environment else false)
		
	quit(0)

func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count(ch)
	return c
