extends Area2D

var pickup_type = "mask"  # "mask", "filter", "sapling"
var scroll_speed = 400.0
var player_ref = null
var spawner_ref = null
var pickup_cooldown = 0.0  # Prevent immediate re-pickup after rejection
const COOLDOWN_TIME = 1.0  # 1 second cooldown after rejection

func _ready():
	body_entered.connect(_on_body_entered)
	# Find spawner reference
	call_deferred("_find_spawner")

func _find_spawner():
	spawner_ref = get_parent()

func _process(delta):
	if not visible:
		return

	# Handle pickup cooldown
	if pickup_cooldown > 0:
		pickup_cooldown -= delta

	# Manual overlap check (fallback for signal failures)
	if not player_ref and pickup_cooldown <= 0:
		var overlapping = get_overlapping_bodies()
		for body in overlapping:
			if body.is_in_group("player"):
				player_ref = body
				handle_pickup()
				break

	# Move pickup left with scroll speed
	position.x -= scroll_speed * delta

	# Check if off-screen (to be recycled)
	if position.x < -200:
		return_to_pool()

func _on_body_entered(body):
	# Defensive checks: ensure body is valid and is the player
	if not is_instance_valid(body):
		return

	if not body.is_in_group("player"):
		return

	player_ref = body
	handle_pickup()

func handle_pickup() -> void:
	# Defensive checks: prevent double-processing
	if not player_ref:
		print("[Pickup] BLOCKED - player_ref is null")
		return

	if not visible:
		print("[Pickup] BLOCKED - mask is invisible (visible=false)")
		return

	# Check cooldown (prevents immediate re-pickup after rejection)
	if pickup_cooldown > 0:
		print("[Pickup] Cooldown active (%.1fs remaining), skipping pickup" % pickup_cooldown)
		return

	# Validate player reference is still valid
	if not is_instance_valid(player_ref):
		print("[Pickup] Player reference invalid!")
		return

	print("[Pickup] Processing %s pickup..." % pickup_type)
	var pickup_success = false

	match pickup_type:
		"mask":
			pickup_success = player_ref.apply_mask()  # Returns true if consumed
			print("[Pickup] Mask pickup result: %s" % ("SUCCESS" if pickup_success else "REJECTED"))
		"filter":
			player_ref.pickup_filter()
			pickup_success = true
		"sapling":
			player_ref.pickup_sapling()
			pickup_success = true

	# Only consume pickup if it was successfully processed
	if pickup_success:
		print("[Pickup] Pickup successful, returning to pool")
		return_to_pool()
	else:
		# Pickup rejected (e.g., inventory full) - set cooldown
		pickup_cooldown = COOLDOWN_TIME
		print("[Pickup] Pickup rejected, cooldown set for %.1fs" % COOLDOWN_TIME)

func return_to_pool():
	if spawner_ref and is_instance_valid(spawner_ref):
		spawner_ref.return_to_pool(self)
	else:
		visible = false

func set_type(type: String) -> void:
	pickup_type = type

func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed
