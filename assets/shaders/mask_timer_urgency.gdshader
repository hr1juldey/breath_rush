shader_type canvas_item;

// Urgency level: 0.0 = safe (green), 0.5 = warning (yellow), 1.0 = critical (red)
uniform float urgency : hint_range(0.0, 1.0) = 0.0;

// Pulse alpha for urgency effect (animated)
uniform float pulse_alpha : hint_range(0.0, 1.0) = 1.0;

// Base colors for different urgency levels
const vec3 COLOR_SAFE = vec3(0.3, 0.9, 0.8);      // Cyan/teal (safe)
const vec3 COLOR_WARNING = vec3(1.0, 0.9, 0.3);   // Yellow (warning)
const vec3 COLOR_CRITICAL = vec3(1.0, 0.3, 0.3);  // Red (critical)

void fragment() {
	// Sample base texture
	vec4 tex_color = texture(TEXTURE, UV);

	// Calculate color based on urgency (lerp between safe → warning → critical)
	vec3 tint_color;
	if (urgency < 0.5) {
		// Safe to warning (0.0 - 0.5)
		float t = urgency * 2.0;
		tint_color = mix(COLOR_SAFE, COLOR_WARNING, t);
	} else {
		// Warning to critical (0.5 - 1.0)
		float t = (urgency - 0.5) * 2.0;
		tint_color = mix(COLOR_WARNING, COLOR_CRITICAL, t);
	}

	// Apply tint to texture (multiply blend)
	vec3 final_color = tex_color.rgb * tint_color;

	// Apply pulse alpha (for urgency breathing effect)
	float final_alpha = tex_color.a * pulse_alpha;

	COLOR = vec4(final_color, final_alpha);
}
