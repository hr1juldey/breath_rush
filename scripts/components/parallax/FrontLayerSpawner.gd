extends "res://scripts/components/parallax/ParallaxLayerSpawner.gd"
class_name FrontLayerSpawner

## Spawns foreground elements: trees, fruit stalls
## Largest scale, fastest movement (motion_scale 0.9)
## Trees are integrated with AQI system

# Tree type configs for quick lookup
var tree_configs: Dictionary = {}
var non_tree_configs: Array[Dictionary] = []

func _ready():
	# Front layer settings - trees/decorations sit on horizon
	pool_size = 6
	spawn_interval_min = 2.5
	spawn_interval_max = 5.0
	y_variance = 1.0
	base_scale = 0.25
	scale_variance = 0.03
	despawn_x = -400.0 # Well off-screen left
	spawn_x = 2000.0 # Well off-screen right
	motion_scale = 0.9
	layer_y_offset = -30.0 # Front layer too low - move up

	# Load textures with region and scale data from ParallaxScalingEditor
	texture_configs = [
		{
			"texture": preload("res://assets/parallax/tree_1.webp"),
			"region": Rect2(224, 80, 744, 1008),
			"scale": 0.1889,
			"y_offset": - 75.0, # Tree1 50% under - move up significantly
			"type": "tree_1"
		},
		{
			"texture": preload("res://assets/parallax/tree_2.webp"),
			"region": Rect2(232, 144, 712, 888),
			"scale": 0.2483,
			"y_offset": - 70.0, # Tree2 halfway under - move up significantly
			"type": "tree_2"
		},
		{
			"texture": preload("res://assets/parallax/tree_3.webp"),
			"region": Rect2(0, 0, 1200, 1077),
			"scale": 0.3428,
			"y_offset": 20.0, # Tree sinking - move up
			"type": "tree_3"
		},
		{
			"texture": preload("res://assets/parallax/fruit_stall.webp"),
			"region": Rect2(0, 40, 1200, 1120),
			"scale": 0.145,
			"y_offset": - 95.0,
			"type": "fruit_stall"
		},
		{
			"texture": preload("res://assets/parallax/billboard.webp"),
			"region": Rect2(240, 112, 712, 960),
			"scale": 0.15,
			"y_offset": - 110.0,
			"type": "billboard"
		},
	]

	# Build tree config map for quick lookup
	for config in texture_configs:
		if config.has("type") and config["type"].begins_with("tree_"):
			tree_configs[config["type"]] = config
		elif not config.get("type", "").begins_with("tree_"):
			non_tree_configs.append(config)

	super._ready()

# Override texture selection to use TreeSpawnManager probabilities
func _select_texture_config() -> Dictionary:
	"""Select texture config based on TreeSpawnManager probabilities"""
	var tree_manager = _get_tree_spawn_manager()

	if tree_manager:
		var tree_type = tree_manager.should_spawn_tree_type()
		if tree_type != "":
			return tree_configs.get(tree_type, {})

	# Fall back to random non-tree element if no tree selected
	if non_tree_configs.size() > 0:
		return non_tree_configs[randi() % non_tree_configs.size()]

	# Final fallback to any config
	return texture_configs[randi() % texture_configs.size()] if texture_configs.size() > 0 else {}

# Override spawn to attach AQI sources
func _spawn_object():
	if object_pool.is_empty() or texture_configs.is_empty():
		return

	var sprite = object_pool.pop_back()
	var config = _select_texture_config()

	if config.is_empty():
		object_pool.append(sprite)
		return

	sprite.texture = config["texture"]

	# Apply region if specified
	if config.has("region") and config["region"] != null:
		sprite.region_enabled = true
		sprite.region_rect = config["region"]
		# Set bottom-center pivot based on region size
		var region: Rect2 = config["region"]
		sprite.offset = Vector2(-region.size.x / 2.0, -region.size.y)
	else:
		sprite.region_enabled = false
		# Set bottom-center pivot so sprites sit on horizon
		if sprite.texture:
			sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -sprite.texture.get_height())

	sprite.position.x = spawn_x

	# Get scale from config (per-asset) or use base_scale with variance (fallback)
	var scale_val: float
	if config.has("scale") and config["scale"] > 0:
		scale_val = config["scale"]
	else:
		scale_val = base_scale + randf_range(-scale_variance, scale_variance)

	# Calculate sprite height after scaling (needed for pivot correction)
	var sprite_height: float
	if config.has("region") and config["region"] != null:
		sprite_height = config["region"].size.y * scale_val
	elif sprite.texture:
		sprite_height = sprite.texture.get_height() * scale_val
	else:
		sprite_height = 0.0

	# Calculate y-position using quadratic formula (gives world CENTER Y)
	var world_center_y = quad_a + quad_b * scale_val + quad_c * scale_val * scale_val

	# Convert from world space to screen space (Parallax2D uses camera-relative coords)
	var screen_center_y = world_center_y - camera_y

	# Pivot correction: quadratic formula gives CENTER Y, but we changed pivot to BOTTOM
	# So we need to move DOWN by half the sprite height to position the bottom correctly
	var pivot_correction = sprite_height / 2.0

	# Per-asset Y offset for fine-tuning (optional)
	var asset_y_offset = config.get("y_offset", 0.0)

	# Apply layer offset, global offset, pivot correction, asset offset, and variance
	sprite.position.y = screen_center_y + pivot_correction + layer_y_offset + global_y_offset + asset_y_offset + randf_range(-y_variance, y_variance)

	sprite.scale = Vector2(scale_val, scale_val)
	sprite.visible = true

	# Attach TreeAQISource if this is a tree
	if config.has("type") and config["type"].begins_with("tree_"):
		_attach_tree_aqi_source(sprite, config["type"])

	active_objects.append(sprite)
	object_spawned.emit(sprite)

func _get_tree_spawn_manager() -> Node:
	"""Get TreeSpawnManager from main scene"""
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		return main.get_node_or_null("TreeSpawnManager")

	# Fallback to group
	var managers = get_tree().get_nodes_in_group("tree_spawn_manager")
	return managers[0] if managers.size() > 0 else null

func _attach_tree_aqi_source(sprite: Node, tree_type: String) -> void:
	"""Attach TreeAQISource to spawned tree sprite"""
	var tree_aqi = TreeAQISource.new()
	tree_aqi.name = "TreeAQISource"

	# Extract tree number from tree_type (tree_1, tree_2, tree_3)
	var tree_num = int(tree_type.trim_prefix("tree_"))
	tree_aqi.tree_type = tree_num

	sprite.add_child(tree_aqi)
