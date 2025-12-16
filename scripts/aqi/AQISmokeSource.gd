class_name AQISmokeSource
extends AQISource

"""
Temporary AQI source representing active car smoke damage
Applied when player enters smoke cloud without mask protection
"""

func _init():
	source_type = SourceType.INCREASES_AQI
	range_type = RangeType.NONE  # No distance falloff - direct effect while in smoke
	base_effect = 700.0  # 700 AQI per minute (very high!)
