extends ParallaxLayerSpawner
class_name FarLayerSpawner

## Spawns distant landmarks: Laal Kila, Hauskhas, CP, etc.
## Only ONE monument visible per screen (realistic design)

func _ready():
	# Far layer settings - landmarks sit on horizon
	pool_size = 1  # Only 1 monument at a time
	spawn_interval_min = 8.0  # Long interval between monuments
	spawn_interval_max = 12.0
	y_position = 530.0  # Horizon line from SS/6.png
	y_variance = 5.0
	base_scale = 0.4
	scale_variance = 0.05
	despawn_x = -400.0
	spawn_x = 1300.0
	motion_scale = 0.3

	# Load textures from assets/parallax/
	textures = [
		preload("res://assets/parallax/Laal_kila.webp"),
		preload("res://assets/parallax/Hauskhas.webp"),
		preload("res://assets/parallax/CP.webp"),
		preload("res://assets/parallax/Lotus_park.webp"),
		preload("res://assets/parallax/Hanuman.webp"),
		preload("res://assets/parallax/Select_City_mall.webp"),
	]

	super._ready()
