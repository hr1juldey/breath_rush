extends Area2D

var obstacle_type = "car" # "car", "bike", "pollution"
var scroll_speed = 400.0
var car_relative_speed = 150.0  # Speed relative to road (oncoming traffic)
var collision_damage = 12
var player_ref = null
var spawner_ref = null # Reference to spawner for proper pool return

var recycled = false
var off_screen_time = 0.0
var is_off_screen = false
var collision_smoke_timer = 0.0
var collision_smoke_active = false

# Stage flags to prevent repeated triggers
var stage_5s_done = false
var stage_15s_done = false
var stage_35s_done = false

# Smoke particle references for dynamic velocity compensation
var local_smoke_gpu: GPUParticles2D = null
var local_smoke_cpu: CPUParticles2D = null

# AQI source reference
var aqi_source: AQISource = null

func _ready():
	if has_node("CollisionShape2D"):
		pass # Collision shape will be set up in scene

	body_entered.connect(_on_body_entered)

	# Randomize car's relative speed for variety (100-200 units/sec)
	car_relative_speed = randf_range(100.0, 200.0)

	# Set z-index based on lane depth for realistic perspective
	# Player is at z-index 5
	# Lane-based depth: Higher Y = closer to camera = higher z-index
	call_deferred("_set_lane_based_z_index")

	# Setup smoke particles with GPU/CPU fallback
	_setup_smoke_particles()

func _process(delta):
	# Move obstacle left with scroll speed + car's own speed (oncoming traffic)
	if not is_off_screen:
		var total_speed = scroll_speed + car_relative_speed
		position.x -= total_speed * delta

		# Update local smoke direction to compensate for car velocity
		_update_local_smoke_velocity(total_speed)

	# Reset collision smoke after brief burst
	if collision_smoke_active:
		collision_smoke_timer += delta
		if collision_smoke_timer >= 2.0:  # 2 second burst
			_reset_smoke_to_normal()
			collision_smoke_active = false

	# Time-based despawn: 15 seconds after going off-screen
	if position.x < -950: # Car is completely off-screen (accounts for smoke emitter offset ~440px)
		if not is_off_screen:
			is_off_screen = true
			off_screen_time = 0.0
			# Stop movement, hide car sprite and collision, but keep smoke visible
			_hide_car_only()
			print("[Obstacle] Car off-screen at x=%.0f, STOPPED to keep smoke visible" % position.x)

			# Disable AQI source when car goes off-screen (so AQI stops increasing)
			if aqi_source and is_instance_valid(aqi_source):
				aqi_source.is_active = false
				print("[Obstacle] AQI source disabled - smoke stays but AQI locked")

		off_screen_time += delta

		# Stage 1: After 5s off-screen, reduce particle emission
		if off_screen_time >= 5.0 and not stage_5s_done:
			stage_5s_done = true
			_reduce_particle_lifetime()
			print("[Obstacle] 5s: Reduced particle emission")

		# Stage 2: After 15s, stop emitting new particles entirely
		if off_screen_time >= 15.0 and not stage_15s_done:
			stage_15s_done = true
			_stop_emitting_new_particles()
			print("[Obstacle] 15s: Stopped emitting")

		# Stage 3: After 35s, clear particle buffer
		if off_screen_time >= 35.0 and not stage_35s_done:
			stage_35s_done = true
			_clear_particle_buffer()
			print("[Obstacle] 35s: Cleared buffer")

		# Stage 3: Return to pool after ALL particles have naturally died
		# Particles emitted at 15s will die at 15s + 26.1s = 41.1s (max GPU lifetime)
		if off_screen_time >= 45.0:  # 15s stop emitting + 30s buffer for all particles to die
			# After ALL particles have died naturally, return to pool
			# DON'T SET visible = false - let's see what happens!
			if spawner_ref and is_instance_valid(spawner_ref):
				print("[Obstacle] Car despawned after 45s - returning to pool (VISIBILITY STILL ON)")
				spawner_ref.return_to_pool(self)
			else:
				# Fallback - still don't hide, just log
				print("[Obstacle] Car despawned after 45s - no spawner ref (STAYING VISIBLE)")
	else:
		is_off_screen = false
		off_screen_time = 0.0
		# Reset stage flags
		stage_5s_done = false
		stage_15s_done = false
		stage_35s_done = false

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
		z_index = 5 # Default to player level
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
	if car_y > player_y + 20: # Car is closer to camera (lower lane)
		z_index = 6 # Car in front of player (deterministic, not random)
		print("[Obstacle] Car in front (Y=%.0f > Player Y=%.0f) z=%d" % [car_y, player_y, z_index])
	elif car_y < player_y - 20: # Car is farther from camera (upper lane)
		z_index = 3 # Car behind player (deterministic, not random)
		print("[Obstacle] Car behind (Y=%.0f < Player Y=%.0f) z=%d" % [car_y, player_y, z_index])
	else: # Same lane
		# When same lane, car should be behind player for better visibility
		z_index = 4
		print("[Obstacle] Car same lane (Y=%.0f ≈ Player Y=%.0f) z=%d (behind)" % [car_y, player_y, z_index])

func _setup_smoke_particles() -> void:
	"""Setup smoke particles with GPU/CPU fallback for browser compatibility"""
	var smoke_emitter = get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	# Cache local smoke particles for dynamic velocity compensation
	local_smoke_gpu = smoke_emitter.get_node_or_null("LocalSmokeGPU")
	local_smoke_cpu = smoke_emitter.get_node_or_null("LocalSmokeCPU")

	var global_smoke_gpu = smoke_emitter.get_node_or_null("GlobalSmokeGPU")
	var global_smoke_cpu = smoke_emitter.get_node_or_null("GlobalSmokeCPU")

	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device:
		if local_smoke_gpu: local_smoke_gpu.emitting = true
		if global_smoke_gpu: global_smoke_gpu.emitting = true
		if local_smoke_cpu: local_smoke_cpu.emitting = false
		if global_smoke_cpu: global_smoke_cpu.emitting = false
	else:
		if local_smoke_gpu: local_smoke_gpu.emitting = false
		if global_smoke_gpu: global_smoke_gpu.emitting = false
		if local_smoke_cpu: local_smoke_cpu.emitting = true
		if global_smoke_cpu: global_smoke_cpu.emitting = true

	# Attach smoke damage zone for AQI proximity detection
	_attach_smoke_damage_zone(smoke_emitter)

func _attach_smoke_damage_zone(smoke_emitter: Node) -> void:
	"""Attach SmokeDamageZone to detect player proximity and apply smoke AQI damage"""
	if not smoke_emitter or not is_instance_valid(smoke_emitter):
		print("[Obstacle] ERROR: Cannot attach smoke damage zone - invalid emitter")
		return

	if smoke_emitter.get_child_count() > 0:
		# Check if already has smoke damage zone
		for child in smoke_emitter.get_children():
			if child is SmokeDamageZone:
				return  # Already attached

	# Create and attach new SmokeDamageZone
	# NOTE: AQIManager check happens later when smoke damage is actually applied
	var smoke_zone = SmokeDamageZone.new()
	smoke_zone.name = "SmokeDamageZone"
	smoke_emitter.add_child(smoke_zone)

func _hide_car_only() -> void:
	"""Disable collision only - KEEP CAR AND SMOKE VISIBLE for testing"""
	# Don't hide sprite - let's see what happens!
	# var sprite = get_node_or_null("Sprite2D")
	# if sprite:
	#     sprite.visible = false

	# Disable collision (so off-screen car doesn't hit player)
	monitoring = false
	monitorable = false
	print("[Obstacle] Collision disabled, but car sprite STAYS VISIBLE for testing")

func _show_car() -> void:
	"""Show car sprite and enable collision"""
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.visible = true

	# Enable collision
	monitoring = true
	monitorable = true

func _emit_collision_smoke() -> void:
	"""Emit a LOT of smoke when car collides with player"""
	var smoke_emitter = get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")

	if not smoke_gpu or not smoke_cpu:
		return

	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device and smoke_gpu:
		# Boost GPU smoke on collision using explosiveness (doesn't clear particles!)
		smoke_gpu.amount_ratio = 1.0  # 100% emission
		smoke_gpu.explosiveness = 0.95  # Brief intense burst
		smoke_gpu.emitting = true
		collision_smoke_timer = 0.0
		collision_smoke_active = true
		print("[Obstacle] COLLISION SMOKE - GPU burst (explosiveness 0.95, 2s)")
	elif smoke_cpu:
		# Boost CPU smoke on collision
		# CPU particles don't have amount_ratio
		smoke_cpu.explosiveness = 0.95  # Brief intense burst
		smoke_cpu.emitting = true
		collision_smoke_timer = 0.0
		collision_smoke_active = true
		print("[Obstacle] COLLISION SMOKE - CPU burst (explosiveness 0.95, 2s)")

func _reset_smoke_to_normal() -> void:
	"""Reset smoke to normal emission after collision burst"""
	var smoke_emitter = get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")

	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device and smoke_gpu:
		# Reset to normal continuous smoke
		smoke_gpu.amount_ratio = 1.0  # 100% emission
		smoke_gpu.explosiveness = 0.3  # Steady stream
		print("[Obstacle] Smoke reset to normal (100% emission, steady)")
	elif smoke_cpu:
		# Reset to normal continuous smoke
		# CPU particles don't have amount_ratio
		smoke_cpu.explosiveness = 0.3  # Steady stream
		print("[Obstacle] Smoke reset to normal (100% emission, steady)")

func _reduce_particle_lifetime() -> void:
	"""Reduce particle emission to let old off-camera particles die naturally"""
	var smoke_emitter = get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")
	var smoke_gpu_trail = smoke_emitter.get_node_or_null("SmokeGPU_Trail")
	var smoke_cpu_trail = smoke_emitter.get_node_or_null("SmokeCPU_Trail")

	if smoke_gpu: smoke_gpu.amount_ratio = 0.1
	if smoke_gpu_trail: smoke_gpu_trail.amount_ratio = 0.1
	if smoke_cpu: smoke_cpu.emitting = false
	if smoke_cpu_trail: smoke_cpu_trail.emitting = false

func _stop_emitting_new_particles() -> void:
	"""Stop emitting new particles entirely"""
	var smoke_emitter = get_node_or_null("SmokeEmitter")
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

func _clear_particle_buffer() -> void:
	"""Clear particle buffer after 20 seconds of natural fading"""
	var smoke_emitter = get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var global_smoke_gpu = smoke_emitter.get_node_or_null("GlobalSmokeGPU")
	var global_smoke_cpu = smoke_emitter.get_node_or_null("GlobalSmokeCPU")
	var local_smoke_gpu = smoke_emitter.get_node_or_null("LocalSmokeGPU")
	var local_smoke_cpu = smoke_emitter.get_node_or_null("LocalSmokeCPU")

	if global_smoke_gpu: global_smoke_gpu.restart()
	if global_smoke_cpu: global_smoke_cpu.restart()
	if local_smoke_gpu: local_smoke_gpu.restart()
	if local_smoke_cpu: local_smoke_cpu.restart()

func _update_local_smoke_velocity(car_speed: float) -> void:
	"""Update local smoke direction to amplify car velocity with 1.1x factor"""
	# Calculate velocity compensation: 1.1 * car_speed
	# This makes smoke flow forward with the car, creating dispersed trail effect
	var velocity_compensation = 1.1 * car_speed

	# Update LocalSmokeCPU direction
	if local_smoke_cpu:
		# Preserve the Y component, update X with compensation
		var current_direction = local_smoke_cpu.direction
		local_smoke_cpu.direction = Vector2(velocity_compensation, current_direction.y)

	# Update LocalSmokeGPU material direction
	if local_smoke_gpu and local_smoke_gpu.process_material:
		var gpu_material = local_smoke_gpu.process_material as ParticleProcessMaterial
		if gpu_material:
			# Get current direction, preserve Y and Z components
			var current_direction = gpu_material.direction
			gpu_material.direction = Vector3(velocity_compensation, current_direction.y, current_direction.z)
			#print_debug("[Smoke] Compensating car speed %.0f → smoke velocity %.0f" % [car_speed, velocity_compensation])
