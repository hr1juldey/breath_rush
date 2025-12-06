extends "res://scripts/components/parallax/ParallaxLayerSpawner.gd"
class_name MidLayerSpawner

## Spawns mid-ground buildings: restaurant, pharmacy, shops
## Medium size, medium speed (motion_scale 0.6)

func _ready():
	# Mid layer settings - buildings sit on horizon
	pool_size = 5
	spawn_interval_min = 3.0
	spawn_interval_max = 6.0
	y_variance = 3.0
	base_scale = 0.3
	scale_variance = 0.03
	despawn_x = -300.0
	spawn_x = 1400.0
	motion_scale = 0.6
	layer_y_offset = 0.0  # Fine-tuning offset for mid layer

	# Load textures with region and scale data from ParallaxScalingEditor
	texture_configs = [
		{
			"texture": preload("res://assets/parallax/restaurant.webp"),
			"region": Rect2(64, 200, 1744, 688),
			"scale": 0.2981
		},
		{
			"texture": preload("res://assets/parallax/pharmacy.webp"),
			"region": Rect2(552, 64, 816, 928),
			"scale": 0.2218
		},
		{
			"texture": preload("res://assets/parallax/shop.webp"),
			"region": Rect2(480, 96, 960, 888),
			"scale": 0.2454
		},
		{
			"texture": preload("res://assets/parallax/home_1.webp"),
			"region": null,
			"scale": 0.3  # Fallback scale
		},
		{
			"texture": preload("res://assets/parallax/building_generic.webp"),
			"region": Rect2(128, 360, 944, 592),
			"scale": 0.7500
		},
		{
			"texture": preload("res://assets/parallax/two_storey_building.webp"),
			"region": Rect2(520, 104, 796, 872),
			"scale": 0.4398
		},
	]

	super._ready()
