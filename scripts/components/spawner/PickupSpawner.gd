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

# Preloaded scenes
var mask_scene = preload("res://scenes/Mask.tscn")
var ev_charger_scene = preload("res://scenes/EVCharger.tscn")

# Object pool
var pickup_pool = []
var pool_size = 6
var spawn_speed = 400.0

# EV Charger tracking
var ev_charger_active: Node = null
var battery_low_threshold = 25.0
var player_ref: Node = null

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

func set_player_reference(player: Node) -> void:
	"""Set player reference for battery checking"""
	player_ref = player

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

# === EV Charger Logic ===

func should_spawn_ev_charger() -> bool:
	"""Check if EV charger should spawn (low battery + no active charger)"""
	if ev_charger_active and is_instance_valid(ev_charger_active):
		return false  # Already has active charger

	if not player_ref:
		return false  # No player reference

	var battery_component = player_ref.get_node_or_null("PlayerBattery")
	if not battery_component:
		return false

	return battery_component.battery <= battery_low_threshold

func spawn_ev_charger(x: float, y: float = 300.0) -> void:
	"""Spawn EV charger at position (middle lane by default)"""
	if ev_charger_active and is_instance_valid(ev_charger_active):
		return  # Already spawned

	var charger = ev_charger_scene.instantiate()
	charger.global_position = Vector2(x, y)
	charger.set_scroll_speed(spawn_speed)

	# Connect signals to pause world
	charger.charging_started.connect(_on_charger_start)
	charger.charging_complete.connect(_on_charger_complete)

	add_child(charger)
	ev_charger_active = charger

	print("[PickupSpawner] EV Charger spawned at (%.0f, %.0f)" % [x, y])

func _on_charger_start():
	"""EV charger started - notify game to pause world"""
	if coordinator_ref and coordinator_ref.get_parent().has_method("pause_world_scroll"):
		coordinator_ref.get_parent().pause_world_scroll()

func _on_charger_complete():
	"""EV charger complete - notify game to resume world"""
	if coordinator_ref and coordinator_ref.get_parent().has_method("resume_world_scroll"):
		coordinator_ref.get_parent().resume_world_scroll()

	ev_charger_active = null
