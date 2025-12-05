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

# Track recent spawns to avoid overlaps
var recent_spawns = {}  # Dictionary: {x_y: time}
var spawn_clearance_time = 2.0  # Seconds to keep spawn positions reserved

# Minimum separation distances
const MIN_SEPARATION_HORIZONTAL = 250.0  # Minimum X distance between cars and masks
const MIN_SEPARATION_VERTICAL = 80.0     # Minimum Y distance (more than 1 lane)

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

	# Clean old spawn records periodically
	if int(game_time) % 5 == 0:  # Every 5 seconds
		clean_old_spawn_records()

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

		# Check if any visible pickup is too close
		if is_too_close_to_pickups(spawn_x, spawn_y):
			print("[Spawner] BLOCKED obstacle spawn at (%.0f, %.0f) - too close to pickup" % [spawn_x, spawn_y])
			return  # Don't spawn obstacle - too close to pickup

		obstacle.global_position = Vector2(spawn_x, spawn_y)
		obstacle.obstacle_type = obstacle_type
		obstacle.visible = true

		# Record spawn position to avoid overlaps
		record_spawn_position(spawn_x, spawn_y)

func spawn_pickup(pickup_data: Dictionary) -> void:
	var pickup = get_pooled_pickup()
	if pickup:
		var spawn_x = pickup_data.get("x", 960)
		var spawn_y = pickup_data.get("y", 300)
		var pickup_type = pickup_data.get("type", "mask")

		# Check if any visible obstacle is too close
		if is_too_close_to_obstacles(spawn_x, spawn_y):
			# Try alternative lanes before giving up
			var lanes = [240, 300, 360]
			var found_safe_lane = false
			for lane_y in lanes:
				if not is_too_close_to_obstacles(spawn_x, lane_y):
					spawn_y = lane_y
					found_safe_lane = true
					print("[Spawner] Adjusted pickup to lane %.0f to avoid obstacle" % lane_y)
					break

			if not found_safe_lane:
				print("[Spawner] BLOCKED pickup spawn at (%.0f, %.0f) - all lanes too close to obstacles" % [spawn_x, spawn_y])
				return  # Don't spawn pickup - all lanes are blocked

		pickup.global_position = Vector2(spawn_x, spawn_y)
		pickup.pickup_type = pickup_type
		pickup.visible = true

		# Record spawn position to avoid overlaps
		record_spawn_position(spawn_x, spawn_y)

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
					# Higher probability (80%) to ensure masks spawn when needed
					if randf() < pickup_point.get("probability", 0.8):
						spawn_pickup(pickup_point)
						var logger = get_node_or_null("/root/Logger")
						if logger:
							logger.info(2, "Mask spawned (time_without_mask: %.1fs)" % time_without_mask)
			else:
				# Spawn other pickups (filter, sapling) normally
				if randf() < pickup_point.get("probability", 0.3):
					spawn_pickup(pickup_point)

			pickup_point["respawned"] = true
			pickup_spawn_index += 1

func is_position_occupied(x: float, y: float) -> bool:
	# Check if position is too close to any recent spawns
	var key = "%d_%d" % [int(x / 100), int(y / 60)]  # Grid-based checking
	if recent_spawns.has(key):
		var spawn_time = recent_spawns[key]
		if game_time - spawn_time < spawn_clearance_time:
			return true
	return false

func record_spawn_position(x: float, y: float) -> void:
	# Record this spawn position with timestamp
	var key = "%d_%d" % [int(x / 100), int(y / 60)]
	recent_spawns[key] = game_time

func clean_old_spawn_records() -> void:
	# Remove old spawn records to prevent memory growth
	var keys_to_remove = []
	for key in recent_spawns:
		if game_time - recent_spawns[key] > spawn_clearance_time:
			keys_to_remove.append(key)
	for key in keys_to_remove:
		recent_spawns.erase(key)

func is_too_close_to_obstacles(pickup_x: float, pickup_y: float) -> bool:
	"""Check if pickup position is too close to any visible obstacle"""
	for obstacle in obstacle_pool:
		if obstacle.visible:
			var obstacle_pos = obstacle.global_position
			var dx = abs(pickup_x - obstacle_pos.x)
			var dy = abs(pickup_y - obstacle_pos.y)

			# Check both horizontal and vertical separation
			if dx < MIN_SEPARATION_HORIZONTAL and dy < MIN_SEPARATION_VERTICAL:
				return true  # Too close!
	return false

func is_too_close_to_pickups(obstacle_x: float, obstacle_y: float) -> bool:
	"""Check if obstacle position is too close to any visible pickup"""
	for pickup in pickup_pool:
		if pickup.visible:
			var pickup_pos = pickup.global_position
			var dx = abs(obstacle_x - pickup_pos.x)
			var dy = abs(pickup_y - pickup_pos.y)

			# Check both horizontal and vertical separation
			if dx < MIN_SEPARATION_HORIZONTAL and dy < MIN_SEPARATION_VERTICAL:
				return true  # Too close!
	return false
