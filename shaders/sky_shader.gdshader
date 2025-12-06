shader_type canvas_item;
// Sky shader with AQI-based state transitions
// Renders textured skies: bad → ok → clear

// State: 0=bad, 1=ok, 2=clear
uniform int sky_state : hint_range(0, 2) = 2;

// Smooth transition: 0→1 when changing states
uniform float transition_progress : hint_range(0.0, 1.0) = 1.0;

// Sky texture samplers
uniform sampler2D sky_bad_texture;
uniform sampler2D sky_ok_texture;
uniform sampler2D sky_clear_texture;

void fragment() {
	// Sample all three sky textures
	vec4 bad_sample = texture(sky_bad_texture, UV);
	vec4 ok_sample = texture(sky_ok_texture, UV);
	vec4 clear_sample = texture(sky_clear_texture, UV);

	// Get current state texture
	vec4 curr_color;

	if (sky_state == 0) {           // bad
		curr_color = bad_sample;
	} else if (sky_state == 1) {    // ok
		curr_color = ok_sample;
	} else {                         // clear
		curr_color = clear_sample;
	}

	// Get previous state texture (for smooth transition)
	vec4 prev_color;

	if (sky_state == 0) {
		prev_color = ok_sample;
	} else if (sky_state == 1) {
		prev_color = clear_sample;
	} else {
		prev_color = bad_sample;
	}

	// Smooth interpolation between states
	vec4 final_color = mix(prev_color, curr_color, transition_progress);

	COLOR = final_color;
}
