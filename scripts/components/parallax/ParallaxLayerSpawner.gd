extends Node
class_name ParallaxLayerSpawner

## Base class for parallax layer spawning with object pooling
## Spawns objects at right edge, despawns at left edge

signal object_spawned(obj: Node2D)
signal object_despawned(obj: Node2D)

@export var textures: Array[Texture2D] = []
@export var pool_size: int = 5
@export var spawn_interval_min: float = 2.0
@export var spawn_interval_max: float = 5.0
@export var y_position: float = 300.0
@export var y_variance: float = 20.0
@export var base_scale: float = 0.5
@export var scale_variance: float = 0.1
@export var despawn_x: float = -200.0
@export var spawn_x: float = 1200.0

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
	if object_pool.is_empty() or textures.is_empty():
		return

	var sprite = object_pool.pop_back()
	sprite.texture = textures[randi() % textures.size()]

	# Set bottom-center pivot so sprites sit on horizon
	if sprite.texture:
		sprite.offset = Vector2(-sprite.texture.get_width() / 2.0, -sprite.texture.get_height())

	sprite.position.x = spawn_x
	sprite.position.y = y_position + randf_range(-y_variance, y_variance)

	var scale_val = base_scale + randf_range(-scale_variance, scale_variance)
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
