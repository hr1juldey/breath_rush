extends Node2D
"""
Spawner Coordinator

This is the main spawner script that coordinates all spawning components.
It delegates functionality to specialized components:

Components:
- ObstacleSpawner: Obstacle pooling and spawning
- PickupSpawner: Pickup pooling and spawning
- SpawnCoordinator: Spatial separation enforcement (FIXES OVERLAP BUG)
- ChunkManager: Chunk data and spawn timing

Before refactoring: 295 lines with 9 responsibilities
After refactoring: ~100 lines coordination only
"""

# Component references (loaded from scene tree)
@onready var obstacle_spawner = $ObstacleSpawner
@onready var pickup_spawner = $PickupSpawner
@onready var spawn_coordinator = $SpawnCoordinator
@onready var chunk_manager = $ChunkManager

# Player reference (for mask condition tracking)
var player_ref: Node = null

func _ready():
	print("[Spawner] ========== Spawner Coordinator Initializing ==========")

	# Setup spawn coordinator with spawner references
	if spawn_coordinator and obstacle_spawner and pickup_spawner:
		spawn_coordinator.setup(obstacle_spawner, pickup_spawner)
		print("[Spawner] ✓ SpawnCoordinator ready")

	# Setup obstacle spawner with coordinator reference
	if obstacle_spawner and spawn_coordinator:
		obstacle_spawner.setup(spawn_coordinator)
		print("[Spawner] ✓ ObstacleSpawner ready")

	# Setup pickup spawner with coordinator reference
	if pickup_spawner and spawn_coordinator:
		pickup_spawner.setup(spawn_coordinator)
		print("[Spawner] ✓ PickupSpawner ready")

	# Find player reference
	call_deferred("_find_player")

	print("[Spawner] ========== All Components Initialized ==========")

func _find_player() -> void:
	"""Find player reference for chunk manager and pickup spawner"""
	var parent = get_parent()
	if parent:
		player_ref = parent.find_child("Player")
		if player_ref and chunk_manager:
			chunk_manager.setup(player_ref)
			print("[Spawner] ✓ ChunkManager ready with player reference")
		if player_ref and pickup_spawner:
			pickup_spawner.set_player_reference(player_ref)
			print("[Spawner] ✓ PickupSpawner has player reference for EV charger")

func _process(_delta: float) -> void:
	"""Coordinate all spawning components"""
	if not chunk_manager:
		return

	# Check if EV charger should spawn (low battery)
	if pickup_spawner and pickup_spawner.should_spawn_ev_charger():
		pickup_spawner.spawn_ev_charger()  # EVCharger uses front layer positioning

	# Get next obstacle spawn from chunk manager
	var obstacle_spawn = chunk_manager.get_next_obstacle_spawn()
	if not obstacle_spawn.is_empty():
		var x = obstacle_spawn.get("x", 960)
		var y = obstacle_spawn.get("y", 300)
		var type = obstacle_spawn.get("type", "car")

		if obstacle_spawner:
			obstacle_spawner.spawn_obstacle(x, y, type)

	# Get next pickup spawn from chunk manager (exclude EV charger from random spawning)
	var pickup_spawn = chunk_manager.get_next_pickup_spawn()
	if not pickup_spawn.is_empty():
		var x = pickup_spawn.get("x", 960)
		var y = pickup_spawn.get("y", 300)
		var type = pickup_spawn.get("type", "mask")

		# Only spawn masks, not chargers
		if pickup_spawner and type == "mask":
			pickup_spawner.spawn_pickup(x, y, type)

# === Public API (Delegate to components) ===

func set_current_chunk(chunk_data: Dictionary) -> void:
	"""Set current chunk data"""
	if chunk_manager:
		chunk_manager.set_current_chunk(chunk_data)

		# Handle initial pickup spawning
		var pickup_points = chunk_manager.get_initial_pickup_points()
		var mask_spawned = false

		for pickup_point in pickup_points:
			var pickup_type = pickup_point.get("type", "mask")
			var x = pickup_point.get("x", 960)
			var y = pickup_point.get("y", 300)

			if pickup_type == "mask":
				# For initial game start, guarantee at least one mask spawns
				if not mask_spawned:
					if pickup_spawner:
						pickup_spawner.spawn_pickup(x, y, pickup_type)
					mask_spawned = true
				else:
					# Additional masks use probability
					if randf() < pickup_point.get("probability", 0.5):
						if pickup_spawner:
							pickup_spawner.spawn_pickup(x, y, pickup_type)
			else:
				# Other pickups use normal probability
				if randf() < pickup_point.get("probability", 0.5):
					if pickup_spawner:
						pickup_spawner.spawn_pickup(x, y, pickup_type)

func return_to_pool(node: Node, is_obstacle: bool = true) -> void:
	"""Return a spawned object to its pool"""
	if is_obstacle and obstacle_spawner:
		obstacle_spawner.return_to_pool(node)
	elif not is_obstacle and pickup_spawner:
		pickup_spawner.return_to_pool(node)

func clear_spawned_objects() -> void:
	"""Clear all spawned objects"""
	if obstacle_spawner:
		obstacle_spawner.clear_all_obstacles()
	if pickup_spawner:
		pickup_spawner.clear_all_pickups()

func set_scroll_speed(speed: float) -> void:
	"""Update scroll speed for all spawned objects"""
	if obstacle_spawner:
		obstacle_spawner.set_scroll_speed(speed)
	if pickup_spawner:
		pickup_spawner.set_scroll_speed(speed)

# === Public API for Game.gd compatibility ===

# Expose pools for Game.gd boost speed updates
var obstacle_pool: Array:
	get:
		if obstacle_spawner:
			return obstacle_spawner.obstacle_pool
		return []

var pickup_pool: Array:
	get:
		if pickup_spawner:
			return pickup_spawner.pickup_pool
		return []
