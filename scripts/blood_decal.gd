extends Decal
class_name BloodDecal

var textures: Array[Texture2D] = [
	preload("res://assets/textures/blood_splatter_1.png"),
	preload("res://assets/textures/blood_splatter_2.png"),
	preload("res://assets/textures/blood_puddle.png")
]

var lifetime: float = 40.0
var age: float = 0.0
var fading: bool = false

func _ready() -> void:
	texture_albedo = textures[randi() % textures.size()]
	var random_scale: float = randf_range(0.8, 1.8)
	size = Vector3(random_scale, 1.2, random_scale)
	rotate_y(randf_range(0, TAU))
	upper_fade = 0.001
	lower_fade = 0.001
	normal_fade = 0.0
	distance_fade_enabled = false
	modulate = Color(1, 1, 1, 1)

func setup(p_scale: float = 1.0, is_puddle: bool = false) -> void:
	if is_puddle:
		texture_albedo = textures[2]
	else:
		texture_albedo = textures[randi() % 2]
	
	size = Vector3(p_scale, 1.2, p_scale)
	rotate_y(randf_range(0, TAU))
	upper_fade = 0.001
	lower_fade = 0.001
	normal_fade = 0.0
	distance_fade_enabled = false
	modulate = Color(1, 1, 1, 1)

func setup_wall(p_scale: float = 1.0) -> void:
	texture_albedo = textures[randi() % 2]
	size = Vector3(p_scale * 1.2, p_scale * 2.2, 1.2)
	modulate = Color(0.92, 0.04, 0.08, 0.96)

func _process(delta: float) -> void:
	age += delta
	if age > lifetime and not fading:
		fade_out()

func fade_out() -> void:
	fading = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 3.0)
	tween.tween_callback(queue_free)
