extends Area2D

var obstacle_type = "car"  # "car", "bike", "pollution"
var scroll_speed = 400.0
var collision_damage = 12
var player_ref = null

var recycled = false

func _ready():
	if has_node("CollisionShape2D"):
		pass  # Collision shape will be set up in scene

	body_entered.connect(_on_body_entered)

	# Set z-index based on lane depth for realistic perspective
	# Player is at z-index 5
	# Lane-based depth: Higher Y = closer to camera = higher z-index
	call_deferred("_set_lane_based_z_index")

	# Setup smoke particles with GPU/CPU fallback
	_setup_smoke_particles()

func _process(delta):
	# Move obstacle left with scroll speed
	position.x -= scroll_speed * delta

	# Check if off-screen with extended buffer for smoke trails
	# Delay despawn to keep smoke visible longer
	if position.x < -1200 and visible:
		visible = false

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		if player_ref == null:
			player_ref = body
			inflict_damage()
			_emit_collision_smoke()

func inflict_damage() -> void:
	if player_ref:
		var damage = randi_range(8, 18)
		player_ref.take_damage(damage)

func set_type(type: String) -> void:
	obstacle_type = type

func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed

func _set_lane_based_z_index() -> void:
	"""Set z-index based on lane depth for realistic perspective"""
	# Find player to compare Y positions
	var game = get_tree().root.get_node_or_null("Main")
	if not game:
		z_index = 5  # Default to player level
		return

	var player = game.get_node_or_null("Player")
	if not player:
		z_index = 5
		return

	var player_y = player.global_position.y
	var car_y = global_position.y

	# Lane-based depth logic:
	# Higher Y = closer to camera = should render in FRONT
	# Player z-index = 5
	if car_y > player_y + 20:  # Car is closer to camera (lower lane)
		z_index = randi_range(6, 7)  # Car in front of player
		print("[Obstacle] Car in front (Y=%.0f > Player Y=%.0f) z=%d" % [car_y, player_y, z_index])
	elif car_y < player_y - 20:  # Car is farther from camera (upper lane)
		z_index = randi_range(0, 4)  # Car behind player
		print("[Obstacle] Car behind (Y=%.0f < Player Y=%.0f) z=%d" % [car_y, player_y, z_index])
	else:  # Same lane
		# When same lane, car should be behind player for better visibility
		z_index = 4
		print("[Obstacle] Car same lane (Y=%.0f ≈ Player Y=%.0f) z=%d (behind)" % [car_y, player_y, z_index])

func _setup_smoke_particles() -> void:
	"""Setup smoke particles with GPU/CPU fallback for browser compatibility"""
	var smoke_emitter = get_node_or_null("CollisionShape2D/SmokeEmitter")
	if not smoke_emitter:
		return  # No smoke emitter in this obstacle

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")

	if not smoke_gpu or not smoke_cpu:
		return  # Missing smoke nodes

	# Try GPU particles first
	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device:
		# GPU available - use GPUParticles2D
		smoke_gpu.emitting = true
		smoke_cpu.emitting = false
		print("[Obstacle] Using GPU particles for smoke")
	else:
		# GPU not available (browser/mobile) - fallback to CPU
		smoke_gpu.emitting = false
		smoke_cpu.emitting = true
		print("[Obstacle] GPU not available, using CPU particles for smoke")

func _emit_collision_smoke() -> void:
	"""Emit a LOT of smoke when car collides with player"""
	var smoke_emitter = get_node_or_null("CollisionShape2D/SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")

	if not smoke_gpu or not smoke_cpu:
		return

	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device and smoke_gpu:
		# Boost GPU smoke on collision
		smoke_gpu.amount = 12000  # Double the particles
		smoke_gpu.explosiveness = 0.8  # Burst emission
		smoke_gpu.emitting = true
		print("[Obstacle] COLLISION SMOKE - GPU boosted")
	elif smoke_cpu:
		# Boost CPU smoke on collision
		smoke_cpu.amount = 1200
		smoke_cpu.explosiveness = 0.8
		smoke_cpu.emitting = true
		print("[Obstacle] COLLISION SMOKE - CPU boosted")
