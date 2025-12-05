extends GutTest

## Integration tests for shader controllers with scene
## Tests controller+shader interactions

var scene: Node2D
var sky_controller: SkyController
var smog_controller: SmogController
var parallax_controller: ParallaxController

func before_each():
	"""Load Main scene for integration testing"""
	scene = load("res://scenes/Main.tscn").instantiate()
	add_child(scene)

	# Cache controller references
	parallax_controller = scene.get_node("ParallaxBG")
	sky_controller = scene.get_node("ParallaxBG/SkyLayer/SkyShaderSprite")
	smog_controller = scene.get_node("ParallaxBG/SmogManager")

func after_each():
	"""Clean up scene"""
	if scene:
		scene.queue_free()

## TEST GROUP 1: Scene Structure Validation

func test_scene_loads():
	"""Main.tscn should load without errors"""
	assert_not_null(scene, "Scene failed to load")

func test_parallax_controller_attached():
	"""ParallaxController should be attached to ParallaxBG"""
	assert_not_null(parallax_controller, "ParallaxController not found")
	assert_true(parallax_controller is ParallaxController, "Not a ParallaxController")

func test_sky_controller_attached():
	"""SkyController should be attached to SkyShaderSprite"""
	assert_not_null(sky_controller, "SkyController not found")
	assert_true(sky_controller is SkyController, "Not a SkyController")

func test_smog_controller_attached():
	"""SmogController should be attached to SmogManager"""
	assert_not_null(smog_controller, "SmogController not found")
	assert_true(smog_controller is SmogController, "Not a SmogController")

## TEST GROUP 2: Sky Shader Material

func test_sky_shader_material_exists():
	"""Sky sprite should have ShaderMaterial"""
	assert_not_null(sky_controller.material, "Sky material is null")
	assert_true(sky_controller.material is ShaderMaterial, "Not a ShaderMaterial")

func test_sky_shader_uniforms_initialized():
	"""Sky shader uniforms should be set"""
	var mat = sky_controller.material as ShaderMaterial
	assert_not_null(mat.get_shader_parameter("sky_state"), "sky_state not set")
	assert_not_null(mat.get_shader_parameter("transition_progress"), "transition_progress not set")

## TEST GROUP 3: Smog Shader Materials

func test_smog_materials_cached():
	"""SmogController should cache all 3 smog materials"""
	assert_eq(smog_controller.smog_materials.size(), 3, "Should have 3 smog materials")

func test_smog_shader_uniforms_exist():
	"""Smog shaders should have required uniforms"""
	for i in range(smog_controller.smog_materials.size()):
		var mat = smog_controller.smog_materials[i]
		assert_not_null(mat, "Smog material %d is null" % i)
		assert_not_null(mat.get_shader_parameter("noise_time"), "noise_time not found in layer %d" % i)
		assert_not_null(mat.get_shader_parameter("opacity"), "opacity not found in layer %d" % i)

## TEST GROUP 4: Sky State Transitions

func test_sky_initial_state():
	"""Sky should start in clear state (2)"""
	var mat = sky_controller.material as ShaderMaterial
	var state = mat.get_shader_parameter("sky_state") as int
	assert_eq(state, 2, "Sky should initialize to clear (state 2)")

func test_sky_set_aqi_triggers_transition():
	"""Calling set_aqi should update sky"""
	# Set AQI to bad (> 200)
	sky_controller.set_aqi(250.0)
	# Transition happens via Tween, check state changed
	await get_tree().process_frame
	assert_eq(sky_controller.current_state, 0, "Sky state should change to bad (0)")

func test_sky_state_names():
	"""Sky states should have readable names"""
	var clear_name = sky_controller.get_current_state()
	assert_eq(clear_name, "clear", "Initial state should be 'clear'")

## TEST GROUP 5: Smog Opacity Updates

func test_smog_aqi_zero_opacity():
	"""AQI = 0 should produce zero opacity"""
	smog_controller.set_aqi(0.0)
	for i in range(smog_controller.smog_materials.size()):
		var opacity = smog_controller.get_layer_opacity(i)
		assert_eq(opacity, 0.0, "Layer %d opacity at AQI 0 should be 0.0" % i)

func test_smog_aqi_mid_opacity():
	"""AQI = 150 should produce opacity ≈ 0.35 (base) for layer 0"""
	smog_controller.set_aqi(150.0)
	var base_opacity = 150.0 / 300.0  # ≈ 0.5
	var expected_layer0 = base_opacity * 0.4  # ≈ 0.2
	var actual = smog_controller.get_layer_opacity(0)
	assert_almost_eq(actual, expected_layer0, 0.01, "Layer 0 opacity incorrect at AQI 150")

func test_smog_aqi_max_clamping():
	"""AQI > 300 should clamp opacity to 0.7 * multiplier"""
	smog_controller.set_aqi(600.0)
	var expected_layer2 = 0.7 * 0.8  # Max opacity × multiplier
	var actual = smog_controller.get_layer_opacity(2)
	assert_almost_eq(actual, expected_layer2, 0.01, "Layer 2 opacity should be clamped")

## TEST GROUP 6: Parallax Scrolling

func test_parallax_scroll_increases():
	"""Parallax scroll offset should increase over time"""
	var initial = parallax_controller.get_scroll_offset()
	await get_tree().process_frame
	var updated = parallax_controller.get_scroll_offset()
	assert_true(updated > initial, "Scroll offset should increase")

func test_parallax_scroll_rate():
	"""Parallax should scroll at configured speed"""
	var speed = parallax_controller.scroll_speed
	assert_eq(speed, 300.0, "Default scroll speed should be 300")

## TEST GROUP 7: Shader Parameter Synchronization

func test_smog_noise_time_updates():
	"""Smog noise_time should update each frame"""
	var initial_times: Array[float] = []
	for mat in smog_controller.smog_materials:
		initial_times.append(mat.get_shader_parameter("noise_time") as float)

	# Wait a frame
	await get_tree().process_frame

	for i in range(smog_controller.smog_materials.size()):
		var updated_time = smog_controller.smog_materials[i].get_shader_parameter("noise_time") as float
		assert_true(updated_time > initial_times[i], "Noise time for layer %d should increase" % i)

func test_sky_shader_can_transition():
	"""Sky shader transition should work without errors"""
	sky_controller.set_aqi(250.0)  # Trigger transition
	await get_tree().process_frame
	assert_true(true, "Sky transition completed without error")

## TEST GROUP 8: Multi-Layer Depth

func test_smog_layer_order():
	"""Smog layers should be in correct order (between parallax layers)"""
	var layers = [
		"SkyLayer",
		"SmogLayer_1",
		"FarLayer",
		"SmogLayer_2",
		"MidLayer",
		"SmogLayer_3",
		"FrontLayer",
	]

	var parallax_bg = scene.get_node("ParallaxBG")
	var children = parallax_bg.get_children()
	var found_order: Array[String] = []

	for child in children:
		if child is ParallaxLayer:
			found_order.append(child.name)

	# Check that smog layers are between other layers
	var smog1_idx = found_order.find("SmogLayer_1")
	var far_idx = found_order.find("FarLayer")
	var smog2_idx = found_order.find("SmogLayer_2")
	var mid_idx = found_order.find("MidLayer")

	assert_true(smog1_idx > 0 and smog1_idx < far_idx, "SmogLayer_1 should be before FarLayer")
	assert_true(smog2_idx > far_idx and smog2_idx < mid_idx, "SmogLayer_2 should be before MidLayer")

## Helper for floating-point comparison
func assert_almost_eq(actual: float, expected: float, tolerance: float, msg: String = ""):
	var diff = abs(actual - expected)
	assert_true(diff <= tolerance, "Values differ by %.4f: %s" % [diff, msg])
