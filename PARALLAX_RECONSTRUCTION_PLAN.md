# Parallax Reconstruction Plan for Main.tscn

## Problem Analysis

**ParallaxScalingEditor.tscn** shows all assets as if on the same street:
- Camera: (480, 180.415), zoom (1.0, 1.0)
- Ground line: y=420
- Horizon: y=200
- Sky: 1920x1080 at scale 1.0, positioned y≈-91 to -109

**But these assets belong to DIFFERENT depth layers:**
- Far layer (motion_scale 0.3): Lotus_park, Laal_kila, Hauskhas, Hanuman
- Mid layer (motion_scale 0.6): building_generic, two_storey, restaurant, shop, pharmacy
- Front layer (motion_scale 0.9): tree_1, tree_2, tree_3, fruit_stall, billboard

## The Transformation

### Layer-Specific Adjustments

From the data, we see:

| Layer | Scale Range | Y Range (Editor) | Motion Scale |
|-------|-------------|------------------|--------------|
| Far   | 0.40-1.73   | -4 to 234        | 0.3          |
| Mid   | 0.22-0.75   | 178 to 320       | 0.6          |
| Front | 0.09-0.34   | 289 to 378       | 0.9          |

### Key Insight

The editor shows "roadside scale" - but in Main.tscn:
- **Far layer**: Objects appear SMALLER because they're distant (reduce scale, keep relative size)
- **Mid layer**: Medium distance
- **Front layer**: Objects appear at ACTUAL scale because they're close

### Correct Approach

**For each layer, use the quadratic formula WITH layer-specific parameters:**

```gdscript
# Base quadratic: y = 410 - 400*scale + 90*scale²

# Far Layer (motion_scale 0.3)
base_scale = 0.35  # Medium of 0.40-1.73 range
# Use formula as-is, but spawned sprites will be smaller in parallax view

# Mid Layer (motion_scale 0.6)
base_scale = 0.30  # Medium of 0.22-0.75 range
# Use formula as-is

# Front Layer (motion_scale 0.9)
base_scale = 0.25  # Medium of 0.09-0.34 range
# Use formula as-is
```

## Main.tscn Reconstruction Steps

### 1. Camera (Copy from ParallaxScalingEditor)
```
Camera2D:
  position: Vector2(480, 180.415)
  zoom: Vector2(1.0, 1.0)
  position_smoothing_enabled: true
```

### 2. Sky Layer
```
ParallaxLayer (SkyLayer):
  motion_scale: Vector2(0.1, 0)
  position: Vector2(0, 0)

  Sprite2D (SkyShaderSprite):
    material: SkyShaderMaterial
    position: Vector2(480, -90)  # Above horizon
    scale: Vector2(1.0, 1.0)  # Sky is 1920x1080, fits perfectly
    texture: sky_clear.webp (switched via shader)
```

### 3. Smog Layers (Between parallax layers)

Calculate positions based on depth:

```
SmogLayer_1 (between sky and far):
  motion_scale: Vector2(0.15, 0)  # Between 0.1 (sky) and 0.3 (far)
  scale: ???  # Need to calculate to avoid flickering

SmogLayer_2 (between far and mid):
  motion_scale: Vector2(0.45, 0)  # Between 0.3 (far) and 0.6 (mid)

SmogLayer_3 (between mid and front):
  motion_scale: Vector2(0.75, 0)  # Between 0.6 (mid) and 0.9 (front)
```

**Smog Scale Calculation:**
- Smog texture: 1920x1080
- Each smog layer should cover viewport with slight overlap
- Scale = viewport_size / (texture_size * layer_scale)

Current viewport: 960x540 (typical game resolution)
- SmogLayer_1: scale 0.08 (current Main.tscn has scale 0.375 on layer, 10x on sprite)
- SmogLayer_2: scale 0.205
- SmogLayer_3: scale 0.26

### 4. Parallax Spawner Layers

**Far Layer:**
```
ParallaxLayer:
  motion_scale: Vector2(0.3, 0)

FarLayerSpawner:
  base_scale: 0.35  # From data
  scale_variance: 0.05
  # Y calculated by quadratic formula: y = 410 - 400*scale + 90*scale²
```

**Mid Layer:**
```
ParallaxLayer:
  motion_scale: Vector2(0.6, 0)

MidLayerSpawner:
  base_scale: 0.30
  scale_variance: 0.03
  # Y calculated by quadratic formula
```

**Front Layer:**
```
ParallaxLayer:
  motion_scale: Vector2(0.9, 0)

FrontLayerSpawner:
  base_scale: 0.25
  scale_variance: 0.03
  # Y calculated by quadratic formula
```

### 5. Road (Copy from ParallaxScalingEditor)
```
Road:
  position: Vector2(0, 420)  # Ground line
  scale: Vector2(0.7, 0.7)  # Check current Main.tscn
```

### 6. Player (Preserve current Main.tscn)
```
Player:
  position: Vector2(458, 289)  # Current position
  scale: Vector2(0.4, 0.4)  # Current scale
  # All player controller scripts preserved
```

## Implementation Checklist

- [ ] Copy camera settings from ParallaxScalingEditor to Main.tscn
- [ ] Fix sky layer: scale 1.0, position y≈-90
- [ ] Recalculate smog layer scales to eliminate flickering
- [ ] Keep quadratic formula in spawners (already implemented)
- [ ] Verify spawner base_scale values match data analysis
- [ ] Test player controller still works
- [ ] Test lane changing still works
- [ ] Verify parallax scrolling looks correct
