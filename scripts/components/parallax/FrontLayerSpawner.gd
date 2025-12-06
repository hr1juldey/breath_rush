extends "res://scripts/components/parallax/ParallaxLayerSpawner.gd"
class_name FrontLayerSpawner

## Spawns foreground elements: trees, fruit stalls
## Largest scale, fastest movement (motion_scale 0.9)

func _ready():
	# Front layer settings - trees/decorations sit on horizon
	pool_size = 6
	spawn_interval_min = 2.5
	spawn_interval_max = 5.0
	y_variance = 5.0
	base_scale = 0.25
	scale_variance = 0.03
	despawn_x = -250.0
	spawn_x = 1400.0
	motion_scale = 0.9
	layer_y_offset = 0.0  # Fine-tuning offset for front layer

	# Load textures with region and scale data from ParallaxScalingEditor
	texture_configs = [
		{
			"texture": preload("res://assets/parallax/tree_1.webp"),
			"region": Rect2(224, 80, 744, 1008),
			"scale": 0.1889
		},
		{
			"texture": preload("res://assets/parallax/tree_2.webp"),
			"region": Rect2(232, 144, 712, 888),
			"scale": 0.2483
		},
		{
			"texture": preload("res://assets/parallax/tree_3.webp"),
			"region": Rect2(0, 0, 1200, 1077),
			"scale": 0.3428
		},
		{
			"texture": preload("res://assets/parallax/fruit_stall.webp"),
			"region": Rect2(0, 40, 1200, 1120),
			"scale": 0.1133
		},
		{
			"texture": preload("res://assets/parallax/billboard.webp"),
			"region": Rect2(240, 112, 712, 960),
			"scale": 0.0888
		},
	]

	super._ready()
