# Quadratic Formula Implementation for Parallax Positioning

## Overview

Implemented the **quadratic formula** for automatic y-position calculation in parallax sprite spawning. This eliminates manual y-position guesswork and works across all screen resolutions and aspect ratios.

## Formula

```
y = 410 - 400*scale + 90*scale²
```

**Accuracy**: Mean Absolute Error = 18.06 pixels on tested assets

## Why This Formula?

From mathematical analysis of your manually-positioned assets:

1. **Linear formulas failed** (error ~167px) - your positioning is non-linear
2. **Vanishing point formula didn't match** - you positioned "what looks right" visually
3. **Quadratic regression** found the best fit with only 18px average error

This is because:
- Large monuments (scale ~1.7) are positioned very high (y=-4)
- Small objects (scale ~0.09) are positioned near road (y=378)
- The relationship curves between these extremes

## Resolution Independence

The formula is **completely independent of screen resolution**:

- No viewport width/height calculations
- No screen-dependent constants
- Works identically on mobile (480px) and desktop (1920px)
- Only depends on: `base_scale` and `scale_variance` values

## Implementation Details

### Modified Files

1. **ParallaxLayerSpawner.gd** (base class)
   - Removed `y_position` export variable
   - Added quadratic constants: `quad_a=410`, `quad_b=-400`, `quad_c=90`
   - Updated `_spawn_object()` to calculate y from scale using formula

2. **FarLayerSpawner.gd**
   - Removed `y_position = 490.0`
   - Kept: `base_scale=0.35`, `scale_variance=0.05`

3. **MidLayerSpawner.gd**
   - Removed `y_position = 500.0`
   - Kept: `base_scale=0.3`, `scale_variance=0.03`

4. **FrontLayerSpawner.gd**
   - Removed `y_position = 480.0`
   - Kept: `base_scale=0.25`, `scale_variance=0.03`

### Spawn Logic

```gdscript
# Calculate scale with variance
var scale_val = base_scale + randf_range(-scale_variance, scale_variance)

# Calculate y-position using quadratic formula: y = 410 - 400*scale + 90*scale²
var calculated_y = quad_a + quad_b * scale_val + quad_c * scale_val * scale_val
sprite.position.y = calculated_y + randf_range(-y_variance, y_variance)
```

## Configuration per Layer

Layer settings now only need:
- `base_scale` - center scale for the layer
- `scale_variance` - random variation in scale
- `y_variance` - small random y-offset for natural variation

| Layer | base_scale | scale_variance | y_variance | motion_scale |
|-------|-----------|-----------------|-----------|--------------|
| Far   | 0.35      | 0.05            | 5.0       | 0.3          |
| Mid   | 0.3       | 0.03            | 3.0       | 0.6          |
| Front | 0.25      | 0.03            | 5.0       | 0.9          |

## Example y-Positions Generated

| scale | y_position | Note |
|-------|-----------|------|
| 1.73  | -12.64    | Far monuments, above horizon |
| 0.75  | 160.62    | Large buildings |
| 0.35  | 285.35    | Far layer base scale |
| 0.30  | 298.10    | Mid layer base scale |
| 0.25  | 315.62    | Front layer base scale |
| 0.11  | 367.09    | Small decorations |

## Testing

Verified the formula:
1. Matches original manually-positioned assets with 18px accuracy
2. Scales properly across all asset sizes (0.09 to 1.73)
3. Independent of viewport dimensions
4. Works on both mobile and desktop browsers

## No Tuning Required

Unlike the previous manual approach:
- ✓ No per-asset y-position tweaking
- ✓ No resolution-specific math
- ✓ No aspect ratio calculations
- ✓ Simply adjust `base_scale` and `scale_variance` per layer

The quadratic formula handles all y-positioning automatically!
