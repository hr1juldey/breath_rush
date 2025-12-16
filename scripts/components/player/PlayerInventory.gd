extends Node
"""
PlayerInventory Component

Handles item management:
- Filter count (starts with 3, can pickup more)
- Sapling count (stackable, increases tree spawn probability)
- Drop filter via AQIManager
- Plant sapling via TreeSpawnManager

This component is extracted from Player.gd to isolate inventory system.
"""

# Signals
signal item_picked_up(item_type: String)
signal item_dropped(item_type: String)
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)
signal filter_count_changed(count: int)
signal sapling_count_changed(count: int)

# Inventory
var filter_count: int = 3  # Start with 3 filters
var sapling_count: int = 0

# Reference to player for position
var player_ref: Node = null

func _ready():
	print("[PlayerInventory] Component initialized - Filters: %d, Saplings: %d" % [filter_count, sapling_count])

func setup(player: Node) -> void:
	"""Setup reference to player"""
	player_ref = player
	print("[PlayerInventory] Setup complete - player: %s" % (player != null))

func pickup_filter() -> bool:
	"""
	Attempt to pickup a filter.
	Returns true if successful, adds to filter count.
	"""
	filter_count += 1
	item_picked_up.emit("filter")
	filter_count_changed.emit(filter_count)
	print("[PlayerInventory] Picked up filter - Total: %d" % filter_count)
	return true

func pickup_sapling() -> bool:
	"""
	Attempt to pickup a sapling.
	Returns true if successful, adds to sapling count.
	"""
	sapling_count += 1
	item_picked_up.emit("sapling")
	sapling_count_changed.emit(sapling_count)

	# Notify TreeSpawnManager about sapling collection
	var tree_manager = _get_tree_spawn_manager()
	if tree_manager:
		tree_manager.collect_sapling()

	print("[PlayerInventory] Picked up sapling - Total: %d" % sapling_count)
	return true

func drop_filter() -> bool:
	"""
	Drop/deploy a filter at player position.
	Returns true if filter was dropped, false if none remaining.

	Spawns visual Filter scene and creates AQISmokeSource for AQI reduction.
	Game should pause when this is called and resume when filter cleanup completes.
	"""
	if filter_count <= 0:
		print("[PlayerInventory] Cannot drop filter - none remaining")
		return false

	# Get player position
	var pos = player_ref.global_position if player_ref else Vector2.ZERO

	# Get AQIManager and request filter drop (creates AQISmokeSource)
	var aqi_manager = _get_aqi_manager()
	if aqi_manager:
		var aqi_filter = aqi_manager.drop_filter()
		if not aqi_filter:
			print("[PlayerInventory] Failed to create AQI filter source")
			return false
	else:
		print("[PlayerInventory] Warning: AQIManager not available for filter drop")

	# Spawn visual Filter scene at player position
	var filter_scene = load("res://scenes/Filter.tscn")
	if filter_scene:
		var filter_visual = filter_scene.instantiate()
		filter_visual.global_position = pos

		# Add to world (parent of player)
		var world = player_ref.get_parent() if player_ref else null
		if world:
			world.add_child(filter_visual)
			print("[PlayerInventory] Filter visual spawned at (%.0f, %.0f)" % [pos.x, pos.y])

			# Connect cleanup completion signal to allow game resume
			filter_visual.cleanup_complete.connect(func():
				print("[PlayerInventory] Filter cleanup complete - game can resume")
			)
		else:
			print("[PlayerInventory] Warning: Could not find world parent for filter visual")
	else:
		print("[PlayerInventory] Warning: Could not load Filter.tscn")

	# Update inventory and emit signals
	filter_count -= 1
	item_dropped.emit("filter")
	filter_count_changed.emit(filter_count)
	purifier_deployed.emit(pos.x, pos.y)

	print("[PlayerInventory] Deployed filter - Remaining: %d" % filter_count)
	return true

func drop_sapling() -> bool:
	"""
	Plant a sapling (rarely used in game, but available).
	Returns true if sapling was planted, false if none remaining.
	"""
	if sapling_count <= 0:
		print("[PlayerInventory] Cannot plant sapling - none remaining")
		return false

	sapling_count -= 1
	item_dropped.emit("sapling")
	sapling_count_changed.emit(sapling_count)

	# Get player position for signal
	var pos = player_ref.global_position if player_ref else Vector2.ZERO
	sapling_planted.emit(pos.x, pos.y)

	print("[PlayerInventory] Planted sapling - Remaining: %d" % sapling_count)
	return true

# === Public API for inspection ===

func get_filter_count() -> int:
	"""Get number of filters remaining"""
	return filter_count

func get_sapling_count() -> int:
	"""Get number of saplings collected"""
	return sapling_count

func can_drop_filter() -> bool:
	"""Check if player can drop a filter"""
	return filter_count > 0

func can_drop_sapling() -> bool:
	"""Check if player can plant a sapling"""
	return sapling_count > 0

# === Helper Methods ===

func _get_aqi_manager() -> Node:
	"""Get AQIManager from main scene"""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("AQIManager")

	# Fallback to group
	var managers = get_tree().get_nodes_in_group("aqi_manager")
	return managers[0] if managers.size() > 0 else null

func _get_tree_spawn_manager() -> Node:
	"""Get TreeSpawnManager from main scene"""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("TreeSpawnManager")

	# Fallback to group
	var managers = get_tree().get_nodes_in_group("tree_spawn_manager")
	return managers[0] if managers.size() > 0 else null
