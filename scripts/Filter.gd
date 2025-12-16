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

func _ready():
	print("[Filter] Spawned at position: %.0f, %.0f" % [global_position.x, global_position.y])
	print("[Filter] Starting 15-second air purification cycle")
	print("[Filter] Particles will flow through Intake_1 and Intake_2 curves into filter")

	# Cache intake path endpoints for particle behavior
	if intake_path_1 and intake_path_1.curve:
		intake_endpoints.append(intake_path_1.global_position)
	if intake_path_2 and intake_path_2.curve:
		intake_endpoints.append(intake_path_2.global_position)

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
