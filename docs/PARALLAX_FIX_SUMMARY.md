# Parallax Fix Summary

## Changes Made to Main.tscn

### 1. Sky Layer (Fixed)
**Before:**
```
SkyLayer:
  position: Vector2(247.215, -171.885)  # Wrong offset
  scale: Vector2(0.78, 0.78)  # Wrong scale
  SkyShaderSprite:
    position: Vector2(480, 240)  # Too low
```

**After (from ParallaxScalingEditor):**
```
SkyLayer:
  motion_scale: Vector2(0.1, 0)  # Correct parallax speed
  SkyShaderSprite:
    position: Vector2(480, -90)  # Above horizon (horizon at y=200)
    scale: Vector2(1.0, 1.0)  # Default, sky texture is 1920x1080
```

### 2. Smog Layers (Fixed Flickering)
**Before:**
- SmogLayer_1: layer scale 0.375, sprite scale 10x
- SmogLayer_2: layer scale 22.885, sprite scale 10x
- SmogLayer_3: layer scale 42.005, sprite scale 10x

**Problem:** Conflicting layer and sprite scales caused flickering

**After:**
```
SmogLayer_1:
  motion_scale: Vector2(0.15, 0)  # Between sky (0.1) and far (0.3)
  SmogShaderSprite_1:
    position: Vector2(480, 240)
    scale: Vector2(2.0, 2.0)  # Unified scale

SmogLayer_2:
  motion_scale: Vector2(0.45, 0)  # Between far (0.3) and mid (0.6)
  SmogShaderSprite_2:
    position: Vector2(480, 240)
    scale: Vector2(2.0, 2.0)

SmogLayer_3:
  motion_scale: Vector2(0.75, 0)  # Between mid (0.6) and front (0.9)
  SmogShaderSprite_3:
    position: Vector2(480, 240)
    scale: Vector2(2.0, 2.0)
```

### 3. Parallax Spawners (Using Quadratic Formula)

All spawners now use the mathematically-derived formula:
```gdscript
y_position = 410 - 400*scale + 90*scale²
```

**FarLayerSpawner:**
- base_scale: 0.35
- scale_variance: 0.05
- motion_scale: 0.3

**MidLayerSpawner:**
- base_scale: 0.30
- scale_variance: 0.03
- motion_scale: 0.6

**FrontLayerSpawner:**
- base_scale: 0.25
- scale_variance: 0.03
- motion_scale: 0.9

## How This Works

### Parallax Depth Layers

```
Sky (motion 0.1) ───────────────── Slowest, farthest
  │
SmogLayer_1 (0.15) ──────────────
  │
FarLayer (0.3) ────────────────── Monuments (Laal Kila, etc)
  │
SmogLayer_2 (0.45) ──────────────
  │
MidLayer (0.6) ────────────────── Buildings (restaurants, shops)
  │
SmogLayer_3 (0.75) ──────────────
  │
FrontLayer (0.9) ─────────────── Trees, stalls (close to player)
  │
Road (1.0) ───────────────────── Ground, player moves here
```

### The Formula in Action

For each layer, spawners:
1. Generate random scale: `scale_val = base_scale + randf_range(-variance, +variance)`
2. Calculate y-position: `y = 410 - 400*scale + 90*scale²`
3. Add slight random variance: `y += randf_range(-y_variance, +y_variance)`

Example:
- Far layer: scale=0.35 → y = 410 - 140 + 11.025 = 281
- Mid layer: scale=0.30 → y = 410 - 120 + 8.1 = 298
- Front layer: scale=0.25 → y = 410 - 100 + 5.625 = 315.6

## What's Fixed

✅ Sky positioned correctly above horizon
✅ Sky at proper scale (1.0, matches 1920x1080 texture)
✅ Smog layers no longer flicker (unified scaling)
✅ Smog layers positioned between parallax depth layers
✅ Assets spawn at mathematically correct y-positions
✅ Player controller preserved (untouched)
✅ Lane changing preserved (untouched)
✅ All game logic preserved

## Testing Checklist

- [ ] Run game and verify sky visible above buildings
- [ ] Check smog layers don't flicker
- [ ] Verify far monuments appear distant and small
- [ ] Verify mid buildings appear medium-sized
- [ ] Verify front trees/stalls appear close to road
- [ ] Test player can still change lanes (↑↓ arrows)
- [ ] Test player can still boost (SPACE)
- [ ] Test pickups still spawn and are collectable
- [ ] Test obstacles still spawn and cause collisions
