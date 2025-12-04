extends Node

## Modular Debug Logger for Breath Rush
## Usage: Logger.info(Logger.Category.PLAYER, "message")
## Toggle categories in config/debug.json or via Logger.set_category_enabled()

# Logger categories (can be enabled/disabled individually)
# Using const dict instead of enum for autoload accessibility
const Category = {
	"PLAYER": 0,      # Player movement, health, battery, items
	"HUD": 1,         # HUD updates, UI rendering
	"SPAWNER": 2,     # Object spawning, pooling, recycling
	"COLLISION": 3,   # Collision events, damage
	"WORLD": 4,       # World scrolling, chunk loading
	"SKY": 5,         # Sky transitions, AQI changes
	"AUDIO": 6,       # Audio playback events
	"INPUT": 7,       # Input processing
	"PERSISTENCE": 8, # Save/load operations
	"PERFORMANCE": 9  # FPS, memory, frame time
}

# Category names for display
const CATEGORY_NAMES = {
	0: "PLAYER",
	1: "HUD",
	2: "SPAWNER",
	3: "COLLISION",
	4: "WORLD",
	5: "SKY",
	6: "AUDIO",
	7: "INPUT",
	8: "PERSISTENCE",
	9: "PERFORMANCE"
}

# Category colors (for rich text in console)
const CATEGORY_COLORS = {
	0: Color.CYAN,
	1: Color.GREEN,
	2: Color.YELLOW,
	3: Color.RED,
	4: Color.MAGENTA,
	5: Color.SKY_BLUE,
	6: Color.LIGHT_CORAL,
	7: Color.LIGHT_GREEN,
	8: Color.ORANGE,
	9: Color.GOLD
}

# Enabled categories (can be toggled at runtime)
var enabled_categories: Dictionary = {}

# Log level
enum LogLevel {
	DEBUG,   # Verbose logging (every frame updates)
	INFO,    # Important events
	WARNING, # Potential issues
	ERROR    # Critical errors
}

var current_log_level: LogLevel = LogLevel.INFO

# Log file settings
var log_to_file: bool = true
var log_file_path: String = "user://debug_log.txt"
var log_file: FileAccess = null
var session_start_time: int = 0

# Performance tracking
var frame_count: int = 0
var last_performance_log: int = 0
var performance_log_interval_ms: int = 1000  # Log performance every 1 second

# Object tracking for Z-depth and size logging
var tracked_objects: Dictionary = {}  # node_path -> {z_index, size, type}

func _init():
	# Default: Enable all categories
	for category in Category.values():
		enabled_categories[category] = true

	session_start_time = Time.get_ticks_msec()

func _ready():
	# Load logger config from file
	load_config()

	# Open log file if enabled
	if log_to_file:
		open_log_file()

	info(Category["PERFORMANCE"], "=== GAME SESSION START ===")
	info(Category["PERFORMANCE"], "Godot Version: %s" % Engine.get_version_info())
	info(Category["PERFORMANCE"], "Platform: %s" % OS.get_name())
	info(Category["PERFORMANCE"], "Screen Size: %s" % get_viewport().get_visible_rect().size)

func _process(_delta):
	frame_count += 1

	# Log performance metrics periodically
	if enabled_categories.get(Category["PERFORMANCE"], false):
		var current_time = Time.get_ticks_msec()
		if current_time - last_performance_log >= performance_log_interval_ms:
			log_performance_metrics()
			last_performance_log = current_time

func _exit_tree():
	info(Category["PERFORMANCE"], "=== GAME SESSION END ===")
	if log_file:
		log_file.close()

## Load logger configuration from file
func load_config() -> void:
	var config_path = "res://config/debug.json"
	if not FileAccess.file_exists(config_path):
		warning(Category["PERSISTENCE"], "Debug config not found, using defaults")
		return

	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		warning(Category["PERSISTENCE"], "Failed to open debug config")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		warning(Category["PERSISTENCE"], "Failed to parse debug config")
		return

	var config = json.data

	# Apply log level
	if config.has("log_level"):
		current_log_level = config["log_level"]

	# Apply category toggles
	if config.has("categories"):
		for category_name in config["categories"]:
			var category_id = get_category_by_name(category_name)
			if category_id != -1:
				enabled_categories[category_id] = config["categories"][category_name]

	# Apply file logging setting
	if config.has("log_to_file"):
		log_to_file = config["log_to_file"]

	# Apply performance log interval
	if config.has("performance_log_interval_ms"):
		performance_log_interval_ms = config["performance_log_interval_ms"]

## Get category ID from name string
func get_category_by_name(category_name: String) -> int:
	for category_id in CATEGORY_NAMES:
		if CATEGORY_NAMES[category_id] == category_name:
			return category_id
	return -1

## Open log file for writing
func open_log_file() -> void:
	log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if not log_file:
		push_error("Failed to open log file: %s" % log_file_path)

## Core logging function
func log_message(category: int, level: LogLevel, message: String) -> void:
	# Check if category is enabled
	if not enabled_categories.get(category, true):
		return

	# Check log level
	if level < current_log_level:
		return

	# Format timestamp
	var elapsed_ms = Time.get_ticks_msec() - session_start_time
	var timestamp = "[%02d:%02d.%03d]" % [
		int(elapsed_ms / 60000) % 60,
		int(elapsed_ms / 1000) % 60,
		elapsed_ms % 1000
	]

	# Format category
	var category_name = CATEGORY_NAMES.get(category, "UNKNOWN")

	# Format level
	var level_str = ""
	match level:
		LogLevel.DEBUG: level_str = "DEBUG"
		LogLevel.INFO: level_str = "INFO"
		LogLevel.WARNING: level_str = "WARN"
		LogLevel.ERROR: level_str = "ERROR"

	# Build log line
	var log_line = "%s [%s] [%s] %s" % [timestamp, level_str, category_name, message]

	# Print to console
	print(log_line)

	# Write to file
	if log_to_file and log_file:
		log_file.store_line(log_line)
		log_file.flush()  # Ensure immediate write

## Convenience logging methods
func debug(category: int, message: String) -> void:
	log_message(category, LogLevel.DEBUG, message)

func info(category: int, message: String) -> void:
	log_message(category, LogLevel.INFO, message)

func warning(category: int, message: String) -> void:
	log_message(category, LogLevel.WARNING, message)

func error(category: int, message: String) -> void:
	log_message(category, LogLevel.ERROR, message)

## Category-specific convenience methods
func player(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["PLAYER"], level, message)

func hud(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["HUD"], level, message)

func spawner(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["SPAWNER"], level, message)

func collision(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["COLLISION"], level, message)

func world(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["WORLD"], level, message)

func sky(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["SKY"], level, message)

func audio(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["AUDIO"], level, message)

func input_event(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["INPUT"], level, message)

func persistence(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["PERSISTENCE"], level, message)

func performance(message: String, level: LogLevel = LogLevel.INFO) -> void:
	log_message(Category["PERFORMANCE"], level, message)

## Toggle a category on/off
func set_category_enabled(category: int, enabled: bool) -> void:
	enabled_categories[category] = enabled
	info(Category["PERFORMANCE"], "Category %s %s" % [CATEGORY_NAMES[category], "ENABLED" if enabled else "DISABLED"])

## Toggle all categories
func set_all_categories_enabled(enabled: bool) -> void:
	for category in Category.values():
		enabled_categories[category] = enabled

## Log object state (position, size, z-index)
func log_object_state(category: int, node: Node, label: String = "") -> void:
	if not enabled_categories.get(category, true):
		return

	var obj_label = label if label != "" else node.name

	# Get position and z-index if Node2D
	var pos = Vector2.ZERO
	var z = 0
	if node is Node2D:
		var node2d = node as Node2D
		pos = node2d.global_position
		z = node2d.z_index
	elif node is Control:
		var control = node as Control
		pos = control.global_position

	# Get size if available
	var size_str = "N/A"
	if node is Sprite2D:
		var sprite = node as Sprite2D
		if sprite.texture:
			var texture_size = sprite.texture.get_size() * sprite.scale
			size_str = "%.0fx%.0f" % [texture_size.x, texture_size.y]
	elif node is Control:
		var control = node as Control
		size_str = "%.0fx%.0f" % [control.size.x, control.size.y]

	# Get visibility
	var visible_str = "VISIBLE" if node.visible else "HIDDEN"

	log_message(category, LogLevel.DEBUG,
		"%s | Pos:(%.1f, %.1f) Z:%d Size:%s %s" % [obj_label, pos.x, pos.y, z, size_str, visible_str])

## Log spawn event with details
func log_spawn(node: Node2D, spawn_type: String, pool_recycled: bool = false) -> void:
	if not enabled_categories.get(Category["SPAWNER"], true):
		return

	var action = "RECYCLED" if pool_recycled else "SPAWNED"
	var pos = node.global_position

	spawner("%s %s at (%.1f, %.1f) z:%d" % [action, spawn_type, pos.x, pos.y, node.z_index])

## Log despawn/recycle event
func log_despawn(node: Node2D, despawn_type: String, reason: String = "") -> void:
	if not enabled_categories.get(Category["SPAWNER"], true):
		return

	var pos = node.global_position
	var reason_str = " [%s]" % reason if reason != "" else ""

	spawner("DESPAWNED %s at (%.1f, %.1f)%s" % [despawn_type, pos.x, pos.y, reason_str])

## Log collision event
func log_collision(node1: Node2D, node2: Node2D, damage: float = 0.0) -> void:
	if not enabled_categories.get(Category["COLLISION"], true):
		return

	var damage_str = " [DMG: %.1f]" % damage if damage > 0 else ""
	collision("COLLISION: %s <-> %s%s" % [node1.name, node2.name, damage_str])

## Log performance metrics
func log_performance_metrics() -> void:
	var fps = Engine.get_frames_per_second()
	var memory_static = OS.get_static_memory_usage() / 1024.0 / 1024.0  # MB
	var memory_peak = OS.get_static_memory_peak_usage() / 1024.0 / 1024.0  # MB
	var process_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0  # ms
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0  # ms

	var objects_count = Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)

	performance(
		"FPS:%d | Process:%.2fms Physics:%.2fms | Mem:%.1fMB (Peak:%.1fMB) | Objs:%d Nodes:%d" %
		[fps, process_time, physics_time, memory_static, memory_peak, objects_count, nodes_count]
	)

## Track an object for continuous monitoring
func track_object(node: Node2D, object_type: String) -> void:
	var path = node.get_path()
	tracked_objects[path] = {
		"node": node,
		"type": object_type,
		"spawn_time": Time.get_ticks_msec()
	}
	debug(Category["SPAWNER"], "Tracking object: %s (%s)" % [node.name, object_type])

## Untrack an object
func untrack_object(node: Node2D) -> void:
	var path = node.get_path()
	if tracked_objects.has(path):
		var lifetime_ms = Time.get_ticks_msec() - tracked_objects[path]["spawn_time"]
		debug(Category["SPAWNER"], "Untracking object: %s (lifetime: %.2fs)" % [node.name, lifetime_ms / 1000.0])
		tracked_objects.erase(path)

## Log all tracked objects (useful for debugging)
func log_all_tracked_objects(category: int = -1) -> void:
	var cat = category if category != -1 else Category["SPAWNER"]
	if not enabled_categories.get(cat, true):
		return

	info(cat, "=== TRACKED OBJECTS (%d) ===" % tracked_objects.size())
	for path in tracked_objects:
		var data = tracked_objects[path]
		var node = data["node"]
		if is_instance_valid(node):
			log_object_state(cat, node, data["type"])
		else:
			warning(cat, "Invalid tracked object: %s" % path)

## Clear all tracked objects
func clear_tracked_objects() -> void:
	tracked_objects.clear()
	info(Category["SPAWNER"], "Cleared all tracked objects")

## Save current log to timestamped file
func save_log_snapshot() -> void:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var snapshot_path = "user://debug_log_%s.txt" % timestamp

	if log_file:
		log_file.close()

	# Copy current log to snapshot
	if FileAccess.file_exists(log_file_path):
		var source = FileAccess.open(log_file_path, FileAccess.READ)
		var dest = FileAccess.open(snapshot_path, FileAccess.WRITE)
		if source and dest:
			dest.store_string(source.get_as_text())
			dest.close()
			source.close()
			info(Category["PERSISTENCE"], "Log snapshot saved: %s" % snapshot_path)

	# Reopen main log file
	if log_to_file:
		open_log_file()