shader_type canvas_item;
// Smog/fog shader with flowing noise pattern
// Creates organic haze effect with horizontal scroll

// Animation
uniform float noise_time = 0.0;           // Updated by controller
uniform float noise_speed : hint_range(0.5, 3.0) = 2.0;  // 2% faster than camera

// Visual parameters
uniform float noise_scale : hint_range(0.5, 10.0) = 3.0;  // Detail level
uniform float opacity : hint_range(0.0, 1.0) = 0.5;       // AQI-driven

// Simple hash-based pseudo-random function
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Cubic interpolation (smoother than smoothstep, prevents flickering)
float cubic(float t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// Simple 2D noise (Perlin-like)
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	// Four corners
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Smooth interpolation
	float u = cubic(f.x);
	float v = cubic(f.y);

	// Mix corners
	float ab = mix(a, b, u);
	float cd = mix(c, d, u);
	return mix(ab, cd, v);
}

// Fractal Brownian Motion (FBM) for organic look
float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 1.0;
	float frequency = 1.0;

	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p * frequency);
		amplitude *= 0.5;
		frequency *= 2.0;
	}

	return value;
}

void fragment() {
	// Horizontal scrolling UV (time-based animation)
	vec2 scroll_uv = UV;
	scroll_uv.x -= noise_time * noise_speed;

	// Generate multi-octave noise pattern
	float fog_pattern = fbm(scroll_uv * noise_scale);

	// Remap noise to useful range and add contrast
	fog_pattern = smoothstep(0.25, 0.75, fog_pattern);

	// Apply opacity modulation (texture alpha ignored, shader controls it)
	float final_alpha = fog_pattern * opacity;

	// Grayish fog color
	vec3 fog_color = vec3(0.55, 0.55, 0.55);

	// Force output alpha - ignore texture alpha
	COLOR = vec4(fog_color, final_alpha);
}
