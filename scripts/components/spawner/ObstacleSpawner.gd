extends Node
"""
ObstacleSpawner Component

Handles ONLY obstacle spawning:
- Obstacle object pooling
- Obstacle spawn execution
- Obstacle visibility management
- Pool recycling

This component is extracted from Spawner.gd to isolate obstacle spawning.
"""

# Preloaded scene
var obstacle_scene = preload("res://scenes/Obstacle.tscn")

# Object pool
var obstacle_pool = []
var pool_size = 8
var spawn_speed = 400.0

# Reference to coordinator (for collision checking)
var coordinator_ref: Node = null

func _ready():
	# Pre-instantiate obstacle pool
	for i in range(pool_size):
		var obstacle = obstacle_scene.instantiate()
		obstacle.visible = false
		obstacle.monitoring = false  # BUGFIX: Disable collision detection
		obstacle.set_process(false)  # BUGFIX: Disable movement
		add_child(obstacle)
		obstacle_pool.append(obstacle)

	print("[ObstacleSpawner] Component initialized - Pool size: %d" % pool_size)

func setup(coordinator: Node) -> void:
	"""Setup reference to spawn coordinator"""
	coordinator_ref = coordinator
	print("[ObstacleSpawner] Setup complete - coordinator: %s" % (coordinator != null))

func spawn_obstacle(x: float, y: float, obstacle_type: String) -> bool:
	"""
	Attempt to spawn an obstacle at given position.
	Returns true if spawned, false if blocked or no pool available.
	"""
	# Check with coordinator if position is blocked
	if coordinator_ref and coordinator_ref.is_blocked_by_pickups(x, y):
		print("[ObstacleSpawner] BLOCKED spawn at (%.0f, %.0f) - too close to pickup" % [x, y])
		return false

	# Get pooled obstacle
	var obstacle = get_pooled_obstacle()
	if not obstacle:
		push_warning("[ObstacleSpawner] No available obstacles in pool!")
		return false

	# Configure and show obstacle
	obstacle.global_position = Vector2(x, y)
	obstacle.obstacle_type = obstacle_type
	obstacle.set_scroll_speed(spawn_speed)

	# BUGFIX: Re-enable collision and movement when spawning
	obstacle.monitoring = true
	obstacle.set_process(true)

	obstacle.visible = true

	# Notify coordinator of spawn
	if coordinator_ref:
		coordinator_ref.record_spawn(x, y, "obstacle")

	return true

func get_pooled_obstacle() -> Node:
	"""Get an available obstacle from pool"""
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and not obstacle.visible:
			return obstacle
	return null

func return_to_pool(obstacle: Node) -> void:
	"""Return an obstacle to the pool"""
	if obstacle and is_instance_valid(obstacle):
		obstacle.visible = false

		# BUGFIX: Disable collision and movement when returning to pool
		obstacle.monitoring = false
		obstacle.set_process(false)

func set_scroll_speed(speed: float) -> void:
	"""Update scroll speed for all obstacles"""
	spawn_speed = speed
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and obstacle.has_method("set_scroll_speed"):
			obstacle.set_scroll_speed(speed)

func clear_all_obstacles() -> void:
	"""Return all obstacles to pool"""
	for obstacle in obstacle_pool:
		if obstacle.visible:
			return_to_pool(obstacle)

# === Public API for inspection ===

func get_visible_obstacles() -> Array:
	"""Get all currently visible obstacles"""
	var visible = []
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and obstacle.visible:
			visible.append(obstacle)
	return visible

func get_pool_size() -> int:
	"""Get total pool size"""
	return pool_size

func get_available_count() -> int:
	"""Get number of available (invisible) obstacles"""
	var count = 0
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and not obstacle.visible:
			count += 1
	return count
