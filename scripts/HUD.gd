extends CanvasLayer
# Charge display (battery)
@onready var charge_display = $TopLeft/ChargeDisplay

# Lung display (health) - shader-based breathing animation
@onready var lung_base = $TopRight/LungBase

# Health breathing animation manager (shader-based)
var health_breathing_ui: Node

# Battery transition animation manager (shader-based)
var battery_transition_ui: Node

# Mask timer UI manager (shader-based)
var mask_timer_ui: Node

# Mask timer (still needed for reference)
@onready var mask_timer_container = $CenterTop/MaskTimer
@onready var mask_timer_label = $CenterTop/MaskTimer/TimerLabel

# Bottom indicators
@onready var aqi_indicator = $BottomRight/AQIIndicator
@onready var mask_inventory_label = $BottomRight/MaskInventoryLabel
@onready var coins_label = $BottomRight/CoinsLabel

# Note: Health animation handled by HealthBreathingUI (shader-based)
# Note: Battery animation handled by BatteryTransitionUI (shader-based)

# Game state
var player_ref = null
var current_coins = 0

func _ready():
	print("[HUD] Initializing HUD...")

	# Find player reference
	var parent = get_parent()
	print("[HUD] Parent scene: ", parent.name if parent else "null")
	if parent:
		player_ref = parent.find_child("Player")
		print("[HUD] Player reference found: ", player_ref != null)
		if player_ref:
			print("[HUD] Player node: ", player_ref.name)

	# Create and add health breathing UI (shader-based)
	health_breathing_ui = load("res://scripts/HealthBreathingUI.gd").new()
	add_child(health_breathing_ui)
	print("[HUD] HealthBreathingUI created and added as child")

	# Setup player reference for health breathing UI
	if player_ref:
		print("[HUD] Passing player reference to HealthBreathingUI...")
		health_breathing_ui.setup_player_reference(player_ref)
	else:
		push_warning("[HUD] WARNING: No player reference found!")

	# Create and add battery transition UI (shader-based)
	battery_transition_ui = load("res://scripts/BatteryTransitionUI.gd").new()
	add_child(battery_transition_ui)
	print("[HUD] BatteryTransitionUI created and added as child")

	# Setup player reference for battery transition UI
	if player_ref:
		print("[HUD] Passing player reference to BatteryTransitionUI...")
		battery_transition_ui.setup_player_reference(player_ref)

	# Create and add mask timer UI (shader-based)
	mask_timer_ui = load("res://scripts/MaskTimerUI.gd").new()
	add_child(mask_timer_ui)
	print("[HUD] MaskTimerUI created and added as child")

	# Setup player reference for mask timer UI
	if player_ref:
		print("[HUD] Passing player reference to MaskTimerUI...")
		mask_timer_ui.setup_player_reference(player_ref)

	if player_ref:
		player_ref.mask_activated.connect(_on_mask_activated)
		player_ref.mask_deactivated.connect(_on_mask_deactivated)
		player_ref.mask_inventory_changed.connect(_on_mask_inventory_changed)
		print("[HUD] Connected to player signals (battery, mask)")

		# Initialize displays
		call_deferred("_initialize_displays")

	print("[HUD] ✓ Initialization complete")

func _process(delta):
	if player_ref:
		update_aqi_display()
		# Lung animation now handled by shader in HealthBreathingUI
		# Mask timer now handled by MaskTimerUI
		# Battery display now handled by BatteryTransitionUI

func _on_mask_activated(_duration: float) -> void:
	if mask_timer_container:
		mask_timer_container.show()

func _on_mask_deactivated() -> void:
	if mask_timer_container:
		mask_timer_container.hide()

# === CHARGE/BATTERY DISPLAY ===
# Battery display now handled by BatteryTransitionUI with shader-based crossfade animation
# No manual charge update code needed

# === LUNG/HEALTH DISPLAY ===
# Note: Health display is now handled by HealthBreathingUI with shader-based breathing animation
# No manual animation code needed - the shader handles sinusoidal breathing using TIME

# === MASK TIMER DISPLAY ===
# Mask timer display now handled by MaskTimerUI with shader-based urgency effects

# === AQI DISPLAY ===
func update_aqi_display() -> void:
	"""Update AQI indicator with current air quality"""
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

# === COINS/CURRENCY ===
func add_coins(amount: int) -> void:
	"""Add coins to the player's total"""
	current_coins += amount
	update_coin_display()

func update_coin_display() -> void:
	"""Update coin display label"""
	if coins_label:
		coins_label.text = "AIR: %d" % current_coins

func reset_coins() -> void:
	"""Reset coin count to zero"""
	current_coins = 0
	update_coin_display()

func get_coins_earned() -> int:
	"""Get total coins earned this session"""
	return current_coins

# === MASK INVENTORY ===
func _on_mask_inventory_changed(count: int) -> void:
	"""Handle mask inventory changes"""
	update_mask_inventory_display(count)

func update_mask_inventory_display(count: int) -> void:
	"""Update mask inventory label"""
	if mask_inventory_label:
		mask_inventory_label.text = "Masks: %d/5" % count

# === INITIALIZATION ===
func _initialize_displays() -> void:
	"""Initialize all displays with current player values"""
	if player_ref and player_ref.mask_component:
		update_mask_inventory_display(player_ref.mask_component.get_inventory_count())
