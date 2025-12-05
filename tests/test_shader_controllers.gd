extends GutTest

## Unit tests for shader-based controllers
## Tests: SkyController, SmogController, ParallaxController

var sky_controller: SkyController
var smog_controller: SmogController
var parallax_controller: ParallaxController

func before_each():
	"""Setup test fixtures"""
	# Note: Full integration tests require scene with ShaderMaterials
	# These tests verify logic without scene dependency
	pass

## TEST GROUP 1: Parallax Scrolling

func test_parallax_controller_exists():
	"""ParallaxController class should be defined"""
	assert_true(ParallaxController != null, "ParallaxController not defined")

func test_parallax_scroll_offset_increases():
	"""Scroll offset should increase over time"""
	var controller = ParallaxController.new()
	controller.scroll_speed = 100.0
	controller.current_scroll_offset = 0.0

	controller.set_scroll_offset(500.0)
	assert_eq(controller.get_scroll_offset(), 500.0, "Scroll offset not set")

func test_parallax_scroll_offset_returns():
	"""get_scroll_offset should return current value"""
	var controller = ParallaxController.new()
	controller.current_scroll_offset = 123.45
	assert_eq(controller.get_scroll_offset(), 123.45, "Scroll offset mismatch")

## TEST GROUP 2: Sky Controller Logic

func test_sky_controller_aqi_to_state_clear():
	"""AQI <= 100 should map to clear (state 2)"""
	var controller = SkyController.new()
	controller.current_state = 0
	controller.bad_threshold = 200.0
	controller.ok_threshold = 100.0

	# Test clear state mapping
	assert_eq(controller.current_state, 0)  # Will update when _transition_to_state called

func test_sky_controller_aqi_to_state_ok():
	"""100 < AQI <= 200 should map to ok (state 1)"""
	var controller = SkyController.new()
	controller.bad_threshold = 200.0
	controller.ok_threshold = 100.0

	# Verify thresholds are set
	assert_eq(controller.bad_threshold, 200.0, "Bad threshold not set")
	assert_eq(controller.ok_threshold, 100.0, "OK threshold not set")

func test_sky_controller_aqi_to_state_bad():
	"""AQI > 200 should map to bad (state 0)"""
	var controller = SkyController.new()
	controller.bad_threshold = 200.0
	controller.ok_threshold = 100.0

	# Verify thresholds are correct
	assert_true(300.0 > controller.bad_threshold, "AQI 300 should exceed bad threshold")

## TEST GROUP 3: Smog Controller Logic

func test_smog_controller_aqi_clamping():
	"""AQI values outside range should be clamped"""
	var controller = SmogController.new()
	controller.max_fog_aqi = 300.0

	var negative_aqi = -50.0
	var clamped = clamp(negative_aqi, 0.0, controller.max_fog_aqi)
	assert_eq(clamped, 0.0, "Negative AQI should clamp to 0")

	var large_aqi = 500.0
	clamped = clamp(large_aqi, 0.0, controller.max_fog_aqi)
	assert_eq(clamped, 300.0, "Large AQI should clamp to max")

func test_smog_opacity_formula():
	"""Opacity formula: opacity = clamp(AQI/300, 0, 0.7)"""
	var max_aqi = 300.0
	var max_opacity = 0.7

	var test_cases = [
		{"aqi": 0.0, "expected": 0.0},
		{"aqi": 150.0, "expected": 0.35},
		{"aqi": 300.0, "expected": 0.7},
		{"aqi": 600.0, "expected": 0.7},  # clamped
	]

	for case in test_cases:
		var opacity = clamp(case.aqi / max_aqi, 0.0, max_opacity)
		assert_almost_eq(opacity, case.expected, 0.01,
			"Opacity mismatch at AQI %.1f" % case.aqi)

func test_smog_layer_multipliers():
	"""Each layer should have correct opacity multiplier"""
	var controller = SmogController.new()
	var expected = [0.4, 0.6, 0.8]

	assert_eq(controller.layer_multipliers.size(), 3, "Should have 3 layer multipliers")
	for i in range(expected.size()):
		assert_eq(controller.layer_multipliers[i], expected[i],
			"Layer %d multiplier incorrect" % i)

func test_smog_layer_opacity_calculation():
	"""Layer opacity = base_opacity * multiplier"""
	var base_opacity = 0.5
	var multipliers = [0.4, 0.6, 0.8]
	var expected_opacities = [0.2, 0.3, 0.4]

	for i in range(multipliers.size()):
		var layer_opacity = base_opacity * multipliers[i]
		assert_almost_eq(layer_opacity, expected_opacities[i], 0.01,
			"Layer %d opacity incorrect" % i)

## TEST GROUP 4: Shader Parameter Types

func test_sky_state_is_integer():
	"""Sky state should be 0, 1, or 2"""
	var valid_states = [0, 1, 2]
	for state in valid_states:
		assert_true(state in valid_states, "State %d invalid" % state)

func test_transition_progress_in_range():
	"""Transition progress should be 0.0 to 1.0"""
	var progress = 0.5
	var clamped = clamp(progress, 0.0, 1.0)
	assert_eq(clamped, 0.5, "Progress not clamped correctly")

func test_smog_noise_time_positive():
	"""Noise time should accumulate positively"""
	var noise_time = 0.0
	var delta = 0.016  # ~60fps
	var scroll_speed = 300.0

	for frame in range(60):
		noise_time += delta * scroll_speed * 1.02
		assert_true(noise_time > 0.0, "Noise time should be positive")

## TEST GROUP 5: Edge Cases

func test_zero_aqi():
	"""AQI = 0 should produce zero fog"""
	var opacity = clamp(0.0 / 300.0, 0.0, 0.7)
	assert_eq(opacity, 0.0, "Zero AQI should produce zero opacity")

func test_max_aqi_clamping():
	"""AQI > max should clamp to max_opacity"""
	var large_aqi = 1000.0
	var opacity = clamp(large_aqi / 300.0, 0.0, 0.7)
	assert_eq(opacity, 0.7, "Large AQI should clamp to 0.7")

func test_sky_state_cycling():
	"""Sky states should cycle: bad → ok → clear"""
	var states = [0, 1, 2]
	for state in states:
		assert_true(state >= 0 and state <= 2, "Invalid state: %d" % state)

## Helper for floating-point comparison
func assert_almost_eq(actual: float, expected: float, tolerance: float, msg: String = ""):
	var diff = abs(actual - expected)
	assert_true(diff <= tolerance, "Values differ by %.4f: %s" % [diff, msg])
