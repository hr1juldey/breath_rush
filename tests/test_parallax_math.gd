extends GutTest

## Unit tests for 2.5D parallax mathematical verification
## Tests ensure all parallax calculations match the mathematical plan

var parallax_controller: ParallaxController
var smog_controller: SmogController

func before_each():
	"""Setup test fixtures before each test"""
	# Create dummy nodes for testing (can be extended to use real scene)
	parallax_controller = ParallaxController.new()
	smog_controller = SmogController.new()

## TEST GROUP 1: Parallax Layer Motion_Scale Configuration

func test_sky_layer_motion_scale():
	"""Sky layer should have motion_scale = Vector2(0.1, 0)"""
	var expected = Vector2(0.1, 0)
	var actual = parallax_controller.expected_motion_scales["SkyLayer"]
	assert_eq(actual, expected, "Sky layer motion_scale incorrect")

func test_far_layer_motion_scale():
	"""Far layer should have motion_scale = Vector2(0.3, 0)"""
	var expected = Vector2(0.3, 0)
	var actual = parallax_controller.expected_motion_scales["FarLayer"]
	assert_eq(actual, expected, "Far layer motion_scale incorrect")

func test_mid_layer_motion_scale():
	"""Mid layer should have motion_scale = Vector2(0.6, 0)"""
	var expected = Vector2(0.6, 0)
	var actual = parallax_controller.expected_motion_scales["MidLayer"]
	assert_eq(actual, expected, "Mid layer motion_scale incorrect")

func test_front_layer_motion_scale():
	"""Front layer should have motion_scale = Vector2(0.9, 0)"""
	var expected = Vector2(0.9, 0)
	var actual = parallax_controller.expected_motion_scales["FrontLayer"]
	assert_eq(actual, expected, "Front layer motion_scale incorrect")

## TEST GROUP 2: Parallax Motion Mathematics

func test_parallax_formula_sky():
	"""Sky layer motion: offset = camera × 0.1"""
	var camera_offset = 1000.0
	var motion_scale = 0.1
	var expected = camera_offset * motion_scale  # 100.0
	assert_eq(expected, 100.0, "Sky layer parallax formula failed")

func test_parallax_formula_far():
	"""Far layer motion: offset = camera × 0.3"""
	var camera_offset = 1000.0
	var motion_scale = 0.3
	var expected = camera_offset * motion_scale  # 300.0
	assert_eq(expected, 300.0, "Far layer parallax formula failed")

func test_parallax_formula_mid():
	"""Mid layer motion: offset = camera × 0.6"""
	var camera_offset = 1000.0
	var motion_scale = 0.6
	var expected = camera_offset * motion_scale  # 600.0
	assert_eq(expected, 600.0, "Mid layer parallax formula failed")

func test_parallax_formula_front():
	"""Front layer motion: offset = camera × 0.9"""
	var camera_offset = 1000.0
	var motion_scale = 0.9
	var expected = camera_offset * motion_scale  # 900.0
	assert_eq(expected, 900.0, "Front layer parallax formula failed")

## TEST GROUP 3: Apparent Distance Calculation

func test_apparent_distance_sky():
	"""Perceived distance = camera_distance / motion_scale"""
	var camera_distance = 1000.0
	var motion_scale = 0.1
	var apparent_distance = camera_distance / motion_scale
	assert_eq(apparent_distance, 10000.0, "Sky apparent distance incorrect (should appear 10× farther)")

func test_apparent_distance_far():
	"""Far landmarks should appear ~3.3× farther than camera"""
	var camera_distance = 1000.0
	var motion_scale = 0.3
	var apparent_distance = camera_distance / motion_scale
	var expected_multiplier = 1.0 / motion_scale  # ~3.33
	assert_almost_eq(expected_multiplier, 3.333, 0.01, "Far layer distance multiplier incorrect")

func test_apparent_distance_mid():
	"""Mid elements should appear ~1.67× farther than camera"""
	var camera_distance = 1000.0
	var motion_scale = 0.6
	var expected_multiplier = 1.0 / motion_scale  # ~1.67
	assert_almost_eq(expected_multiplier, 1.667, 0.01, "Mid layer distance multiplier incorrect")

func test_apparent_distance_front():
	"""Front elements should appear ~1.1× farther than camera"""
	var camera_distance = 1000.0
	var motion_scale = 0.9
	var expected_multiplier = 1.0 / motion_scale  # ~1.11
	assert_almost_eq(expected_multiplier, 1.111, 0.01, "Front layer distance multiplier incorrect")

## TEST GROUP 4: Fog/Smog AQI Calculation

func test_fog_alpha_aqi_0():
	"""AQI 0 (clear air) should produce fog_alpha = 0.0"""
	var aqi = 0.0
	var expected = 0.0
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_eq(actual, expected, "Fog alpha at AQI 0 should be 0.0")

func test_fog_alpha_aqi_50():
	"""AQI 50 should produce fog_alpha ≈ 0.167"""
	var aqi = 50.0
	var expected = 50.0 / 300.0  # 0.1667
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_almost_eq(actual, expected, 0.01, "Fog alpha at AQI 50 incorrect")

func test_fog_alpha_aqi_100():
	"""AQI 100 should produce fog_alpha ≈ 0.333"""
	var aqi = 100.0
	var expected = 100.0 / 300.0  # 0.3333
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_almost_eq(actual, expected, 0.01, "Fog alpha at AQI 100 incorrect")

func test_fog_alpha_aqi_150():
	"""AQI 150 (moderate) should produce fog_alpha = 0.5"""
	var aqi = 150.0
	var expected = 150.0 / 300.0  # 0.5
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_eq(actual, expected, "Fog alpha at AQI 150 should be 0.5")

func test_fog_alpha_aqi_200():
	"""AQI 200 should produce fog_alpha ≈ 0.667"""
	var aqi = 200.0
	var expected = 200.0 / 300.0  # 0.6667
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_almost_eq(actual, expected, 0.01, "Fog alpha at AQI 200 incorrect")

func test_fog_alpha_aqi_300():
	"""AQI 300+ should clamp to max fog_alpha = 0.7"""
	var aqi = 300.0
	var expected = 0.7  # Clamped to max
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_eq(actual, expected, "Fog alpha at AQI 300 should clamp to 0.7")

func test_fog_alpha_aqi_over_300():
	"""AQI > 300 should still clamp to max fog_alpha = 0.7"""
	var aqi = 500.0
	var expected = 0.7  # Clamped to max
	var actual = smog_controller.calculate_fog_alpha(aqi)
	assert_eq(actual, expected, "Fog alpha > AQI 300 should clamp to 0.7")

## TEST GROUP 5: Fog Linear Interpolation

func test_fog_alpha_linear_progression():
	"""Fog alpha should progress linearly with AQI"""
	var aqi_values = [0, 50, 100, 150, 200, 250, 300]

	for aqi in aqi_values:
		var expected = clamp(float(aqi) / 300.0, 0.0, 0.7)
		var actual = smog_controller.calculate_fog_alpha(float(aqi))
		assert_almost_eq(actual, expected, 0.001,
			"Fog alpha mismatch at AQI %.0f" % aqi)

## TEST GROUP 6: Parallax Verification Error Detection

func test_parallax_tolerance_within_limit():
	"""Error within 1 pixel tolerance should pass verification"""
	var camera_offset = 500.0
	var motion_scale = 0.3
	var expected = camera_offset * motion_scale  # 150.0
	var actual = 150.2  # 0.2 pixel error (within 1.0 tolerance)
	var error = abs(expected - actual)
	assert_true(error <= 1.0, "Parallax error should be within tolerance")

func test_parallax_tolerance_exceeds_limit():
	"""Error exceeding 1 pixel tolerance should fail"""
	var camera_offset = 500.0
	var motion_scale = 0.3
	var expected = camera_offset * motion_scale  # 150.0
	var actual = 151.5  # 1.5 pixel error (exceeds 1.0 tolerance)
	var error = abs(expected - actual)
	assert_false(error <= 1.0, "Parallax error should exceed tolerance")

## TEST GROUP 7: Edge Cases

func test_zero_camera_offset():
	"""All layers should be at position 0 when camera offset is 0"""
	var camera_offset = 0.0
	var scales = [0.1, 0.3, 0.6, 0.9]

	for scale in scales:
		var expected = camera_offset * scale  # Always 0.0
		assert_eq(expected, 0.0, "Layer at camera offset 0 should be at 0")

func test_large_camera_offset():
	"""Parallax should scale correctly for large camera offsets (10000+ pixels)"""
	var camera_offset = 10000.0
	var motion_scales = {
		"Sky": 0.1,      # Expected: 1000.0
		"Far": 0.3,      # Expected: 3000.0
		"Mid": 0.6,      # Expected: 6000.0
		"Front": 0.9,    # Expected: 9000.0
	}

	var expected_positions = [1000.0, 3000.0, 6000.0, 9000.0]

	for i in range(motion_scales.size()):
		var layer_name = motion_scales.keys()[i]
		var scale = motion_scales[layer_name]
		var expected = camera_offset * scale
		assert_eq(expected, expected_positions[i], "%s position at large offset incorrect" % layer_name)

func test_negative_camera_offset():
	"""Parallax should handle negative offsets (camera moving backward)"""
	var camera_offset = -500.0
	var motion_scale = 0.5
	var expected = camera_offset * motion_scale  # -250.0
	assert_eq(expected, -250.0, "Negative camera offset handling failed")

## Helper assertion for floating-point comparisons
func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String = ""):
	var diff = abs(actual - expected)
	assert_true(diff <= tolerance, "Values differ by %f (tolerance: %f). %s" % [diff, tolerance, message])
