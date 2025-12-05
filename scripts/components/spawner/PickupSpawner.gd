extends Node
"""
PickupSpawner Component

Handles ONLY pickup spawning:
- Pickup object pooling
- Pickup spawn execution
- Lane adjustment for obstacles
- Pool recycling

This component is extracted from Spawner.gd to isolate pickup spawning.
"""

# Preloaded scene
var mask_scene = preload("res://scenes/Mask.tscn")

# Object pool
var pickup_pool = []
var pool_size = 6
var spawn_speed = 400.0

# Lane positions for adjustment
var lane_positions = [240, 300, 360]

# Reference to coordinator (for collision checking)
var coordinator_ref: Node = null

func _ready():
	# Pre-instantiate pickup pool
	for i in range(pool_size):
		var pickup = mask_scene.instantiate()
		pickup.visible = false
		pickup.monitoring = false  # BUGFIX: Disable collision detection in pool
		add_child(pickup)
		pickup_pool.append(pickup)

	print("[PickupSpawner] Component initialized - Pool size: %d" % pool_size)

func setup(coordinator: Node) -> void:
	"""Setup reference to spawn coordinator"""
	coordinator_ref = coordinator
	print("[PickupSpawner] Setup complete - coordinator: %s" % (coordinator != null))

func spawn_pickup(x: float, y: float, pickup_type: String) -> bool:
	"""
	Attempt to spawn a pickup at given position.
	Tries alternative lanes if position blocked.
	Returns true if spawned, false if all lanes blocked.
	"""
	# Check with coordinator if position is blocked
	if coordinator_ref and coordinator_ref.is_blocked_by_obstacles(x, y):
		# Try alternative lanes
		for lane_y in lane_positions:
			if not coordinator_ref.is_blocked_by_obstacles(x, lane_y):
				print("[PickupSpawner] Adjusted to lane %.0f to avoid obstacle" % lane_y)
				return _spawn_at(x, lane_y, pickup_type)

		# All lanes blocked
		print("[PickupSpawner] BLOCKED spawn at (%.0f, %.0f) - all lanes blocked" % [x, y])
		return false

	# Position clear - spawn
	return _spawn_at(x, y, pickup_type)

func _spawn_at(x: float, y: float, pickup_type: String) -> bool:
	"""Internal: Spawn pickup at specific position"""
	# Get pooled pickup
	var pickup = get_pooled_pickup()
	if not pickup:
		push_warning("[PickupSpawner] No available pickups in pool!")
		return false

	# Configure and show pickup
	pickup.global_position = Vector2(x, y)
	pickup.pickup_type = pickup_type
	pickup.set_scroll_speed(spawn_speed)

	# BUGFIX: Re-enable collision detection when spawning
	pickup.monitoring = true

	pickup.visible = true

	# Notify coordinator of spawn
	if coordinator_ref:
		coordinator_ref.record_spawn(x, y, "pickup")

	return true

func get_pooled_pickup() -> Node:
	"""Get an available pickup from pool"""
	for pickup in pickup_pool:
		if is_instance_valid(pickup) and not pickup.visible:
			return pickup
	return null

func return_to_pool(pickup: Node) -> void:
	"""Return a pickup to the pool"""
	if pickup and is_instance_valid(pickup):
		pickup.visible = false
		pickup.global_position = Vector2(0, 0)

		# BUGFIX: Disable collision detection when returning to pool (deferred to avoid signal conflicts)
		pickup.set_deferred("monitoring", false)

		# BUGFIX: Reset pickup state to prevent stale references
		pickup.player_ref = null
		pickup.pickup_cooldown = 0.0

func set_scroll_speed(speed: float) -> void:
	"""Update scroll speed for all pickups"""
	spawn_speed = speed
	for pickup in pickup_pool:
		if is_instance_valid(pickup) and pickup.has_method("set_scroll_speed"):
			pickup.set_scroll_speed(speed)

func clear_all_pickups() -> void:
	"""Return all pickups to pool"""
	for pickup in pickup_pool:
		if pickup.visible:
			return_to_pool(pickup)

# === Public API for inspection ===

func get_visible_pickups() -> Array:
	"""Get all currently visible pickups"""
	var visible = []
	for pickup in pickup_pool:
		if is_instance_valid(pickup) and pickup.visible:
			visible.append(pickup)
	return visible

func get_pool_size() -> int:
	"""Get total pool size"""
	return pool_size

func get_available_count() -> int:
	"""Get number of available (invisible) pickups"""
	var count = 0
	for pickup in pickup_pool:
		if is_instance_valid(pickup) and not pickup.visible:
			count += 1
	return count
