extends Area2D

var pickup_type = "mask"  # "mask", "filter", "sapling"
var player_ref = null

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		player_ref = body
		handle_pickup()

func handle_pickup() -> void:
	if not player_ref:
		return

	match pickup_type:
		"mask":
			player_ref.apply_mask()
		"filter":
			player_ref.pickup_filter()
		"sapling":
			player_ref.pickup_sapling()

	queue_free()

func set_type(type: String) -> void:
	pickup_type = type
