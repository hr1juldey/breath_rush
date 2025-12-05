extends Node
"""
PlayerInput Component

Handles ONLY input processing:
- Keyboard input (WASD, arrow keys, space, etc.)
- Touch input (mobile controls)
- Input event parsing
- Action signals

This component is extracted from Player.gd to isolate input system.
"""

# Signals for actions
signal lane_change_requested(direction: int)
signal boost_start_requested()
signal boost_stop_requested()
signal mask_use_requested()
signal item_drop_requested()

# Horizontal input state
var horizontal_input = 0.0

func _ready():
	print("[PlayerInput] Component initialized")

func _input(event: InputEvent) -> void:
	"""Process input events"""
	if event is InputEventKey:
		_handle_keyboard(event)
	elif event is InputEventScreenTouch:
		_handle_touch(event)

func _process(_delta: float) -> void:
	"""Update continuous input state"""
	horizontal_input = 0.0

	# Check horizontal input
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_L):
		horizontal_input = 1.0
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_H):
		horizontal_input = -1.0

func _handle_keyboard(event: InputEventKey) -> void:
	"""Handle keyboard input events"""
	if event.pressed:
		# Lane changes
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			lane_change_requested.emit(-1)
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			lane_change_requested.emit(1)

		# Boost
		elif event.keycode == KEY_SPACE:
			boost_start_requested.emit()

		# Item drop
		elif event.keycode == KEY_D:
			item_drop_requested.emit()

		# Mask use
		elif event.keycode == KEY_M:
			mask_use_requested.emit()
	else:
		# Key released
		if event.keycode == KEY_SPACE:
			boost_stop_requested.emit()

func _handle_touch(event: InputEventScreenTouch) -> void:
	"""Handle touch input events (mobile)"""
	if not event.pressed:
		return

	var touch_pos = event.position
	var screen_size = get_viewport().get_visible_rect().size
	var half_width = screen_size.x / 2.0

	if touch_pos.x < half_width:
		# Left half - lane controls
		if touch_pos.y < screen_size.y / 2.0:
			lane_change_requested.emit(-1)
		else:
			lane_change_requested.emit(1)
	else:
		# Right half - boost or drop
		if touch_pos.y < screen_size.y * 0.75:
			boost_start_requested.emit()
		else:
			item_drop_requested.emit()

# === Public API for inspection ===

func get_horizontal_input() -> float:
	"""Get current horizontal input (-1.0 to 1.0)"""
	return horizontal_input
