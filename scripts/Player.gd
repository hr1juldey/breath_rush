extends CharacterBody2D

# Lane positions
var lane_positions = [240, 300, 360]
var current_lane = 1  # Middle lane by default
var target_y = lane_positions[current_lane]

# Health system
var health = 100.0
var max_health = 100.0
var base_drain_multiplier = 0.01666  # Health drain per second based on AQI

# Mask system
var mask_time = 0.0
var mask_duration = 15.0
var mask_hp_restore = 10
var mask_leak_time = 5.0
var mask_leak_rate = 1.0

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
signal item_picked_up(item_type: String)
signal item_dropped(item_type: String)
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)

var aqi_current = 250.0

func _ready():
	position.y = target_y
	health = max_health
	battery = max_battery
	health_changed.emit(health)
	battery_changed.emit(battery)

func _process(delta):
	# Update mask time
	if mask_time > 0:
		mask_time -= delta
		if mask_time <= 0:
			mask_time = 0
			mask_deactivated.emit()

	# Handle health drain
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
			is_boosting = false
		battery_changed.emit(battery)

	# Handle charging
	if charge_time > 0:
		charge_time -= delta
		if charge_time <= 0:
			battery = max_battery
			charge_time = 0
			battery_changed.emit(battery)

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
	if battery > 0:
		is_boosting = true

func stop_boost():
	is_boosting = false

func calculate_health_drain():
	return max(0.1, aqi_current / 60.0)

func apply_mask():
	health = min(health + mask_hp_restore, max_health)
	mask_time = mask_duration
	mask_activated.emit(mask_duration)
	health_changed.emit(health)

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
	health -= amount
	health = clamp(health, 0, max_health)
	health_changed.emit(health)

func set_aqi(aqi_value):
	aqi_current = aqi_value
