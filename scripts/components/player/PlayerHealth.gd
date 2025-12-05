extends Node
"""
PlayerHealth Component

Handles ONLY health-related functionality:
- Health points (HP)
- Grace period (initial invulnerability)
- Health drain from AQI
- Damage handling
- Death detection

This component is extracted from Player.gd to isolate health system.
"""

# Signals
signal health_changed(value: float)
signal player_died()

# Health
var health = 500.0  # TEMP: Increased for testing mask pickup bug
var max_health = 500.0  # TEMP: Increased for testing mask pickup bug
var base_drain_multiplier = 0.01666  # Base drain multiplier

# Grace period (initial invulnerability)
var grace_period = 5.0  # TEMP: Increased to 5 seconds for testing
var elapsed_time = 0.0
var grace_period_active = true

# AQI tracking (for drain calculation)
var aqi_current = 250.0

func _ready():
	health = max_health
	print("[PlayerHealth] Component initialized - HP: %.1f/%.1f" % [health, max_health])

func _process(delta: float) -> void:
	"""Update grace period timer"""
	if grace_period_active:
		elapsed_time += delta
		if elapsed_time >= grace_period:
			grace_period_active = false
			var logger = get_node_or_null("/root/Logger")
			if logger:
				logger.info(0, "Grace period ended at %.2f seconds" % elapsed_time)
			print("[PlayerHealth] Grace period ended")

func process_health_drain(delta: float, has_mask: bool, leak_damage: float) -> void:
	"""
	Process health drain based on AQI and mask status.
	Called by Player coordinator each frame.

	Args:
		delta: Frame time
		has_mask: Is player wearing mask?
		leak_damage: Damage from mask leak (if applicable)
	"""
	# Don't take damage during grace period
	if grace_period_active:
		return

	if has_mask:
		# During mask, no AQI drain, but apply leak damage
		health -= leak_damage
	else:
		# Calculate and apply AQI drain
		var drain = calculate_health_drain()
		health -= drain * delta

	# Clamp and emit
	health = clamp(health, 0, max_health)
	health_changed.emit(health)

	# Check for death
	if health <= 0:
		player_died.emit()

func calculate_health_drain() -> float:
	"""
	Calculate health drain rate based on AQI.

	Formula: AQI / 150 = HP per second
	- At AQI 250: 250/150 = 1.67 HP/sec (100 HP lasts ~60 seconds)
	- At AQI 500: 500/150 = 3.33 HP/sec (100 HP lasts ~30 seconds)
	"""
	return max(0.1, aqi_current / 150.0)

func take_damage(amount: float) -> void:
	"""
	Take direct damage (e.g., from collision, obstacle).
	Ignores grace period intentionally for explicit damage sources.
	"""
	health -= amount
	health = clamp(health, 0, max_health)
	health_changed.emit(health)

	var logger = get_node_or_null("/root/Logger")
	if logger:
		logger.info(3, "Player took %.1f damage, health now: %.1f" % [amount, health])

	# Check for death
	if health <= 0:
		player_died.emit()

func restore_health(amount: float) -> void:
	"""Restore health (e.g., from mask activation, health pickup)"""
	health = min(health + amount, max_health)
	health_changed.emit(health)

	print("[PlayerHealth] Restored %.1f HP - now %.1f/%.1f" % [amount, health, max_health])

func set_aqi(aqi_value: float) -> void:
	"""Update current AQI value for drain calculation"""
	aqi_current = aqi_value

# === Public API for inspection ===

func get_health() -> float:
	"""Get current health"""
	return health

func get_max_health() -> float:
	"""Get maximum health"""
	return max_health

func is_alive() -> bool:
	"""Check if player is still alive"""
	return health > 0

func is_in_grace_period() -> bool:
	"""Check if player is in grace period"""
	return grace_period_active

func get_health_percentage() -> float:
	"""Get health as percentage (0.0 to 1.0)"""
	return health / max_health if max_health > 0 else 0.0
