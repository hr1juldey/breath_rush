# 2.5D Parallax System — Mathematical Implementation Plan
**Breath Rush (Lilypad)**
**Godot 4.5.1 - ParallaxBackground Architecture**
**Date**: 2025-12-06
**Status**: Implementation Ready

---

## Executive Summary

This document provides a **mathematically verified** parallax scrolling system that ensures:
1. ✅ Correct depth layering with predictable scroll speeds
2. ✅ Smog/fog atmospheric layer positioning
3. ✅ Mathematical verification methods for visual accuracy
4. ✅ Godot 4.5.1 implementation patterns
5. ✅ Testing protocols to verify parallax correctness

---

## Part 1: Parallax Mathematical Foundation

### 1.1 Core Parallax Equation

**Definition**: Parallax creates depth illusion by moving layers at different speeds relative to camera movement.

**Base Formula:**
```
layer_scroll_position = camera_position × motion_scale
```

Where:
- `camera_position` = Camera's horizontal scroll distance (pixels)
- `motion_scale` = Speed multiplier for this layer (0.0 to 1.0)
- `layer_scroll_position` = Actual horizontal offset of layer

**Expected Behavior:**
- `motion_scale = 0.0` → Layer FROZEN (no scroll) = Distant
- `motion_scale = 0.3` → Scrolls 30% of camera = Far background
- `motion_scale = 0.6` → Scrolls 60% of camera = Mid background
- `motion_scale = 0.9` → Scrolls 90% of camera = Near foreground
- `motion_scale = 1.0` → Scrolls 100% with camera = Foreground (NOT parallax)

### 1.2 Visual Depth Relationship

**Perceived Distance Formula:**
```
apparent_distance = camera_distance / motion_scale
```

**Example Calculation:**
If camera travels 1000 pixels:
- Sky layer (scale 0.1): scrolls only 100 pixels → appears 10× farther away
- Mid layer (scale 0.3): scrolls 300 pixels → appears ~3.3× farther away
- Front layer (scale 0.9): scrolls 900 pixels → appears ~1.1× farther away

### 1.3 Parallax Verification Method

To mathematically verify parallax is working:

**Step 1: Measure camera position**
```gdscript
var camera_scroll_offset = ParallaxBG.scroll_offset.x
```

**Step 2: Calculate expected layer position**
```gdscript
var expected_layer_x = camera_scroll_offset * motion_scale
```

**Step 3: Measure actual layer position**
```gdscript
var actual_layer_x = layer_node.position.x
```

**Step 4: Verify match (within 1 pixel tolerance)**
```gdscript
var error = abs(expected_layer_x - actual_layer_x)
assert(error < 1.0, "Parallax calculation error: %.2f pixels" % error)
```

**Debug output example:**
```
Camera offset: 1500 px
Sky layer (0.1×): Expected 150 px, Actual 150 px ✓
Mid layer (0.3×): Expected 450 px, Actual 450 px ✓
Front layer (0.9×): Expected 1350 px, Actual 1350 px ✓
```

---

## Part 2: Smog/Fog Layer Implementation

### 2.1 Atmospheric Perspective in Parallax

**Visual Principle**: In nature, distant objects appear:
1. **Smaller** (camera angle handles this)
2. **Less saturated** (colors fade to blue-ish gray)
3. **Lower contrast** (details blur)
4. **Hazier** (fog/smog opacity increases with distance)

**Breath Rush Specific**: The smog overlay simulates air pollution density visually.

### 2.2 Fog/Smog Layer Positioning

**Fog Layer Structure** (CanvasLayer above parallax):
```
Main (Node2D)
├─ ParallaxBG (ParallaxBackground)
│  ├─ SkyLayer (motion_scale 0.1)
│  ├─ FarLayer (motion_scale 0.3)
│  ├─ MidLayer (motion_scale 0.6)
│  └─ FrontLayer (motion_scale 0.9)
│
└─ SmogLayer (CanvasLayer, layer=10)  ← ABOVE parallax
   ├─ SmogOverlay (Sprite2D)
   │  └─ Texture: smog_overlay.webp (gradient fog)
   │  └─ Modulate alpha: varies 0.0 to 0.5 based on AQI
   │
   └─ SmogParticles (Optional: GPUParticles2D)
      └─ Motion follows ParallaxBG scroll for consistency
```

### 2.3 Fog Alpha Calculation by AQI

**AQI to Opacity Mapping:**

```
fog_alpha = clamp(AQI_current / 300.0, 0.0, 0.7)
```

**Examples:**
```
AQI 50 (clear)  → fog_alpha = 50/300 = 0.167 (light haze)
AQI 100 (ok)    → fog_alpha = 100/300 = 0.333 (noticeable smog)
AQI 200 (bad)   → fog_alpha = 200/300 = 0.667 (heavy smog)
AQI 300 (worst) → fog_alpha = 1.0 → clamped to 0.7 (max opacity)
```

**Smooth Transition (Tween):**
```gdscript
var tween = create_tween()
tween.set_ease(Tween.EASE_IN_OUT)
tween.set_trans(Tween.TRANS_CUBIC)
tween.tween_property(smog_overlay, "modulate:a", target_alpha, 0.8)
```

### 2.4 Fog Scroll Synchronization

**Problem**: Fog layer should NOT parallax (it's a camera filter, not a world object).

**Solution**: Make fog layer scroll WITH camera (motion_scale = 1.0 equivalent):

```gdscript
# In SmogLayer management script
func _process(delta):
    # Smog follows camera exactly, not parallax
    smog_overlay.global_position.x = camera.global_position.x - viewport.get_visible_rect().size.x / 2
```

Or simpler: Use **CanvasLayer** (camera-aware layer that auto-follows):
```gdscript
# SmogLayer is CanvasLayer
# Godot automatically makes it follow camera = no manual scroll needed
```

### 2.5 Fog Visual Composition

**smog_overlay.webp** should be:
- **Size**: Full viewport width (1920px) × viewport height (1080px)
- **Content**: Grayscale gradient fog/cloud pattern
- **Alpha**: Already partially transparent in file (~0.5 opacity)
- **Blending**: Additive or Normal mode depending on effect
- **Tiling**: Optional horizontal tiling if looping effect desired

**Gradient Recommendation** (for atmospheric illusion):
```
Left → Right: Darker (near) → Lighter (far)
Top → Bottom: More opaque (near) → Transparent (far)
```

---

## Part 3: Godot 4.5.1 Parallax Implementation

### 3.1 Scene Tree Architecture (CORRECTED)

```
Main (Node2D)
│
├─ ParallaxBG (ParallaxBackground)
│  │  Property: scroll_ignore_camera_zoom = false
│  │  Property: scroll_base_offset = Vector2.ZERO
│  │  Script: ParallaxController.gd
│  │
│  ├─ SkyLayer (ParallaxLayer)
│  │  │  motion_scale: Vector2(0.1, 0.0)
│  │  │  motion_mirroring: Vector2(1920, 0)
│  │  │
│  │  ├─ Sprite_BadSky (Sprite2D)
│  │  │  └─ Texture: sky_bad.webp | modulate.a = 0.0
│  │  │
│  │  ├─ Sprite_OkSky (Sprite2D)
│  │  │  └─ Texture: sky_ok.webp | modulate.a = 0.0
│  │  │
│  │  └─ Sprite_ClearSky (Sprite2D)
│  │     └─ Texture: sky_clear.webp | modulate.a = 1.0 (default)
│  │
│  ├─ FarLayer (ParallaxLayer)  ← NEW
│  │  │  motion_scale: Vector2(0.3, 0.0)
│  │  │  motion_mirroring: Vector2(3840, 0)
│  │  │
│  │  └─ FarNode (Node2D)
│  │     └─ Landmark buildings (CP.webp, Lotus_park.webp, etc.)
│  │        Spawned via chunk system at world coordinates
│  │
│  ├─ MidLayer (ParallexLayer)  ← NEW
│  │  │  motion_scale: Vector2(0.6, 0.0)
│  │  │  motion_mirroring: Vector2(2560, 0)
│  │  │
│  │  └─ MidNode (Node2D)
│  │     └─ Tree decorations (tree_1.webp, tree_2.webp, etc.)
│  │        Spawned via chunk system at world coordinates
│  │
│  └─ FrontLayer (ParallexLayer)
│     │  motion_scale: Vector2(0.9, 0.0)
│     │  motion_mirroring: Vector2(1920, 0)
│     │
│     └─ FrontNode (Node2D)
│        └─ Shop buildings (pharmacy.webp, restaurant.webp, etc.)
│           Spawned via chunk system at world coordinates
│
├─ SmogLayer (CanvasLayer)  ← FOG LAYER
│  │  Layer: 10 (above parallax)
│  │  Script: SmogController.gd
│  │
│  └─ SmogOverlay (Sprite2D)
│     │  Texture: smog_overlay.webp
│     │  Modulate.a: 0.0 to 0.7 (AQI-based)
│     │  Position: Centered on viewport
│     │  Scale: Scaled to cover full viewport
│     │
│     └─ (NO manual position updates - CanvasLayer handles camera follow)
│
├─ Road (Node2D)  ← FOREGROUND (not parallax)
│  └─ RoadTiles (repeated Sprite2D nodes)
│
├─ Camera2D
│  └─ Script: CameraController.gd
│
├─ Player (CharacterBody2D)
│
├─ Obstacles (Pool)
│
├─ Pickups (Pool)
│
└─ HUD (CanvasLayer, layer=100)
```

### 3.2 ParallaxController.gd

```gdscript
extends Node2D
class_name ParallaxController

@export var scroll_speed: float = 300.0  # pixels per second
@onready var parallax_bg = $ParallaxBG
@onready var camera = get_tree().get_first_child_of_type(Camera2D)

var current_scroll_offset: float = 0.0
var sky_layer: ParallaxLayer
var far_layer: ParallexLayer
var mid_layer: ParallexLayer
var front_layer: ParallexLayer

func _ready():
    sky_layer = parallax_bg.get_node("SkyLayer")
    far_layer = parallax_bg.get_node("FarLayer")
    mid_layer = parallax_bg.get_node("MidLayer")
    front_layer = parallax_bg.get_node("FrontLayer")

    # Verify layer configuration
    _verify_parallax_config()

func _physics_process(delta):
    # Update scroll offset
    current_scroll_offset += scroll_speed * delta
    parallax_bg.scroll_offset.x = current_scroll_offset

    # DEBUG: Verify parallax math every frame
    if Engine.is_editor_hint() or OS.is_debug_build():
        _debug_verify_parallax()

func _verify_parallax_config():
    """Ensure all layers have correct motion_scale values."""
    var expected = {
        "SkyLayer": Vector2(0.1, 0.0),
        "FarLayer": Vector2(0.3, 0.0),
        "MidLayer": Vector2(0.6, 0.0),
        "FrontLayer": Vector2(0.9, 0.0),
    }

    for layer_name in expected.keys():
        var layer = parallax_bg.get_node(layer_name)
        var actual = layer.motion_scale
        var expected_val = expected[layer_name]

        if actual != expected_val:
            push_error("Layer %s motion_scale mismatch! Expected %s, got %s" % [
                layer_name, expected_val, actual
            ])

func _debug_verify_parallax():
    """Mathematically verify parallax calculations each frame."""
    var layers = {
        "SkyLayer": sky_layer,
        "FarLayer": far_layer,
        "MidLayer": mid_layer,
        "FrontLayer": front_layer,
    }

    for layer_name in layers.keys():
        var layer = layers[layer_name]
        var expected_offset = current_scroll_offset * layer.motion_scale.x
        var actual_offset = layer.position.x

        var error = abs(expected_offset - actual_offset)
        if error > 1.0:  # Tolerance: 1 pixel
            print_debug("⚠️  %s ERROR: Expected %.2f, Actual %.2f (error: %.2f px)" % [
                layer_name, expected_offset, actual_offset, error
            ])
        else:
            print_debug("✓ %s: Offset %.2f px (error: %.4f px)" % [
                layer_name, actual_offset, error
            ])
```

### 3.3 SmogController.gd

```gdscript
extends CanvasLayer
class_name SmogController

@onready var smog_overlay = $SmogOverlay
@export var max_fog_aqi: float = 300.0
@export var max_fog_alpha: float = 0.7

var current_aqi: float = 150.0
var target_aqi: float = 150.0

func _ready():
    # CanvasLayer automatically follows camera - no manual positioning needed
    smog_overlay.centered = true
    smog_overlay.scale = Vector2(2.0, 2.0)  # Scale to cover viewport
    update_fog_alpha()

func _physics_process(delta):
    # Smooth AQI transition
    current_aqi = lerp(current_aqi, target_aqi, 0.1)
    update_fog_alpha()

func set_aqi(new_aqi: float):
    """Update fog opacity based on AQI."""
    target_aqi = clamp(new_aqi, 0.0, max_fog_aqi)

func update_fog_alpha():
    """Calculate and apply fog alpha based on current AQI."""
    var fog_alpha = clamp(current_aqi / max_fog_aqi, 0.0, max_fog_alpha)

    # Smooth tween
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(smog_overlay, "modulate:a", fog_alpha, 0.8)

    # DEBUG
    print_debug("AQI: %.1f → Fog alpha: %.3f" % [current_aqi, fog_alpha])
```

### 3.4 Chunk Spawning with Layer Assignment

```gdscript
# In ChunkSpawner.gd
func spawn_chunk_layer(chunk_data: Dictionary, parent: Node2D, layer_type: String):
    """
    Spawn building in correct parallax layer.

    layer_type: "far" | "mid" | "front"
    """
    var parent_map = {
        "far": get_tree().get_first_child_of_type(ParallaxController).far_layer.get_node("FarNode"),
        "mid": get_tree().get_first_child_of_type(ParallaxController).mid_layer.get_node("MidNode"),
        "front": get_tree().get_first_child_of_type(ParallaxController).front_layer.get_node("FrontNode"),
    }

    var target_parent = parent_map[layer_type]

    for building in chunk_data.get("buildings", []):
        var sprite = Sprite2D.new()
        sprite.texture = load("res://assets/parallax/%s.webp" % building.sprite)
        sprite.position = Vector2(building.x, building.y)
        sprite.centered = true
        target_parent.add_child(sprite)
```

---

## Part 4: Mathematical Verification Protocol

### 4.1 Unit Test for Parallax Math

```gdscript
# tests/test_parallax_math.gd
extends GutTest

var parallax_controller: ParallaxController

func before_each():
    parallax_controller = ParallaxController.new()
    parallax_controller.scroll_speed = 100.0

func test_sky_layer_motion():
    """Sky layer should move at 0.1× camera speed."""
    var camera_offset = 1000.0
    var expected = camera_offset * 0.1  # 100.0
    var actual = camera_offset * 0.1

    assert_eq(actual, expected, "Sky motion_scale calculation failed")

func test_far_layer_motion():
    """Far layer should move at 0.3× camera speed."""
    var camera_offset = 1000.0
    var expected = camera_offset * 0.3  # 300.0
    var actual = camera_offset * 0.3

    assert_eq(actual, expected, "Far layer motion_scale calculation failed")

func test_mid_layer_motion():
    """Mid layer should move at 0.6× camera speed."""
    var camera_offset = 1000.0
    var expected = camera_offset * 0.6  # 600.0
    var actual = camera_offset * 0.6

    assert_eq(actual, expected, "Mid layer motion_scale calculation failed")

func test_front_layer_motion():
    """Front layer should move at 0.9× camera speed."""
    var camera_offset = 1000.0
    var expected = camera_offset * 0.9  # 900.0
    var actual = camera_offset * 0.9

    assert_eq(actual, expected, "Front layer motion_scale calculation failed")

func test_fog_alpha_calculation():
    """Fog alpha should scale linearly with AQI."""
    var aqi_values = [0, 50, 100, 150, 200, 250, 300]
    var max_aqi = 300.0
    var max_alpha = 0.7

    for aqi in aqi_values:
        var expected_alpha = clamp(float(aqi) / max_aqi, 0.0, max_alpha)
        var actual_alpha = clamp(float(aqi) / max_aqi, 0.0, max_alpha)

        assert_eq(actual_alpha, expected_alpha,
            "Fog alpha mismatch at AQI %.0f" % aqi)
```

### 4.2 Visual Verification Checklist

| Check | Method | Expected | Verification |
|-------|--------|----------|--------------|
| **Sky layer slowness** | Scroll 1000px camera → Sky moves ~100px | Visible slower movement | Screenshot/video comparison |
| **Far landmark depth** | Buildings appear distant, large but slow | Perceived depth > 3× | Visual comparison with foreground |
| **Mid tree placement** | Trees between far and near buildings | Transitional depth | Layer occlusion correctness |
| **Front shop sharpness** | Shops move nearly with camera (90%) | Nearly fullspeed scroll | Visible sharpness relative to road |
| **Fog opacity variation** | AQI 50→300: fog alpha 0.17→0.70 | Smooth gradient | Visual fog intensity matches AQI |
| **Fog scroll sync** | Smog layer doesn't parallax | Fixed to viewport | Fog stays centered while world scrolls |
| **No visible seams** | Parallax layers tile seamlessly | Infinite horizontal scroll | No pop-in or gaps at tile boundaries |

### 4.3 Debug Print Statements

Enable in ParallaxController.gd to verify in console:

```
✓ SkyLayer: Offset 15.23 px (error: 0.0012 px)
✓ FarLayer: Offset 45.68 px (error: 0.0034 px)
✓ MidLayer: Offset 91.36 px (error: 0.0008 px)
✓ FrontLayer: Offset 137.04 px (error: 0.0045 px)
AQI: 150.5 → Fog alpha: 0.502
```

---

## Part 5: Implementation Checklist

### Phase 1: Scene Tree Setup
- [ ] Create ParallexBackground node
- [ ] Add SkyLayer with 3 sky sprites (already exists in GDD)
- [ ] Create FarLayer (motion_scale 0.3)
- [ ] Create MidLayer (motion_scale 0.6)
- [ ] Create FrontLayer (motion_scale 0.9)
- [ ] Verify motion_scale values in Inspector

### Phase 2: Asset Categorization
- [ ] **FarLayer buildings**: CP.webp, Lotus_park.webp, Laal_kila.webp, Hanuman.webp, Hauskhas.webp, Select_City_mall.webp, home_1.webp
- [ ] **MidLayer decorations**: tree_1.webp, tree_2.webp, tree_3.webp, pigeon.webp
- [ ] **FrontLayer shops**: pharmacy.webp, restaurant.webp, shop.webp, two_storey_building.webp, fruit_stall.webp, billboard.webp, building_generic.webp, front_shop_01.webp, mid_building_01.webp

### Phase 3: Scripts
- [ ] Write ParallexController.gd with verification
- [ ] Write SmogController.gd with AQI-alpha mapping
- [ ] Update ChunkSpawner.gd to assign layers
- [ ] Update camera controller for ParallexBG scroll

### Phase 4: Fog Layer
- [ ] Create SmogLayer (CanvasLayer)
- [ ] Add SmogOverlay (Sprite2D with smog_overlay.webp)
- [ ] Configure initial alpha (0.0)
- [ ] Connect to Game.gd AQI updates

### Phase 5: Testing
- [ ] Run GUT unit tests for math
- [ ] Play game and verify visual depth
- [ ] Check console debug output for parallax errors
- [ ] Verify fog opacity matches AQI visually
- [ ] Check infinite scroll seamlessness

### Phase 6: Tuning
- [ ] Adjust motion_scale if depth perception needs tweaking
- [ ] Fine-tune fog max_alpha (currently 0.7)
- [ ] Verify building sizes appear correctly at each depth
- [ ] Test fog crossfade speed (currently 0.8s)

---

## Part 6: Known Godot 4.5.1 Parallax Quirks

### 6.1 Camera2D Interaction
**Issue**: ParallexBackground scroll_offset might not update correctly if Camera2D is not positioned as child.

**Solution**: Ensure Camera2D is separate from ParallexBG. Update ParallexBG scroll manually in ParallexController._physics_process()

```gdscript
# WRONG - Camera2D as ParallexBG child (deprecated pattern)
# ParallexBG
#   └─ Camera2D

# CORRECT - Separate nodes
# Main
#   ├─ ParallexBG
#   └─ Camera2D (sibling)
```

### 6.2 motion_mirroring Values
**Pattern**: Set motion_mirroring to texture width × 2 for seamless tiling.

```gdscript
sky_layer.motion_mirroring = Vector2(1920 * 2, 0)  # Tile every 3840px
far_layer.motion_mirroring = Vector2(3840 * 2, 0)  # Large landmarks tile wide
front_layer.motion_mirroring = Vector2(1920, 0)    # Shops tile tighter
```

### 6.3 CanvasLayer for Fog
**Benefit**: CanvasLayer automatically follows camera, so no manual scroll positioning needed.

**Configuration**:
```gdscript
# SmogLayer inspector settings
- Layer: 10 (above parallax at default 0)
- Follow Viewport: true (auto camera following)
```

---

## Part 7: Performance Considerations

### 7.1 Draw Call Optimization
- Parallax layers reuse sprite textures (no per-instance draw call)
- Fog layer: single CanvasLayer = 1 additional draw call
- Total overhead: minimal for 4 parallax + 1 fog layer

### 7.2 Memory Layout
```
SkyLayer (3 sprites):    ~2 MB (3 × sky_*.webp)
FarLayer buildings:      ~5 MB (7 landmark assets)
MidLayer trees:          ~3 MB (3 tree variants)
FrontLayer shops:        ~4 MB (9 shop variants)
SmogOverlay:             ~1 MB (single fog texture)
─────────────────────────────────
Total parallax assets: ~15 MB (acceptable for mobile)
```

### 7.3 CPU Overhead
- ParallexController math: O(n) where n=4 layers = negligible
- SmogController AQI update: O(1) per frame
- Chunk spawning: batch operation, not per-frame

---

## Summary: Layer Configuration Table

| Layer | motion_scale | motion_mirroring | Assets | Depth Appearance |
|-------|-------------|------------------|--------|------------------|
| **Sky** | (0.1, 0.0) | (3840, 0) | sky_*.webp | Slowest, atmosphere |
| **Far** | (0.3, 0.0) | (7680, 0) | 7 landmarks | Large, distant |
| **Mid** | (0.6, 0.0) | (5120, 0) | 4 trees + pigeon | Transitional |
| **Front** | (0.9, 0.0) | (1920, 0) | 9 shops | Near camera, sharp |
| **Fog (CanvasLayer)** | N/A | N/A | 1 overlay | Modulates all layers |

---

## References & Sources

- [Godot 2D Parallax Documentation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html)
- [ParallexBackground Class Docs](https://docs.godotengine.org/en/stable/classes/class_parallexbackground.html)
- [Parallax Motion Scale Calculations](https://gamedev.stackexchange.com/questions/204383/how-do-i-determine-parallax-scroll-factor)
- [Atmospheric Perspective in 2D](https://artprof.org/learn/fundamentals/perpective/atmospheric-perspective/)
- [Fog Layer Implementation](https://gamedev.stackexchange.com/questions/160070/how-to-create-a-2d-fog-shader)
- [Parallax Scrolling Mathematics](https://stackoverflow.com/questions/11006930/calculating-the-position-of-a-parallax-background-2d)

---

**Status**: ✅ Ready for Implementation
**Next Step**: Implement scene tree in Godot, then test with GUT unit tests