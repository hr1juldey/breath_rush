class_name CarAQISource
extends AQISource

"""
Attached to obstacle cars - increases AQI while in range
Linear falloff with distance
"""

func _init():
	source_type = SourceType.INCREASES_AQI
	range_type = RangeType.LINEAR
	base_effect = 5.0  # 5% per minute base
	effective_range = 800.0  # Effect radius
