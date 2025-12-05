extends Node
"""
PlayerMask Component

Handles ONLY mask-related functionality:
- Mask inventory (0-5 masks)
- Mask wearing (active timer)
- Mask activation/deactivation
- Mask pickup logic
- Mask leak mechanics

This component is extracted from Player.gd to isolate mask system
and eliminate bugs caused by complexity and coupling.
"""

# Signals
signal mask_activated(duration: float)
signal mask_deactivated()
signal mask_inventory_changed(count: int)

# Mask timer
var mask_time = 0.0
var mask_duration = 30.0
var mask_leak_time = 5.0
var mask_leak_rate = 1.0

# Mask inventory
var mask_inventory = 0
var max_mask_inventory = 5

# Mask effects
var mask_hp_restore = 10

# References (set by parent)
var player_ref: Node = null
var mask_sprite: Sprite2D = null

func _ready():
	print("[PlayerMask] Component initialized")

func setup(player: Node, sprite: Sprite2D) -> void:
	"""Setup references to player and mask sprite"""
	player_ref = player
	mask_sprite = sprite

	if mask_sprite:
		mask_sprite.visible = false

	print("[PlayerMask] Setup complete - player: %s, sprite: %s" % [player != null, sprite != null])

func _process(delta: float) -> void:
	"""Update mask timer"""
	if mask_time > 0:
		mask_time -= delta
		if mask_time <= 0:
			mask_time = 0
			deactivate_mask()

func apply_mask() -> bool:
	"""
	Attempt to apply/store a mask pickup.
	Returns true if mask was consumed (added to inventory or activated).
	Returns false if mask was rejected (inventory full).

	This is the MAIN ENTRY POINT for mask pickups from the world.
	"""
	var logger = get_node_or_null("/root/Logger")

	# Calculate total masks (wearing + inventory)
	var total_masks = mask_inventory
	if is_wearing_mask():
		total_masks += 1

	# Debug: Log current state with total count
	print("[PlayerMask] apply_mask() called - wearing=%s, inventory=%d/%d, total=%d" %
		[is_wearing_mask(), mask_inventory, max_mask_inventory, total_masks])

	# Check if TOTAL masks would exceed max - reject pickup
	if total_masks >= max_mask_inventory:
		print("[PlayerMask] REJECTED - at max capacity (%d total)" % total_masks)
		if logger:
			logger.warning(0, "Mask pickup REJECTED - at max capacity (%d total)" % total_masks)
		return false  # Reject - don't consume mask

	# If wearing mask OR have inventory - add to inventory
	if is_wearing_mask() or has_inventory():
		print("[PlayerMask] Adding to inventory (wearing mask OR have inventory)")
		add_to_inventory()
		print("[PlayerMask] After add - inventory: %d/%d" % [mask_inventory, max_mask_inventory])
		if logger:
			logger.info(0, "Mask stored in inventory (%d/%d)" % [mask_inventory, max_mask_inventory])
		return true  # Success

	# No active mask AND inventory empty - use immediately
	print("[PlayerMask] Activating immediately (no mask, empty inventory)")
	activate_mask()
	if logger:
		logger.info(0, "Mask activated immediately")
	return true  # Success

func is_wearing_mask() -> bool:
	"""Check if player is currently wearing a mask"""
	return mask_time > 0

func has_inventory() -> bool:
	"""Check if player has masks in inventory"""
	return mask_inventory > 0

func add_to_inventory() -> bool:
	"""Add a mask to inventory. Returns true if successful."""
	if mask_inventory < max_mask_inventory:
		mask_inventory += 1
		mask_inventory_changed.emit(mask_inventory)
		return true
	return false

func activate_mask() -> void:
	"""Activate a mask (restore health, start timer, show sprite)"""
	# Restore health (requires player reference)
	if player_ref and player_ref.has_method("restore_health"):
		player_ref.restore_health(mask_hp_restore)

	# Start mask timer
	mask_time = mask_duration
	mask_activated.emit(mask_duration)

	# Show mask sprite
	if mask_sprite:
		mask_sprite.visible = true

	print("[PlayerMask] Mask activated - duration: %.1fs" % mask_duration)

func deactivate_mask() -> void:
	"""Deactivate mask (hide sprite, emit signal)"""
	mask_deactivated.emit()

	# Hide mask sprite
	if mask_sprite:
		mask_sprite.visible = false

	print("[PlayerMask] Mask deactivated")

func use_mask_manually() -> void:
	"""Player manually uses mask from inventory (M key)"""
	# Can't use if already wearing mask
	if is_wearing_mask():
		print("[PlayerMask] Can't use - already wearing mask")
		return

	# Can't use if no inventory
	if mask_inventory <= 0:
		print("[PlayerMask] Can't use - no masks in inventory")
		return

	# Consume from inventory and activate
	mask_inventory -= 1
	mask_inventory_changed.emit(mask_inventory)
	activate_mask()

	var logger = get_node_or_null("/root/Logger")
	if logger:
		logger.info(0, "Mask manually activated from inventory (%d/%d remaining)" %
			[mask_inventory, max_mask_inventory])

func get_leak_damage(delta: float) -> float:
	"""Calculate leak damage during last 5 seconds of mask"""
	if is_wearing_mask() and mask_time < mask_leak_time:
		return mask_leak_rate * delta
	return 0.0

func is_leaking() -> bool:
	"""Check if mask is in leak phase (last 5 seconds)"""
	return is_wearing_mask() and mask_time < mask_leak_time

# === Public API for inspection ===

func get_mask_time() -> float:
	"""Get remaining mask time"""
	return mask_time

func get_inventory_count() -> int:
	"""Get current mask inventory count"""
	return mask_inventory

func get_max_inventory() -> int:
	"""Get maximum mask inventory capacity"""
	return max_mask_inventory

func is_inventory_full() -> bool:
	"""Check if mask inventory is full"""
	return mask_inventory >= max_mask_inventory
