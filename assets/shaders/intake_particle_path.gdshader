shader_type particles;

// Path endpoint (filter center) that particles are attracted to
uniform vec2 target_point = vec2(0.0, 0.0);

// Attraction strength - controls how strongly particles are pulled toward filter
uniform float attraction_strength = 400.0;

// Distance at which particles start fading/dying (when they reach filter)
uniform float kill_distance = 60.0;

// How much the attraction increases as particle approaches target
uniform float proximity_boost = 0.3;

void start() {
	// Store lifetime fraction in CUSTOM.y
	CUSTOM.y = 0.0;
}

void process() {
	// Update lifetime fraction (0.0 to 1.0)
	CUSTOM.y = min(1.0, CUSTOM.y + DELTA / LIFETIME);

	// Get particle position in 2D
	vec2 current_pos = TRANSFORM[3].xy;

	// Calculate direction and distance to target (filter center)
	vec2 direction_to_target = target_point - current_pos;
	float distance = length(direction_to_target);

	// Apply attraction force toward filter
	if (distance > 1.0) {
		vec2 normalized_direction = normalize(direction_to_target);

		// Base attraction
		float attraction = attraction_strength;

		// Boost attraction as particle gets closer (proximity effect)
		float proximity_factor = 1.0 - (distance / 500.0);
		proximity_factor = clamp(proximity_factor, 0.0, 1.0);
		attraction += proximity_factor * attraction_strength * proximity_boost;

		// Apply force to velocity
		VELOCITY.xy += normalized_direction * attraction * DELTA;
	}

	// Apply light damping to prevent erratic movement
	VELOCITY.xy *= 0.97;

	// Kill particle when it reaches the filter (collision with filter zone)
	if (distance < kill_distance) {
		// Fade out the particle smoothly
		COLOR.a *= 0.8; // Reduce alpha each frame

		// If very close, kill it
		if (distance < kill_distance * 0.5) {
			VELOCITY = vec3(0.0);
			COLOR.a = 0.0;
		}
	}

	// Secondary fade-out based on lifetime (final 15% of life)
	if (CUSTOM.y > 0.85) {
		float fade_factor = (1.0 - CUSTOM.y) / 0.15;
		COLOR.a *= fade_factor;
	}
}
