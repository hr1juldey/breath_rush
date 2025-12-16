class_name AQIManager
extends Node

"""
Singleton managing all AQI calculations and game state
Tracks distance, handles filter lifecycle, enforces EV charger limit
"""

signal aqi_changed(new_aqi: float, delta_aqi: float)
signal distance_changed(new_distance: float, progress: float)
signal filter_dropped(filter: AQISource, drop_progress: float)
signal filter_expired(filter: AQISource)
signal tree_spawned(tree: AQISource, spawn_progress: float)
signal game_won()
signal game_lost(reason: String)

# === Configuration ===
@export var starting_aqi: float = 100.0
@export var min_aqi: float = 15.0
@export var max_aqi: float = 500.0
@export var natural_decay_percent: float = 1.0  # % per minute
@export var total_distance: float = 5000.0      # Goal distance
@export var win_aqi_threshold: float = 150.0    # Max AQI for win

# === State ===
var current_aqi: float = 100.0
var distance_traveled: float = 0.0
var is_paused: bool = false

# === Sources ===
var aqi_sources: Array = []  # All registered AQISource nodes
var dropped_filters: Array = []  # FilterAQISource references

# === Filter Tracking ===
var filters_remaining: int = 3
var filters_dropped: int = 0

# === EV Charger Tracking ===
var ev_chargers_spawned: int = 0
var ev_chargers_max: int = 3

# === Game End Guard ===
var game_ended: bool = false

func _ready():
	add_to_group("aqi_manager")
	current_aqi = starting_aqi
	print("[AQIManager] Initialized - Starting AQI: %.1f, Goal: %.0fm" % [current_aqi, total_distance])

func _process(delta: float):
	if is_paused:
		return

	var aqi_delta = 0.0

	# Natural decay (1% per minute)
	aqi_delta -= current_aqi * (natural_decay_percent / 100.0) * (delta / 60.0)

	# Sum all source contributions
	for source in aqi_sources:
		if source and is_instance_valid(source) and source.is_active:
			aqi_delta += source.calculate_effect(distance_traveled, delta)

	# Apply changes
	var old_aqi = current_aqi
	current_aqi = clamp(current_aqi + aqi_delta, min_aqi, max_aqi)

	if abs(current_aqi - old_aqi) > 0.01:
		aqi_changed.emit(current_aqi, current_aqi - old_aqi)

	# Check lose condition (AQI too high) - only fire once
	if current_aqi >= max_aqi and not game_ended:
		game_ended = true
		game_lost.emit("AQI reached critical level!")

func register_source(source: AQISource):
	if source not in aqi_sources:
		aqi_sources.append(source)
		print("[AQIManager] Registered source: %s (total: %d)" % [source.name, aqi_sources.size()])

func unregister_source(source: AQISource):
	aqi_sources.erase(source)

func update_distance(delta_distance: float):
	"""Called by Game.gd each frame"""
	distance_traveled += delta_distance
	var progress = distance_traveled / total_distance
	distance_changed.emit(distance_traveled, progress)

	# Check win condition
	if distance_traveled >= total_distance:
		_check_win_condition()

func _check_win_condition():
	if game_ended:
		return  # Already ended, don't check again

	# Must have dropped all 3 filters
	if filters_dropped < 3:
		game_ended = true
		game_lost.emit("Did not deploy all 3 filters!")
		return

	# All filters must still be active
	var active_filters = 0
	for filter in dropped_filters:
		if filter and is_instance_valid(filter) and filter.is_active:
			active_filters += 1

	if active_filters < 3:
		game_ended = true
		game_lost.emit("Filters expired before reaching goal!")
		return

	# AQI must be below threshold
	if current_aqi > win_aqi_threshold:
		game_ended = true
		game_lost.emit("AQI too high at finish!")
		return

	game_ended = true
	game_won.emit()

# === Filter Management ===

func can_drop_filter() -> bool:
	return filters_remaining > 0

func drop_filter() -> AQISource:
	"""Create and register a new filter at current position"""
	if filters_remaining <= 0:
		return null

	filters_remaining -= 1
	filters_dropped += 1

	var filter = load("res://scripts/aqi/FilterAQISource.gd").new()
	filter.name = "Filter_%d" % filters_dropped
	add_child(filter)
	dropped_filters.append(filter)

	var progress = distance_traveled / total_distance
	filter_dropped.emit(filter, progress)

	# Connect expiry signal
	filter.filter_expired.connect(func(): filter_expired.emit(filter))

	print("[AQIManager] Filter dropped! Remaining: %d" % filters_remaining)
	return filter

func get_filters_remaining() -> int:
	return filters_remaining

func get_active_filter_count() -> int:
	var count = 0
	for filter in dropped_filters:
		if filter and is_instance_valid(filter) and filter.is_active:
			count += 1
	return count

# === EV Charger Management ===

func can_spawn_ev_charger() -> bool:
	return ev_chargers_spawned < ev_chargers_max

func record_ev_charger_spawn():
	ev_chargers_spawned += 1
	print("[AQIManager] EV Charger spawned (%d/%d)" % [ev_chargers_spawned, ev_chargers_max])

func get_ev_chargers_remaining() -> int:
	return ev_chargers_max - ev_chargers_spawned

# === Pause Control ===

func pause():
	is_paused = true

func resume():
	is_paused = false
