extends Area2D
class_name EVCharger

## EV Charging Station - spawns only when player battery is low
## Pauses world scrolling for 5 seconds while recharging

signal charging_started
signal charging_complete

var scroll_speed = 400.0
var is_charging = false
var charge_duration = 5.0
var charge_timer = 0.0

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	if not is_charging:
		# Scroll left
		global_position.x -= scroll_speed * delta

		# Despawn if off-screen
		if global_position.x < -100:
			queue_free()
	else:
		# Charging - update timer
		charge_timer += delta
		if charge_timer >= charge_duration:
			_finish_charging()

func _on_body_entered(body):
	if body.name == "Player" and not is_charging:
		_start_charging(body)

func _on_area_entered(area):
	if area.get_parent().name == "Player" and not is_charging:
		_start_charging(area.get_parent())

func _start_charging(player: Node):
	"""Start charging sequence"""
	is_charging = true
	charge_timer = 0.0

	# Notify player battery to enter charging zone
	var battery_component = player.get_node_or_null("PlayerBattery")
	if battery_component:
		battery_component.enter_charging_zone()

	# Emit signal to pause world
	charging_started.emit()

	print("[EVCharger] Charging started - 5 second pause")

func _finish_charging():
	"""Complete charging and resume world"""
	is_charging = false
	charging_complete.emit()

	print("[EVCharger] Charging complete - resuming world")

	# Despawn after use
	queue_free()

func set_scroll_speed(speed: float):
	scroll_speed = speed
