@tool
extends SceneTree

func _init() -> void:
	print("Generating game textures...")
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("assets/textures"):
		dir.make_dir_recursive("assets/textures")
	
	create_blood_splatter("res://assets/textures/blood_splatter_1.png", 256, 1)
	create_blood_splatter("res://assets/textures/blood_splatter_2.png", 256, 2)
	create_blood_puddle("res://assets/textures/blood_puddle.png", 256)
	create_blood_footprint("res://assets/textures/blood_footprint.png", 128)
	create_joystick_base("res://assets/textures/joystick_base.png", 256)
	create_joystick_knob("res://assets/textures/joystick_knob.png", 128)
	create_fire_button("res://assets/textures/fire_button.png", 256)
	create_super_blast_button("res://assets/textures/super_blast_button.png", 256)
	create_jump_button("res://assets/textures/jump_button.png", 256)
	create_smoke_particle_texture("res://assets/textures/smoke_particle.png", 128)
	create_shockwave_texture("res://assets/textures/shockwave.png", 256)
	create_fire_particle_texture("res://assets/textures/fire_particle.png", 128)
	create_molotov_icon("res://assets/textures/molotov_icon.png", 128)
	create_pause_icon("res://assets/textures/pause_icon.png", 128)
	
	print("Textures generated successfully!")
	quit()

func create_blood_splatter(path: String, size: int, seed_val: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	# 100% Opaque solid arterial crimson
	var blood_col := Color(0.74, 0.015, 0.045, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 7789 + 1337

	# 1. Main organic core formed by multiple overlapping circular blobs
	var num_core_blobs := 7
	for b in range(num_core_blobs):
		var blob_offset := Vector2(rng.randf_range(-14, 14), rng.randf_range(-14, 14))
		var blob_rad := rng.randf_range(16.0, 32.0)
		draw_filled_circle_solid(img, center + blob_offset, blob_rad, blood_col)

	# 2. Organic jagged contours using multi-octave perturbation
	for x in range(size):
		for y in range(size):
			var p := Vector2(x, y)
			var diff := p - center
			var dist := diff.length()
			var angle := diff.angle()
			var noise_val := sin(angle * 3.0 + seed_val) * 8.0 + cos(angle * 7.0 + seed_val * 2.0) * 6.0 + sin(angle * 13.0) * 3.5
			var dynamic_rad := 24.0 + noise_val
			if dist <= dynamic_rad:
				img.set_pixel(x, y, blood_col)

	# 3. High-velocity arterial spray tendrils shooting outwards
	var tendril_count := 8
	for t in range(tendril_count):
		var base_ang := (float(t) / float(tendril_count)) * TAU + rng.randf_range(-0.25, 0.25)
		var t_len := rng.randf_range(35.0, size * 0.44)
		var steps := int(t_len / 2.0)
		for s in range(steps):
			var progress := float(s) / float(steps)
			var cur_dist := 18.0 + progress * (t_len - 18.0)
			var cur_w := (1.0 - progress) * rng.randf_range(2.5, 5.0) + 0.8
			var jitter := Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2))
			var t_pos := center + Vector2(cos(base_ang), sin(base_ang)) * cur_dist + jitter
			draw_filled_circle_solid(img, t_pos, cur_w, blood_col)

	# 4. Satellite spray droplets (100% solid, crisp)
	var droplet_count := 45
	for i in range(droplet_count):
		var ang := rng.randf_range(0, TAU)
		var dist := rng.randf_range(28, size * 0.47)
		var drop_center := center + Vector2(cos(ang), sin(ang)) * dist
		var drop_rad := rng.randf_range(1.5, 4.8)
		draw_filled_circle_solid(img, drop_center, drop_rad, blood_col)

	img.save_png(path)

func create_blood_puddle(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	# 100% Opaque viscous pool
	var blood_col := Color(0.70, 0.012, 0.04, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 44211

	# 1. Heavy amorphous pool formed by overlapping core masses
	var core_masses := 10
	for m in range(core_masses):
		var off := Vector2(rng.randf_range(-22, 22), rng.randf_range(-22, 22))
		var r := rng.randf_range(28.0, 48.0)
		draw_filled_circle_solid(img, center + off, r, blood_col)

	# 2. Amoebic organic contour
	for x in range(size):
		for y in range(size):
			var p := Vector2(x, y)
			var diff := p - center
			var dist := diff.length()
			var angle := diff.angle()
			var wave := sin(angle * 2.0) * 14.0 + cos(angle * 5.0) * 9.0 + sin(angle * 9.0) * 4.0
			var pool_rad := 52.0 + wave
			if dist <= pool_rad:
				img.set_pixel(x, y, blood_col)

	# 3. Perimeter bleed lobes & satellite drips
	for i in range(50):
		var ang := rng.randf_range(0, TAU)
		var dist := rng.randf_range(48, size * 0.46)
		var drop_center := center + Vector2(cos(ang), sin(ang)) * dist
		var drop_rad := rng.randf_range(1.8, 5.2)
		draw_filled_circle_solid(img, drop_center, drop_rad, blood_col)

	img.save_png(path)

func draw_filled_circle_solid(img: Image, center: Vector2, radius: float, col: Color) -> void:
	var min_x := clampi(int(center.x - radius - 1), 0, img.get_width() - 1)
	var max_x := clampi(int(center.x + radius + 1), 0, img.get_width() - 1)
	var min_y := clampi(int(center.y - radius - 1), 0, img.get_height() - 1)
	var max_y := clampi(int(center.y + radius + 1), 0, img.get_height() - 1)
	var r_sq := radius * radius

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var dx := float(x) - center.x
			var dy := float(y) - center.y
			if (dx * dx + dy * dy) <= r_sq:
				img.set_pixel(x, y, col)

func create_blood_footprint(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var blood_col := Color(0.8, 0.02, 0.05, 0.9)
	var center := Vector2(size * 0.5, size * 0.5)

	# Sole and heel of shoe
	var heel_center := center + Vector2(0, size * 0.22)
	var heel_rx := size * 0.14
	var heel_ry := size * 0.16
	draw_filled_ellipse(img, heel_center, heel_rx, heel_ry, blood_col)

	var sole_center := center - Vector2(0, size * 0.12)
	var sole_rx := size * 0.18
	var sole_ry := size * 0.24
	draw_filled_ellipse(img, sole_center, sole_rx, sole_ry, blood_col)

	img.save_png(path)

func create_joystick_base(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.46
	var thickness := 6.0

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if absf(dist - radius) <= thickness:
				var alpha: float = 1.0 - (absf(dist - radius) / thickness)
				img.set_pixel(x, y, Color(1, 1, 1, alpha * 0.85))
			elif dist < radius:
				# Dark translucent disc visible on white
				img.set_pixel(x, y, Color(0.08, 0.08, 0.12, 0.45))

	img.save_png(path)

func create_joystick_knob(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.42

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var edge_fade: float = clampf((radius - dist) / 3.0, 0.0, 1.0)
				# Solid white knob with slight drop rim
				img.set_pixel(x, y, Color(1, 1, 1, edge_fade * 0.8))

	img.save_png(path)

func create_fire_button(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.44
	var thickness := 7.0

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if absf(dist - radius) <= thickness:
				var alpha: float = 1.0 - (absf(dist - radius) / thickness)
				img.set_pixel(x, y, Color(1, 1, 1, alpha * 0.9))
			elif dist < radius:
				# Dark translucent disc
				img.set_pixel(x, y, Color(0.08, 0.08, 0.12, 0.55))

	img.save_png(path)

func create_super_blast_button(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.44
	var thickness := 8.0

	# Glowing orange/red rim on dark base
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if absf(dist - radius) <= thickness:
				var alpha: float = 1.0 - (absf(dist - radius) / thickness)
				img.set_pixel(x, y, Color(1.0, 0.35, 0.1, alpha * 0.95))
			elif dist < radius:
				img.set_pixel(x, y, Color(0.12, 0.05, 0.05, 0.65))

	# Draw 3 miniature rocket silhouettes in center
	var rocket_col := Color(1.0, 0.92, 0.85, 0.95)
	for r in range(3):
		var offset_x: float = (r - 1) * (size * 0.18)
		var rocket_c := center + Vector2(offset_x, (0 if r == 1 else size * 0.06))
		draw_filled_ellipse(img, rocket_c, size * 0.06, size * 0.14, rocket_col)
		draw_filled_circle(img, rocket_c - Vector2(0, size * 0.14), size * 0.05, rocket_col)

	img.save_png(path)

func create_jump_button(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.44
	var rim_thickness := 8.0

	# Dark glass disc body with subtle gradient
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if absf(dist - radius) <= rim_thickness:
				var alpha: float = 1.0 - (absf(dist - radius) / rim_thickness)
				# Electric cyan-white glowing rim
				img.set_pixel(x, y, Color(0.3, 0.85, 1.0, alpha * 0.95))
			elif dist < radius:
				var t: float = dist / radius
				var dark_shade: float = lerpf(0.18, 0.08, t)
				img.set_pixel(x, y, Color(dark_shade * 0.8, dark_shade, dark_shade * 1.4, 0.75))

	# Prominent bold upward arrow icon in upper-center
	var arrow_col := Color(1.0, 1.0, 1.0, 0.98)
	var cyan_glow := Color(0.25, 0.9, 1.0, 0.95)
	
	var tip := center - Vector2(0, size * 0.18)
	var head_height := size * 0.26
	var max_half_w := size * 0.26
	
	# Arrow head triangle
	for y in range(int(tip.y), int(tip.y + head_height)):
		var progress: float = float(y - tip.y) / head_height
		var half_w: float = progress * max_half_w
		for x in range(int(tip.x - half_w), int(tip.x + half_w + 1)):
			if Vector2(x, y).distance_to(center) < radius - 8:
				var is_edge: bool = (absf(x - (tip.x - half_w)) < 3.0 or absf(x - (tip.x + half_w)) < 3.0)
				img.set_pixel(x, y, cyan_glow if is_edge else arrow_col)

	# Arrow stem
	var stem_w := int(size * 0.08)
	var stem_top := int(tip.y + head_height - 2)
	var stem_bottom := int(tip.y + head_height + size * 0.14)
	for y in range(stem_top, stem_bottom):
		for x in range(int(tip.x - stem_w), int(tip.x + stem_w + 1)):
			if Vector2(x, y).distance_to(center) < radius - 8:
				img.set_pixel(x, y, arrow_col)

	img.save_png(path)

func create_smoke_particle_texture(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := size * 0.46

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= max_r:
				var falloff: float = (1.0 - (dist / max_r))
				var smooth_val: float = falloff * falloff * (3.0 - 2.0 * falloff)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, smooth_val * 0.7))

	img.save_png(path)

func create_shockwave_texture(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.42
	var width := size * 0.08

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			var d := absf(dist - radius)
			if d <= width:
				var alpha: float = 1.0 - (d / width)
				img.set_pixel(x, y, Color(1.0, 0.8, 0.4, alpha * 0.9))

	img.save_png(path)

func create_fire_particle_texture(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var max_r := size * 0.44

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= max_r:
				var t := dist / max_r
				var alpha: float = (1.0 - t) * (1.0 - t)
				# Warm core to orange flame to red edge
				var col: Color = Color(1.0, 0.95, 0.4).lerp(Color(1.0, 0.4, 0.05), t * 1.5)
				if t > 0.6:
					col = col.lerp(Color(0.8, 0.1, 0.02), (t - 0.6) / 0.4)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha * 0.85))

	img.save_png(path)

func create_molotov_icon(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.45

	# Outer glowing amber ring
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if absf(dist - radius) <= 5.0:
				var alpha: float = 1.0 - (absf(dist - radius) / 5.0)
				img.set_pixel(x, y, Color(1.0, 0.55, 0.15, alpha * 0.9))
			elif dist < radius:
				img.set_pixel(x, y, Color(0.12, 0.07, 0.04, 0.75))

	# Bottle body
	var bottle_col := Color(0.9, 0.5, 0.2, 0.95)
	var bottle_center := center + Vector2(0, size * 0.14)
	draw_filled_ellipse(img, bottle_center, size * 0.18, size * 0.22, bottle_col)
	# Bottle neck
	draw_filled_ellipse(img, center - Vector2(0, size * 0.08), size * 0.07, size * 0.12, bottle_col)

	# Flame on top of bottle
	var flame_col := Color(1.0, 0.9, 0.3, 0.98)
	var flame_center := center - Vector2(0, size * 0.24)
	draw_filled_circle(img, flame_center, size * 0.12, flame_col)
	draw_filled_circle(img, flame_center - Vector2(0, size * 0.06), size * 0.07, Color(1.0, 0.4, 0.1, 0.95))

	img.save_png(path)

func create_pause_icon(path: String, size: int) -> void:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.44

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x, y).distance_to(center)
			if absf(dist - radius) <= 4.0:
				var alpha: float = 1.0 - (absf(dist - radius) / 4.0)
				img.set_pixel(x, y, Color(1, 1, 1, alpha * 0.85))
			elif dist < radius:
				img.set_pixel(x, y, Color(0.1, 0.12, 0.16, 0.65))

	# Two vertical pause bars
	var bar_w := int(size * 0.08)
	var bar_h := int(size * 0.38)
	var offset_x := int(size * 0.12)
	var bar_col := Color(1, 1, 1, 0.95)

	# Left bar
	for x in range(int(center.x - offset_x - bar_w * 0.5), int(center.x - offset_x + bar_w * 0.5)):
		for y in range(int(center.y - bar_h * 0.5), int(center.y + bar_h * 0.5)):
			img.set_pixel(x, y, bar_col)

	# Right bar
	for x in range(int(center.x + offset_x - bar_w * 0.5), int(center.x + offset_x + bar_w * 0.5)):
		for y in range(int(center.y - bar_h * 0.5), int(center.y + bar_h * 0.5)):
			img.set_pixel(x, y, bar_col)

	img.save_png(path)

func draw_filled_circle(img: Image, center: Vector2, radius: float, col: Color) -> void:
	var min_x := clampi(int(center.x - radius - 1), 0, img.get_width() - 1)
	var max_x := clampi(int(center.x + radius + 1), 0, img.get_width() - 1)
	var min_y := clampi(int(center.y - radius - 1), 0, img.get_height() - 1)
	var max_y := clampi(int(center.y + radius + 1), 0, img.get_height() - 1)

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha: float = clampf((radius - dist) + 0.5, 0.0, 1.0) * col.a
				var existing: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, maxf(existing.a, alpha)))

func draw_filled_ellipse(img: Image, center: Vector2, rx: float, ry: float, col: Color) -> void:
	var min_x := clampi(int(center.x - rx - 1), 0, img.get_width() - 1)
	var max_x := clampi(int(center.x + rx + 1), 0, img.get_width() - 1)
	var min_y := clampi(int(center.y - ry - 1), 0, img.get_height() - 1)
	var max_y := clampi(int(center.y + ry + 1), 0, img.get_height() - 1)

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var nx := (x - center.x) / rx
			var ny := (y - center.y) / ry
			var val := (nx * nx) + (ny * ny)
			if val <= 1.0:
				var alpha: float = clampf((1.0 - sqrt(val)) * 3.0, 0.0, 1.0) * col.a
				var existing: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, maxf(existing.a, alpha)))
