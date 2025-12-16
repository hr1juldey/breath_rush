class_name CleanAirPeriodManager
extends Node

"""
Manages "Clean Air Periods" - a bonus phase when:
- All 3 filters have been deployed
- AQI is low (below 100)

During this phase:
- No cars spawn for 180 seconds
- Pigeons can perch safely on buildings
- 3 new filters are reloaded for the player
"""

signal clean_air_period_started
signal clean_air_period_ended

# Configuration
@export var aqi_threshold_for_clean_air: float = 150.0  # AQI must be "Moderate" or better after 3 filters
@export var clean_air_duration: float = 180.0  # 3 minutes

# References
var aqi_manager: AQIManager
var spawner: Node
var pigeon_manager: PigeonSpawnManager

# State
var clean_air_active: bool = false
var clean_air_timer: float = 0.0
var filters_deployed_at_start: int = 0

func _ready():
	add_to_group("clean_air_period_manager")

	# Find references
	aqi_manager = get_tree().get_first_node_in_group("aqi_manager")
	pigeon_manager = get_tree().get_first_node_in_group("pigeon_spawn_manager")
	spawner = get_parent().find_child("Spawner")

	if aqi_manager:
		aqi_manager.filter_dropped.connect(_on_filter_dropped)
		# Don't initialize clean air on startup - must earn it by deploying filters
		print("[CleanAirPeriodManager] Connected to AQIManager")
		print("[CleanAirPeriodManager] - Threshold: AQI < %.1f when all 3 filters deployed" % aqi_threshold_for_clean_air)
	else:
		print("[CleanAirPeriodManager] WARNING: AQIManager not found!")

func _process(delta: float):
	if not clean_air_active:
		return

	clean_air_timer -= delta

	# Check if clean air period should end
	if clean_air_timer <= 0.0:
		_end_clean_air_period()

func _on_filter_dropped(filter: AQISource, drop_progress: float) -> void:
	"""Called when a filter is deployed"""
	if not aqi_manager:
		return

	print("[CleanAirPeriodManager] Filter dropped! (Total: %d, AQI: %.1f)" % [aqi_manager.filters_dropped, aqi_manager.current_aqi])

	# Check if all 3 filters have now been deployed
	if aqi_manager.filters_dropped >= 3:
		print("[CleanAirPeriodManager] ✓ All 3 filters deployed!")
		# Check if AQI is low enough
		if aqi_manager.current_aqi <= aqi_threshold_for_clean_air:
			print("[CleanAirPeriodManager] ✓ AQI low enough (%.1f <= %.1f)" % [aqi_manager.current_aqi, aqi_threshold_for_clean_air])
			_start_clean_air_period()
		else:
			print("[CleanAirPeriodManager] ✗ AQI too high (%.1f > %.1f) - Clean air period NOT triggered" % [aqi_manager.current_aqi, aqi_threshold_for_clean_air])

func _start_clean_air_period() -> void:
	"""Begin a clean air bonus period"""
	if clean_air_active:
		return  # Already active

	clean_air_active = true
	clean_air_timer = clean_air_duration
	filters_deployed_at_start = aqi_manager.filters_dropped

	# Reload filters for the player (give 3 more to deploy)
	# Keep filters_dropped as-is (it's the total count for win condition)
	# Reset BOTH AQIManager and PlayerInventory filter counts
	aqi_manager.filters_remaining = 3

	# Also update PlayerInventory filter count
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		var player = main.get_node_or_null("Player")
		if player:
			var inventory = player.get_node_or_null("PlayerInventory")
			if inventory:
				inventory.filter_count = 3
				inventory.filter_count_changed.emit(3)
				print("[CleanAirPeriodManager] ✓ PlayerInventory filter count reset to 3")
			else:
				print("[CleanAirPeriodManager] ⚠️ PlayerInventory not found!")
		else:
			print("[CleanAirPeriodManager] ⚠️ Player node not found!")

	print("[CleanAirPeriodManager] ✨ CLEAN AIR PERIOD STARTED!")
	print("[CleanAirPeriodManager] - No cars for %.0f seconds" % clean_air_duration)
	print("[CleanAirPeriodManager] - Pigeons can nest safely")
	print("[CleanAirPeriodManager] - 3 new filters reloaded")

	clean_air_period_started.emit()

func _end_clean_air_period() -> void:
	"""End the clean air bonus period"""
	if not clean_air_active:
		return

	clean_air_active = false
	clean_air_timer = 0.0

	print("[CleanAirPeriodManager] ⚠️ CLEAN AIR PERIOD ENDED - Cars returning to roads!")

	clean_air_period_ended.emit()

func is_clean_air_active() -> bool:
	"""Check if we're currently in a clean air period"""
	return clean_air_active

func get_clean_air_time_remaining() -> float:
	"""Get remaining time in clean air period"""
	return max(0.0, clean_air_timer)
