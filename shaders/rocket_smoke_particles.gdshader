shader_type particles;

uniform float spread_radius : hint_range(0.01, 0.5) = 0.08;
uniform float initial_velocity : hint_range(0.1, 2.0) = 0.4;
uniform vec3 gravity = vec3(0.0, 0.3, 0.0);

float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0)
		s = 305419896;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0)
		s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

uint hash_id(uint x) {
	x = ((x >> 16u) ^ x) * 0x45d9f3bu;
	x = ((x >> 16u) ^ x) * 0x45d9f3bu;
	x = (x >> 16u) ^ x;
	return x;
}

void start() {
	uint seed = hash_id(uint(INDEX) + uint(1337));
	float r1 = rand_from_seed(seed);
	float r2 = rand_from_seed(seed);
	float r3 = rand_from_seed(seed);

	// Tiny puff offset around emission origin
	vec3 offset = vec3(
		(r1 - 0.5) * spread_radius,
		(r2 - 0.5) * spread_radius,
		(r3 - 0.5) * spread_radius
	);

	TRANSFORM[3].xyz = EMISSION_TRANSFORM[3].xyz + offset;

	// Initial small scale
	TRANSFORM[0] = vec4(0.1, 0.0, 0.0, 0.0);
	TRANSFORM[1] = vec4(0.0, 0.1, 0.0, 0.0);
	TRANSFORM[2] = vec4(0.0, 0.0, 0.1, 0.0);

	// Subtle smoky grey
	COLOR = vec4(0.9, 0.9, 0.95, 0.8);
	VELOCITY = vec3((r1 - 0.5) * 0.3, (r2 - 0.2) * initial_velocity, (r3 - 0.5) * 0.3);
	CUSTOM = vec4(0.0);
}

void process() {
	// Tiny buoyancy and air resistance
	VELOCITY += gravity * DELTA;
	VELOCITY *= 0.95;
	TRANSFORM[3].xyz += VELOCITY * DELTA;

	// Progress through lifetime tracked in CUSTOM.y
	CUSTOM.y += DELTA / LIFETIME;
	float progress = clamp(CUSTOM.y, 0.0, 1.0);
	float current_scale = mix(0.12, 0.35, smoothstep(0.0, 1.0, progress));

	TRANSFORM[0] = vec4(current_scale, 0.0, 0.0, 0.0);
	TRANSFORM[1] = vec4(0.0, current_scale, 0.0, 0.0);
	TRANSFORM[2] = vec4(0.0, 0.0, current_scale, 0.0);

	// Smoothly dissolve smoke puff
	float alpha = (1.0 - progress) * 0.7;
	COLOR = vec4(0.88, 0.88, 0.9, alpha);
}
