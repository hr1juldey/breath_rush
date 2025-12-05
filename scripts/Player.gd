extends CharacterBody2D
"""
Player Coordinator

This is the main player script that coordinates all player components.
It delegates functionality to specialized components and forwards signals.

Components:
- PlayerMovement: Lane switching, horizontal movement
- PlayerHealth: HP, grace period, AQI drain
- PlayerBattery: Battery, boost mechanics
- PlayerMask: Mask inventory, mask wearing
- PlayerInventory: Item carrying (filter, sapling)
- PlayerInput: Keyboard and touch input

Before refactoring: 335 lines with 13 responsibilities
After refactoring: ~120 lines coordination only
"""

# Component references (loaded from scene tree)
@onready var movement = $PlayerMovement
@onready var health = $PlayerHealth
@onready var battery = $PlayerBattery
@onready var mask_component = $PlayerMask
@onready var inventory = $PlayerInventory
@onready var input_handler = $PlayerInput

# Sprite references
@onready var mask_sprite = $MaskSprite

# Signals (forwarded from components)
signal health_changed(new_health: float)
signal battery_changed(new_battery: float)
signal mask_activated(duration: float)
signal mask_deactivated()
signal mask_inventory_changed(count: int)
signal item_picked_up(item_type: String)
signal item_dropped(item_type: String)
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)
signal boost_started()
signal boost_stopped()

# AQI tracking (shared across components)
var aqi_current = 250.0

func _ready():
	print("[Player] ========== Player Coordinator Initializing ==========")

	# Setup components with required references
	if movement:
		movement.setup(self)
		print("[Player] ✓ Movement component ready")

	if health:
		health.health_changed.connect(_on_health_changed)
		health.player_died.connect(_on_player_died)
		health.set_aqi(aqi_current)
		print("[Player] ✓ Health component ready")

	if battery:
		battery.battery_changed.connect(_on_battery_changed)
		battery.boost_started.connect(_on_boost_started)
		battery.boost_stopped.connect(_on_boost_stopped)
		print("[Player] ✓ Battery component ready")

	if mask_component:
		mask_component.setup(self, mask_sprite)
		mask_component.mask_activated.connect(_on_mask_activated)
		mask_component.mask_deactivated.connect(_on_mask_deactivated)
		mask_component.mask_inventory_changed.connect(_on_mask_inventory_changed)
		print("[Player] ✓ Mask component ready")

	if inventory:
		inventory.setup(self)
		inventory.item_picked_up.connect(_on_item_picked_up)
		inventory.item_dropped.connect(_on_item_dropped)
		inventory.purifier_deployed.connect(_on_purifier_deployed)
		inventory.sapling_planted.connect(_on_sapling_planted)
		print("[Player] ✓ Inventory component ready")

	if input_handler:
		input_handler.lane_change_requested.connect(_on_lane_change_requested)
		input_handler.boost_start_requested.connect(_on_boost_start_requested)
		input_handler.boost_stop_requested.connect(_on_boost_stop_requested)
		input_handler.mask_use_requested.connect(_on_mask_use_requested)
		input_handler.item_drop_requested.connect(_on_item_drop_requested)
		print("[Player] ✓ Input component ready")

	# Emit initial values
	health_changed.emit(health.get_health())
	battery_changed.emit(battery.get_battery())

	print("[Player] ========== All Components Initialized ==========")

	# Log initial state
	call_deferred("_log_initial_state")

func _process(delta: float) -> void:
	"""Coordinate all components"""
	# Periodic debug logging (every 60 frames = ~1 second at 60 FPS)
	if Engine.get_frames_drawn() % 60 == 0:
		_log_periodic_state()

	# Coordinate health drain (requires mask and health components)
	if health and mask_component:
		var has_mask = mask_component.is_wearing_mask()
		var leak_damage = mask_component.get_leak_damage(delta)
		health.process_health_drain(delta, has_mask, leak_damage)

	# Coordinate movement (requires movement and input components)
	if movement and input_handler:
		var h_input = input_handler.get_horizontal_input()
		movement.process_movement(delta, h_input)
		movement.apply_movement()

# === Component Signal Handlers (Forward to external listeners) ===

func _on_health_changed(value: float) -> void:
	health_changed.emit(value)

func _on_battery_changed(value: float) -> void:
	battery_changed.emit(value)

func _on_mask_activated(duration: float) -> void:
	mask_activated.emit(duration)
	_log_mask_activated(duration)

func _on_mask_deactivated() -> void:
	mask_deactivated.emit()
	_log_mask_deactivated()

func _on_mask_inventory_changed(count: int) -> void:
	mask_inventory_changed.emit(count)

func _on_item_picked_up(item_type: String) -> void:
	item_picked_up.emit(item_type)

func _on_item_dropped(item_type: String) -> void:
	item_dropped.emit(item_type)

func _on_purifier_deployed(x: float, y: float) -> void:
	purifier_deployed.emit(x, y)

func _on_sapling_planted(x: float, y: float) -> void:
	sapling_planted.emit(x, y)

func _on_boost_started() -> void:
	boost_started.emit()

func _on_boost_stopped() -> void:
	boost_stopped.emit()

func _on_player_died() -> void:
	print("[Player] Player died!")

# === Input Signal Handlers (Delegate to components) ===

func _on_lane_change_requested(direction: int) -> void:
	if movement:
		movement.change_lane(direction)

func _on_boost_start_requested() -> void:
	if battery:
		battery.start_boost()

func _on_boost_stop_requested() -> void:
	if battery:
		battery.stop_boost()

func _on_mask_use_requested() -> void:
	if mask_component:
		mask_component.use_mask_manually()

func _on_item_drop_requested() -> void:
	if inventory:
		inventory.drop_item()

# === Public API (Delegate to components) ===

func apply_mask() -> bool:
	"""Called by Pickup.gd when mask is collected"""
	if mask_component:
		return mask_component.apply_mask()
	return false

func restore_health(amount: float) -> void:
	"""Called by mask component when mask activates"""
	if health:
		health.restore_health(amount)

func pickup_filter() -> bool:
	"""Called by Pickup.gd when filter is collected"""
	if inventory:
		return inventory.pickup_filter()
	return false

func pickup_sapling() -> bool:
	"""Called by Pickup.gd when sapling is collected"""
	if inventory:
		return inventory.pickup_sapling()
	return false

func take_damage(amount: float) -> void:
	"""Called by obstacles when player collides"""
	if health:
		health.take_damage(amount)

func enter_charging_zone() -> void:
	"""Called by charging zones"""
	if battery:
		battery.enter_charging_zone()

func exit_charging_zone() -> void:
	"""Called by charging zones"""
	if battery:
		battery.exit_charging_zone()

func set_aqi(aqi_value: float) -> void:
	"""Update AQI for health drain calculation"""
	aqi_current = aqi_value
	if health:
		health.set_aqi(aqi_value)

# === Logging ===

func _log_initial_state() -> void:
	var logger = get_node_or_null("/root/Logger")
	if not logger or not movement:
		return
	logger.info(0, "Player initialized at Y:%.1f (Lane %d)" %
		[movement.get_position().y, movement.get_current_lane()])
	logger.info(0, "Health: %.1f | Battery: %.1f | AQI: %.1f" %
		[health.get_health(), battery.get_battery(), aqi_current])
	logger.log_object_state(0, self, "Player")

func _log_periodic_state() -> void:
	var logger = get_node_or_null("/root/Logger")
	if not logger or not movement or not health or not battery or not mask_component:
		return

	var pos = movement.get_global_position()
	var lane = movement.get_current_lane()
	var hp = health.get_health()
	var bat = battery.get_battery()
	var mask_time = mask_component.get_mask_time()
	var mask_inv = mask_component.get_inventory_count()

	logger.debug(0,
		"Pos:(%.1f,%.1f) Lane:%d HP:%.1f Bat:%.1f Mask:%.1fs Inv:%d AQI:%.1f" %
		[pos.x, pos.y, lane, hp, bat, mask_time, mask_inv, aqi_current])

func _log_mask_activated(duration: float) -> void:
	var logger = get_node_or_null("/root/Logger")
	if logger:
		logger.info(0, "Mask ACTIVATED - duration: %.1fs" % duration)

func _log_mask_deactivated() -> void:
	var logger = get_node_or_null("/root/Logger")
	if logger:
		logger.info(0, "Mask DEACTIVATED")
