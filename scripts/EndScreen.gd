extends Control

"""
End Screen - Shows game over/win screen with stats.
Reuses the start image with an overlay showing results.
"""

@onready var start_image = $StartImage
@onready var overlay = $Overlay
@onready var result_label = $Overlay/ResultLabel
@onready var stats_label = $Overlay/StatsLabel
@onready var restart_button = $Overlay/RestartButton

# Game result data (set before transitioning to this scene)
static var game_won: bool = false
static var final_distance: float = 0.0
static var final_coins: int = 0
static var final_aqi: float = 0.0
static var loss_reason: String = ""

func _ready():
	print("[EndScreen] Ready - showing results")

	# Display results
	if game_won:
		result_label.text = "YOU WIN!"
		result_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		result_label.text = "GAME OVER"
		result_label.add_theme_color_override("font_color", Color.RED)

	# Show stats
	var stats_text = "Distance: %.1f m\nCoins: %d\nFinal AQI: %.0f" % [final_distance, final_coins, final_aqi]
	if not game_won and loss_reason != "":
		stats_text += "\n\n" + loss_reason
	stats_label.text = stats_text

	# Focus restart button
	if restart_button:
		restart_button.grab_focus()

	set_process_input(true)

func _input(event):
	# Restart on SPACE, ENTER, or R
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_R:
			_restart_game()

func _on_restart_button_pressed():
	_restart_game()

func _restart_game():
	print("[EndScreen] Restarting game...")
	# Reset static vars
	game_won = false
	final_distance = 0.0
	final_coins = 0
	final_aqi = 0.0
	loss_reason = ""

	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")
