extends Node
"""
Health Breathing Animation UI Manager

Manages the 2D health display with shader-based breathing animation.
Handles level transitions and updates shader uniforms based on player health.

Uses a simple 2-layer approach:
- Damage sprite: Shows which lungs are damaged
- Breathing sprite (masked): Shows breathing animation for healthy lungs
- Shader blends between them with sinusoidal oscillation
"""

# References
var lung_display: Sprite2D
var player_ref: Node

# Health damage and breathing sprite paths
const DAMAGE_SPRITES = [
	"res://assets/ui/health/damage/health_damage_0.webp",
	"res://assets/ui/health/damage/health_damage_1.webp",
	"res://assets/ui/health/damage/health_damage_2.webp",
	"res://assets/ui/health/damage/health_damage_3.webp",
	"res://assets/ui/health/damage/health_damage_4.webp",
	"res://assets/ui/health/damage/health_damage_5.webp",
]

const BREATHING_SPRITES = [
	"res://assets/ui/health/breathing_masked/health_breathing_0_masked.webp",
	"res://assets/ui/health/breathing_masked/health_breathing_1_masked.webp",
	"res://assets/ui/health/breathing_masked/health_breathing_2_masked.webp",
	"res://assets/ui/health/breathing_masked/health_breathing_3_masked.webp",
	"res://assets/ui/health/breathing_masked/health_breathing_4_masked.webp",
	"res://assets/ui/health/breathing_masked/health_breathing_5_masked.webp",
]

# Shader parameters
const BREATHING_PERIOD = 3.0
const BREATHING_STRENGTH = 0.6

# State
var current_health_level = 0
var shader_material: ShaderMaterial

func _ready():
	print("[HealthBreathingUI] Initializing...")

	# Find lung display reference
	var parent = get_parent()
	if parent:
		lung_display = parent.find_child("LungBase")
		print("[HealthBreathingUI] Parent: ", parent.name)
		print("[HealthBreathingUI] LungBase found: ", lung_display != null)

	if not lung_display:
		push_error("[HealthBreathingUI] ERROR: Could not find LungBase sprite")
		return

	# Create shader material
	var shader = load("res://assets/shaders/health_breathing.gdshader")
	if not shader:
		push_error("[HealthBreathingUI] ERROR: Could not load health_breathing.gdshader")
		return

	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	print("[HealthBreathingUI] Shader loaded and material created")

	# Apply shader material to lung display
	lung_display.material = shader_material
	print("[HealthBreathingUI] Shader material applied to LungBase")

	# Set initial uniforms
	_update_health_display(0)
	print("[HealthBreathingUI] Initialization complete")

func setup_player_reference(player: Node) -> void:
	"""Setup player reference and connect health signal. Called by HUD after instantiation."""
	print("[HealthBreathingUI] setup_player_reference called with: ", player)
	player_ref = player

	if player_ref:
		player_ref.health_changed.connect(_on_health_changed)
		print("[HealthBreathingUI] ✓ Connected to player health_changed signal")

		# Initialize with current health from health component
		if player_ref.health:
			var current_health = player_ref.health.health
			var health_percent = (current_health / player_ref.health.max_health) * 100.0
			print("[HealthBreathingUI] Initializing with current health: ", health_percent, "%")
			_on_health_changed(health_percent)
	else:
		push_warning("[HealthBreathingUI] WARNING: setup_player_reference called with null player")

func _on_health_changed(new_health: float) -> void:
	"""Called when player health changes"""
	# TEMP: Silenced for mask pickup debugging
	#print("[HealthBreathingUI] ━━━ Health changed: ", new_health, "% ━━━")

	# Map health percentage (0-100) to damage level (0-5)
	var health_level = _get_health_level(new_health)
	#print("[HealthBreathingUI] Mapped to level: ", health_level, " (", max(0, 5 - health_level), " healthy lungs)")

	if health_level != current_health_level:
		print("[HealthBreathingUI] Level changed: ", current_health_level, " → ", health_level)
		current_health_level = health_level
		_update_health_display(health_level)
	#else:
		#print("[HealthBreathingUI] Level unchanged (still level ", health_level, ")")

func _get_health_level(health_percent: float) -> int:
	"""
	Map health percentage to damage level.
	Level 0: 5 healthy lungs
	Level 5: all damaged/critical
	"""
	if health_percent > 80: return 0      # 5 healthy
	elif health_percent > 60: return 1    # 4 healthy, 1 damaged
	elif health_percent > 40: return 2    # 3 healthy, 2 damaged
	elif health_percent > 20: return 3    # 2 healthy, 3 damaged
	elif health_percent > 0: return 4     # 1 healthy, 4 damaged
	else: return 5                        # All damaged

func _update_health_display(level: int) -> void:
	"""Update shader uniforms and sprite texture for the new health level"""
	if not shader_material or not lung_display:
		push_warning("[HealthBreathingUI] Cannot update display: shader_material or lung_display is null")
		return

	# Clamp level to valid range
	level = clampi(level, 0, 5)
	print("[HealthBreathingUI] Updating display for level ", level)

	# Update sprite's base texture (damage sprite)
	var damage_sprite = load(DAMAGE_SPRITES[level])
	lung_display.texture = damage_sprite
	print("[HealthBreathingUI]   - Base texture: ", DAMAGE_SPRITES[level])

	# Update shader texture uniforms
	shader_material.set_shader_parameter("damage_texture", damage_sprite)
	print("[HealthBreathingUI]   - Shader damage_texture: ", DAMAGE_SPRITES[level])

	var breathing_sprite = load(BREATHING_SPRITES[level])
	shader_material.set_shader_parameter("breathing_texture", breathing_sprite)
	print("[HealthBreathingUI]   - Shader breathing_texture: ", BREATHING_SPRITES[level])

	# Update breathing animation parameters
	shader_material.set_shader_parameter("breathing_period", BREATHING_PERIOD)
	shader_material.set_shader_parameter("breathing_strength", BREATHING_STRENGTH)
	print("[HealthBreathingUI]   - Animation: period=", BREATHING_PERIOD, "s, strength=", BREATHING_STRENGTH)

	print("[HealthBreathingUI] ✓ Display updated: Level ", level, " (", max(0, 5 - level), " healthy lungs)")
