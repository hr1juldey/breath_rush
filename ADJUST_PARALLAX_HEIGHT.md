# How to Adjust Parallax Asset Heights

## Quick Fix - Adjust in Godot Editor

1. Open `scenes/Main.tscn` in Godot
2. In the Scene tree, expand: `ParallaxBG`
3. Select each spawner node:
   - `FarLayer/FarLayerSpawner`
   - `MidLayer/MidLayerSpawner`
   - `FrontLayer/FrontLayerSpawner`

4. In the **Inspector**, find `Global Y Offset` property
5. Adjust the value:
   - **Positive values** = move assets DOWN (closer to road)
   - **Negative values** = move assets UP (away from road)

### Example Adjustments:

If assets are floating **above** the road:
```
FarLayerSpawner -> Global Y Offset = +30
MidLayerSpawner -> Global Y Offset = +30
FrontLayerSpawner -> Global Y Offset = +30
```

If assets are clipping **through** the road:
```
FarLayerSpawner -> Global Y Offset = -20
MidLayerSpawner -> Global Y Offset = -20
FrontLayerSpawner -> Global Y Offset = -20
```

### Testing:

1. Set the offset values in the Inspector
2. Run the game (F5)
3. Watch where assets spawn
4. Adjust and repeat until they sit properly on the road

### Recommended Starting Values:

Try these if assets are still floating:
- `FarLayerSpawner`: `global_y_offset = 40.0`
- `MidLayerSpawner`: `global_y_offset = 30.0`
- `FrontLayerSpawner`: `global_y_offset = 20.0`

## Manual Edit (Alternative)

You can also edit `scenes/Main.tscn` directly:

Find these lines (around line 88, 104, 120):
```
[node name="FarLayerSpawner" type="Node" parent="ParallaxBG/FarLayer"]
script = ExtResource("22_far_spawner")
global_y_offset = 0.0  # <- CHANGE THIS NUMBER
```

Change `0.0` to whatever offset you need (e.g., `40.0`, `50.0`, `60.0`)

## Technical Details

Current formula per layer:
- Far: `y = 489 - 400*scale + 90*scale² + global_y_offset`
- Mid: `y = 511.9 - 400*scale + 90*scale² + global_y_offset`
- Front: `y = 509 - 400*scale + 90*scale² + global_y_offset`

Road is at `y = 420`
Camera is at `y = 180.415`

Assets should spawn around:
- Far layer: y ≈ 360-380 (on horizon)
- Mid layer: y ≈ 400-410 (near road)
- Front layer: y ≈ 415-425 (sitting on road)
