extends Node2D

@onready var road_tile_a = $RoadTileA
@onready var road_tile_b = $RoadTileB

var scroll_speed = 400.0
var texture_width = 960.0
var recycle_threshold = -960.0

func _ready():
	# Set initial positions for tiles
	if road_tile_a and road_tile_b:
		road_tile_a.position.x = 0
		road_tile_b.position.x = texture_width

		# Get actual texture width if available
		if road_tile_a.texture:
			texture_width = road_tile_a.texture.get_width()
			road_tile_b.position.x = texture_width
			recycle_threshold = -texture_width

func _process(delta):
	if not road_tile_a or not road_tile_b:
		return

	# Move both tiles left
	road_tile_a.position.x -= scroll_speed * delta
	road_tile_b.position.x -= scroll_speed * delta

	# Recycle tiles that go off-screen
	if road_tile_a.position.x < recycle_threshold:
		road_tile_a.position.x += texture_width * 2

	if road_tile_b.position.x < recycle_threshold:
		road_tile_b.position.x += texture_width * 2

func set_scroll_speed(new_speed: float) -> void:
	scroll_speed = new_speed

func get_scroll_speed() -> float:
	return scroll_speed

func reset_position() -> void:
	if road_tile_a:
		road_tile_a.position.x = 0
	if road_tile_b:
		road_tile_b.position.x = texture_width
