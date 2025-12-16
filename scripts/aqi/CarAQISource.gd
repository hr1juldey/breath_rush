class_name CarAQISource
extends AQISource

"""
Attached to obstacle cars - increases AQI while in range
Linear falloff with distance
"""

func _init():
	source_type = SourceType.INCREASES_AQI
	range_type = RangeType.LINEAR
	base_effect = .25 # Gradually increase AQI to ~300 while car is visible (10s on screen)
	effective_range = 800.0 # Effect radius
