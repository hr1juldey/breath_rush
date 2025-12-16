extends Node2D

"""
Filter Script - Visual air purifier showing active cleaning

When player drops a filter:
1. Game pauses (stops scrolling)
2. Filter spawns at player position
3. Shows 15 seconds of air purification:
   - Dark smoke particles SUCKED INTO the filter via intake paths
   - Light BLUE clean air trails EMITTED outward
4. Emits signal when cleanup complete
5. Game resumes

Filter actively shows:
- Bad air particles being pulled into filter center along curved paths
- Clean light blue air particles being released
- Particles follow Intake_1 and Intake_2 path curves into filter
"""

signal cleanup_started()
signal cleanup_complete()

var cleanup_duration: float = 15.0
var cleanup_time: float = 0.0
var is_active: bool = true

@onready var sprite = $Sprite2D
@onready var intake_particles = $IntakeSmokeParticles  # Dark particles being sucked in via curves
@onready var emission_particles = $CleanAirEmission    # Light blue clean air
@onready var intake_path_1 = $Intake_1
@onready var intake_path_2 = $Intake_2

# Intake path reference points for particle guidance
var intake_endpoints: Array = []

# Filter kill zone for particle collision detection
var filter_kill_zone: Area2D = null

func _ready():
	print("[Filter] Spawned at position: %.0f, %.0f" % [global_position.x, global_position.y])
	print("[Filter] Starting 15-second air purification cycle")
	print("[Filter] Particles will flow through Intake_1 and Intake_2 curves into filter")

	# Setup custom particle shader for path-following intake particles
	_setup_intake_particle_shader()

	# Cache intake path endpoints for particle behavior
	if intake_path_1 and intake_path_1.curve:
		intake_endpoints.append(intake_path_1.global_position)
	if intake_path_2 and intake_path_2.curve:
		intake_endpoints.append(intake_path_2.global_position)

	# Create filter kill zone for particle collision detection
	_create_filter_kill_zone()

	cleanup_started.emit()
	_start_cleanup_animation()

func _process(delta):
	if not is_active:
		return

	cleanup_time += delta

	# Update particle emission intensity based on progress
	_update_cleanup_progress(cleanup_time / cleanup_duration)

	# Check if cleanup complete
	if cleanup_time >= cleanup_duration:
		_finish_cleanup()

func _start_cleanup_animation() -> void:
	"""Start intake and emission particles - particles follow curves into filter"""
	if intake_particles:
		intake_particles.emitting = true
		print("[Filter] Dark smoke intake particles activated - following intake curves")

	if emission_particles:
		emission_particles.emitting = true
		print("[Filter] Clean blue air emission particles activated")

func _update_cleanup_progress(progress: float) -> void:
	"""Update particle emission intensity based on cleanup progress"""
	# Gradually increase particle emission as filter works
	if intake_particles:
		intake_particles.amount_ratio = lerp(0.3, 1.0, progress)

	if emission_particles:
		emission_particles.amount_ratio = lerp(0.5, 1.0, progress)

func _finish_cleanup() -> void:
	"""Cleanup complete - stop particles and fade out"""
	is_active = false
	cleanup_complete.emit()
	print("[Filter] Cleanup complete at %.0f, %.0f - Air purified!" % [global_position.x, global_position.y])

	# Stop particle emission
	if intake_particles:
		intake_particles.emitting = false

	if emission_particles:
		emission_particles.emitting = false

	# Fade out filter sprite
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func get_cleanup_time() -> float:
	"""Get elapsed cleanup time"""
	return cleanup_time

func get_cleanup_progress() -> float:
	"""Get cleanup progress (0.0 to 1.0)"""
	return clamp(cleanup_time / cleanup_duration, 0.0, 1.0)

# === Particle Path Following & Collision System ===

func _setup_intake_particle_shader() -> void:
	"""Setup custom shader material for intake particles to follow paths and die at filter"""
	if not intake_particles:
		return

	# Load custom particle shader
	var shader = load("res://assets/shaders/intake_particle_path.gdshader")
	if not shader:
		print("[Filter] Warning: Could not load intake_particle_path.gdshader")
		return

	# Create shader material
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader

	# Set shader parameters
	# Target point is filter center (where particles should die)
	var filter_center = Vector2(0, 0)  # Relative to filter, center is at origin
	shader_material.set_shader_parameter("target_point", filter_center)

	# Attraction strength pulls particles toward filter
	shader_material.set_shader_parameter("attraction_strength", 400.0)

	# Kill distance - particles die when within this distance of filter
	shader_material.set_shader_parameter("kill_distance", 60.0)

	# Proximity boost - increases attraction as particle gets closer
	shader_material.set_shader_parameter("proximity_boost", 0.3)

	# Apply material to particles
	intake_particles.process_material = shader_material

	print("[Filter] Intake particle shader configured for path following and collision")

func _create_filter_kill_zone() -> void:
	"""Create invisible Area2D zone at filter center to detect particle "collisions" """
	if filter_kill_zone:
		return  # Already created

	# Create kill zone area
	filter_kill_zone = Area2D.new()
	filter_kill_zone.name = "FilterKillZone"

	# Create collision shape - small circle at filter center
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50.0  # Detection radius for particle kill

	collision_shape.shape = circle_shape
	filter_kill_zone.add_child(collision_shape)

	# Position at filter center
	filter_kill_zone.position = Vector2.ZERO

	# Add to filter
	add_child(filter_kill_zone)

	# Setup physics layers - only detects particles visually (no physics interaction)
	filter_kill_zone.collision_layer = 0
	filter_kill_zone.collision_mask = 0  # Purely visual detection

	print("[Filter] Kill zone created at filter center for particle collision detection")
