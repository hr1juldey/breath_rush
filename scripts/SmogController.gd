extends Node
class_name SmogController

## Single Responsibility: Manage smog shader parameters across 3 layers
## Updates noise animation and opacity based on AQI

@export var max_fog_aqi: float = 300.0
@export var max_fog_opacity: float = 0.7

var smog_materials: Array[ShaderMaterial] = []
var current_aqi: float = 150.0

# Opacity multipliers per layer (far, mid, near)
var layer_multipliers: Array[float] = [0.4, 0.6, 0.8]

# Scroll speed multipliers per layer (should match Parallax2D motion_scale)
# ADJUSTED: Closer values reduce beat pattern interference
# Was [0.15, 0.45, 0.75] which created flickering beat patterns
var scroll_speed_multipliers: Array[float] = [0.30, 0.35, 0.40]

# Phase offsets to prevent pattern alignment (prevents flickering)
# ADJUSTED: Smaller variation for smoother transition between layers
# Was [0.0, 137.5, 283.1] which caused pattern misalignment
var phase_offsets: Array[float] = [0.0, 20.0, 40.0]

func _ready():
	# Cache shader materials from all 3 smog sprites
	var smog_paths = [
		"../SmogLayer_1/SmogShaderSprite_1",
		"../SmogLayer_2/SmogShaderSprite_2",
		"../SmogLayer_3/SmogShaderSprite_3"
	]

	for i in range(smog_paths.size()):
		var sprite = get_node_or_null(smog_paths[i]) as Sprite2D
		if sprite and sprite.material:
			var mat = sprite.material as ShaderMaterial
			smog_materials.append(mat)

			# Initialize each layer with phase offset to prevent pattern alignment
			mat.set_shader_parameter("noise_time", phase_offsets[i])
		else:
			push_error("SmogController: Cannot find smog sprite at %s" % smog_paths[i])

	if smog_materials.is_empty():
		push_error("SmogController: No smog materials found!")

func _physics_process(delta):
	"""Update noise animation for all smog layers with proper parallax scroll speeds"""
	for i in range(smog_materials.size()):
		if smog_materials[i]:
			# Each layer scrolls at speed proportional to its parallax motion_scale
			# This prevents flickering from pattern interference
			var speed_mult = scroll_speed_multipliers[i]
			var current_time = smog_materials[i].get_shader_parameter("noise_time") as float

			# Base scroll speed REDUCED from 300.0 → 80.0 → 30.0 for very slow, organic flow
			# Multipliers now tightly grouped [0.30, 0.35, 0.40] for smooth layering
			var scroll_increment = delta * 30.0 * speed_mult
			smog_materials[i].set_shader_parameter("noise_time", current_time + scroll_increment)

func set_aqi(aqi: float):
	"""Update all smog layers opacity based on AQI"""
	current_aqi = clamp(aqi, 0.0, max_fog_aqi)

	# Calculate base opacity from AQI
	var base_opacity = clamp(current_aqi / max_fog_aqi, 0.0, max_fog_opacity)

	# Apply to each layer with multiplier
	for i in range(smog_materials.size()):
		if smog_materials[i]:
			var layer_opacity = base_opacity * layer_multipliers[i]
			smog_materials[i].set_shader_parameter("opacity", layer_opacity)

	print_debug("Smog AQI: %.1f → base_opacity: %.3f" % [current_aqi, base_opacity])

func get_current_aqi() -> float:
	"""Return current AQI value"""
	return current_aqi

func get_layer_opacity(layer_index: int) -> float:
	"""Get opacity for specific layer (for testing)"""
	if layer_index >= smog_materials.size() or not smog_materials[layer_index]:
		return 0.0

	return smog_materials[layer_index].get_shader_parameter("opacity") as float
