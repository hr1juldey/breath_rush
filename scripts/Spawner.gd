extends Node2D

var obstacle_scene = preload("res://scenes/Obstacle.tscn")
var mask_scene = preload("res://scenes/Mask.tscn")
var purifier_scene = preload("res://scenes/Purifier.tscn")
var sapling_scene = preload("res://scenes/Sapling.tscn")

var obstacle_pool = []
var pickup_pool = []
var pool_size_obstacles = 8
var pool_size_pickups = 6
var spawn_speed = 400.0

var current_chunk_data = null
var spawn_index = 0
var time_accumulated = 0.0

# Pickup respawn system
var pickup_spawn_index = 0
var pickup_time_accumulated = 0.0
var initial_pickups_spawned = false
var game_time = 0.0
var pickup_respawn_delay = 30.0  # Start respawning pickups after 30 seconds

# Player reference for mask spawn condition
var player_ref = null
var time_without_mask = 0.0
var mask_spawn_threshold = 5.0  # Only spawn masks if player hasn't worn mask for 5+ seconds

func _ready():
	# Pre-instantiate obstacle pool
	for i in range(pool_size_obstacles):
		var obstacle = obstacle_scene.instantiate()
		obstacle.visible = false
		add_child(obstacle)
		obstacle_pool.append(obstacle)

	# Pre-instantiate pickup pool
	for i in range(pool_size_pickups):
		var pickup = mask_scene.instantiate()  # Default to mask
		pickup.visible = false
		add_child(pickup)
		pickup_pool.append(pickup)

	# Find player reference
	call_deferred("_find_player")

func _process(delta):
	time_accumulated += delta
	game_time += delta

	# Track time without mask for spawn condition
	if player_ref:
		if player_ref.mask_time <= 0:
			time_without_mask += delta
		else:
			time_without_mask = 0.0

	if current_chunk_data:
		process_spawns()

		# Only start pickup respawning after initial delay
		if game_time >= pickup_respawn_delay:
			process_pickup_spawns(delta)

func process_spawns() -> void:
	if not current_chunk_data:
		return

	var spawn_points = current_chunk_data.get("spawn_points", [])

	# Check if we've spawned all points, then reset to loop the chunk
	if spawn_index >= spawn_points.size():
		# Reset all spawn points for next loop
		for spawn_point in spawn_points:
			spawn_point["spawned"] = false
		spawn_index = 0
		time_accumulated = 0.0

	for spawn_point in spawn_points:
		var delay = spawn_point.get("delay", 0.0)
		if time_accumulated >= delay and not spawn_point.get("spawned", false):
			spawn_obstacle(spawn_point)
			spawn_point["spawned"] = true
			spawn_index += 1

func spawn_obstacle(spawn_data: Dictionary) -> void:
	var obstacle = get_pooled_obstacle()
	if obstacle:
		var spawn_x = spawn_data.get("x", 960)
		var spawn_y = spawn_data.get("y", 300)
		var obstacle_type = spawn_data.get("type", "car")

		obstacle.global_position = Vector2(spawn_x, spawn_y)
		obstacle.obstacle_type = obstacle_type
		obstacle.visible = true

func spawn_pickup(pickup_data: Dictionary) -> void:
	var pickup = get_pooled_pickup()
	if pickup:
		var spawn_x = pickup_data.get("x", 960)
		var spawn_y = pickup_data.get("y", 300)
		var pickup_type = pickup_data.get("type", "mask")

		pickup.global_position = Vector2(spawn_x, spawn_y)
		pickup.pickup_type = pickup_type
		pickup.visible = true

func get_pooled_obstacle() -> Node:
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and not obstacle.visible:
			return obstacle
	return null

func get_pooled_pickup() -> Node:
	for pickup in pickup_pool:
		if is_instance_valid(pickup) and not pickup.visible:
			return pickup
	return null

func return_to_pool(node: Node, is_obstacle: bool = true) -> void:
	node.visible = false
	if not is_obstacle and node in pickup_pool:
		node.global_position = Vector2(0, 0)

func set_current_chunk(chunk_data: Dictionary) -> void:
	current_chunk_data = chunk_data
	spawn_index = 0
	time_accumulated = 0.0

	# Spawn initial pickups only once at game start
	if not initial_pickups_spawned:
		var pickup_points = chunk_data.get("pickup_points", [])
		var mask_spawned = false

		for pickup_point in pickup_points:
			var pickup_type = pickup_point.get("type", "mask")

			if pickup_type == "mask":
				# For initial game start, guarantee at least one mask spawns
				if not mask_spawned:
					# First mask always spawns
					spawn_pickup(pickup_point)
					mask_spawned = true
				else:
					# Additional masks use probability
					if randf() < pickup_point.get("probability", 0.5):
						spawn_pickup(pickup_point)
			else:
				# Other pickups use normal probability
				if randf() < pickup_point.get("probability", 0.5):
					spawn_pickup(pickup_point)

		initial_pickups_spawned = true

func clear_spawned_objects() -> void:
	for obstacle in obstacle_pool:
		if obstacle.visible:
			return_to_pool(obstacle, true)

	for pickup in pickup_pool:
		if pickup.visible:
			return_to_pool(pickup, false)

func _find_player() -> void:
	var parent = get_parent()
	if parent:
		player_ref = parent.find_child("Player")

func process_pickup_spawns(delta: float) -> void:
	if not current_chunk_data:
		return

	pickup_time_accumulated += delta

	var pickup_points = current_chunk_data.get("pickup_points", [])

	# Check if we've spawned all pickup points, then reset to loop
	if pickup_spawn_index >= pickup_points.size():
		# Reset all pickup points for next loop
		for pickup_point in pickup_points:
			pickup_point["respawned"] = false
		pickup_spawn_index = 0
		pickup_time_accumulated = 0.0

	for pickup_point in pickup_points:
		var delay = pickup_point.get("delay", 5.0)  # Default 5 second delay between pickups
		if pickup_time_accumulated >= delay and not pickup_point.get("respawned", false):
			# Check spawn condition based on pickup type
			var pickup_type = pickup_point.get("type", "mask")

			if pickup_type == "mask":
				# Only spawn mask if player hasn't worn mask for 5+ seconds
				if time_without_mask >= mask_spawn_threshold:
					if randf() < pickup_point.get("probability", 0.4):
						spawn_pickup(pickup_point)
			else:
				# Spawn other pickups (filter, sapling) normally
				if randf() < pickup_point.get("probability", 0.3):
					spawn_pickup(pickup_point)

			pickup_point["respawned"] = true
			pickup_spawn_index += 1
