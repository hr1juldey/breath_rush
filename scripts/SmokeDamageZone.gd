class_name SmokeDamageZone
extends Area2D

"""
Smoke Damage Zone - Detects player proximity to smoke and applies AQI effects

Attached to SmokeEmitter nodes on cars. Creates an invisible detection zone
that matches the particle visibility rect. When player enters without mask,
applies a +700 AQI smoke damage effect.
"""

var smoke_aqi_source: AQISmokeSource = null
var player_in_smoke: bool = false
var player_ref: Node = null
var damage_already_applied: bool = false

@export var base_aqi_effect: float = 700.0  # Sudden spike amount when entering smoke

func _ready():
	# Setup physics - detect player (CharacterBody2D on layer 1)
	collision_layer = 0  # Not on any layer (invisible to physics)
	collision_mask = 1   # Only detect player (layer 1)
	monitoring = true    # Enable body detection
	monitorable = false  # Don't let others detect us

	# Create collision shape matching particle visibility rect
	_setup_collision_shape()

	# Connect signals - use body_entered for CharacterBody2D (player)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	print("[SmokeDamageZone] Initialized - listening for player (body detection)")

func _setup_collision_shape() -> void:
	"""Create invisible collision area for smoke trail detection"""
	if get_child_count() > 0:
		return  # Already has collision shape

	# Create collision shape for smoke trail area
	# Smoke trails behind car (positive X direction in world space)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(800, 300)  # Reasonable smoke trail area

	collision.shape = shape
	collision.position = Vector2(400, 0)  # Offset behind car (smoke trails right)
	add_child(collision)

	print("[SmokeDamageZone] Collision shape: 800x300 at offset (400, 0)")

func _process(delta):
	if not player_in_smoke:
		return

	# Periodically check if mask status changed (in case mask expires while in smoke)
	_update_smoke_effect()

func _on_body_entered(body):
	"""Player entered smoke cloud - AQI ALWAYS spikes, mask only protects health"""
	if not (body.is_in_group("player") or body.name == "Player"):
		return

	# IMPORTANT: Only apply damage if the car is actually on screen (not in pool)
	var obstacle = _get_parent_obstacle()
	if not obstacle or not _is_obstacle_on_screen(obstacle):
		# Car is in pool or off-screen, ignore silently
		return

	player_in_smoke = true
	player_ref = body
	damage_already_applied = false

	# AQI ALWAYS increases when entering smoke (environmental pollution)
	_apply_smoke_aqi_spike()
	damage_already_applied = true

	# Mask protects HEALTH, but AQI still goes up
	if _player_has_smoke_protection():
		print("[SmokeDamageZone] Player entered smoke WITH MASK - AQI +%d (health protected)" % int(base_aqi_effect))
	else:
		# No mask = take health damage from smoke inhalation
		_apply_health_damage(body)
		print("[SmokeDamageZone] Player entered smoke WITHOUT MASK - AQI +%d + health damage!" % int(base_aqi_effect))

func _on_body_exited(body):
	"""Player exited smoke cloud"""
	if not (body.is_in_group("player") or body.name == "Player"):
		return

	player_in_smoke = false
	player_ref = null
	damage_already_applied = false

	print("[SmokeDamageZone] Player exited smoke")

func _update_smoke_effect() -> void:
	"""AQI spike was already applied on entry - no continuous effect needed"""
	# AQI spike is one-time on entry, no continuous damage
	# Mask status doesn't affect AQI, only health damage (handled elsewhere)
	pass

func _apply_smoke_aqi_spike() -> void:
	"""Apply sudden AQI spike when player enters smoke (ALWAYS, regardless of mask)"""
	var aqi_manager = _get_aqi_manager()
	if not aqi_manager:
		print("[SmokeDamageZone] ERROR: Cannot apply smoke spike - AQIManager not found")
		return

	# Apply sudden spike directly to current AQI
	# Smoke damage = +700 AQI (sudden increase)
	var damage_amount = base_aqi_effect
	aqi_manager.current_aqi = min(aqi_manager.max_aqi, aqi_manager.current_aqi + damage_amount)
	aqi_manager.aqi_changed.emit(aqi_manager.current_aqi, damage_amount)

	print("[SmokeDamageZone] ✗ SMOKE SPIKE: AQI jumped by +%.0f (now %.1f)" % [damage_amount, aqi_manager.current_aqi])

func _apply_health_damage(player: Node) -> void:
	"""Apply health damage when player enters smoke without mask"""
	if not player or not is_instance_valid(player):
		return

	# Check if player has take_damage method
	if player.has_method("take_damage"):
		var smoke_health_damage = 15.0  # Health damage from smoke inhalation
		player.take_damage(smoke_health_damage)
		print("[SmokeDamageZone] ✗ SMOKE HEALTH DAMAGE: Player took %.0f damage" % smoke_health_damage)

func _get_aqi_manager() -> Node:
	"""Get AQIManager reference"""
	# Try autoload first
	if Engine.has_singleton("AQIManager"):
		return Engine.get_singleton("AQIManager")
	# Fallback to group
	var managers = get_tree().get_nodes_in_group("aqi_manager")
	return managers[0] if managers.size() > 0 else null

func _apply_smoke_aqi_effect() -> void:
	"""Legacy: Create and register smoke AQI source (deprecated - use _apply_smoke_aqi_spike instead)"""
	if smoke_aqi_source != null and is_instance_valid(smoke_aqi_source):
		return  # Already applied

	# Safety check: ensure parent exists before adding child
	var parent = get_parent()
	if not parent or not is_instance_valid(parent):
		print("[SmokeDamageZone] ERROR: Cannot apply smoke effect - invalid parent")
		return

	smoke_aqi_source = AQISmokeSource.new()
	smoke_aqi_source.name = "SmokeDamage_%d" % randi()
	smoke_aqi_source.base_effect = base_aqi_effect

	# Add to parent (the car) so it gets properly grouped
	parent.add_child(smoke_aqi_source)
	print("[SmokeDamageZone] Smoke AQI source created and attached to parent")

func _remove_smoke_aqi_effect() -> void:
	"""Remove smoke AQI source when player leaves or gets mask protection"""
	if smoke_aqi_source == null or not is_instance_valid(smoke_aqi_source):
		return

	smoke_aqi_source.queue_free()
	smoke_aqi_source = null

func _player_has_smoke_protection() -> bool:
	"""
	Check if player is PROTECTED from smoke damage.
	Returns true ONLY if player is wearing a mask AND it's not leaking.
	Smoke damage applies when this returns false (no mask or mask leaking).
	"""
	if not player_ref or not is_instance_valid(player_ref):
		return false

	var mask_component = player_ref.get_node_or_null("PlayerMask")
	if not mask_component:
		return false  # No mask component = no protection = smoke damage applies

	# SMOKE PROTECTION: Both conditions must be true
	# 1. Player must be wearing a mask
	# 2. Mask must NOT be leaking
	# If either is false, smoke damage applies
	return mask_component.is_wearing_mask() and not mask_component.is_leaking()

func _get_parent_obstacle() -> Node:
	"""Get the Obstacle node that owns this smoke damage zone"""
	# SmokeDamageZone is child of SmokeEmitter, which is child of Obstacle
	var smoke_emitter = get_parent()
	if not smoke_emitter or not is_instance_valid(smoke_emitter):
		return null
	var obstacle = smoke_emitter.get_parent()
	if not obstacle or not is_instance_valid(obstacle):
		return null
	return obstacle

func _is_obstacle_on_screen(obstacle: Node) -> bool:
	"""Check if obstacle is actually on screen (not in pool at origin)"""
	if not obstacle or not is_instance_valid(obstacle):
		return false

	# Cars in pool are positioned at (0, 0) or off-screen left
	# Screen width is ~960px, cars spawn from right side (~1100+)
	# Valid on-screen range: roughly 100 to 1200 on X axis
	var pos_x = obstacle.global_position.x

	# If car is at origin (0,0) or very close, it's still in pool
	if pos_x < 50:
		return false

	# If car is way off screen to the left, it's despawning
	if pos_x < -500:
		return false

	# Car is on screen or spawning from right side
	return true
