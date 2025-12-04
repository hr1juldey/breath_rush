extends Area2D

var obstacle_type = "car"  # "car", "bike", "pollution"
var scroll_speed = 400.0
var collision_damage = 12
var player_ref = null

var recycled = false

func _ready():
	if has_node("CollisionShape2D"):
		pass  # Collision shape will be set up in scene

	body_entered.connect(_on_body_entered)

	# Set z-index for depth: Player is at z-index 5
	# 70% of cars behind player (z-index 0-4), 30% in front (z-index 6-7)
	if randf() < 0.7:
		z_index = randi_range(0, 4)  # Behind player
	else:
		z_index = randi_range(6, 7)  # In front of player

func _process(delta):
	# Move obstacle left with scroll speed
	position.x -= scroll_speed * delta

	# Check if off-screen (to be recycled)
	if position.x < -200 and visible:
		visible = false

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		if player_ref == null:
			player_ref = body
			inflict_damage()

func inflict_damage() -> void:
	if player_ref:
		var damage = randi_range(8, 18)
		player_ref.take_damage(damage)

func set_type(type: String) -> void:
	obstacle_type = type

func set_scroll_speed(speed: float) -> void:
	scroll_speed = speed
