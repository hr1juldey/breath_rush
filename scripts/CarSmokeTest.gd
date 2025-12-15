extends Node2D

# Test scene for previewing car smoke effects
# Moves cars across screen to show smoke trails

@onready var car1 = $Car1Test
@onready var car2 = $Car2Test

var scroll_speed = 200.0  # Slower than game for easy viewing
var move_cars = true

func _ready():
	print("=== Car Smoke Test Scene ===")
	print("Press SPACE to toggle car movement")
	print("Press R to reset positions")
	print("Press +/- to adjust smoke speed")
	print("===========================")

	# Enable smoke particles
	_setup_smoke(car1)
	_setup_smoke(car2)

func _process(delta):
	if move_cars:
		# Move cars to the left to show smoke trail
		car1.position.x -= scroll_speed * delta
		car2.position.x -= scroll_speed * delta

		# Reset when off-screen
		if car1.position.x < -200:
			car1.position.x = 1200
		if car2.position.x < -200:
			car2.position.x = 1200

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				move_cars = !move_cars
				print("Car movement: ", "ON" if move_cars else "OFF")
			KEY_R:
				_reset_positions()
			KEY_EQUAL, KEY_PLUS:
				scroll_speed += 50
				print("Scroll speed: ", scroll_speed)
			KEY_MINUS:
				scroll_speed = max(50, scroll_speed - 50)
				print("Scroll speed: ", scroll_speed)

func _reset_positions():
	car1.position.x = 400
	car2.position.x = 750
	print("Positions reset")

func _setup_smoke(car: Node):
	"""Enable smoke particles for testing"""
	var smoke_emitter = car.get_node_or_null("SmokeEmitter")
	if not smoke_emitter:
		return

	var smoke_gpu = smoke_emitter.get_node_or_null("SmokeGPU")
	var smoke_cpu = smoke_emitter.get_node_or_null("SmokeCPU")

	if smoke_gpu:
		smoke_gpu.emitting = true
	if smoke_cpu:
		smoke_cpu.emitting = false
