extends Node
"""
SpawnCoordinator Component

Handles ONLY spatial coordination between obstacles and pickups:
- Spatial separation enforcement (250px horizontal, 80px vertical)
- Collision checking between obstacle and pickup pools
- Spawn position validation
- Spawn recording for debugging

This component FIXES the overlap bug by ensuring obstacles and pickups
never spawn within minimum separation distance.

This component is extracted from Spawner.gd to isolate coordination logic.
"""

# Minimum separation distances
const MIN_SEPARATION_HORIZONTAL = 250.0  # 250px horizontal separation
const MIN_SEPARATION_VERTICAL = 80.0     # 80px vertical separation (> 1 lane)

# References to spawner components
var obstacle_spawner: Node = null
var pickup_spawner: Node = null

func _ready():
	print("[SpawnCoordinator] Component initialized")
	print("[SpawnCoordinator] Min separation: H=%.0fpx, V=%.0fpx" %
		[MIN_SEPARATION_HORIZONTAL, MIN_SEPARATION_VERTICAL])

func setup(obstacles: Node, pickups: Node) -> void:
	"""Setup references to obstacle and pickup spawners"""
	obstacle_spawner = obstacles
	pickup_spawner = pickups
	print("[SpawnCoordinator] Setup complete - obstacles: %s, pickups: %s" %
		[obstacles != null, pickups != null])

func is_blocked_by_obstacles(pickup_x: float, pickup_y: float) -> bool:
	"""
	Check if pickup position is too close to any visible obstacle.
	Returns true if blocked, false if clear.
	"""
	if not obstacle_spawner:
		return false

	var obstacles = obstacle_spawner.get_visible_obstacles()
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			var obstacle_pos = obstacle.global_position
			var dx = abs(pickup_x - obstacle_pos.x)
			var dy = abs(pickup_y - obstacle_pos.y)

			# Check both horizontal and vertical separation
			if dx < MIN_SEPARATION_HORIZONTAL and dy < MIN_SEPARATION_VERTICAL:
				return true  # Too close!

	return false  # Clear

func is_blocked_by_pickups(obstacle_x: float, obstacle_y: float) -> bool:
	"""
	Check if obstacle position is too close to any visible pickup.
	Returns true if blocked, false if clear.
	"""
	if not pickup_spawner:
		return false

	var pickups = pickup_spawner.get_visible_pickups()
	for pickup in pickups:
		if is_instance_valid(pickup):
			var pickup_pos = pickup.global_position
			var dx = abs(obstacle_x - pickup_pos.x)
			var dy = abs(obstacle_y - pickup_pos.y)

			# Check both horizontal and vertical separation
			if dx < MIN_SEPARATION_HORIZONTAL and dy < MIN_SEPARATION_VERTICAL:
				return true  # Too close!

	return false  # Clear

func record_spawn(x: float, y: float, spawn_type: String) -> void:
	"""Record spawn for debugging/analytics"""
	# Optional: Could track spawn history for analysis
	pass

# === Public API for inspection ===

func get_min_separation_horizontal() -> float:
	"""Get minimum horizontal separation distance"""
	return MIN_SEPARATION_HORIZONTAL

func get_min_separation_vertical() -> float:
	"""Get minimum vertical separation distance"""
	return MIN_SEPARATION_VERTICAL
