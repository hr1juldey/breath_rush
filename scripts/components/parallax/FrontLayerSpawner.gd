extends ParallaxLayerSpawner
class_name FrontLayerSpawner

## Spawns foreground elements: trees, fruit stalls
## Largest scale, fastest movement (motion_scale 0.9)

func _ready():
	# Front layer settings - trees/decorations sit on horizon
	pool_size = 6
	spawn_interval_min = 2.5
	spawn_interval_max = 5.0
	y_position = 530.0  # Horizon line
	y_variance = 5.0
	base_scale = 0.25
	scale_variance = 0.05
	despawn_x = -250.0
	spawn_x = 1200.0
	motion_scale = 0.9

	# Load textures from assets/parallax/
	textures = [
		preload("res://assets/parallax/tree_1.webp"),
		preload("res://assets/parallax/tree_2.webp"),
		preload("res://assets/parallax/tree_3.webp"),
		preload("res://assets/parallax/fruit_stall.webp"),
		preload("res://assets/parallax/billboard.webp"),
	]

	super._ready()
