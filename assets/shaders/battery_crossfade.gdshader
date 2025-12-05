shader_type canvas_item;

// Current battery level texture
uniform sampler2D current_texture : hint_default_white;

// Next battery level texture (for transition)
uniform sampler2D next_texture : hint_default_white;

// Crossfade weight: 0.0 = show current, 1.0 = show next
uniform float crossfade_weight : hint_range(0.0, 1.0) = 0.0;

// Blink alpha modulation (for discharge)
uniform float blink_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Sample both textures
	vec4 current_color = texture(current_texture, UV);
	vec4 next_color = texture(next_texture, UV);

	// Apply blink alpha to current texture (discharge only)
	current_color.a *= blink_alpha;

	// Crossfade between current and next
	vec4 blended = mix(current_color, next_color, crossfade_weight);

	COLOR = blended;
}
