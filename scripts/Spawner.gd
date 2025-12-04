extends Node2D

var obstacle_scene = preload("res://scenes/Obstacle.tscn")
var mask_scene = preload("res://scenes/Mask.tscn")
var purifier_scene = preload("res://scenes/Purifier.tscn")
var sapling_scene = preload("res://scenes/Sapling.tscn")

var obstacle_pool = []
var pickup_pool = []
var pool_size_obstacles = 8
var pool_size_pickups = 6
var spawn_speed = 400.0

var current_chunk_data = null
var spawn_index = 0
var time_accumulated = 0.0

func _ready():
	# Pre-instantiate obstacle pool
	for i in range(pool_size_obstacles):
		var obstacle = obstacle_scene.instantiate()
		obstacle.visible = false
		add_child(obstacle)
		obstacle_pool.append(obstacle)

	# Pre-instantiate pickup pool
	for i in range(pool_size_pickups):
		var pickup = mask_scene.instantiate()  # Default to mask
		pickup.visible = false
		add_child(pickup)
		pickup_pool.append(pickup)

func _process(delta):
	time_accumulated += delta

	if current_chunk_data and spawn_index < current_chunk_data.get("spawn_points", []).size():
		process_spawns()

func process_spawns() -> void:
	if not current_chunk_data:
		return

	var spawn_points = current_chunk_data.get("spawn_points", [])

	for spawn_point in spawn_points:
		var delay = spawn_point.get("delay", 0.0)
		if time_accumulated >= delay and not spawn_point.get("spawned", false):
			spawn_obstacle(spawn_point)
			spawn_point["spawned"] = true
			spawn_index += 1

func spawn_obstacle(spawn_data: Dictionary) -> void:
	var obstacle = get_pooled_obstacle()
	if obstacle:
		var spawn_x = spawn_data.get("x", 960)
		var spawn_y = spawn_data.get("y", 300)
		var obstacle_type = spawn_data.get("type", "car")

		obstacle.global_position = Vector2(spawn_x, spawn_y)
		obstacle.obstacle_type = obstacle_type
		obstacle.visible = true

func spawn_pickup(pickup_data: Dictionary) -> void:
	var pickup = get_pooled_pickup()
	if pickup:
		var spawn_x = pickup_data.get("x", 960)
		var spawn_y = pickup_data.get("y", 300)
		var pickup_type = pickup_data.get("type", "mask")

		pickup.global_position = Vector2(spawn_x, spawn_y)
		pickup.pickup_type = pickup_type
		pickup.visible = true

func get_pooled_obstacle() -> Node:
	for obstacle in obstacle_pool:
		if is_instance_valid(obstacle) and not obstacle.visible:
			return obstacle
	return null

func get_pooled_pickup() -> Node:
	for pickup in pickup_pool:
		if is_instance_valid(pickup) and not pickup.visible:
			return pickup
	return null

func return_to_pool(node: Node, is_obstacle: bool = true) -> void:
	node.visible = false
	if not is_obstacle and node in pickup_pool:
		node.global_position = Vector2(0, 0)

func set_current_chunk(chunk_data: Dictionary) -> void:
	current_chunk_data = chunk_data
	spawn_index = 0
	time_accumulated = 0.0

	# Spawn pickups from chunk data
	var pickup_points = chunk_data.get("pickup_points", [])
	for pickup_point in pickup_points:
		if randf() < pickup_point.get("probability", 0.5):
			spawn_pickup(pickup_point)

func clear_spawned_objects() -> void:
	for obstacle in obstacle_pool:
		if obstacle.visible:
			return_to_pool(obstacle, true)

	for pickup in pickup_pool:
		if pickup.visible:
			return_to_pool(pickup, false)
