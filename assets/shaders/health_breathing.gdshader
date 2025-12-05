shader_type canvas_item;

// Base damage state texture
uniform sampler2D damage_texture : hint_default_white;

// Breathing animation texture (masked - only healthy lungs)
uniform sampler2D breathing_texture : hint_default_white;

// Breathing animation parameters
uniform float breathing_period : hint_range(1.0, 5.0) = 3.0;
uniform float breathing_strength : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	// Sample both textures at current UV
	vec4 dst = texture(damage_texture, UV);      // Destination (damage sprite - background)
	vec4 src_raw = texture(breathing_texture, UV); // Source (breathing sprite - foreground)

	// Calculate sinusoidal breathing alpha oscillation
	// sin(TIME) ranges from -1 to 1
	// (sin + 1) / 2 ranges from 0 to 1
	float breathing_alpha = (sin(TIME * 2.0 * 3.14159 / breathing_period) + 1.0) / 2.0;
	breathing_alpha *= breathing_strength;  // Scale to 0 to breathing_strength

	// Modulate breathing texture alpha by breathing animation
	vec4 src = src_raw;
	src.a *= breathing_alpha;

	// Porter-Duff "over" operation: src over dst
	// This properly composites the breathing sprite over the damage sprite
	// respecting transparency (alpha=0 means invisible, not translucent)
	float final_a = src.a + dst.a * (1.0 - src.a);

	vec3 final_rgb;
	if (final_a > 0.0) {
		// Proper alpha compositing with pre-multiplication
		// Prevents color bleeding from transparent pixels
		final_rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / final_a;
	} else {
		// Both fully transparent - use black
		final_rgb = vec3(0.0);
	}

	COLOR = vec4(final_rgb, final_a);
}
