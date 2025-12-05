extends Sprite2D
class_name SkyController

## Single Responsibility: Manage sky shader state based on AQI
## Handles smooth transitions between bad/ok/clear sky states

@onready var shader_material = material as ShaderMaterial

var current_state: int = 2  # 0=bad, 1=ok, 2=clear
var transition_duration: float = 1.0

# AQI thresholds for state changes
var bad_threshold: float = 200.0
var ok_threshold: float = 100.0

func _ready():
	if shader_material == null:
		push_error("SkyController: No ShaderMaterial attached!")
		return

	# Ensure material is unique instance
	material = material.duplicate()
	shader_material = material as ShaderMaterial

	# Initialize state
	_update_shader_uniform("transition_progress", 1.0)

func set_aqi(aqi: float):
	"""Update sky state based on AQI value"""
	var new_state: int = 2  # default: clear

	if aqi > bad_threshold:
		new_state = 0  # bad
	elif aqi > ok_threshold:
		new_state = 1  # ok

	if new_state != current_state:
		_transition_to_state(new_state)

func _transition_to_state(new_state: int):
	"""Smooth transition to new sky state"""
	current_state = new_state

	# Update shader state
	_update_shader_uniform("sky_state", current_state)

	# Animate transition_progress from 0 → 1
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(
		func(progress: float): _update_shader_uniform("transition_progress", progress),
		0.0, 1.0, transition_duration
	)

	var state_names = ["bad", "ok", "clear"]
	print_debug("Sky transitioning to: %s" % state_names[current_state])

func _update_shader_uniform(param_name: String, value):
	"""Update shader parameter safely"""
	if shader_material:
		shader_material.set_shader_parameter(param_name, value)
	else:
		push_error("SkyController: ShaderMaterial not found!")

func get_current_state() -> String:
	"""Debug: get current state name"""
	var states = ["bad", "ok", "clear"]
	return states[current_state] if current_state < states.size() else "unknown"

func set_thresholds(bad_aqi: float, ok_aqi: float):
	"""Reconfigure AQI thresholds"""
	bad_threshold = bad_aqi
	ok_threshold = ok_aqi
