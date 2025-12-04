extends CanvasLayer

# Health dots
@onready var health_dot1 = $TopLeft/MarginContainer/VBox/HealthDots/HealthDot1
@onready var health_dot2 = $TopLeft/MarginContainer/VBox/HealthDots/HealthDot2
@onready var health_dot3 = $TopLeft/MarginContainer/VBox/HealthDots/HealthDot3
@onready var health_dot4 = $TopLeft/MarginContainer/VBox/HealthDots/HealthDot4
@onready var health_dot5 = $TopLeft/MarginContainer/VBox/HealthDots/HealthDot5

# Lung icons
@onready var lung1_fill = $TopRight/MarginContainer/VBox/LungIcons/Lung1/Fill
@onready var lung2_fill = $TopRight/MarginContainer/VBox/LungIcons/Lung2/Fill
@onready var lung3_fill = $TopRight/MarginContainer/VBox/LungIcons/Lung3/Fill
@onready var lung4_fill = $TopRight/MarginContainer/VBox/LungIcons/Lung4/Fill
@onready var lung5_fill = $TopRight/MarginContainer/VBox/LungIcons/Lung5/Fill

# Mask timer
@onready var mask_timer_container = $CenterTop/MaskTimer
@onready var mask_time_label = $CenterTop/MaskTimer/MarginContainer/HBox/VBox/TimeLabel

# Bottom indicators
@onready var aqi_indicator = $BottomRight/AQIIndicator
@onready var mask_inventory_label = $BottomRight/MaskInventoryLabel
@onready var coins_label = $BottomRight/CoinsLabel

var player_ref = null
var current_coins = 0
var health_dots = []
var lung_fills = []

# Pulse animation
var pulse_time = 0.0
var pulse_speed = 2.0

func _ready():
	# Store references in arrays for easier management
	health_dots = [health_dot1, health_dot2, health_dot3, health_dot4, health_dot5]
	lung_fills = [lung1_fill, lung2_fill, lung3_fill, lung4_fill, lung5_fill]

	# Find player reference
	var parent = get_parent()
	if parent:
		player_ref = parent.find_child("Player")

	if player_ref:
		player_ref.health_changed.connect(_on_health_changed)
		player_ref.battery_changed.connect(_on_battery_changed)
		player_ref.mask_activated.connect(_on_mask_activated)
		player_ref.mask_deactivated.connect(_on_mask_deactivated)
		player_ref.mask_inventory_changed.connect(_on_mask_inventory_changed)

		# Initialize displays with current player values (deferred to ensure player is initialized)
		call_deferred("_initialize_displays")

func _process(delta):
	if player_ref:
		update_mask_timer()
		update_aqi_display()
		update_lung_pulse(delta)

func _on_health_changed(new_health: float) -> void:
	update_health_dots(new_health)
	update_lung_fills(new_health)

func _on_battery_changed(new_battery: float) -> void:
	# Battery is no longer displayed visually in the new HUD
	pass

func _on_mask_activated(_duration: float) -> void:
	if mask_timer_container:
		mask_timer_container.show()

func _on_mask_deactivated() -> void:
	if mask_timer_container:
		mask_timer_container.hide()

func update_health_dots(health: float) -> void:
	# Show/hide health dots based on health percentage
	# Each dot represents 20% health
	var dots_to_show = int(ceil(health / 20.0))

	for i in range(health_dots.size()):
		if health_dots[i]:
			if i < dots_to_show:
				health_dots[i].modulate = Color(0.2, 1.0, 0.3, 1.0)  # Green
			else:
				health_dots[i].modulate = Color(0.3, 0.3, 0.3, 0.4)  # Dimmed gray

func update_lung_fills(health: float) -> void:
	# Update lung fill opacity based on health
	# Each lung represents 20% health
	var health_percent = health / 100.0

	for i in range(lung_fills.size()):
		if lung_fills[i]:
			var lung_threshold = float(i) / 5.0
			if health_percent >= lung_threshold:
				# This lung should be visible
				var lung_alpha = clamp((health_percent - lung_threshold) * 5.0, 0.0, 1.0)
				lung_fills[i].modulate.a = lung_alpha
			else:
				lung_fills[i].modulate.a = 0.0

func update_lung_pulse(delta: float) -> void:
	if not player_ref:
		return

	# Create breathing/pulsing effect for lungs
	pulse_time += delta * pulse_speed
	var pulse_scale = 1.0 + sin(pulse_time) * 0.1  # Pulse between 0.9 and 1.1

	# Apply pulse to all visible lung fills
	var health_percent = player_ref.health / 100.0
	for i in range(lung_fills.size()):
		if lung_fills[i] and lung_fills[i].modulate.a > 0.0:
			lung_fills[i].scale = Vector2(pulse_scale, pulse_scale)

func update_mask_timer() -> void:
	if player_ref and mask_time_label:
		if player_ref.mask_time > 0:
			var seconds_remaining = int(player_ref.mask_time) + 1
			mask_time_label.text = "%d sec remaining..." % seconds_remaining
		else:
			if mask_timer_container:
				mask_timer_container.hide()

func update_aqi_display() -> void:
	if not aqi_indicator or not player_ref:
		return

	var aqi = int(player_ref.aqi_current)
	var aqi_text = "AQI %d" % aqi
	var color = Color.RED

	if aqi <= 50:
		aqi_text += " - Good"
		color = Color.GREEN
	elif aqi <= 100:
		aqi_text += " - Fair"
		color = Color.YELLOW
	elif aqi <= 200:
		aqi_text += " - Poor"
		color = Color.ORANGE
	else:
		aqi_text += " - Hazardous"
		color = Color.RED

	aqi_indicator.text = aqi_text
	aqi_indicator.modulate = color

func add_coins(amount: int) -> void:
	current_coins += amount
	update_coin_display()

func update_coin_display() -> void:
	if coins_label:
		coins_label.text = "AIR: %d" % current_coins

func reset_coins() -> void:
	current_coins = 0
	update_coin_display()

func get_coins_earned() -> int:
	return current_coins

func _on_mask_inventory_changed(count: int) -> void:
	update_mask_inventory_display(count)

func update_mask_inventory_display(count: int) -> void:
	if mask_inventory_label:
		mask_inventory_label.text = "Masks: %d/5" % count

func _initialize_displays() -> void:
	if player_ref:
		_on_health_changed(player_ref.health)
		_on_battery_changed(player_ref.battery)
		update_mask_inventory_display(player_ref.mask_inventory)
