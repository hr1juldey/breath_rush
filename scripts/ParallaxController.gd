extends Node
class_name ParallaxController

## Single Responsibility: Manage parallax background scrolling
## Updates scroll_offset at consistent speed

@export var scroll_speed: float = 300.0
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
