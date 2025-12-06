extends "res://scripts/components/parallax/ParallaxLayerSpawner.gd"
class_name FarLayerSpawner

## Spawns distant landmarks: Laal Kila, Hauskhas, CP, etc.
## Only ONE monument visible per screen (realistic design)

func _ready():
	# Far layer settings - landmarks sit on horizon
	pool_size = 1  # Only 1 monument at a time
	spawn_interval_min = 8.0  # Long interval between monuments
	spawn_interval_max = 12.0
	y_variance = 5.0
	base_scale = 0.35
	scale_variance = 0.05
	despawn_x = -400.0
	spawn_x = 1400.0
	motion_scale = 0.3
	layer_y_offset = 0.0  # Fine-tuning offset for far layer

	# Load textures with region and scale data from ParallaxScalingEditor
	texture_configs = [
		{
			"texture": preload("res://assets/parallax/Laal_kila.webp"),
			"region": Rect2(0, 256, 1920, 592),
			"scale": 1.5866
		},
		{
			"texture": preload("res://assets/parallax/Hauskhas.webp"),
			"region": Rect2(0, 56, 1920, 968),
			"scale": 0.7403
		},
		{
			"texture": preload("res://assets/parallax/CP.webp"),
			"region": null,
			"scale": 0.5  # Fallback scale
		},
		{
			"texture": preload("res://assets/parallax/Lotus_park.webp"),
			"region": Rect2(128, 216, 1608, 584),
			"scale": 1.729
		},
		{
			"texture": preload("res://assets/parallax/Hanuman.webp"),
			"region": Rect2(608, 48, 696, 1000),
			"scale": 0.4030
		},
		{
			"texture": preload("res://assets/parallax/Select_City_mall.webp"),
			"region": null,
			"scale": 0.5  # Fallback scale
		},
	]

	super._ready()
