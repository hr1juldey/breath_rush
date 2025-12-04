extends Area2D

var reward_coins = 50
var player_ref = null

signal delivery_successful(coins: int, position: Vector2)

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		player_ref = body
		check_delivery()

func _on_area_entered(area):
	# Alternative detection for Area2D-based player
	if area.name == "Player" or area.is_in_group("player"):
		player_ref = area
		check_delivery()

func check_delivery() -> void:
	if not player_ref:
		return

	# Check if player has a filter
	if player_ref.carried_item == "filter":
		complete_delivery()

func complete_delivery() -> void:
	if player_ref:
		player_ref.drop_item()
		delivery_successful.emit(reward_coins, global_position)

func set_reward(coins: int) -> void:
	reward_coins = coins
