extends Node
class_name ParallaxLayerSpawner

## Base class for parallax layer spawning with object pooling
## Spawns objects at right edge, despawns at left edge

signal object_spawned(obj: Node2D)
signal object_despawned(obj: Node2D)

# Texture configuration - child classes should populate this
# Each entry: {"texture": Texture2D, "region": Rect2 or null, "scale": float, "y_offset": float (optional)}
var texture_configs: Array[Dictionary] = []

@export var pool_size: int = 5
@export var spawn_interval_min: float = 2.0
@export var spawn_interval_max: float = 5.0
@export var base_scale: float = 0.5
@export var scale_variance: float = 0.1
@export var y_variance: float = 20.0
@export var despawn_x: float = -200.0
@export var spawn_x: float = 1400.0

# Parallax positioning constants (from mathematical analysis - recalculated)
var horizon_y: float = 200.0
var quad_a: float = 428.08
var quad_b: float = -469.51
var quad_c: float = 128.64

# Camera Y position - needed to convert world coords to screen coords
var camera_y: float = 180.415

# Layer-specific offset - override in child classes for per-layer adjustment
# Positive = move DOWN, Negative = move UP
var layer_y_offset: float = 0.0

# Global vertical offset - ADJUST THIS to move all layers up/down together
# Positive = move DOWN (closer to road), Negative = move UP (away from road)
@export var global_y_offset: float = 380.0

var object_pool: Array[Sprite2D] = []
var active_objects: Array[Sprite2D] = []
var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0
var scroll_speed: float = 300.0
var motion_scale: float = 1.0

func _ready():
	_create_pool()
	next_spawn_time = randf_range(0.5, spawn_interval_min)

func _create_pool():
	for i in pool_size:
		var sprite = Sprite2D.new()
		sprite.visible = false
		add_child(sprite)
		object_pool.append(sprite)

func _physics_process(delta):
	spawn_timer += delta

	# Check spawn
	if spawn_timer >= next_spawn_time and not object_pool.is_empty():
		_spawn_object()
		spawn_timer = 0.0
		next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)

	# Move and check despawn
	var effective_speed = scroll_speed * motion_scale * delta
	for obj in active_objects.duplicate():
		obj.position.x -= effective_speed
		if obj.position.x < despawn_x:
			_despawn_object(obj)

func _spawn_object():
	if object_pool.is_empty() or texture_configs.is_empty():
		return

	var sprite = object_pool.pop_back()
	var config = texture_configs[randi() % texture_configs.size()]

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

	active_objects.append(sprite)
	object_spawned.emit(sprite)

func _despawn_object(sprite: Sprite2D):
	sprite.visible = false
	active_objects.erase(sprite)
	object_pool.append(sprite)
	object_despawned.emit(sprite)

func set_scroll_speed(speed: float):
	scroll_speed = speed

func set_motion_scale(scale: float):
	motion_scale = scale
