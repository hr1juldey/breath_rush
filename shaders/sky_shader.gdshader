shader_type canvas_item;
// Sky shader with AQI-based state transitions
// Renders gradient skies: bad (tan) → ok (light tan) → clear (blue)

// State: 0=bad, 1=ok, 2=clear
uniform int sky_state : hint_range(0, 2) = 2;

// Smooth transition: 0→1 when changing states
uniform float transition_progress : hint_range(0.0, 1.0) = 1.0;

// Bad AQI colors (dark, tan/brown)
uniform vec3 bad_sky_top : hint_color = vec3(0.75, 0.65, 0.50);
uniform vec3 bad_sky_bottom : hint_color = vec3(0.55, 0.45, 0.35);

// OK AQI colors (light tan)
uniform vec3 ok_sky_top : hint_color = vec3(0.82, 0.78, 0.70);
uniform vec3 ok_sky_bottom : hint_color = vec3(0.68, 0.62, 0.52);

// Clear AQI colors (blue sky)
uniform vec3 clear_sky_top : hint_color = vec3(0.45, 0.75, 1.0);
uniform vec3 clear_sky_bottom : hint_color = vec3(0.30, 0.55, 0.85);

void fragment() {
	// Get current state colors
	vec3 curr_top, curr_bottom;

	if (sky_state == 0) {           // bad
		curr_top = bad_sky_top;
		curr_bottom = bad_sky_bottom;
	} else if (sky_state == 1) {    // ok
		curr_top = ok_sky_top;
		curr_bottom = ok_sky_bottom;
	} else {                         // clear
		curr_top = clear_sky_top;
		curr_bottom = clear_sky_bottom;
	}

	// Get previous state colors (for interpolation)
	vec3 prev_top, prev_bottom;

	if (sky_state == 0) {
		prev_top = ok_sky_top;
		prev_bottom = ok_sky_bottom;
	} else if (sky_state == 1) {
		prev_top = clear_sky_top;
		prev_bottom = clear_sky_bottom;
	} else {
		prev_top = bad_sky_top;
		prev_bottom = bad_sky_bottom;
	}

	// Smooth interpolation between states
	vec3 final_top = mix(prev_top, curr_top, transition_progress);
	vec3 final_bottom = mix(prev_bottom, curr_bottom, transition_progress);

	// Vertical gradient: bottom → top (UV.y: 0=bottom, 1=top)
	vec3 sky_color = mix(final_bottom, final_top, UV.y);

	COLOR = vec4(sky_color, 1.0);
}
