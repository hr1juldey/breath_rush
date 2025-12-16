extends Control

"""
Start Screen - Shows title image and waits for player input to start game.
"""

@onready var start_image = $StartImage
@onready var start_button = $StartButton

func _ready():
	print("[StartScreen] Ready - Press SPACE or click START NOW to begin")

	# Ensure we can receive input
	set_process_input(true)

	# Focus the button for keyboard navigation
	if start_button:
		start_button.grab_focus()

func _input(event):
	# Start game on SPACE, ENTER, or mouse click
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()

func _on_start_button_pressed():
	_start_game()

func _start_game():
	print("[StartScreen] Starting game...")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
