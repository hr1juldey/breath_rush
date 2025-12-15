extends Area2D
class_name EVCharger

## EV Charging Station - spawns as a building when player battery is low
## Realistic charging behavior: slow down → stop → charge → speed up → leave
## Positioned like front layer buildings (beside the road)
##
## ============== TUNING GUIDE ==============
## All controls are here - adjust @export values below
## Compare with FrontLayerSpawner elements for reference:
##   - Trees: scale ~0.19-0.34, y_offset -70 to -95
##   - FruitStall: scale 0.145, y_offset -95
##   - Billboard: scale 0.089, y_offset -30
## Ground level Y = 420, Horizon Y = 200
## Player scooter is at Y ~289, scale 0.4
## ==========================================

signal charging_started
signal charging_complete

enum ChargingState {SCROLLING, SLOWING_DOWN, CHARGING, SPEEDING_UP}

var state: ChargingState = ChargingState.SCROLLING
var scroll_speed = 400.0
var current_world_speed = 400.0 # Track actual world speed during transitions
var charge_timer = 0.0
var transition_timer = 0.0

# Player reference for animation coordination
var player_ref: Node = null

# ============== POSITION CONTROLS ==============
@export_group("Position")
@export var spawn_x: float = 1800.0 ## Off-screen right spawn point
@export var despawn_x: float = -400.0 ## Off-screen left despawn point
@export var spawn_y: float = 250.0 ## Vertical position (lower = higher on screen)
## Reference: Ground=420, Horizon=200, Player=289
## FrontLayer buildings sit around Y=310-350

# ============== SCALE CONTROLS ==============
@export_group("Scale")
@export var charger_scale: Vector2 = Vector2(0.25, 0.25) ## Sprite scale (X, Y)
## Reference: Player scale=0.4, Trees=0.19-0.34, Buildings=0.22-0.30
## Make this ~0.35 to match player height

# ============== SPRITE OFFSET (pivot correction) ==============
@export_group("Sprite Offset")
@export var sprite_offset: Vector2 = Vector2(0, -350) ## Move sprite relative to collision
## Negative Y = sprite moves UP (bottom anchored to position)
## Adjust so charger base sits on ground level

# ============== COLLISION CONTROLS ==============
@export_group("Collision")
@export var collision_offset: Vector2 = Vector2(0, -50) ## Collision box offset
@export var collision_size: Vector2 = Vector2(80, 100) ## Collision box size

# ============== TIMING CONTROLS ==============
@export_group("Timing")
@export var charge_duration: float = 10.0 ## How long to charge (seconds)
@export var transition_duration: float = 1.0 ## Slow down / speed up time (seconds)

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

# ============== ANIMATION FRAMES ==============
# Charging animation textures (0% → 25% → 50% → 75% → 100%)
var charge_frames: Array[Texture2D] = []

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Load charging animation frames
	_load_animation_frames()

	# Position charger like a building in front layer space
	global_position = Vector2(spawn_x, spawn_y)

	# Apply scale and offset from export controls (overrides scene defaults)
	if sprite:
		sprite.scale = charger_scale
		sprite.offset = sprite_offset

	# Apply collision settings
	if collision:
		collision.position = collision_offset
		if collision.shape is RectangleShape2D:
			collision.shape.size = collision_size

	print("[EVCharger] Spawned at (%.1f, %.1f) scale=(%.2f, %.2f) - state: SCROLLING" % [
		global_position.x, global_position.y, charger_scale.x, charger_scale.y
	])

func _physics_process(delta):
	match state:
		ChargingState.SCROLLING:
			_process_scrolling(delta)
		ChargingState.SLOWING_DOWN:
			_process_slowing_down(delta)
		ChargingState.CHARGING:
			_process_charging(delta)
		ChargingState.SPEEDING_UP:
			_process_speeding_up(delta)

func _process_scrolling(delta):
	"""Normal scrolling - world moves at full speed"""
	global_position.x -= scroll_speed * delta

	# Despawn if off-screen
	if global_position.x < despawn_x:
		queue_free()

func _process_slowing_down(delta):
	"""World slows down as scooter approaches charger"""
	transition_timer += delta
	var progress = min(transition_timer / transition_duration, 1.0)

	# Ease out - start fast, end slow
	var ease_progress = 1.0 - pow(1.0 - progress, 2.0)
	current_world_speed = scroll_speed * (1.0 - ease_progress)

	# Update game scroll speed
	_set_world_scroll_speed(current_world_speed)

	# Move charger at reduced speed
	global_position.x -= current_world_speed * delta

	if progress >= 1.0:
		# Fully stopped - start charging
		current_world_speed = 0.0
		_set_world_scroll_speed(0.0)
		state = ChargingState.CHARGING
		charge_timer = 0.0
		charging_started.emit()

		# Start gradual battery charging (animates HUD over charge_duration)
		if player_ref:
			var battery = player_ref.get_node_or_null("PlayerBattery")
			if battery:
				battery.start_gradual_charge(charge_duration)

		print("[EVCharger] State: CHARGING (world stopped, charging for %.1fs)" % charge_duration)

func _process_charging(delta):
	"""World is stopped, battery is charging (gradual charge runs in PlayerBattery)"""
	charge_timer += delta

	# Update charging animation frame based on progress
	_update_charging_animation()

	if charge_timer >= charge_duration:
		# Charging complete - start speeding up
		# Note: Battery is already at max from gradual charging in PlayerBattery
		state = ChargingState.SPEEDING_UP
		transition_timer = 0.0
		print("[EVCharger] State: SPEEDING_UP (charge complete)")

func _process_speeding_up(delta):
	"""World speeds back up as scooter leaves charger"""
	transition_timer += delta
	var progress = min(transition_timer / transition_duration, 1.0)

	# Ease in - start slow, end fast
	var ease_progress = pow(progress, 2.0)
	current_world_speed = scroll_speed * ease_progress

	# Update game scroll speed
	_set_world_scroll_speed(current_world_speed)

	# Move charger at increasing speed
	global_position.x -= current_world_speed * delta

	if progress >= 1.0:
		# Back to full speed - return to normal scrolling
		current_world_speed = scroll_speed
		_set_world_scroll_speed(scroll_speed)
		charging_complete.emit()
		state = ChargingState.SCROLLING
		print("[EVCharger] State: SCROLLING (charging complete, scrolling off-screen)")

func _on_body_entered(body):
	if body.name == "Player" and state == ChargingState.SCROLLING:
		_begin_charging_sequence(body)

func _on_area_entered(area):
	var parent = area.get_parent()
	if parent and parent.name == "Player" and state == ChargingState.SCROLLING:
		_begin_charging_sequence(parent)

func _begin_charging_sequence(player: Node):
	"""Begin the slow down → charge → speed up sequence"""
	player_ref = player
	state = ChargingState.SLOWING_DOWN
	transition_timer = 0.0

	# Notify player battery
	var battery = player.get_node_or_null("PlayerBattery")
	if battery:
		battery.enter_charging_zone()

	print("[EVCharger] State: SLOWING_DOWN (player collided)")

func _set_world_scroll_speed(speed: float):
	"""Set scroll speed for all world elements"""
	# Get Game node: EVCharger > PickupSpawner > Spawner > Main
	var game = get_parent().get_parent().get_parent()
	if not game:
		push_error("[EVCharger] Could not find Game node!")
		return

	# Update Game's scroll_speed variable
	if "scroll_speed" in game:
		game.scroll_speed = speed

	# Update Road
	var road = game.get_node_or_null("Road")
	if road and road.has_method("set_scroll_speed"):
		road.set_scroll_speed(speed)

	# Update Spawner (which updates obstacles and pickups)
	var spawner = game.get_node_or_null("Spawner")
	if spawner and spawner.has_method("set_scroll_speed"):
		spawner.set_scroll_speed(speed)

	# Set world_paused flag for parallax layers
	if "world_paused" in game:
		game.world_paused = (speed == 0.0)

func set_scroll_speed(speed: float):
	scroll_speed = speed
	if state == ChargingState.SCROLLING:
		current_world_speed = speed

# ============== ANIMATION HELPERS ==============

func _load_animation_frames():
	"""Load the 5 charging animation frames"""
	charge_frames = [
		load("res://assets/pickups/ev_charger/prop_ev_charger_0.webp"),    # 0% - empty
		load("res://assets/pickups/ev_charger/prop_ev_charger_25.webp"),   # 25% - 1 bar
		load("res://assets/pickups/ev_charger/prop_ev_charger_50.webp"),   # 50% - 2 bars
		load("res://assets/pickups/ev_charger/prop_ev_charger_75.webp"),   # 75% - 3 bars
		load("res://assets/pickups/ev_charger/prop_ev_charger_100.webp")   # 100% - full + bolt
	]

	# Set initial frame (0%)
	if sprite and charge_frames.size() > 0:
		sprite.texture = charge_frames[0]
		print("[EVCharger] Loaded %d animation frames" % charge_frames.size())

func _update_charging_animation():
	"""Update sprite texture based on charging progress"""
	if not sprite or charge_frames.size() == 0:
		return

	# Calculate progress (0.0 to 1.0)
	var progress = charge_timer / charge_duration

	# Map progress to frame index
	# 0.0-0.2 → frame 0 (0%)
	# 0.2-0.4 → frame 1 (25%)
	# 0.4-0.6 → frame 2 (50%)
	# 0.6-0.8 → frame 3 (75%)
	# 0.8-1.0 → frame 4 (100%)
	var frame_index = int(progress * 5.0)
	frame_index = clamp(frame_index, 0, charge_frames.size() - 1)

	# Update sprite texture
	sprite.texture = charge_frames[frame_index]
