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

@export var base_aqi_effect: float = 700.0

func _ready():
	# Setup physics - only detect player on layer 1
	collision_layer = 0  # Not on any layer (invisible to physics)
	collision_mask = 1   # Only detect player (layer 1)

	# Create collision shape matching particle visibility rect
	_setup_collision_shape()

	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	print("[SmokeDamageZone] Initialized - listening for player proximity")

func _setup_collision_shape() -> void:
	"""Create invisible collision area matching particle bounds"""
	if get_child_count() > 0:
		return  # Already has collision shape

	# Particle visibility rect: Rect2(-5000, -1000, 10000, 2000)
	# Create collision shape to match
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(10000, 2000)  # Width x Height

	collision.shape = shape
	collision.position = Vector2(0, -500)  # Center vertically in rect
	add_child(collision)

func _process(delta):
	if not player_in_smoke:
		return

	# Periodically check if mask status changed (in case mask expires while in smoke)
	_update_smoke_effect()

func _on_area_entered(area):
	"""Player entered smoke cloud"""
	if not (area.is_in_group("player") or area.name == "Player"):
		return

	player_in_smoke = true
	player_ref = area

	if _player_has_smoke_protection():
		print("[SmokeDamageZone] Player entered smoke WITH MASK - no damage")
		return

	_apply_smoke_aqi_effect()
	print("[SmokeDamageZone] Player entered smoke WITHOUT MASK - applying +%d AQI" % int(base_aqi_effect))

func _on_area_exited(area):
	"""Player exited smoke cloud"""
	if not (area.is_in_group("player") or area.name == "Player"):
		return

	player_in_smoke = false
	player_ref = null

	_remove_smoke_aqi_effect()
	print("[SmokeDamageZone] Player exited smoke - stopping smoke damage")

func _update_smoke_effect() -> void:
	"""Check if mask status changed while player is in smoke"""
	if not player_ref or not is_instance_valid(player_ref):
		return

	var has_protection = _player_has_smoke_protection()
	var has_source = smoke_aqi_source != null and is_instance_valid(smoke_aqi_source)

	# Mask just became active - remove smoke source
	if has_protection and has_source:
		_remove_smoke_aqi_effect()
		print("[SmokeDamageZone] Mask activated while in smoke - removed smoke damage")
		return

	# Mask just expired - add smoke source
	if not has_protection and not has_source:
		_apply_smoke_aqi_effect()
		print("[SmokeDamageZone] Mask expired while in smoke - re-applying smoke damage")

func _apply_smoke_aqi_effect() -> void:
	"""Create and register smoke AQI source"""
	if smoke_aqi_source != null and is_instance_valid(smoke_aqi_source):
		return  # Already applied

	smoke_aqi_source = AQISmokeSource.new()
	smoke_aqi_source.name = "SmokeDamage_%d" % randi()
	smoke_aqi_source.base_effect = base_aqi_effect

	# Add to parent (the car) so it gets properly grouped
	get_parent().add_child(smoke_aqi_source)

func _remove_smoke_aqi_effect() -> void:
	"""Remove smoke AQI source when player leaves or gets mask protection"""
	if smoke_aqi_source == null or not is_instance_valid(smoke_aqi_source):
		return

	smoke_aqi_source.queue_free()
	smoke_aqi_source = null

func _player_has_smoke_protection() -> bool:
	"""Check if player has active mask protection (not leaking)"""
	if not player_ref or not is_instance_valid(player_ref):
		return false

	var mask_component = player_ref.get_node_or_null("PlayerMask")
	if not mask_component:
		return false

	# Must be wearing mask AND not in leak period
	return mask_component.is_wearing_mask() and not mask_component.is_leaking()
