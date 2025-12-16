class_name AQISource
extends Node

"""
Base class for all AQI-affecting entities (cars, trees, filters)
Automatically registers with AQIManager on ready
"""

enum SourceType { INCREASES_AQI, DECREASES_AQI }
enum RangeType { NONE, LINEAR, INVERSE, INVERSE_SQUARE }

@export var source_type: SourceType = SourceType.DECREASES_AQI
@export var range_type: RangeType = RangeType.NONE
@export var base_effect: float = 1.0
@export var effective_range: float = 1000.0

var spawn_distance: float = 0.0  # Distance when this source was created
var is_active: bool = true

func _ready():
	# Auto-register with AQIManager
	var aqi_manager = _get_aqi_manager()
	if aqi_manager:
		spawn_distance = aqi_manager.distance_traveled
		aqi_manager.register_source(self)

func _exit_tree():
	var aqi_manager = _get_aqi_manager()
	if aqi_manager:
		aqi_manager.unregister_source(self)

func _get_aqi_manager() -> Node:
	# Try autoload first
	if Engine.has_singleton("AQIManager"):
		return Engine.get_singleton("AQIManager")
	# Fallback to group
	var managers = get_tree().get_nodes_in_group("aqi_manager")
	return managers[0] if managers.size() > 0 else null

func calculate_effect(player_distance: float, delta: float) -> float:
	"""Calculate AQI change contribution for this frame"""
	if not is_active:
		return 0.0

	var distance_from_source = abs(player_distance - spawn_distance)
	var range_multiplier = _get_range_multiplier(distance_from_source)
	var effect = base_effect * range_multiplier * delta

	# Return negative to decrease AQI, positive to increase AQI
	return -effect if source_type == SourceType.DECREASES_AQI else effect

func _get_range_multiplier(distance: float) -> float:
	match range_type:
		RangeType.NONE:
			return 1.0
		RangeType.LINEAR:
			return max(0.0, 1.0 - (distance / effective_range))
		RangeType.INVERSE:  # r^-1 for trees
			var d = max(distance / 100.0, 0.1)
			return 1.0 / d
		RangeType.INVERSE_SQUARE:  # r^-2 for filters
			var d = max(distance / 100.0, 0.1)
			return 1.0 / (d * d)
	return 1.0
