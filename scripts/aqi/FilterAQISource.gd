class_name FilterAQISource
extends AQISource

"""
Dropped filters - decreases AQI with r^-2 falloff
Automatically expires after 60 seconds
"""

signal filter_expired()

@export var lifespan: float = 60.0  # 60 seconds

var time_alive: float = 0.0

func _init():
	source_type = SourceType.DECREASES_AQI
	range_type = RangeType.INVERSE_SQUARE
	base_effect = 0.0  # AQI reduction handled by Filter.gd _reduce_aqi() during cleanup
	effective_range = 3000.0

func _process(delta: float):
	if not is_active:
		return

	time_alive += delta

	if time_alive >= lifespan:
		is_active = false
		filter_expired.emit()
		print("[FilterAQISource] Filter expired after %.1fs" % lifespan)

func get_remaining_time() -> float:
	return max(0.0, lifespan - time_alive)

func get_lifespan_progress() -> float:
	return time_alive / lifespan
