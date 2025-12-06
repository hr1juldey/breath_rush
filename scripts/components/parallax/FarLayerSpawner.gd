extends "res://scripts/components/parallax/ParallaxLayerSpawner.gd"
class_name FarLayerSpawner

## Spawns distant landmarks: Laal Kila, Hauskhas, CP, etc.
## Only ONE monument visible per screen (realistic design)

func _ready():
	# Far layer settings - landmarks sit on horizon
	pool_size = 1 # Only 1 monument at a time
	spawn_interval_min = 5.0 # Long interval between monuments
	spawn_interval_max = 12.0
	y_variance = 1.0
	base_scale = 0.35
	scale_variance = 0.05
	despawn_x = -1000.0 # Well off-screen left (account for large monument width)
	spawn_x = 3000.0 # Well off-screen right (account for large monument width)
	motion_scale = 0.2
	layer_y_offset = 120.0 # Far layer too high - move down more

	# Load textures with region and scale data from ParallaxScalingEditor
	texture_configs = [
		{
			"texture": preload("res://assets/parallax/Laal_kila.webp"),
			"region": Rect2(0, 256, 1920, 592),
			"scale": .9,
			"y_offset": 90.0 # Large monument - too big, getting cut off, move down more
		},
		{
			"texture": preload("res://assets/parallax/Hauskhas.webp"),
			"region": Rect2(0, 56, 1920, 968),
			"scale": 0.60,
			"y_offset": 10.0
		},
		{
			"texture": preload("res://assets/parallax/CP.webp"),
			"region": null,
			"scale": 0.46,
			"y_offset": - 70.0
		},
		{
			"texture": preload("res://assets/parallax/Lotus_park.webp"),
			"region": Rect2(128, 216, 1608, 584),
			"scale": .95,
			"y_offset": 120.0 # Lotus park at good level but getting cut off - move down
		},
		{
			"texture": preload("res://assets/parallax/Hanuman.webp"),
			"region": Rect2(608, 48, 696, 1000),
			"scale": 0.412,
			"y_offset": - 146.0 # Floating ~12px - move down
		},
		{
			"texture": preload("res://assets/parallax/Select_City_mall.webp"),
			"region": null,
			"scale": 0.5,
			"y_offset": 0.0
		},
	]

	super._ready()
