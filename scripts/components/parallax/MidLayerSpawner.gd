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

	# Load textures from assets/parallax/
	textures = [
		preload("res://assets/parallax/restaurant.webp"),
		preload("res://assets/parallax/pharmacy.webp"),
		preload("res://assets/parallax/shop.webp"),
		preload("res://assets/parallax/home_1.webp"),
		preload("res://assets/parallax/building_generic.webp"),
		preload("res://assets/parallax/two_storey_building.webp"),
	]

	super._ready()
