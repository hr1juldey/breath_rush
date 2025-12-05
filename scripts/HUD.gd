extends CanvasLayer
# Charge display (battery)
@onready var charge_display = $TopLeft/ChargeDisplay

# Lung display (health) - shader-based breathing animation
@onready var lung_base = $TopRight/LungBase

# Health breathing animation manager (shader-based)
var health_breathing_ui: Node

# Mask timer
@onready var mask_timer_container = $CenterTop/MaskTimer
@onready var mask_timer_label = $CenterTop/MaskTimer/TimerLabel

# Bottom indicators
@onready var aqi_indicator = $BottomRight/AQIIndicator
@onready var mask_inventory_label = $BottomRight/MaskInventoryLabel
@onready var coins_label = $BottomRight/CoinsLabel

# Charge sprite paths (7 battery states)
const CHARGE_SPRITES = [
	"res://assets/ui/charge/charge_5_full.webp",      # 100%
	"res://assets/ui/charge/charge_4_cells.webp",     # 80%
	"res://assets/ui/charge/charge_3_cells.webp",     # 60%
	"res://assets/ui/charge/charge_2_cells.webp",     # 40%
	"res://assets/ui/charge/charge_1_cell.webp",      # 20% - 1 green cell
	"res://assets/ui/charge/charge_0_red.webp",       # Critical - 1 red cell
	"res://assets/ui/charge/charge_empty.webp",       # Empty
]

# Note: Health animation is now handled by shader in HealthBreathingUI
# No need to manually manage breathing frames

# Game state
var player_ref = null
var current_coins = 0

func _ready():
	print("[HUD] Initializing HUD...")

	# Setup charge display with initial state (100%)
	charge_display.texture = load(CHARGE_SPRITES[0])
	print("[HUD] Charge display initialized")

	# Setup mask timer font
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	mask_timer_label.add_theme_font_override("font", font)
	mask_timer_label.add_theme_font_size_override("font_size", 12)
	print("[HUD] Mask timer font configured")

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

	if player_ref:
		player_ref.battery_changed.connect(_on_battery_changed)
		player_ref.mask_activated.connect(_on_mask_activated)
		player_ref.mask_deactivated.connect(_on_mask_deactivated)
		player_ref.mask_inventory_changed.connect(_on_mask_inventory_changed)
		print("[HUD] Connected to player signals (battery, mask)")

		# Initialize displays
		call_deferred("_initialize_displays")

	print("[HUD] ✓ Initialization complete")

func _process(delta):
	if player_ref:
		update_mask_timer()
		update_aqi_display()
		# Lung animation now handled by shader in HealthBreathingUI

func _on_battery_changed(new_battery: float) -> void:
	update_charge_display(new_battery)

func _on_mask_activated(_duration: float) -> void:
	if mask_timer_container:
		mask_timer_container.show()

func _on_mask_deactivated() -> void:
	if mask_timer_container:
		mask_timer_container.hide()

# === CHARGE/BATTERY DISPLAY ===
func get_charge_index(battery_percent: float) -> int:
	"""Map battery percentage to sprite index in CHARGE_SPRITES"""
	if battery_percent >= 85: return 0    # 5 cells - Full
	elif battery_percent >= 65: return 1  # 4 cells
	elif battery_percent >= 45: return 2  # 3 cells
	elif battery_percent >= 25: return 3  # 2 cells
	elif battery_percent >= 10: return 4  # 1 green cell
	elif battery_percent > 0: return 5    # 1 red cell - Critical
	else: return 6                         # Empty

func update_charge_display(battery: float) -> void:
	"""Update charge display to show correct battery level"""
	var index = get_charge_index(battery)
	charge_display.texture = load(CHARGE_SPRITES[index])

# === LUNG/HEALTH DISPLAY ===
# Note: Health display is now handled by HealthBreathingUI with shader-based breathing animation
# No manual animation code needed - the shader handles sinusoidal breathing using TIME

# === MASK TIMER DISPLAY ===
func update_mask_timer() -> void:
	"""Update mask countdown timer text"""
	if player_ref and mask_timer_label:
		if player_ref.mask_time > 0:
			var seconds = int(ceil(player_ref.mask_time))
			mask_timer_label.text = "%d" % seconds
		else:
			if mask_timer_container:
				mask_timer_container.hide()

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
	if player_ref:
		_on_battery_changed(player_ref.battery)
		update_mask_inventory_display(player_ref.mask_inventory)
