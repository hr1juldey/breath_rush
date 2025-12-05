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

func _ready():
	# Cache shader materials from all 3 smog sprites
	var smog_paths = [
		"../SmogLayer_1/SmogShaderSprite_1",
		"../SmogLayer_2/SmogShaderSprite_2",
		"../SmogLayer_3/SmogShaderSprite_3"
	]

	for path in smog_paths:
		var sprite = get_node_or_null(path) as Sprite2D
		if sprite and sprite.material:
			smog_materials.append(sprite.material as ShaderMaterial)
		else:
			push_error("SmogController: Cannot find smog sprite at %s" % path)

	if smog_materials.is_empty():
		push_error("SmogController: No smog materials found!")

func _physics_process(delta):
	"""Update noise animation for all smog layers"""
	for material in smog_materials:
		if material:
			var current_time = material.get_shader_parameter("noise_time") as float
			material.set_shader_parameter("noise_time", current_time + delta * 300.0 * 1.02)

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
