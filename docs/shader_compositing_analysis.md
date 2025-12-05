# Alpha Compositing Error Analysis

**Date**: 2025-12-05
**Issue**: Breathing animation showing wrong colors (cyan) and not matching Python prototype
**Root Cause**: Incorrect compositing method in shader (using `mix()` instead of Porter-Duff "over")

---

## Python Reference Implementation (CORRECT)

### Code from test_degradation_simple.py (line 74-84):

```python
# BOTTOM: Damage sprite (static)
composite = damage_sprites[current_level].copy()

# TOP: Masked breathing sprite (oscillating alpha)
breathing_modulated = breathing_masked_sprites[current_level].copy()
breathing_array = np.array(breathing_modulated)
breathing_array[:, :, 3] = (breathing_array[:, :, 3] * alpha).astype(np.uint8)
breathing_modulated = Image.fromarray(breathing_array)

composite = Image.alpha_composite(composite, breathing_modulated)
```

### What PIL's `alpha_composite()` Does:

PIL uses the **Porter-Duff "Over" operator** - the industry standard for layering transparent images.

**Formula** (straight alpha):
```
final_alpha = src.a + dst.a × (1 - src.a)
final_rgb = (src.rgb × src.a + dst.rgb × dst.a × (1 - src.a)) / final_alpha
```

**Behavior**:
- Where breathing sprite is opaque (alpha=1): Show breathing sprite only
- Where breathing sprite is transparent (alpha=0): Show damage sprite only
- Where breathing sprite is semi-transparent: Proper alpha compositing (NOT simple blend)

**Key**: This respects the masked breathing sprite's transparency - where lungs are "gone", the breathing sprite is fully transparent, so the damage sprite shows through completely.

---

## Current Shader Implementation (WRONG)

### Code from health_breathing.gdshader (line 24-33):

```glsl
// Modulate breathing texture alpha by breathing animation
vec4 modulated_breathing = breathing_color;
modulated_breathing.a *= breathing_alpha;

// Alpha composite: breathing texture over damage texture
// If breathing pixel is transparent, show damage underneath
vec3 blended_rgb = mix(damage_color.rgb, breathing_color.rgb, modulated_breathing.a);
float blended_a = max(damage_color.a, modulated_breathing.a);

COLOR = vec4(blended_rgb, blended_a);
```

### What This Actually Does:

**The `mix()` function**: `mix(a, b, t) = a × (1-t) + b × t`

So the shader computes:
```glsl
blended_rgb = damage_color.rgb × (1 - modulated_breathing.a) + breathing_color.rgb × modulated_breathing.a
```

**This is LINEAR INTERPOLATION, NOT alpha compositing!**

### Why This Fails:

1. **Ignores destination alpha**: Only uses modulated_breathing.a as blend factor
2. **Blends RGB values incorrectly**: Doesn't account for pre-multiplication
3. **Wrong alpha calculation**: `max(src.a, dst.a)` is not Porter-Duff formula

### Visual Consequence - The Cyan Color Mystery:

When breathing sprite has transparent areas (masked-out lungs):
- The breathing texture file may contain **residual RGB data** in transparent pixels (artifacts from masking)
- Even though alpha=0, the RGB channels might have cyan/blue values
- `mix()` blends these RGB values proportionally, causing **color bleeding**
- Result: Cyan ghosts appear where lungs should be invisible

**Example**:
```
Breathing texture at "gone lung" position:
  RGBA = (100, 200, 255, 0)  ← Cyan color with alpha=0

Current shader (WRONG):
  blended_rgb = damage.rgb × (1-0) + (100,200,255) × 0 = damage.rgb ✓

But when modulated_breathing.a = 0.3 (during breathing cycle):
  blended_rgb = damage.rgb × 0.7 + (100,200,255) × 0.3
  Result: Cyan tint bleeds through! ✗

Correct Porter-Duff (RIGHT):
  If breathing.alpha = 0 originally, modulation makes it 0
  Alpha composite shows damage.rgb only ✓
```

---

## Porter-Duff "Over" Operation Explained

### Conceptual Model (Source: [Porter-Duff Compositing](https://ssp.impulsetrain.com/porterduff.html))

> "Think of two pieces of cardboard held up with one in front of the other. Neither shape is trimmed, and in places where both are present, only the top layer is visible."

**Key Insight**: Porter-Duff is NOT blending colored glass - it's compositing opaque shapes with anti-aliased edges.

### The Formula (Straight Alpha)

Source: [Alpha Compositing OpenGL](https://apoorvaj.io/alpha-compositing-opengl-blending-and-premultiplied-alpha)

```glsl
// Given:
vec4 src;  // Source (breathing sprite) - foreground
vec4 dst;  // Destination (damage sprite) - background

// Porter-Duff "over":
float final_alpha = src.a + dst.a * (1.0 - src.a);

vec3 final_rgb;
if (final_alpha > 0.0) {
    final_rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / final_alpha;
} else {
    final_rgb = vec3(0.0);  // Both fully transparent
}

gl_FragColor = vec4(final_rgb, final_alpha);
```

### Breakdown:

1. **Alpha composition**: `src.a + dst.a × (1 - src.a)`
   - If src fully opaque (a=1): final_alpha = 1 + 0 = 1
   - If src fully transparent (a=0): final_alpha = 0 + dst.a = dst.a
   - If src semi-transparent: final_alpha is weighted sum

2. **RGB composition**: `(src.rgb × src.a + dst.rgb × dst.a × (1-src.a)) / final_alpha`
   - Source contribution: `src.rgb × src.a` (pre-multiply source)
   - Destination contribution: `dst.rgb × dst.a × (1-src.a)` (dst shows through src's transparency)
   - Divide by final alpha to get proper color

3. **Division safety**: Check `final_alpha > 0` to avoid divide-by-zero

---

## Common Compositing Mistakes

### Mistake 1: Using `mix()` / `lerp()` (What I Did)

```glsl
// WRONG - This is linear interpolation, not compositing
COLOR.rgb = mix(dst.rgb, src.rgb, src.a);
```

**Problem**: Treats alpha as opacity (colored glass) rather than coverage (cardboard cutout)

**Result**:
- Blends RGB values even where source should be invisible
- Causes color bleeding from transparent pixels
- Doesn't respect the layer model

### Mistake 2: Forgetting Pre-multiplication

```glsl
// WRONG - Not pre-multiplying by alpha
COLOR.rgb = src.rgb + dst.rgb * (1.0 - src.a);
```

**Problem**: Source RGB should be weighted by src.a before adding

### Mistake 3: Wrong Alpha Formula

```glsl
// WRONG - Using max() instead of Porter-Duff formula
COLOR.a = max(src.a, dst.a);
```

**Problem**: Alpha should be additive with occlusion factor, not max

### Mistake 4: Division by Zero

```glsl
// WRONG - Can crash when both layers fully transparent
COLOR.rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / final_alpha;
```

**Fix**: Guard with conditional check

---

## Godot Shader-Specific Considerations

Source: [Godot Shaders Blending Modes](https://godotshaders.com/snippet/blending-modes/)

### Canvas Item Shaders

Godot's `canvas_item` shaders work in RGBA space. For alpha compositing:

1. **Straight alpha** (default): Colors NOT pre-multiplied, need full Porter-Duff formula
2. **Premultiplied alpha**: Can use simplified formula, but requires texture format support

### Texture Filtering Artifacts

From [Godot Proposals #4433](https://github.com/godotengine/godot-proposals/issues/4433):

> "Texture filtering of translucent pixels generally results in rendering artifacts due to the nature of post-multiplicative alpha compositing"

**Issue**: When GPU samples between pixels during texture filtering, it interpolates RGBA separately. If RGB has garbage data in transparent pixels, filtering creates halos.

**Solution**: Ensure masked breathing sprites have RGB=0 where alpha=0 (or use premultiplied textures)

---

## Correct Shader Implementation

### For Godot Canvas Item (Straight Alpha):

```glsl
void fragment() {
    // Sample textures
    vec4 dst = texture(damage_texture, UV);      // Background (damage)
    vec4 src_raw = texture(breathing_texture, UV); // Foreground (breathing)

    // Modulate breathing sprite's alpha by animation
    float breathing_alpha = (sin(TIME * 2.0 * 3.14159 / breathing_period) + 1.0) / 2.0;
    breathing_alpha *= breathing_strength;

    vec4 src = src_raw;
    src.a *= breathing_alpha;  // Modulate source alpha

    // Porter-Duff "over" operation: src over dst
    float final_a = src.a + dst.a * (1.0 - src.a);

    vec3 final_rgb;
    if (final_a > 0.0) {
        // Proper alpha compositing with pre-multiplication
        final_rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / final_a;
    } else {
        // Both fully transparent - use black
        final_rgb = vec3(0.0);
    }

    COLOR = vec4(final_rgb, final_a);
}
```

### Key Differences from Current (Broken) Implementation:

| Aspect | Current (Wrong) | Correct |
|--------|----------------|---------|
| **RGB blending** | `mix(dst.rgb, src.rgb, src.a)` | `(src.rgb × src.a + dst.rgb × dst.a × (1-src.a)) / final_a` |
| **Alpha calculation** | `max(dst.a, src.a)` | `src.a + dst.a × (1-src.a)` |
| **Pre-multiplication** | None | `src.rgb × src.a` and `dst.rgb × dst.a` |
| **Division safety** | None | `if (final_a > 0.0)` guard |
| **Color bleeding** | Yes - blends garbage RGB | No - respects alpha=0 |

---

## Why This Wasted 3 Hours in Python

You likely encountered similar issues during prototyping:

### Common PIL Mistake:

```python
# WRONG - Manual blending instead of alpha_composite
result = Image.blend(damage, breathing, alpha)  # Linear interpolation
```

vs

```python
# CORRECT - Proper alpha compositing
result = Image.alpha_composite(damage, breathing)  # Porter-Duff "over"
```

### Debugging Clues That Point to Compositing Errors:

1. **Color bleeding/halos**: Unexpected colors at edges or in transparent areas
2. **Wrong opacity**: Layers too transparent or too opaque
3. **Color shifts**: Tint changes when layering (like the cyan we saw)
4. **Edge artifacts**: Bright or dark fringes around objects

---

## Testing the Fix

### Before (Current Shader):
- ✗ Cyan color appears during breathing animation
- ✗ Colors blend incorrectly in transparent areas
- ✗ Doesn't match Python prototype visually

### After (Porter-Duff Implementation):
- ✓ No color bleeding from transparent pixels
- ✓ Proper layering: breathing sprite over damage sprite
- ✓ Matches Python prototype exactly
- ✓ Clean edges, no halos or artifacts

### Test Procedure:

1. Replace shader fragment code with correct Porter-Duff implementation
2. Run game and observe breathing animation
3. Compare side-by-side with `degradation_simple_5to1.webm` video from Python test
4. Verify:
   - No cyan or unexpected colors
   - Breathing lungs oscillate brown↔pink smoothly
   - Transparent lung areas show damage sprite underneath
   - Health degradation changes lung count correctly (5→4→3→2→1→0)

---

## References

- [Blending Modes - Godot Shaders](https://godotshaders.com/snippet/blending-modes/)
- [Porter-Duff Compositing Explained](https://ssp.impulsetrain.com/porterduff.html)
- [Alpha Compositing, OpenGL Blending and Premultiplied Alpha](https://apoorvaj.io/alpha-compositing-opengl-blending-and-premultiplied-alpha)
- [Godot Proposals #4433 - Premultiplied Alpha](https://github.com/godotengine/godot-proposals/issues/4433)

---

## Summary

**The Bug**: Using `mix()` for alpha compositing is a fundamental mistake that causes:
- Color bleeding from transparent pixels (cyan artifacts)
- Incorrect layer blending
- Doesn't match Porter-Duff "over" operator used by PIL

**The Fix**: Implement proper Porter-Duff "over" formula in shader:
- Pre-multiply RGB by alpha
- Use correct alpha composition formula
- Guard against division by zero
- Respect transparency completely (alpha=0 means invisible, not translucent)

**Lesson**: Alpha compositing ≠ Linear interpolation. Image layers are cardboard cutouts, not colored glass.
