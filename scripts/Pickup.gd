extends Area2D

var pickup_type = "mask"  # "mask", "filter", "sapling"
var scroll_speed = 400.0
var player_ref = null
var spawner_ref = null

func _ready():
	body_entered.connect(_on_body_entered)
	# Find spawner reference
	call_deferred("_find_spawner")

func _find_spawner():
	spawner_ref = get_parent()

func _process(delta):
	if not visible:
		return

	# Move pickup left with scroll speed
	position.x -= scroll_speed * delta

	# Check if off-screen (to be recycled)
	if position.x < -200:
		return_to_pool()

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		player_ref = body
		handle_pickup()

func handle_pickup() -> void:
	if not player_ref or not visible:
		return

	match pickup_type:
		"mask":
			player_ref.apply_mask()
		"filter":
			player_ref.pickup_filter()
		"sapling":
			player_ref.pickup_sapling()

	# Return to pool instead of destroying
	return_to_pool()

func return_to_pool():
	if spawner_ref and is_instance_valid(spawner_ref):
		spawner_ref.return_to_pool(self, false)
	else:
		visible = false

func set_type(type: String) -> void:
	pickup_type = type

func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed
