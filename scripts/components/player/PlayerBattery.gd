extends Node
"""
PlayerBattery Component

Handles ONLY battery and boost functionality:
- Battery charge level
- Boost mechanics (speed multiplier)
- Battery drain during boost
- Charging zones
- Boost state management

This component is extracted from Player.gd to isolate battery system.
"""

# Signals
signal battery_changed(value: float)
signal boost_started()
signal boost_stopped()

# Battery
var battery = 100.0
var max_battery = 100.0
var battery_drain_per_sec = 8.0

# Boost
var is_boosting = false
var boost_speed_mult = 1.35

# Charging
var charge_time = 0.0
var charge_seconds = 2.0

# Gradual charging (for EV charger animation)
var is_gradual_charging = false
var gradual_charge_duration = 5.0  # 5 seconds total
var gradual_charge_elapsed = 0.0
var gradual_charge_start_value = 0.0

func _ready():
	battery = max_battery
	print("[PlayerBattery] Component initialized - Battery: %.1f/%.1f" % [battery, max_battery])

func _process(delta: float) -> void:
	"""Process battery drain and charging"""
	# Handle battery drain while boosting
	if is_boosting:
		battery -= battery_drain_per_sec * delta
		if battery <= 0:
			battery = 0
			stop_boost()
		battery_changed.emit(battery)

	# Handle instant charging (old system)
	if charge_time > 0:
		charge_time -= delta
		if charge_time <= 0:
			battery = max_battery
			charge_time = 0
			battery_changed.emit(battery)
			print("[PlayerBattery] Fully charged!")

	# Handle gradual charging (EV charger - animates battery UI)
	if is_gradual_charging:
		gradual_charge_elapsed += delta
		var progress = min(gradual_charge_elapsed / gradual_charge_duration, 1.0)
		var target_charge = max_battery - gradual_charge_start_value
		battery = gradual_charge_start_value + (target_charge * progress)
		battery_changed.emit(battery)

		if progress >= 1.0:
			battery = max_battery
			is_gradual_charging = false
			print("[PlayerBattery] Gradual charge complete! Battery: %.1f" % battery)

func start_boost() -> void:
	"""Start boost if battery available"""
	if battery > 0 and not is_boosting:
		is_boosting = true
		boost_started.emit()
		print("[PlayerBattery] Boost started - battery: %.1f" % battery)

func stop_boost() -> void:
	"""Stop boost"""
	if is_boosting:
		is_boosting = false
		boost_stopped.emit()
		print("[PlayerBattery] Boost stopped - battery: %.1f" % battery)

func enter_charging_zone() -> void:
	"""Enter a charging zone - start charging timer"""
	charge_time = charge_seconds
	print("[PlayerBattery] Entered charging zone - charging for %.1fs" % charge_seconds)

func start_gradual_charge(duration: float = 5.0) -> void:
	"""Start gradual charging over specified duration (for EV charger animation)"""
	is_gradual_charging = true
	gradual_charge_duration = duration
	gradual_charge_elapsed = 0.0
	gradual_charge_start_value = battery
	print("[PlayerBattery] Starting gradual charge: %.1f → %.1f over %.1fs" % [battery, max_battery, duration])

func exit_charging_zone() -> void:
	"""Exit charging zone - cancel charging"""
	charge_time = 0
	print("[PlayerBattery] Exited charging zone - charging cancelled")

# === Public API for inspection ===

func get_battery() -> float:
	"""Get current battery level"""
	return battery

func get_max_battery() -> float:
	"""Get maximum battery capacity"""
	return max_battery

func get_battery_percentage() -> float:
	"""Get battery as percentage (0.0 to 1.0)"""
	return battery / max_battery if max_battery > 0 else 0.0

func is_boost_active() -> bool:
	"""Check if boost is currently active"""
	return is_boosting

func get_boost_multiplier() -> float:
	"""Get boost speed multiplier"""
	return boost_speed_mult

func is_charging() -> bool:
	"""Check if currently charging"""
	return charge_time > 0
