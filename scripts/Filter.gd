extends Node2D

"""
Filter Script - Visual air purifier showing active cleaning

When player drops a filter:
1. Game pauses (stops scrolling)
2. Filter spawns at player position
3. Shows 15 seconds of air purification:
   - First 2 seconds: Dark smoke particles SUCKED INTO the filter
   - Remaining 13 seconds: Light BLUE clean air trails EMITTED outward
4. AQI reduces during cleanup
5. Emits signal when cleanup complete
6. Game resumes
"""

signal cleanup_started()
signal cleanup_complete()

# Timing configuration
var cleanup_duration: float = 15.0
var intake_duration: float = 2.0  # First 2 seconds: dirty air intake
var cleanup_time: float = 0.0
var is_active: bool = true

# Phase tracking
enum Phase { INTAKE, EMISSION }
var current_phase: Phase = Phase.INTAKE

# AQI reduction per second during emission phase
var aqi_reduction_rate: float = 20.0  # Reduces AQI by 20 per second during emission

@onready var filter_object = $Filter_object
@onready var filter_sprite = $Filter_object/Filter_sprite
@onready var intake_particles = $IntakeSmokeParticles  # Dark particles being sucked in
@onready var emission_particles = $CleanAirEmission    # Light blue clean air

func _ready():
	print("[Filter] Spawned at position: %.0f, %.0f" % [global_position.x, global_position.y])
	print("[Filter] Starting 15-second air purification cycle")
	print("[Filter] Phase 1 (0-2s): Dirty air intake")
	print("[Filter] Phase 2 (2-15s): Clean air emission + AQI reduction")

	cleanup_started.emit()
	_start_intake_phase()

func _process(delta):
	if not is_active:
		return

	cleanup_time += delta

	# Phase transition: Intake -> Emission at 2 seconds
	if current_phase == Phase.INTAKE and cleanup_time >= intake_duration:
		_start_emission_phase()

	# During emission phase, reduce AQI
	if current_phase == Phase.EMISSION:
		_reduce_aqi(delta)

	# Check if cleanup complete
	if cleanup_time >= cleanup_duration:
		_finish_cleanup()

func _start_intake_phase() -> void:
	"""Phase 1: Dirty air sucked into filter (first 2 seconds)"""
	current_phase = Phase.INTAKE

	# Start intake particles (dark smoke being sucked in)
	if intake_particles:
		intake_particles.emitting = true
		intake_particles.amount_ratio = 1.0
		print("[Filter] ➡ INTAKE PHASE: Dark smoke being sucked into filter")

	# Keep emission particles off during intake
	if emission_particles:
		emission_particles.emitting = false

func _start_emission_phase() -> void:
	"""Phase 2: Clean air emitted (remaining 13 seconds)"""
	current_phase = Phase.EMISSION

	# Stop intake particles
	if intake_particles:
		intake_particles.emitting = false
		print("[Filter] ✓ INTAKE COMPLETE: Stopping dirty air intake")

	# Start emission particles (clean blue air)
	if emission_particles:
		emission_particles.emitting = true
		emission_particles.amount_ratio = 1.0
		print("[Filter] ➡ EMISSION PHASE: Clean air being released + AQI reducing")

func _reduce_aqi(delta: float) -> void:
	"""Reduce AQI during emission phase"""
	var aqi_manager = _get_aqi_manager()
	if not aqi_manager:
		return

	# Calculate reduction for this frame
	var reduction = aqi_reduction_rate * delta

	# Apply reduction (don't go below minimum)
	var old_aqi = aqi_manager.current_aqi
	aqi_manager.current_aqi = max(aqi_manager.min_aqi, aqi_manager.current_aqi - reduction)

	# Emit signal if changed
	if abs(old_aqi - aqi_manager.current_aqi) > 0.01:
		aqi_manager.aqi_changed.emit(aqi_manager.current_aqi, -reduction)

func _get_aqi_manager() -> Node:
	"""Get AQIManager reference"""
	var managers = get_tree().get_nodes_in_group("aqi_manager")
	return managers[0] if managers.size() > 0 else null

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
	if filter_sprite:
		tween.tween_property(filter_sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

	# Calculate total AQI reduction
	var emission_time = cleanup_duration - intake_duration  # 13 seconds
	var total_reduction = aqi_reduction_rate * emission_time  # 20 * 13 = 260 AQI reduced
	print("[Filter] ✓ Total AQI reduced by %.0f during cleanup" % total_reduction)

func get_cleanup_time() -> float:
	"""Get elapsed cleanup time"""
	return cleanup_time

func get_cleanup_progress() -> float:
	"""Get cleanup progress (0.0 to 1.0)"""
	return clamp(cleanup_time / cleanup_duration, 0.0, 1.0)
