# Parallax Asset Scaling Workflow

## Problem
Parallax assets are spawned from object pools (hidden), making it impossible to visually adjust their scales in the Godot editor to ensure proper relative sizing.

## Solution
Use a dedicated **ParallaxScalingEditor.tscn** scene to visually adjust all asset scales, then export those scales to be used by spawners.

---

## Step 1: Lock Game Scenes (Prevent Accidental Edits)

In Godot Editor:

1. Open **Main.tscn** or any game scene
2. Click the **lock icon** (🔒) in the toolbar (top-right of 2D viewport)
   - This prevents you from selecting/moving nodes in that scene
3. Alternatively: Right-click scene in FileSystem → **Mark as Favorite** to visually separate it

**Scenes to lock:**
- `scenes/Main.tscn`
- `scenes/Player.tscn`
- `scenes/HUD.tscn`
- Any other game scenes you don't want to accidentally modify

---

## Step 2: Open ParallaxScalingEditor

1. In Godot: **Scene → Open Scene**
2. Navigate to `scenes/ParallaxScalingEditor.tscn`
3. Click **Open**

You should see:
- **Red line** at y=420 (ground/road position)
- **Green line** at y=200 (horizon line)
- **Three columns of assets**:
  - **Left (x~300)**: Far layer monuments (Laal Kila, Hauskhas, etc.)
  - **Middle (x~900)**: Mid layer buildings (restaurants, shops, etc.)
  - **Right (x~1500)**: Front layer decorations (trees, stalls, etc.)

---

## Step 3: Adjust Asset Scales Visually

### Goal
Make all assets **sit properly on the red ground line** with **realistic relative sizes**.

### How to Adjust Scales

1. **Select a sprite** in the scene tree (e.g., `FarAssets/Laal_kila`)
2. In **Inspector → Transform → Scale**:
   - Adjust `x` and `y` values (keep them equal for uniform scaling)
   - Watch the sprite resize in the viewport
3. **Position check**:
   - Bottom of sprite should touch the red ground line (y=420)
   - If not, the pivot is wrong (should already be set to bottom-center)

### Scaling Guidelines

Based on reference images (SS/5.png, SS/6.png):

**Far Layer** (monuments):
- Should be **large but distant** (perspective illusion)
- Suggested range: **0.25 - 0.45**
- Example: Taj-like monument at 0.35, Connaught Place at 0.40

**Mid Layer** (buildings):
- Should be **medium-sized**, clearly visible
- Suggested range: **0.25 - 0.35**
- Example: Restaurant at 0.30, shops at 0.28

**Front Layer** (trees/stalls):
- Should be **smallest** but closest to camera
- Suggested range: **0.20 - 0.30**
- Example: Trees at 0.25, fruit stall at 0.22

### Camera Controls

- **Zoom**: Mouse wheel or pinch gesture
- **Pan**: Middle mouse button drag or two-finger drag
- **Reset**: Set Camera2D zoom back to (0.5, 0.5) in Inspector

---

## Step 4: Export Scales to JSON

Once you're happy with all the scales:

1. **Press E** key in the editor (while ParallaxScalingEditor scene is running)
2. Check console output: `✓ Scales exported to res://data/parallax_scales.json`
3. Open `data/parallax_scales.json` to verify:

```json
{
	"far_layer": {
		"Laal_kila": 0.35,
		"Hauskhas": 0.32,
		"CP": 0.40,
		"Lotus_park": 0.38,
		"Hanuman": 0.36,
		"Select_City_mall": 0.34
	},
	"mid_layer": {
		"restaurant": 0.30,
		"pharmacy": 0.28,
		"shop": 0.29,
		"home_1": 0.31,
		"building_generic": 0.30,
		"two_storey_building": 0.32
	},
	"front_layer": {
		"tree_1": 0.25,
		"tree_2": 0.26,
		"tree_3": 0.24,
		"fruit_stall": 0.22,
		"billboard": 0.23
	}
}
```

---

## Step 5: Update Spawners to Use Scale Data

I'll help you modify the spawner scripts to:
1. Load `data/parallax_scales.json` on startup
2. Look up the correct scale for each texture when spawning
3. Use that scale instead of `base_scale + random_variance`

---

## Step 6: Test in Game

1. Close ParallaxScalingEditor.tscn
2. Open Main.tscn
3. Run the game (F5)
4. Verify all assets:
   - Sit on the road properly
   - Have correct relative sizes
   - Look like your reference images

---

## Re-import Scales (If Needed)

If you want to reload scales from a previous session:

1. Open ParallaxScalingEditor.tscn
2. **Press I** key to import scales from `data/parallax_scales.json`
3. All sprites will update to match the saved scales

---

## Tips

1. **Work on one layer at a time** - hide other layers if needed
2. **Use reference images** - keep SS/5.png and SS/6.png open for comparison
3. **Test frequently** - export scales, test in game, adjust, repeat
4. **Save often** - Scene → Save Scene after major adjustments

---

## Troubleshooting

**Assets not visible?**
- Check Camera2D zoom (should be 0.5 or lower)
- Check asset x-positions (far~300, mid~900, front~1500)

**Assets floating/sinking?**
- Verify sprite.offset is set to bottom-center pivot
- Check that y_position = 420 (ground line)

**Scales not exporting?**
- Ensure you pressed E while scene is running (not in editor)
- Check console for error messages
- Verify `data/` directory exists

**Can't select sprites in Main.tscn?**
- Good! That means it's locked. Click the lock icon to unlock when needed.
