extends CanvasLayer
# Charge display (battery)
@onready var charge_display = $TopLeft/ChargeDisplay

# Lung display (health) - base layer for damage state
@onready var lung_base = $TopRight/LungBase

# Lung display - breathing animation overlay
@onready var lung_breathing = $TopRight/LungBreathing

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

# Health sprite paths (6 damage states)
const HEALTH_DAMAGE_SPRITES = [
	"res://assets/ui/health/health_damage_0_healthy.webp",
	"res://assets/ui/health/health_damage_1.webp",
	"res://assets/ui/health/health_damage_2.webp",
	"res://assets/ui/health/health_damage_3.webp",
	"res://assets/ui/health/health_damage_4.webp",
	"res://assets/ui/health/health_damage_5_critical.webp"
]

# Breathing animation sprites (6 frames)
const HEALTH_BREATHING_SPRITES = [
	"res://assets/ui/health/health_breathing_0.webp",
	"res://assets/ui/health/health_breathing_1.webp",
	"res://assets/ui/health/health_breathing_2.webp",
	"res://assets/ui/health/health_breathing_3.webp",
	"res://assets/ui/health/health_breathing_4.webp",
	"res://assets/ui/health/health_breathing_5.webp"
]

# Breathing animation
var breathing_frame = 0
var breathing_timer = 0.0
const BREATHING_SPEED = 0.15  # seconds per frame

# Game state
var player_ref = null
var current_coins = 0

func _ready():
	# Setup charge display with initial state (100%)
	charge_display.texture = load(CHARGE_SPRITES[0])

	# Setup lung displays with initial state (5 healthy)
	lung_base.texture = load(HEALTH_DAMAGE_SPRITES[0])
	lung_breathing.texture = load(HEALTH_BREATHING_SPRITES[0])

	# Setup mask timer font
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	mask_timer_label.add_theme_font_override("font", font)
	mask_timer_label.add_theme_font_size_override("font_size", 12)

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

		# Initialize displays
		call_deferred("_initialize_displays")

func _process(delta):
	if player_ref:
		update_mask_timer()
		update_aqi_display()
		update_lung_animation(delta)

func _on_health_changed(new_health: float) -> void:
	update_lung_display(new_health)

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
func get_health_index(health_percent: float) -> int:
	"""Map health percentage to sprite index in HEALTH_DAMAGE_SPRITES"""
	if health_percent > 80: return 0     # 5 healthy lungs
	elif health_percent > 60: return 1   # 4 healthy, 1 damaged
	elif health_percent > 40: return 2   # 3 healthy, 2 damaged
	elif health_percent > 20: return 3   # 2 healthy, 3 damaged
	elif health_percent > 0: return 4    # 1 healthy, 4 damaged
	else: return 5                       # All damaged

func update_lung_display(health: float) -> void:
	"""Update lung display (damage state)"""
	var index = get_health_index(health)
	lung_base.texture = load(HEALTH_DAMAGE_SPRITES[index])

func update_lung_animation(delta: float) -> void:
	"""Animate breathing overlay by cycling through breathing frames"""
	breathing_timer += delta
	if breathing_timer >= BREATHING_SPEED:
		breathing_timer = 0.0
		breathing_frame = (breathing_frame + 1) % HEALTH_BREATHING_SPRITES.size()
		lung_breathing.texture = load(HEALTH_BREATHING_SPRITES[breathing_frame])

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
		_on_health_changed(player_ref.health)
		_on_battery_changed(player_ref.battery)
		update_mask_inventory_display(player_ref.mask_inventory)
