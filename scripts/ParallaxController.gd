extends Node2D
class_name ParallaxController

## Single Responsibility: Manage parallax background scrolling
## Updates scroll_offset at consistent speed

@export var scroll_speed: float = 300.0  # pixels per second
@onready var parallax_bg = $ParallaxBG

var current_scroll_offset: float = 0.0

func _ready():
	if not parallax_bg:
		push_error("ParallaxController: ParallaxBG not found!")

func _physics_process(delta):
	"""Scroll parallax at constant speed"""
	if parallax_bg:
		current_scroll_offset += scroll_speed * delta
		parallax_bg.scroll_offset.x = current_scroll_offset

func get_scroll_offset() -> float:
	"""Get current scroll position"""
	return current_scroll_offset

func set_scroll_offset(offset: float):
	"""Set scroll position (for testing/control)"""
	current_scroll_offset = offset
	if parallax_bg:
		parallax_bg.scroll_offset.x = current_scroll_offset
