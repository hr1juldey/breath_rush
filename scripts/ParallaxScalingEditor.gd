extends Node2D

## Parallax Asset Scaling Editor
## Use this scene to visually adjust asset scales, then export to JSON

@onready var far_assets = $FarAssets
@onready var mid_assets = $MidAssets
@onready var front_assets = $FrontAssets

const GROUND_Y = 420.0
const HORIZON_Y = 200.0

# Asset paths
var far_asset_paths = [
	"res://assets/parallax/Laal_kila.webp",
	"res://assets/parallax/Hauskhas.webp",
	"res://assets/parallax/CP.webp",
	"res://assets/parallax/Lotus_park.webp",
	"res://assets/parallax/Hanuman.webp",
	"res://assets/parallax/Select_City_mall.webp",
]

var mid_asset_paths = [
	"res://assets/parallax/restaurant.webp",
	"res://assets/parallax/pharmacy.webp",
	"res://assets/parallax/shop.webp",
	"res://assets/parallax/home_1.webp",
	"res://assets/parallax/building_generic.webp",
	"res://assets/parallax/two_storey_building.webp",
]

var front_asset_paths = [
	"res://assets/parallax/tree_1.webp",
	"res://assets/parallax/tree_2.webp",
	"res://assets/parallax/tree_3.webp",
	"res://assets/parallax/fruit_stall.webp",
	"res://assets/parallax/billboard.webp",
]

func _ready():
	print("[ParallaxScalingEditor] Loading assets...")
	_load_assets_into_layer(far_assets, far_asset_paths, 300.0, GROUND_Y, 0.35)
	_load_assets_into_layer(mid_assets, mid_asset_paths, 900.0, GROUND_Y, 0.3)
	_load_assets_into_layer(front_assets, front_asset_paths, 1500.0, GROUND_Y, 0.25)
	print("[ParallaxScalingEditor] Assets loaded. Adjust scales, then press E to export.")

func _load_assets_into_layer(parent: Node2D, paths: Array, start_x: float, y_pos: float, default_scale: float):
	var x_offset = start_x
	for path in paths:
		if not ResourceLoader.exists(path):
			print("[ParallaxScalingEditor] Warning: %s not found" % path)
			continue

		var texture = load(path) as Texture2D
		if not texture:
			continue

		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.name = path.get_file().get_basename()

		# Bottom-center pivot
		sprite.offset = Vector2(-texture.get_width() / 2.0, -texture.get_height())

		# Position
		sprite.position = Vector2(x_offset, y_pos)
		sprite.scale = Vector2(default_scale, default_scale)

		parent.add_child(sprite)
		sprite.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

		x_offset += 200.0  # Spacing between assets

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			export_scales()
		elif event.keycode == KEY_I:
			import_scales()

func export_scales():
	"""Export all current scales to JSON file"""
	var scale_data = {
		"far_layer": {},
		"mid_layer": {},
		"front_layer": {}
	}

	# Collect scales from each layer
	for sprite in far_assets.get_children():
		if sprite is Sprite2D:
			scale_data["far_layer"][sprite.name] = sprite.scale.x

	for sprite in mid_assets.get_children():
		if sprite is Sprite2D:
			scale_data["mid_layer"][sprite.name] = sprite.scale.x

	for sprite in front_assets.get_children():
		if sprite is Sprite2D:
			scale_data["front_layer"][sprite.name] = sprite.scale.x

	# Write to file
	var json_string = JSON.stringify(scale_data, "\t")
	var file = FileAccess.open("res://data/parallax_scales.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[ParallaxScalingEditor] ✓ Scales exported to res://data/parallax_scales.json")
		print(json_string)
	else:
		push_error("[ParallaxScalingEditor] Failed to write scale file!")

func import_scales():
	"""Import scales from JSON file"""
	if not FileAccess.file_exists("res://data/parallax_scales.json"):
		print("[ParallaxScalingEditor] No scale file found")
		return

	var file = FileAccess.open("res://data/parallax_scales.json", FileAccess.READ)
	if not file:
		push_error("[ParallaxScalingEditor] Failed to read scale file!")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[ParallaxScalingEditor] Failed to parse JSON!")
		return

	var scale_data = json.data

	# Apply scales to sprites
	_apply_scales_to_layer(far_assets, scale_data.get("far_layer", {}))
	_apply_scales_to_layer(mid_assets, scale_data.get("mid_layer", {}))
	_apply_scales_to_layer(front_assets, scale_data.get("front_layer", {}))

	print("[ParallaxScalingEditor] ✓ Scales imported from res://data/parallax_scales.json")

func _apply_scales_to_layer(parent: Node2D, scales: Dictionary):
	for sprite in parent.get_children():
		if sprite is Sprite2D and scales.has(sprite.name):
			var scale_val = scales[sprite.name]
			sprite.scale = Vector2(scale_val, scale_val)
