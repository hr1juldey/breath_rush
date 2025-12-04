extends CanvasLayer
@onready var health_bar = $TopLeft/VBox/HealthBar
@onready var battery_bar = $TopLeft/VBox/BatteryBar
@onready var mask_inventory_label = $TopLeft/VBox/MaskInventoryLabel
@onready var mask_timer_container = $CenterOverlay/MaskTimer
@onready var mask_timer_label = $CenterOverlay/MaskTimer/MaskLabel
@onready var aqi_indicator = $TopRight/AQIIndicator
@onready var coins_label = $TopRight/CoinsLabel

var player_ref = null
var current_coins = 0

func _ready():
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

		# Initialize mask inventory display
		update_mask_inventory_display(player_ref.mask_inventory)

func _process(_delta):
	if player_ref:
		update_mask_timer()
		update_aqi_display()

func _on_health_changed(new_health: float) -> void:
	if health_bar:
		health_bar.value = new_health

func _on_battery_changed(new_battery: float) -> void:
	if battery_bar:
		battery_bar.value = new_battery

func _on_mask_activated(_duration: float) -> void:
	if mask_timer_container:
		mask_timer_container.show()

func _on_mask_deactivated() -> void:
	if mask_timer_container:
		mask_timer_container.hide()

func update_mask_timer() -> void:
	if player_ref and mask_timer_label:
		if player_ref.mask_time > 0:
			mask_timer_label.text = "Mask Active: %ds" % (int(player_ref.mask_time) + 1)
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
