class_name TreeAQISource
extends AQISource

"""
Attached to spawned trees - decreases AQI with r^-1 falloff
Different tree types have different effectiveness multipliers
"""

@export var tree_type: int = 1  # 1, 2, or 3

const TREE_MULTIPLIERS = {
	1: 1.0,   # tree_1 - basic
	2: 1.5,   # tree_2 - medium
	3: 2.0    # tree_3 - large
}

func _init():
	source_type = SourceType.DECREASES_AQI
	range_type = RangeType.INVERSE
	effective_range = 5000.0

func _ready():
	# Apply tree type multiplier
	base_effect = 2.5 * TREE_MULTIPLIERS.get(tree_type, 1.0)
	super._ready()
