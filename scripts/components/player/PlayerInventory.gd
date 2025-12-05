extends Node
"""
PlayerInventory Component

Handles ONLY item carrying functionality:
- Carried item tracking (filter, sapling)
- Item pickup
- Item drop/deployment
- Deployment signals (purifier, sapling)

This component is extracted from Player.gd to isolate inventory system.
"""

# Signals
signal item_picked_up(item_type: String)
signal item_dropped(item_type: String)
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)

# Inventory
var carried_item: String = ""  # "filter", "sapling", or empty
var item_count = 0

# Reference to player for position
var player_ref: Node = null

func _ready():
	print("[PlayerInventory] Component initialized")

func setup(player: Node) -> void:
	"""Setup reference to player"""
	player_ref = player
	print("[PlayerInventory] Setup complete - player: %s" % (player != null))

func pickup_filter() -> bool:
	"""
	Attempt to pickup a filter.
	Returns true if successful, false if already carrying something.
	"""
	if carried_item == "":
		carried_item = "filter"
		item_count = 1
		item_picked_up.emit("filter")
		print("[PlayerInventory] Picked up filter")
		return true
	else:
		print("[PlayerInventory] Cannot pick up filter - already carrying %s" % carried_item)
		return false

func pickup_sapling() -> bool:
	"""
	Attempt to pickup a sapling.
	Returns true if successful, false if already carrying something.
	"""
	if carried_item == "":
		carried_item = "sapling"
		item_count = 1
		item_picked_up.emit("sapling")
		print("[PlayerInventory] Picked up sapling")
		return true
	else:
		print("[PlayerInventory] Cannot pick up sapling - already carrying %s" % carried_item)
		return false

func drop_item() -> bool:
	"""
	Drop/deploy carried item.
	Returns true if item was dropped, false if no item carried.
	"""
	if carried_item == "":
		return false

	# Get player position for deployment
	var pos = player_ref.global_position if player_ref else Vector2.ZERO

	if carried_item == "filter":
		purifier_deployed.emit(pos.x, pos.y)
		print("[PlayerInventory] Deployed purifier at (%.1f, %.1f)" % [pos.x, pos.y])
	elif carried_item == "sapling":
		sapling_planted.emit(pos.x, pos.y)
		print("[PlayerInventory] Planted sapling at (%.1f, %.1f)" % [pos.x, pos.y])

	item_dropped.emit(carried_item)

	# Clear inventory
	var dropped_item = carried_item
	carried_item = ""
	item_count = 0

	return true

# === Public API for inspection ===

func get_carried_item() -> String:
	"""Get currently carried item type"""
	return carried_item

func is_carrying_item() -> bool:
	"""Check if player is carrying any item"""
	return carried_item != ""

func can_pickup_item() -> bool:
	"""Check if player can pick up another item"""
	return carried_item == ""
