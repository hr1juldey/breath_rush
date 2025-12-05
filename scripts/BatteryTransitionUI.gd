extends Node
"""
Battery Charge Transition Animation Manager

Manages battery display transitions with:
- Discharge: Blink (0.5s) + Crossfade (1.0s)
- Charge: Smooth crossfade (1.5s)
"""

# References
var charge_display: Sprite2D
var player_ref: Node

# Charge sprite paths (7 levels: 5, 4, 3, 2, 1, 0_red, empty)
const CHARGE_SPRITES = [
	"res://assets/ui/charge/charge_5_full.webp",      # Index 0
	"res://assets/ui/charge/charge_4_cells.webp",     # Index 1
	"res://assets/ui/charge/charge_3_cells.webp",     # Index 2
	"res://assets/ui/charge/charge_2_cells.webp",     # Index 3
	"res://assets/ui/charge/charge_1_cell.webp",      # Index 4
	"res://assets/ui/charge/charge_0_red.webp",       # Index 5 (critical)
	"res://assets/ui/charge/charge_empty.webp",       # Index 6
]

# Transition timing (matching Python prototype)
const BLINK_DURATION = 0.5      # Blink phase (discharge only)
const FADE_DURATION = 1.0       # Fade phase (both directions)
const TOTAL_TRANSITION = 1.5    # Total transition time
const BREATHING_PERIOD = 3.0    # Match lung breathing period

# State
var current_charge_level = 0    # Array index (0-6)
var shader_material: ShaderMaterial
var active_tween: Tween = null

func _ready():
	print("[BatteryTransitionUI] Initializing...")

	# Find charge display reference
	var parent = get_parent()
	if parent:
		charge_display = parent.find_child("ChargeDisplay")
		print("[BatteryTransitionUI] Parent: ", parent.name)
		print("[BatteryTransitionUI] ChargeDisplay found: ", charge_display != null)

	if not charge_display:
		push_error("[BatteryTransitionUI] ERROR: Could not find ChargeDisplay sprite")
		return

	# Set initial texture FIRST (so sprite has size/bounds for rendering)
	var initial_texture = load(CHARGE_SPRITES[0])
	charge_display.texture = initial_texture
	print("[BatteryTransitionUI] Initial texture set: ", CHARGE_SPRITES[0])

	# Create shader material
	var shader = load("res://assets/shaders/battery_crossfade.gdshader")
	if not shader:
		push_error("[BatteryTransitionUI] ERROR: Could not load battery_crossfade.gdshader")
		return

	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	print("[BatteryTransitionUI] Shader loaded and material created")

	# Set initial shader parameters
	shader_material.set_shader_parameter("current_texture", initial_texture)
	shader_material.set_shader_parameter("next_texture", initial_texture)
	shader_material.set_shader_parameter("crossfade_weight", 0.0)
	shader_material.set_shader_parameter("blink_alpha", 1.0)
	print("[BatteryTransitionUI] Shader parameters initialized")

	# Apply shader material AFTER texture is set
	charge_display.material = shader_material
	print("[BatteryTransitionUI] Shader material applied to ChargeDisplay")

	# Update current level tracking
	current_charge_level = 0

	print("[BatteryTransitionUI] Initialization complete")

func setup_player_reference(player: Node) -> void:
	"""Setup player reference and connect battery signal"""
	print("[BatteryTransitionUI] setup_player_reference called with: ", player)
	player_ref = player

	if player_ref:
		player_ref.battery_changed.connect(_on_battery_changed)
		print("[BatteryTransitionUI] ✓ Connected to player battery_changed signal")

		# Initialize with current battery from battery component
		if player_ref.battery:
			var current_battery = player_ref.battery.battery
			var battery_percent = (current_battery / player_ref.battery.max_battery) * 100.0
			print("[BatteryTransitionUI] Initializing with current battery: ", battery_percent, "%")
			_on_battery_changed(battery_percent)
	else:
		push_warning("[BatteryTransitionUI] WARNING: setup_player_reference called with null player")

func _on_battery_changed(new_battery: float) -> void:
	"""Called when player battery changes"""
	# TEMP: Silenced for mask pickup debugging
	#print("[BatteryTransitionUI] ━━━ Battery changed: ", new_battery, "% ━━━")

	# Map battery percentage to charge level (0-6)
	var new_level = _get_charge_level(new_battery)
	var level_names = ["5 full", "4 cells", "3 cells", "2 cells", "1 cell", "0 red", "empty"]
	#print("[BatteryTransitionUI] Mapped to level: ", new_level, " (", level_names[new_level], ")")

	if new_level != current_charge_level:
		var direction = "DISCHARGE" if new_level > current_charge_level else "CHARGE"
		print("[BatteryTransitionUI] Level changed: ", current_charge_level, " → ", new_level, " (", direction, ")")

		_start_transition(current_charge_level, new_level, direction)
	#else:
		#print("[BatteryTransitionUI] Level unchanged (still level ", new_level, ")")

func _get_charge_level(battery_percent: float) -> int:
	"""Map battery percentage to charge level (array index 0-6)"""
	if battery_percent >= 90: return 0    # 5 cells (full)
	elif battery_percent >= 70: return 1  # 4 cells
	elif battery_percent >= 50: return 2  # 3 cells
	elif battery_percent >= 30: return 3  # 2 cells
	elif battery_percent >= 15: return 4  # 1 cell (green)
	elif battery_percent > 0: return 5    # 1 cell (red - critical)
	else: return 6                         # Empty

func _start_transition(from_level: int, to_level: int, direction: String) -> void:
	"""Start battery level transition animation"""
	print("[BatteryTransitionUI] Starting transition: ", from_level, "→", to_level, " (", direction, ")")

	# Kill existing tween
	if active_tween:
		active_tween.kill()
		print("[BatteryTransitionUI] Killed existing tween")

	# Load textures
	var from_texture = load(CHARGE_SPRITES[from_level])
	var to_texture = load(CHARGE_SPRITES[to_level])
	print("[BatteryTransitionUI]   - From texture: ", CHARGE_SPRITES[from_level])
	print("[BatteryTransitionUI]   - To texture: ", CHARGE_SPRITES[to_level])

	# Set shader textures
	shader_material.set_shader_parameter("current_texture", from_texture)
	shader_material.set_shader_parameter("next_texture", to_texture)

	# Reset shader parameters
	shader_material.set_shader_parameter("crossfade_weight", 0.0)
	shader_material.set_shader_parameter("blink_alpha", 1.0)

	# Create transition based on direction
	if direction == "DISCHARGE":
		_animate_discharge_transition()
	else:
		_animate_charge_transition()

	# Update current level
	current_charge_level = to_level

func _animate_discharge_transition() -> void:
	"""Discharge: Blink (0.5s) + Crossfade (1.0s)"""
	print("[BatteryTransitionUI] Animating DISCHARGE transition")
	active_tween = create_tween()

	# Phase 1: Blink (0.0-0.5s) - Use tween_method for sinusoidal blink
	var blink_tween = create_tween()
	blink_tween.tween_method(_update_blink_alpha, 0.0, BLINK_DURATION, BLINK_DURATION)

	# Phase 2: Crossfade (0.5-1.5s) - Fade current out, new in
	active_tween.tween_property(shader_material, "shader_parameter/crossfade_weight", 1.0, FADE_DURATION).set_delay(BLINK_DURATION)

	# When done, set stable state
	active_tween.finished.connect(_on_transition_finished)

func _animate_charge_transition() -> void:
	"""Charge: Smooth crossfade (1.5s)"""
	print("[BatteryTransitionUI] Animating CHARGE transition")
	active_tween = create_tween()

	# No blink for charging - just smooth crossfade
	shader_material.set_shader_parameter("blink_alpha", 1.0)

	# Crossfade from old to new
	active_tween.tween_property(shader_material, "shader_parameter/crossfade_weight", 1.0, TOTAL_TRANSITION)

	# When done, set stable state
	active_tween.finished.connect(_on_transition_finished)

func _update_blink_alpha(time: float) -> void:
	"""Update blink alpha with sinusoidal oscillation (matches breathing)"""
	# Sinusoidal oscillation matching 3-second breathing period
	var scaled_time = time * (BREATHING_PERIOD / BLINK_DURATION)
	var alpha = (sin(scaled_time * 2.0 * PI / BREATHING_PERIOD) + 1.0) / 2.0
	# Map from 0-1 to 0.3-1.0 range
	alpha = 0.3 + alpha * 0.7

	shader_material.set_shader_parameter("blink_alpha", alpha)

func _on_transition_finished() -> void:
	"""Transition complete - set stable state"""
	print("[BatteryTransitionUI] Transition finished, setting stable state")
	_set_stable_level(current_charge_level)

func _set_stable_level(level: int) -> void:
	"""Set stable battery level (no transition)"""
	var texture = load(CHARGE_SPRITES[level])

	# Set sprite's base texture (needed for rendering)
	charge_display.texture = texture

	# Set both shader textures to same (no crossfade)
	shader_material.set_shader_parameter("current_texture", texture)
	shader_material.set_shader_parameter("next_texture", texture)
	shader_material.set_shader_parameter("crossfade_weight", 0.0)
	shader_material.set_shader_parameter("blink_alpha", 1.0)

	var level_names = ["5 full", "4 cells", "3 cells", "2 cells", "1 cell", "0 red", "empty"]
	print("[BatteryTransitionUI] ✓ Stable level set: ", level, " (", level_names[level], ")")
