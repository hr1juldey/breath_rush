extends CharacterBody2D

# Lane positions
var lane_positions = [240, 300, 360]
var current_lane = 1  # Middle lane by default
var target_y = lane_positions[current_lane]

# Horizontal movement
var horizontal_speed = 200.0  # Pixels per second
var min_x = 100.0  # Minimum X position
var max_x = 860.0  # Maximum X position (960 - 100)

# Health system
var health = 100.0
var max_health = 100.0
var base_drain_multiplier = 0.01666  # Health drain per second based on AQI

# Mask system
var mask_time = 0.0
var mask_duration = 30.0  # Increased from 15 to 30 seconds
var mask_hp_restore = 10
var mask_leak_time = 5.0
var mask_leak_rate = 1.0
var mask_inventory = 0  # Number of masks in inventory
var max_mask_inventory = 5  # Maximum masks player can carry

# Battery & boost
var battery = 100.0
var max_battery = 100.0
var is_boosting = false
var boost_speed_mult = 1.35
var battery_drain_per_sec = 8.0
var charge_time = 0.0
var charge_seconds = 2.0

# Carrying items
var carried_item = null  # "filter", "sapling", or null
var item_count = 0

# Signals
signal health_changed(new_health: float)
signal battery_changed(new_battery: float)
signal mask_activated(duration: float)
signal mask_deactivated
signal mask_inventory_changed(count: int)
signal item_picked_up(item_type: String)
signal item_dropped(item_type: String)
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)
signal boost_started
signal boost_stopped

var aqi_current = 250.0

# Grace period before health decay starts
var grace_period = 2.0  # 2 seconds
var elapsed_time = 0.0
var grace_period_active = true

@onready var mask_sprite = $MaskSprite

func _ready():
	position.y = target_y
	health = max_health
	battery = max_battery
	health_changed.emit(health)
	battery_changed.emit(battery)

	# Ensure mask sprite is hidden initially
	if mask_sprite:
		mask_sprite.visible = false

	# Log initial state (Logger will be available after first frame)
	call_deferred("_log_initial_state")

func _process(delta):
	# Track elapsed time for grace period
	if grace_period_active:
		elapsed_time += delta
		if elapsed_time >= grace_period:
			grace_period_active = false
			var logger = get_node_or_null("/root/Logger")
			if logger:
				logger.info(0, "Grace period ended at %.2f seconds" % elapsed_time)

	# Periodic debug logging (every 60 frames = ~1 second at 60 FPS)
	if Engine.get_frames_drawn() % 60 == 0:
		_log_periodic_state()

	# Update mask time
	if mask_time > 0:
		mask_time -= delta
		if mask_time <= 0:
			mask_time = 0
			mask_deactivated.emit()
			_log_mask_deactivated()

			# Hide mask sprite
			if mask_sprite:
				mask_sprite.visible = false

	# Handle health drain (only after grace period)
	if not grace_period_active:
		var current_drain = calculate_health_drain()

		if mask_time > 0:
			# During mask, no drain, but add leak in last 5 seconds
			if mask_time < mask_leak_time:
				health -= mask_leak_rate * delta
		else:
			health -= current_drain * delta

		health = clamp(health, 0, max_health)
		health_changed.emit(health)

	# Handle battery drain while boosting
	if is_boosting:
		battery -= battery_drain_per_sec * delta
		if battery <= 0:
			battery = 0
			stop_boost()  # Use stop_boost() to emit signal
		battery_changed.emit(battery)

	# Handle charging
	if charge_time > 0:
		charge_time -= delta
		if charge_time <= 0:
			battery = max_battery
			charge_time = 0
			battery_changed.emit(battery)

	# Handle horizontal movement
	var horizontal_input = 0.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_L):
		horizontal_input = 1.0
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_H):
		horizontal_input = -1.0

	# Apply horizontal movement
	position.x += horizontal_input * horizontal_speed * delta
	position.x = clamp(position.x, min_x, max_x)

	# Lane interpolation
	position.y = lerp(position.y, float(target_y), 0.15)

	# Apply velocity for movement
	velocity.y = 0
	move_and_slide()

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_UP or event.keycode == KEY_W:
				change_lane(-1)
			elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
				change_lane(1)
			elif event.keycode == KEY_SPACE:
				start_boost()
			elif event.keycode == KEY_D:
				drop_item()
			elif event.keycode == KEY_M:
				use_mask_manually()
		else:
			# Key released
			if event.keycode == KEY_SPACE:
				stop_boost()

	if event is InputEventScreenTouch:
		if event.pressed:
			handle_touch(event.position)

func handle_touch(touch_pos):
	var screen_size = get_viewport_rect().size
	var half_width = screen_size.x / 2.0

	if touch_pos.x < half_width:
		# Left half - lane controls
		if touch_pos.y < screen_size.y / 2.0:
			change_lane(-1)
		else:
			change_lane(1)
	else:
		# Right half - boost or drop
		if touch_pos.y < screen_size.y * 0.75:
			start_boost()
		else:
			drop_item()

func change_lane(direction):
	current_lane = clamp(current_lane + direction, 0, lane_positions.size() - 1)
	target_y = lane_positions[current_lane]

func start_boost():
	if battery > 0 and not is_boosting:
		is_boosting = true
		boost_started.emit()

func stop_boost():
	if is_boosting:
		is_boosting = false
		boost_stopped.emit()

func calculate_health_drain():
	# Drain formula: AQI / 150 = HP per second
	# At AQI 250: 250/150 = 1.67 HP/sec (100 HP lasts ~60 seconds)
	# At AQI 500: 500/150 = 3.33 HP/sec (100 HP lasts ~30 seconds)
	return max(0.1, aqi_current / 150.0)

func apply_mask() -> bool:
	"""
	Attempt to apply/store a mask pickup.
	Returns true if mask was consumed (added to inventory or activated).
	Returns false if mask was rejected (inventory full).
	"""
	var logger = get_node_or_null("/root/Logger")

	# Debug: Log current state
	print("[Player] apply_mask() called - mask_time: %.1f, inventory: %d/5" % [mask_time, mask_inventory])

	# Check if inventory is full - reject pickup
	if mask_inventory >= max_mask_inventory:
		print("[Player] REJECTED - inventory full!")
		if logger:
			logger.warning(0, "Mask pickup REJECTED - inventory full (%d/5)" % mask_inventory)
		return false  # Reject - don't consume mask

	# If wearing mask OR have inventory - add to inventory
	if mask_time > 0 or mask_inventory > 0:
		print("[Player] Adding to inventory (wearing mask OR have inventory)")
		add_mask_to_inventory()
		print("[Player] After add - inventory: %d/5" % mask_inventory)
		if logger:
			logger.info(0, "Mask stored in inventory (%d/5)" % mask_inventory)
		return true  # Success

	# No active mask AND inventory empty - use immediately
	print("[Player] Activating immediately (no mask, empty inventory)")
	use_mask_from_inventory()
	if logger:
		logger.info(0, "Mask activated immediately")
	return true  # Success

func add_mask_to_inventory():
	if mask_inventory < max_mask_inventory:
		mask_inventory += 1
		mask_inventory_changed.emit(mask_inventory)

func use_mask_from_inventory():
	# Use mask (either from pickup or inventory)
	health = min(health + mask_hp_restore, max_health)
	mask_time = mask_duration
	mask_activated.emit(mask_duration)
	health_changed.emit(health)

	# Show mask sprite
	if mask_sprite:
		mask_sprite.visible = true

func use_mask_manually():
	# Player presses M to use mask from inventory
	if mask_time > 0:
		# Mask already active
		return

	if mask_inventory > 0:
		mask_inventory -= 1
		mask_inventory_changed.emit(mask_inventory)
		use_mask_from_inventory()

func pickup_filter():
	if carried_item == null:
		carried_item = "filter"
		item_count = 1
		item_picked_up.emit("filter")

func pickup_sapling():
	if carried_item == null:
		carried_item = "sapling"
		item_count = 1
		item_picked_up.emit("sapling")

func drop_item():
	if carried_item != null:
		if carried_item == "filter":
			purifier_deployed.emit(global_position.x, global_position.y)
		elif carried_item == "sapling":
			sapling_planted.emit(global_position.x, global_position.y)
		item_dropped.emit(carried_item)
		carried_item = null
		item_count = 0

func enter_charging_zone():
	charge_time = charge_seconds

func exit_charging_zone():
	charge_time = 0

func take_damage(amount):
	# Don't take damage during grace period
	if grace_period_active:
		return

	health -= amount
	health = clamp(health, 0, max_health)
	health_changed.emit(health)

	var logger = get_node_or_null("/root/Logger")
	if logger:
		logger.info(3, "Player took %.1f damage, health now: %.1f" % [amount, health])

func set_aqi(aqi_value):
	aqi_current = aqi_value

# Logging helper functions (deferred to avoid autoload timing issues)
func _log_initial_state():
	var logger = get_node_or_null("/root/Logger")
	if not logger:
		return
	logger.info(0, "Player initialized at Y:%.1f (Lane %d)" % [position.y, current_lane])  # 0 = PLAYER category
	logger.info(0, "Health: %.1f | Battery: %.1f | AQI: %.1f" % [health, battery, aqi_current])
	logger.log_object_state(0, self, "Player")

func _log_periodic_state():
	var logger = get_node_or_null("/root/Logger")
	if not logger:
		return
	logger.debug(0,  # 0 = PLAYER category
		"Pos:(%.1f,%.1f) Lane:%d Target:%.1f HP:%.1f Bat:%.1f AQI:%.1f" %
		[global_position.x, global_position.y, current_lane, target_y, health, battery, aqi_current])

func _log_mask_deactivated():
	var logger = get_node_or_null("/root/Logger")
	if not logger:
		return
	logger.info(0, "Mask DEACTIVATED")  # 0 = PLAYER category
