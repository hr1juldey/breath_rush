class_name PigeonSpawnManager
extends Node

"""
Manages pigeon spawning when AQI stays below 60 for 30 seconds.
Pigeons perch on buildings and fly away when AQI gets bad.
"""

signal pigeons_spawned(count: int)
signal pigeons_fled()

# Configuration
@export var aqi_threshold: float = 60.0
@export var time_threshold: float = 30.0  # seconds
@export var max_pigeons: int = 8
@export var spawn_check_interval: float = 1.0  # seconds between spawn checks

# State
var aqi_manager: AQIManager
var current_aqi: float = 100.0
var time_below_threshold: float = 0.0
var pigeons_spawned_flag: bool = false
var active_pigeons: Array[Node] = []

# Building spawn positions (Y values for different parallax layers)
# Top of buildings are above the obstacle lanes (240, 300, 360)
# Visual building tops should be at Y ~150-200 to be visible above lanes
var building_spawn_y_positions: Array[float] = [150.0, 170.0, 190.0, 210.0]

# Viewport width for X positioning
# Buildings scroll from right (off-screen) to left
# Spawn at positions where buildings would be visible
var viewport_width: float = 960.0
var viewport_right_edge: float = 1000.0  # Just off-screen to the right

func _ready():
	add_to_group("pigeon_spawn_manager")

	# Find AQIManager
	aqi_manager = get_tree().get_first_node_in_group("aqi_manager")
	if aqi_manager:
		aqi_manager.aqi_changed.connect(_on_aqi_changed)
		current_aqi = aqi_manager.current_aqi  # Initialize with current AQI
		print("[PigeonSpawnManager] Connected to AQIManager - Current AQI: %.1f" % current_aqi)
	else:
		print("[PigeonSpawnManager] WARNING: AQIManager not found!")

func _process(delta: float):
	# Clean up freed pigeons
	active_pigeons = active_pigeons.filter(func(p): return is_instance_valid(p))

	# Track time AQI is below threshold
	if current_aqi < aqi_threshold:
		time_below_threshold += delta

		# Check if we should spawn pigeons
		if time_below_threshold >= time_threshold and not pigeons_spawned_flag:
			_spawn_pigeons()
			pigeons_spawned_flag = true
			print("[PigeonSpawnManager] AQI below %.0f for %.1f seconds - pigeons spawned!" % [aqi_threshold, time_threshold])
	else:
		# AQI is bad - reset timer and make pigeons fly away
		if time_below_threshold > 0.0:
			time_below_threshold = 0.0

		if pigeons_spawned_flag:
			_make_pigeons_flee()
			pigeons_spawned_flag = false
			print("[PigeonSpawnManager] AQI above %.0f - pigeons fleeing!" % aqi_threshold)

func _on_aqi_changed(new_aqi: float, _delta_aqi: float) -> void:
	current_aqi = new_aqi

func _spawn_pigeons() -> void:
	var spawn_count = min(max_pigeons, randi_range(3, max_pigeons))

	# Spawn pigeons at random building positions
	for i in range(spawn_count):
		var pigeon = _create_pigeon()
		if pigeon:
			active_pigeons.append(pigeon)
			get_parent().add_child(pigeon)

	pigeons_spawned.emit(spawn_count)
	print("[PigeonSpawnManager] Spawned %d pigeons" % spawn_count)

func _create_pigeon() -> Node2D:
	var pigeon = Node2D.new()
	pigeon.name = "Pigeon_%d" % active_pigeons.size()
					 	pigeon.set_script(load("res://scripts/vfx/Pigeon.gd"))
	pigeon.scale = Vector2(0.5, 0.5)  # Smaller scale to fit on buildings

	# Random building position
	var y = building_spawn_y_positions[randi() % building_spawn_y_positions.size()]
	var x = viewport_right_edge - randf_range(200.0, 400.0)  # Coming from right side of screen
	pigeon.position = Vector2(x, y)

	# Add sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	pigeon.add_child(sprite)

	# Add animation timer
	var timer = Timer.new()
	timer.name = "AnimationTimer"
	timer.wait_time = 0.3
	pigeon.add_child(timer)
	timer.start()

	return pigeon

func _make_pigeons_flee() -> void:
	for pigeon in active_pigeons:
		if is_instance_valid(pigeon) and pigeon.has_method("start_flying"):
			pigeon.start_flying()

	pigeons_fled.emit()
	print("[PigeonSpawnManager] %d pigeons taking flight!" % active_pigeons.size())

	# Clear active pigeons list (they'll remove themselves)
	active_pigeons.clear()
