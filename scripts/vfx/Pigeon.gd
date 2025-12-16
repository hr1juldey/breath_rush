class_name Pigeon
extends Node2D

"""
A pigeon that perches on buildings when AQI is good.
Flies away when AQI gets bad.
"""

# State
var is_flying: bool = false
var idle_frames: Array[Texture2D] = []
var fly_frames: Array[Texture2D] = []
var current_frame: int = 0

# References
var sprite: Sprite2D
var animation_timer: Timer

# Flying behavior
var fly_direction: Vector2 = Vector2(-1, -1)  # Up and left
var fly_speed: float = 200.0
var flight_duration: float = 2.0
var flight_elapsed: float = 0.0

func _ready():
	# Get references to children (created by PigeonSpawnManager)
	sprite = get_node_or_null("Sprite2D")
	animation_timer = get_node_or_null("AnimationTimer")

	# Load pigeon sprites
	idle_frames = [
		load("res://assets/vfx/pigeons/pigeon_idle_01.webp"),
		load("res://assets/vfx/pigeons/pigeon_idle_02.webp"),
	]
	fly_frames = [
		load("res://assets/vfx/pigeons/pigeon_fly_01.webp"),
		load("res://assets/vfx/pigeons/pigeon_fly_02.webp"),
	]

	if not sprite:
		push_error("Pigeon has no Sprite2D child!")
		return
	if not animation_timer:
		push_error("Pigeon has no AnimationTimer child!")
		return

	# Set initial sprite
	sprite.texture = idle_frames[0]
	sprite.centered = true  # Center the sprite on the position
	sprite.offset = Vector2.ZERO

	# Connect animation timer and start it
	animation_timer.timeout.connect(_on_animation_frame)
	if not animation_timer.is_stopped():
		animation_timer.stop()
	animation_timer.start()

func _process(delta: float):
	if is_flying:
		_update_flight(delta)

func _update_flight(delta: float) -> void:
	flight_elapsed += delta

	# Move pigeon
	position += fly_direction * fly_speed * delta

	# Stop flying after duration
	if flight_elapsed >= flight_duration:
		queue_free()

func _on_animation_frame() -> void:
	if not sprite:
		return

	var frames = fly_frames if is_flying else idle_frames
	if frames.is_empty():
		return

	current_frame = (current_frame + 1) % frames.size()
	sprite.texture = frames[current_frame]

func start_flying() -> void:
	if is_flying:
		return

	is_flying = true
	flight_elapsed = 0.0
	current_frame = 0

	# Randomize flight direction (up-left or up-right)
	fly_direction = Vector2(randf_range(-1.0, 1.0), -1.0).normalized()

	if animation_timer:
		animation_timer.wait_time = 0.1  # Faster animation while flying

func idle() -> void:
	is_flying = false
	flight_elapsed = 0.0
	current_frame = 0

	if animation_timer:
		animation_timer.wait_time = 0.3  # Slower idle animation
