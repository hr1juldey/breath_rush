extends Node
"""
ChunkManager Component

Handles ONLY chunk data management:
- Current chunk data storage
- Spawn point iteration (obstacles)
- Pickup spawn point iteration
- Chunk looping and reset
- Timing and delays

This component is extracted from Spawner.gd to isolate chunk management.
"""

# Chunk data
var current_chunk_data: Dictionary = {}

# Obstacle spawn tracking
var spawn_index = 0
var time_accumulated = 0.0

# Pickup spawn tracking
var pickup_spawn_index = 0
var pickup_time_accumulated = 0.0
var initial_pickups_spawned = false

# Game time tracking
var game_time = 0.0

# Pickup respawn system
var pickup_respawn_delay = 30.0  # Start respawning pickups after 30 seconds

# Player reference for mask condition
var player_ref: Node = null
var time_without_mask = 0.0
var mask_spawn_threshold = 5.0  # Only spawn masks if player hasn't worn mask for 5+ seconds

func _ready():
	print("[ChunkManager] Component initialized")

func setup(player: Node) -> void:
	"""Setup reference to player"""
	player_ref = player
	print("[ChunkManager] Setup complete - player: %s" % (player != null))

func _process(delta: float) -> void:
	"""Update timing and mask tracking"""
	time_accumulated += delta
	game_time += delta

	# Track time without mask for spawn condition
	if player_ref and player_ref.mask_component:
		var mask_time = player_ref.mask_component.get_mask_time()
		if mask_time <= 0:
			time_without_mask += delta
		else:
			time_without_mask = 0.0

func set_current_chunk(chunk_data: Dictionary) -> void:
	"""Set current chunk and reset spawn indices"""
	current_chunk_data = chunk_data
	spawn_index = 0
	time_accumulated = 0.0

	# Spawn initial pickups only once at game start
	if not initial_pickups_spawned:
		# ChunkManager doesn't spawn directly - just marks as ready
		initial_pickups_spawned = true

	print("[ChunkManager] Chunk loaded - obstacle points: %d, pickup points: %d" %
		[chunk_data.get("spawn_points", []).size(), chunk_data.get("pickup_points", []).size()])

func get_next_obstacle_spawn() -> Dictionary:
	"""
	Get next obstacle spawn point if ready.
	Returns empty dict if no spawn ready.
	"""
	if current_chunk_data.is_empty():
		return {}

	var spawn_points = current_chunk_data.get("spawn_points", [])

	# Check if we've spawned all points, then reset to loop
	if spawn_index >= spawn_points.size():
		# Reset all spawn points for next loop
		for spawn_point in spawn_points:
			spawn_point["spawned"] = false
		spawn_index = 0
		time_accumulated = 0.0

	# Check if next spawn is ready
	for spawn_point in spawn_points:
		var delay = spawn_point.get("delay", 0.0)
		if time_accumulated >= delay and not spawn_point.get("spawned", false):
			spawn_point["spawned"] = true
			spawn_index += 1
			return spawn_point

	return {}

func get_next_pickup_spawn() -> Dictionary:
	"""
	Get next pickup spawn point if ready (after initial delay).
	Returns empty dict if no spawn ready.
	"""
	# Only start pickup respawning after initial delay
	if game_time < pickup_respawn_delay:
		return {}

	if current_chunk_data.is_empty():
		return {}

	pickup_time_accumulated += get_process_delta_time()

	var pickup_points = current_chunk_data.get("pickup_points", [])

	# Check if we've spawned all pickup points, then reset to loop
	if pickup_spawn_index >= pickup_points.size():
		# Reset all pickup points for next loop
		for pickup_point in pickup_points:
			pickup_point["respawned"] = false
		pickup_spawn_index = 0
		pickup_time_accumulated = 0.0

	# Check if next pickup is ready
	for pickup_point in pickup_points:
		var delay = pickup_point.get("delay", 5.0)  # Default 5 second delay
		if pickup_time_accumulated >= delay and not pickup_point.get("respawned", false):
			var pickup_type = pickup_point.get("type", "mask")

			# Check spawn condition based on pickup type
			var should_spawn = false

			if pickup_type == "mask":
				# Only spawn mask if player hasn't worn mask for 5+ seconds
				if time_without_mask >= mask_spawn_threshold:
					# Higher probability (80%) to ensure masks spawn when needed
					if randf() < pickup_point.get("probability", 0.8):
						should_spawn = true
						var logger = get_node_or_null("/root/Logger")
						if logger:
							logger.info(2, "Mask spawned (time_without_mask: %.1fs)" % time_without_mask)
			else:
				# Spawn other pickups (filter, sapling) normally
				if randf() < pickup_point.get("probability", 0.3):
					should_spawn = true

			if should_spawn:
				pickup_point["respawned"] = true
				pickup_spawn_index += 1
				return pickup_point

	return {}

func get_initial_pickup_points() -> Array:
	"""Get pickup points for initial spawn (game start only)"""
	if current_chunk_data.is_empty():
		return []
	return current_chunk_data.get("pickup_points", [])

func clear_chunk() -> void:
	"""Clear current chunk data"""
	current_chunk_data = {}
	spawn_index = 0
	pickup_spawn_index = 0
	time_accumulated = 0.0
	pickup_time_accumulated = 0.0

# === Public API for inspection ===

func get_game_time() -> float:
	"""Get elapsed game time"""
	return game_time

func is_ready_for_pickup_respawn() -> bool:
	"""Check if pickup respawning has started"""
	return game_time >= pickup_respawn_delay

func get_time_without_mask() -> float:
	"""Get time player has been without mask"""
	return time_without_mask
