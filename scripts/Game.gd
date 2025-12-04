extends Node2D

@onready var road = $Road
@onready var parallax_bg = $ParallaxBG
@onready var sky_manager = $ParallaxBG/SkyLayer
@onready var world = $World
@onready var player = $Player
@onready var spawner = $Spawner
@onready var hud = $HUD
@onready var delivery_zones_node = $DeliveryZones

var persistence_manager: Node
var current_chunk_index = 0
var map_seed = 42
var current_aqi = 250.0
var base_aqi = 250.0

var chunks_data = []
var run_distance = 0.0
var run_coins = 0.0

var gameplay_config = {}
var brand_config = {}

var scroll_speed = 400.0

func _ready():
	# Load configurations
	load_configs()

	# Initialize player reference
	if player:
		player.set_aqi(current_aqi)

	# Initialize first chunk
	load_chunk_data()
	if chunks_data.size() > 0:
		spawn_chunk(current_chunk_index)

	# Connect delivery zone signals
	connect_delivery_zones()

func _process(delta):
	# Update run distance
	run_distance += scroll_speed * delta

	# Update AQI (simplified - in full game would be more complex)
	update_aqi(delta)

	# Update player AQI awareness
	if player:
		player.set_aqi(current_aqi)

	# Update coin accumulation
	update_coins(delta)

	# Check if we need to advance chunk
	check_chunk_transition()

func load_configs() -> void:
	# Load gameplay config
	if ResourceLoader.exists("res://config/gameplay.json"):
		var gameplay_file = FileAccess.open("res://config/gameplay.json", FileAccess.READ)
		if gameplay_file:
			var json = JSON.new()
			json.parse(gameplay_file.get_as_text())
			gameplay_config = json.data

	# Load brand config
	if ResourceLoader.exists("res://config/brand.json"):
		var brand_file = FileAccess.open("res://config/brand.json", FileAccess.READ)
		if brand_file:
			var json = JSON.new()
			json.parse(brand_file.get_as_text())
			brand_config = json.data

	# Apply settings from config
	if gameplay_config:
		scroll_speed = gameplay_config.get("world", {}).get("scroll_speed", 400)
		base_aqi = gameplay_config.get("aqi", {}).get("base_bad", 250)
		current_aqi = base_aqi

func load_chunk_data() -> void:
	# In a full implementation, this would load multiple chunks
	# For now, we load the sample chunk
	if ResourceLoader.exists("res://data/chunks/chunk_001.json"):
		var chunk_file = FileAccess.open("res://data/chunks/chunk_001.json", FileAccess.READ)
		if chunk_file:
			var json = JSON.new()
			json.parse(chunk_file.get_as_text())
			chunks_data.append(json.data)

func spawn_chunk(chunk_index: int) -> void:
	if chunk_index >= chunks_data.size():
		return

	var chunk = chunks_data[chunk_index]
	current_chunk_index = chunk_index

	# Set sky type (non-blocking call, let it animate in background)
	if sky_manager:
		var sky_type = chunk.get("sky_type", "bad")
		sky_manager.set_sky_type(sky_type)  # Don't await - allow animation to happen async

	# Update base AQI for this chunk
	base_aqi = chunk.get("base_aqi", 250)
	current_aqi = base_aqi

	# Pass chunk to spawner
	if spawner:
		spawner.set_current_chunk(chunk)

	# Create delivery zones from chunk data
	create_delivery_zones_from_chunk(chunk)

func create_delivery_zones_from_chunk(chunk: Dictionary) -> void:
	# Clear existing delivery zones
	for child in delivery_zones_node.get_children():
		child.queue_free()

	# Create new ones from chunk data
	var delivery_zones = chunk.get("delivery_zones", [])
	for zone_data in delivery_zones:
		var zone = Area2D.new()
		zone.position = Vector2(zone_data.get("x", 0), zone_data.get("y", 300))

		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = zone_data.get("radius", 80)
		collision.shape = shape

		zone.add_child(collision)
		delivery_zones_node.add_child(zone)

		# Add DeliveryZone script
		var script = load("res://scripts/DeliveryZone.gd")
		if script:
			zone.set_script(script)
			zone.reward_coins = zone_data.get("reward_coins", 50)

func connect_delivery_zones() -> void:
	for zone in delivery_zones_node.get_children():
		if zone.has_signal("delivery_successful"):
			zone.delivery_successful.connect(_on_delivery_successful)

func _on_delivery_successful(coins: int, _position: Vector2) -> void:
	run_coins += coins
	if hud:
		hud.add_coins(coins)

func update_aqi(_delta: float) -> void:
	# Simplified AQI update - in full game would account for trees, filters, etc.
	pass

func update_coins(delta: float) -> void:
	# Calculate coin gain based on distance and AQI
	if gameplay_config:
		var coin_config = gameplay_config.get("coins", {})
		var base_rate = coin_config.get("base_rate", 0.02)
		var aqi_factor = (base_aqi - current_aqi) / max(base_aqi, 1.0)
		var coins_per_second = base_rate * aqi_factor * scroll_speed / 100.0

		run_coins += coins_per_second * delta
		if hud:
			hud.add_coins(int(run_coins) - int(run_coins - coins_per_second * delta))

func check_chunk_transition() -> void:
	# Simplified chunk transition - in full game would check world position
	pass

func load_persisted_trees() -> void:
	# Load trees from persistence and create them in the world
	# TODO: Implement persistence system
	if persistence_manager == null:
		return
	# var trees = persistence_manager.get_trees()
	# for tree_data in trees:
	#	create_tree_visual(tree_data)

func create_tree_visual(tree_data: Dictionary) -> void:
	# Create a visual representation of a tree
	# In full game, this would be a proper sprite/scene
	var tree = Node2D.new()
	tree.position.x = tree_data.get("x", 0)
	tree.name = tree_data.get("id", "tree_0")

	world.find_child("Trees").add_child(tree)

func end_run() -> void:
	# Save run data
	# TODO: Implement persistence system
	if persistence_manager == null:
		return
	# persistence_manager.update_coins(int(run_coins))

	# Return to menu or show summary
	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			end_run()
