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

# Preloaded scenes - multiple car types
var car_scenes = [
	preload("res://scenes/ObstacleCar1.tscn"),  # Orange/red SUV
	preload("res://scenes/ObstacleCar2.tscn")   # Yellow sedan
]

# Object pool
var obstacle_pool = []
var pool_size = 20  # Increased pool for more cars
var spawn_speed = 400.0

# Reference to coordinator (for collision checking)
var coordinator_ref: Node = null

func _ready():
	# Pre-instantiate obstacle pool with balanced car type distribution
	for i in range(pool_size):
		# Alternate between car types to ensure variety
		var car_scene = car_scenes[i % car_scenes.size()]
		var obstacle = car_scene.instantiate()
		obstacle.visible = false
		obstacle.monitoring = false  # BUGFIX: Disable collision detection
		obstacle.set_process(false)  # BUGFIX: Disable movement
		add_child(obstacle)
		obstacle_pool.append(obstacle)

	print("[ObstacleSpawner] Component initialized - Pool size: %d (%d car types, balanced distribution)" % [pool_size, car_scenes.size()])

func setup(coordinator: Node) -> void:
	"""Setup reference to spawn coordinator"""
	coordinator_ref = coordinator
	print("[ObstacleSpawner] Setup complete - coordinator: %s" % (coordinator != null))

func spawn_obstacle(x: float, y: float, obstacle_type: String) -> bool:
	"""
	Attempt to spawn an obstacle at given position.
	Returns true if spawned, false if blocked or no pool available.
	"""
	# TRAFFIC JAM PREVENTION: Only allow 1 car on screen at a time
	# Check if any car is still on-screen (not past x = -200, well before stop point at -500)
	for obstacle in get_visible_obstacles():
		if obstacle.position.x > -200:  # Car still on-screen (allow new spawn when past -200)
			print("[ObstacleSpawner] BLOCKED spawn - car still on screen at x=%.0f" % obstacle.position.x)
			return false

	# Check with coordinator if position is blocked
	if coordinator_ref and coordinator_ref.is_blocked_by_pickups(x, y):
		print("[ObstacleSpawner] BLOCKED spawn at (%.0f, %.0f) - too close to pickup" % [x, y])
		return false

	# Get pooled obstacle of specific type
	var obstacle = get_pooled_obstacle_by_type(obstacle_type)
	if not obstacle:
		push_warning("[ObstacleSpawner] No available obstacles in pool for type: %s" % obstacle_type)
		return false

	# Configure and show obstacle
	obstacle.global_position = Vector2(x, y)
	obstacle.obstacle_type = obstacle_type
	obstacle.set_scroll_speed(spawn_speed)

	# Set spawner reference for proper pool return
	obstacle.spawner_ref = self

	# Reset despawn timer
	obstacle.off_screen_time = 0.0
	obstacle.is_off_screen = false

	# BUGFIX: Re-enable collision and movement when spawning
	obstacle.set_process(true)

	# Show car sprite and enable collision
	obstacle._show_car()

	# Restart smoke particles when respawning from pool
	_restart_smoke_particles(obstacle)

	# Attach CarAQISource if not already attached
	_attach_aqi_source(obstacle)

	obstacle.visible = true

	# Notify coordinator of spawn
	if coordinator_ref:
		coordinator_ref.record_spawn(x, y, "obstacle")

	print("[ObstacleSpawner] %s spawned at (%.0f, %.0f)" % [obstacle_type, x, y])
	return true

func get_pooled_obstacle_by_type(requested_type: String) -> Node:
	"""Get a specific car type from the pool"""
	# Determine which car scene to look for
	var target_scene_name = ""
	if requested_type == "car1":
		target_scene_name = "ObstacleCar1"
	elif requested_type == "car2":
		target_scene_name = "ObstacleCar2"
	else:
		# Default: return any available car (fallback for "car" type)
		return get_pooled_obstacle()

	# Find available obstacle of the requested type
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and not obstacle.visible:
			if obstacle.name == target_scene_name:
				return obstacle

	# Fallback: if specific type not available, return any available
	return get_pooled_obstacle()

func get_pooled_obstacle() -> Node:
	"""Get any available obstacle from pool"""
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and not obstacle.visible:
			return obstacle
	return null

func return_to_pool(obstacle: Node) -> void:
	"""Return an obstacle to the pool"""
	if obstacle and is_instance_valid(obstacle):
		# Stop smoke particles when returning to pool
		_stop_smoke_particles(obstacle)

		# Reset obstacle state
		# DON'T SET visible = false - testing visibility behavior!
		# obstacle.visible = false
		obstacle.player_ref = null  # Clear player reference
		obstacle.is_off_screen = false
		obstacle.off_screen_time = 0.0
		obstacle.collision_smoke_timer = 0.0
		obstacle.collision_smoke_active = false
		obstacle.stage_5s_done = false
		obstacle.stage_15s_done = false
		obstacle.stage_35s_done = false

		# BUGFIX: Disable collision and movement when returning to pool
		obstacle.monitoring = false
		obstacle.set_process(false)

		print("[ObstacleSpawner] Returned to pool (VISIBILITY STILL ON for testing)")

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

# === Smoke Particle Management ===

func _restart_smoke_particles(obstacle: Node) -> void:
	"""Restart smoke particles when spawning from pool"""
	var smoke_emitter = obstacle.get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")
	var smoke_gpu_trail = smoke_emitter.get_node_or_null("SmokeGPU_Trail")
	var smoke_cpu_trail = smoke_emitter.get_node_or_null("SmokeCPU_Trail")

	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device:
		# GPU mode - local coords + trail
		if smoke_gpu:
			smoke_gpu.amount_ratio = 1.0
			smoke_gpu.explosiveness = 0.3
			smoke_gpu.restart()
			smoke_gpu.emitting = true
		if smoke_gpu_trail:
			smoke_gpu_trail.amount_ratio = 1.0
			smoke_gpu_trail.restart()
			smoke_gpu_trail.emitting = true
		if smoke_cpu: smoke_cpu.emitting = false
		if smoke_cpu_trail: smoke_cpu_trail.emitting = false
	else:
		# CPU fallback
		if smoke_cpu:
			smoke_cpu.explosiveness = 0.3
			smoke_cpu.restart()
			smoke_cpu.emitting = true
		if smoke_cpu_trail:
			smoke_cpu_trail.restart()
			smoke_cpu_trail.emitting = true
		if smoke_gpu: smoke_gpu.emitting = false
		if smoke_gpu_trail: smoke_gpu_trail.emitting = false

func _stop_smoke_particles(obstacle: Node) -> void:
	"""Stop smoke emission when returning to pool"""
	var smoke_emitter = obstacle.get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")
	var smoke_gpu_trail = smoke_emitter.get_node_or_null("SmokeGPU_Trail")
	var smoke_cpu_trail = smoke_emitter.get_node_or_null("SmokeCPU_Trail")

	if smoke_gpu: smoke_gpu.emitting = false
	if smoke_gpu_trail: smoke_gpu_trail.emitting = false
	if smoke_cpu: smoke_cpu.emitting = false
	if smoke_cpu_trail: smoke_cpu_trail.emitting = false

# === AQI Source Management ===

func _attach_aqi_source(obstacle: Node) -> void:
	"""Attach CarAQISource to obstacle if not already present"""
	# Check if already has an AQI source
	if obstacle.get_child_count() > 0:
		for child in obstacle.get_children():
			if child is CarAQISource:
				return  # Already has AQI source

	# Create and attach new CarAQISource
	var car_aqi = CarAQISource.new()
	car_aqi.name = "CarAQISource"
	obstacle.add_child(car_aqi)
