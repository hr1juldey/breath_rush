extends Node
"""
PlayerMovement Component

Handles ONLY movement functionality:
- Lane switching (vertical movement)
- Horizontal movement (left/right)
- Position boundaries
- Movement speed

This component is extracted from Player.gd to isolate movement system.
"""

# Lane system
var lane_positions = [240.0, 300.0, 360.0]
var current_lane = 1  # Middle lane by default
var target_y = 300.0

# Horizontal movement
var horizontal_speed = 200.0
var min_x = 100.0
var max_x = 860.0  # 960 - 100

# Reference to parent CharacterBody2D
var player_body: CharacterBody2D = null

func _ready():
	target_y = lane_positions[current_lane]
	print("[PlayerMovement] Component initialized - Lane: %d, Target Y: %.1f" % [current_lane, target_y])

func setup(body: CharacterBody2D) -> void:
	"""Setup reference to player CharacterBody2D"""
	player_body = body
	if player_body:
		player_body.position.y = target_y
	print("[PlayerMovement] Setup complete - body: %s" % (body != null))

func change_lane(direction: int) -> void:
	"""
	Change lane (up = -1, down = +1).
	Clamps to valid lane range.
	Blocks if car is in target lane.
	"""
	var new_lane = current_lane + direction
	if new_lane >= 0 and new_lane < lane_positions.size():
		var target_lane_y = lane_positions[new_lane]

		# Check if lane is blocked by a car
		if _is_lane_blocked(target_lane_y):
			return  # Don't change lane

		current_lane = new_lane
		target_y = target_lane_y
		print("[PlayerMovement] Lane changed to %d (Y: %.1f)" % [current_lane, target_y])

func _is_lane_blocked(lane_y: float) -> bool:
	"""Check if moving to lane_y would collide with a car using physics query"""
	if not player_body:
		return false

	var space_state = player_body.get_world_2d().direct_space_state

	# Create query at target position
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = player_body.get_node("CollisionShape2D").shape
	query.transform = Transform2D(0, Vector2(player_body.global_position.x, lane_y))
	query.collision_mask = 2  # Layer 2 = cars
	query.exclude = [player_body.get_rid()]

	var result = space_state.intersect_shape(query, 1)
	return result.size() > 0

func process_movement(delta: float, horizontal_input: float) -> void:
	"""
	Process movement each frame.
	Called by Player coordinator.

	Args:
		delta: Frame time
		horizontal_input: -1.0 (left) to +1.0 (right)
	"""
	if not player_body:
		return

	# Apply horizontal movement
	player_body.position.x += horizontal_input * horizontal_speed * delta
	player_body.position.x = clamp(player_body.position.x, min_x, max_x)

	# Lane interpolation (smooth vertical movement to target)
	player_body.position.y = lerp(player_body.position.y, target_y, 0.15)

	# Apply velocity for move_and_slide
	player_body.velocity.y = 0

func apply_movement() -> void:
	"""Call move_and_slide on player body"""
	if player_body:
		player_body.move_and_slide()

# === Public API for inspection ===

func get_current_lane() -> int:
	"""Get current lane index (0-2)"""
	return current_lane

func get_target_y() -> float:
	"""Get target Y position for current lane"""
	return target_y

func get_position() -> Vector2:
	"""Get current player position"""
	if player_body:
		return player_body.position
	return Vector2.ZERO

func get_global_position() -> Vector2:
	"""Get current player global position"""
	if player_body:
		return player_body.global_position
	return Vector2.ZERO
