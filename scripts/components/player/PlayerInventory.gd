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

func drop_item() -> bool:
	"""
	Drop the current item (filter).
	Called when D key is pressed.
	"""
	return drop_filter()

func drop_filter() -> bool:
	"""
	Drop/deploy a filter at player position.
	Returns true if filter was dropped, false if none remaining.

	Spawns visual Filter scene with world slowdown like EV charger.
	- First 2 seconds: dirty air sucked into filter
	- Remaining 13 seconds: clean air emitted
	- AQI reduces during cleanup
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

	# Spawn visual Filter scene in FrontLayerSpawner (parallax layer) like EV charger
	var filter_scene = load("res://scenes/Filter.tscn")
	if not filter_scene:
		print("[PlayerInventory] Warning: Could not load Filter.tscn")
		return false

	var filter_visual = filter_scene.instantiate()

	# Place in front layer at fixed screen position (like buildings/EV charger)
	var game = _get_game()
	if not game:
		print("[PlayerInventory] Warning: Could not find Game node")
		return false

	var spawner = game.get_node_or_null("Spawner")
	if not spawner:
		print("[PlayerInventory] Warning: Could not find Spawner")
		return false

	var front_layer = spawner.get_node_or_null("FrontLayerSpawner")
	if not front_layer:
		print("[PlayerInventory] Warning: Could not find FrontLayerSpawner")
		return false

	# Position at right side of screen like EV charger
	# Screen width ~1152, place at x=1100 (off-screen right)
	# Vertical position on side like buildings (~Y=280)
	filter_visual.global_position = Vector2(1100, 280)

	front_layer.add_child(filter_visual)
	print("[PlayerInventory] Filter visual spawned in FrontLayerSpawner at (1100, 280)")

	# Start world slowdown (like EV charger)
	_start_filter_slowdown(filter_visual)

	# Update inventory and emit signals
	filter_count -= 1
	item_dropped.emit("filter")
	filter_count_changed.emit(filter_count)
	purifier_deployed.emit(pos.x, pos.y)

	print("[PlayerInventory] Deployed filter - Remaining: %d" % filter_count)
	return true

func _start_filter_slowdown(filter_visual: Node) -> void:
	"""Start world slowdown sequence for filter cleanup (like EV charger)"""
	var game = _get_game()
	if not game:
		print("[PlayerInventory] Warning: Could not find Game node for slowdown")
		return

	# Get spawner to stop car spawning
	var spawner = game.get_node_or_null("Spawner")

	# Phase 1: Slow down world (1 second)
	print("[PlayerInventory] FILTER: Slowing down world...")
	var tween = player_ref.create_tween()
	tween.tween_method(_set_world_speed.bind(game), game.scroll_speed, 0.0, 1.0)
	await tween.finished

	# Stop car spawning during filter cleanup
	if spawner:
		var obstacle_spawner = spawner.get_node_or_null("ObstacleSpawner")
		if obstacle_spawner:
			obstacle_spawner.set_process(false)
			print("[PlayerInventory] FILTER: Car spawning STOPPED")

	# World is now stopped
	game.world_paused = true
	print("[PlayerInventory] FILTER: World STOPPED - 15s cleanup starting")

	# Connect to filter cleanup completion
	filter_visual.cleanup_complete.connect(func():
		_resume_after_filter(game, spawner)
	)

func _resume_after_filter(game: Node, spawner: Node) -> void:
	"""Resume world after filter cleanup completes"""
	print("[PlayerInventory] FILTER: Cleanup complete - resuming world")

	# Resume car spawning
	if spawner:
		var obstacle_spawner = spawner.get_node_or_null("ObstacleSpawner")
		if obstacle_spawner:
			obstacle_spawner.set_process(true)
			print("[PlayerInventory] FILTER: Car spawning RESUMED")

	# Phase 2: Speed up world (1 second)
	var tween = player_ref.create_tween()
	tween.tween_method(_set_world_speed.bind(game), 0.0, game.base_scroll_speed, 1.0)
	await tween.finished

	game.world_paused = false
	print("[PlayerInventory] FILTER: World RESUMED at full speed")

func _set_world_speed(speed: float, game: Node) -> void:
	"""Set scroll speed for all world elements"""
	if "scroll_speed" in game:
		game.scroll_speed = speed

	# Update Road
	var road = game.get_node_or_null("Road")
	if road and road.has_method("set_scroll_speed"):
		road.set_scroll_speed(speed)

	# Update Spawner
	var spawner = game.get_node_or_null("Spawner")
	if spawner and spawner.has_method("set_scroll_speed"):
		spawner.set_scroll_speed(speed)

func _get_game() -> Node:
	"""Get Game (Main) node"""
	return get_tree().root.get_node_or_null("Main")

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
