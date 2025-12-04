# Breath Rush — Troubleshooting Guide

When opening the project in Godot 4.5.1, you may encounter errors. This guide helps diagnose and fix them.

---

## Quick Diagnostics

### 1. Check Godot Console (Output Panel)

**Location:** Godot Editor → View → Toggle Bottom Panel (or press `Ctrl+J`)

**Look for these error patterns:**

| Error Pattern | Meaning | Solution |
|---|---|---|
| `Cannot find member in base "Node2D": aqi_current` | Script variable not recognized | Check Player.gd script syntax |
| `Script class "Player" not found` | Script not loading | Check res://scripts/Player.gd path |
| `Cyclic dependency` | Scene references creating loop | Reload scene or clear .godot cache |
| `Cannot find node by path` | @onready reference broken | Fix node parent paths in .tscn |
| `Cannot convert arguments to the function` | Type mismatch in signal | Check signal parameter types |

---

## Common Issues & Fixes

### Issue 1: "Node not found" on _ready()

**Error in Console:**
```
node not found: $HealthBar
At: res://scripts/HUD.gd:9:_ready
```

**Cause:** The @onready reference doesn't exist in scene

**Fix:**
1. Open `scenes/Main.tscn` in Godot editor
2. Check Scene Tree on left — does "UI" node have "HealthBar" child?
3. If missing, add it:
   - Right-click UI → Add Child Node → TextureProgress
   - Name it "HealthBar"
   - Set anchors: left=0.05, top=0.05, right=0.15, bottom=0.15

---

### Issue 2: Script Errors (red text in console)

**Common patterns:**

#### **Problem: "Undefined identifier in expression"**
```
identifier "CharacterBody2D" not found in expression
```

**Cause:** Missing or wrong extends declaration

**Check:** First line of Player.gd should be:
```gdscript
extends CharacterBody2D
```

**Fix if wrong:**
```gdscript
# WRONG:
class Player:

# CORRECT:
extends CharacterBody2D
```

#### **Problem: "Unexpected token in expression"**
```
Unexpected token: "." at line 45, column 12
```

**Cause:** Syntax error in signal emission or connection

**Check these patterns:**
```gdscript
# CORRECT (Godot 4.x):
health_changed.emit(health)
player_ref.health_changed.connect(_on_health_changed)

# WRONG (Godot 3.x style):
emit_signal("health_changed", health)  # Still works but not recommended
```

---

### Issue 3: Asset Not Found

**Error:**
```
res://assets/skies/sky_bad.webp not found
```

**Cause:** Asset file missing from assets/ folder

**Fix:**
1. Check file exists: `/home/riju279/Documents/Code/Games/breath_rush/assets/skies/sky_bad.webp`
2. If missing, copy from ALL_assets/: `cp ALL_assets/bad_sky.webp assets/skies/sky_bad.webp`
3. Reload scene: Scene → Reload Current Scene (F5)

---

### Issue 4: ParallaxBG Typo (KNOWN BUG - FIXED)

**Error in console:**
```
Cannot find member in base "Node2D": parallax_bg
```

**Cause:** Main.tscn had `ParallexBG` (typo) instead of `ParallaxBG`

**Status:** ✅ **FIXED** in latest version

**Verify:** Open `scenes/Main.tscn` and check line 20:
```
[node name="ParallaxBG" type="ParallaxBackground" parent="."]
```

Should be `ParallaxBG`, not `ParallexBG`

---

### Issue 5: Script Can't Find Child Nodes

**Example error:**
```
At: res://scripts/Game.gd:25:_ready
sky_manager is NULL
```

**Cause:** @onready variables are null (node not found in tree)

**Debug Steps:**
1. Open `scenes/Main.tscn` in Godot
2. In **Scene Tree** panel, expand the full node hierarchy
3. Verify these paths exist:
   - Main → ParallaxBG → SkyLayer ✓
   - Main → Road → RoadTileA, RoadTileB ✓
   - Main → Player ✓
   - Main → UI → HealthBar ✓

4. If missing, add them manually or regenerate scene

---

## Cache & Reimport Issues

### Clear Godot Cache

If you see persistent "cannot find" errors even though files exist:

**On Linux:**
```bash
cd /home/riju279/Documents/Code/Games/breath_rush
rm -rf .godot/
godot project.godot
```

**On Windows:**
```
Delete: breath_rush\.godot\
Reopen project in Godot
```

**Why:** Godot caches file paths and script references. Clearing forces full reimport.

### Force Scene Reimport

1. In Godot, open `scenes/Main.tscn`
2. Press `Ctrl+Shift+R` (Reload current scene)
3. Or: Scene → Reload Current Scene

---

## Verifying the Fix

### Checklist for Working Project

After fixes, you should see:

- [x] **Godot opens project** without crashes
- [x] **Main.tscn loads** with full scene tree visible
- [x] **Scene tree shows proper hierarchy**:
  - Main
    - ParallaxBG
      - SkyLayer (with SkyManager.gd script)
        - Sprite_SkyBad
        - Sprite_SkyOk
        - Sprite_SkyClear
    - Road (with RoadScroll.gd)
    - World
    - DeliveryZones
    - Player (instance)
    - Spawner
    - UI (with HUD.gd)
      - HealthBar
      - BatteryBar
      - MaskTimer
      - AQIIndicator
      - AIRCoinCounter
      - TouchControls

- [x] **No red errors** in Output console when loading scene
- [x] **Scripts show green checkmarks** in FileSystem panel (no syntax errors)
- [x] **Press F5** → Game starts running (even with placeholder assets)
- [x] **Closing game** returns to editor without crashes

---

## If Still Broken

### Nuclear Option: Regenerate from Scratch

If nothing works, regenerate the entire skeleton:

```bash
cd /home/riju279/Documents/Code/Games/breath_rush

# Backup current state
tar -czf breath_rush_backup.tar.gz .

# Remove broken files (keep assets & config only)
rm -rf scripts/ scenes/ docs/GDD.md docs/Instruction.md

# Reimport from instructions
# (Would need to rerun the build process)
```

**But first, try these steps:**

1. **Close Godot completely**
2. **Delete .godot folder**:
   ```bash
   rm -rf .godot/
   ```
3. **Reopen project**
4. **Force reimport**: Scene → Reload Current Scene (F5)

---

## Getting Help

### Debugging Steps

1. **Enable verbose output:**
   - Godot → Debug → GDScript → Break on Errors (ON)
   - Godot → Debug → GDScript → Break on Warnings (ON)

2. **Check Script Errors:**
   - FileSystem panel → scripts/ folder
   - Look for red X marks on .gd files
   - Double-click to see error details

3. **Validate JSON:**
   ```bash
   python3 -m json.tool config/gameplay.json  # Should print formatted JSON
   ```

4. **List scene structure:**
   ```bash
   grep "node name" scenes/Main.tscn | head -20  # Shows node hierarchy
   ```

---

## Key Files to Check

If errors persist, verify these files:

1. **scripts/Game.gd** (220 lines)
   - Line 1: `extends Node2D`
   - Has `@onready var` declarations

2. **scenes/Main.tscn** (150 lines)
   - Line 20: `ParallaxBG` (not ParallexBG)
   - All parent paths correct

3. **config/gameplay.json**
   - Valid JSON (can be parsed by Python)
   - Has all required fields

4. **assets/ folder structure**
   - assets/skies/sky_bad.webp ✓
   - assets/road/road_tile.webp ✓
   - assets/player/vim_base.webp ✓

---

## Last Resort: Validate Everything

Run this diagnostic script to check project health:

```bash
#!/bin/bash
cd /home/riju279/Documents/Code/Games/breath_rush

echo "=== Checking GDScript Files ==="
for f in scripts/*.gd; do
  echo "✓ $f ($(wc -l < "$f") lines)"
done

echo "=== Checking Scene Files ==="
for f in scenes/*.tscn; do
  echo "✓ $f"
done

echo "=== Checking JSON Validity ==="
for f in config/*.json data/chunks/*.json; do
  python3 -m json.tool "$f" > /dev/null && echo "✓ $f" || echo "✗ $f INVALID"
done

echo "=== Checking Assets ==="
for f in assets/*/*.webp; do
  [ -f "$f" ] && echo "✓ $f" || echo "✗ $f MISSING"
done
```

---

## Known Limitations (Not Bugs)

These are expected in the skeleton:

- ❌ **No menu system** — Game goes straight to Main.tscn
- ❌ **No sound/music** — AudioStreamPlayer not implemented
- ❌ **Placeholder assets** — 14 empty WebP files to replace with design
- ❌ **No animation system** — Trees/characters don't animate yet
- ❌ **Backend not connected** — No leaderboard/session API calls

These are intentional (next-phase work).

---

**Last Updated:** 2025-12-04
**Project Status:** ✅ Skeleton ready for Godot 4.5.1
**Next Step:** Replace placeholder assets and add menu system
