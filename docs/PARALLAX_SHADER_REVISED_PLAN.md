# Parallax 2.5D with Shader-Based Sky & Smog - REVISED PLAN
**Breath Rush (Lilypad)**
**Date**: 2025-12-06
**Status**: Architecture Design Phase

---

## Critical Corrections to Previous Plan

### ❌ What Was Wrong

1. **Smog Layer Placement**:
   - ❌ Static CanvasLayer above all parallax (kills depth illusion)
   - ✅ Multiple smog layers BETWEEN parallax layers

2. **Smog Implementation**:
   - ❌ Static sprite with alpha (boring, no depth)
   - ✅ Fragment shader with Perlin noise flowing right-to-left at 1.02× scroll speed

3. **Sky Implementation**:
   - ❌ 3 static crossfading sprites (limits visual quality)
   - ✅ CanvasItem shader with state-based color gradients, responds to AQI signal

4. **Signal System**:
   - ❌ No connection from AQI to visual systems
   - ✅ AQI → Sky shader state transition + Smog opacity update

---

## Revised Architecture

### Scene Tree Structure

```
Main (Node2D)
├─ ParallaxBG (ParallaxBackground)
│  │  Script: ParallaxController.gd (updated)
│  │
│  ├─ SkyLayer (ParallaxLayer, motion_scale 0.1)
│  │  ├─ SkyShaderSprite (Sprite2D, shader-based)
│  │  │  └─ Material: ShaderMaterial with SkyShader.gdshader
│  │  │     - Uniform: sky_state (bad/ok/clear = 0/1/2)
│  │  │     - Uniform: transition_progress (0→1)
│  │  │     - Colors: bad_sky_color, ok_sky_color, clear_sky_color
│  │  │
│  │  └─ [Original 3 sky sprites removed]
│  │
│  ├─ SmogLayer_1 (ParallexLayer, motion_scale 0.15)  ← NEW
│  │  └─ SmogShaderSprite_1 (Sprite2D, shader-based)
│  │     └─ Material: ShaderMaterial with SmogShader.gdshader
│  │        - Uniform: noise_offset (for flow animation)
│  │        - Uniform: opacity (AQI-driven)
│  │        - Uniform: noise_speed (1.02× scroll speed)
│  │
│  ├─ FarLayer (ParallexLayer, motion_scale 0.3)
│  │  └─ FarNode (Node2D)
│  │     └─ Landmark buildings
│  │
│  ├─ SmogLayer_2 (ParallexLayer, motion_scale 0.45)  ← NEW
│  │  └─ SmogShaderSprite_2 (Sprite2D, shader-based)
│  │     └─ Material: ShaderMaterial with SmogShader.gdshader
│  │
│  ├─ MidLayer (ParallexLayer, motion_scale 0.6)
│  │  └─ MidNode (Node2D)
│  │     └─ Trees & decorations
│  │
│  ├─ SmogLayer_3 (ParallexLayer, motion_scale 0.75)  ← NEW
│  │  └─ SmogShaderSprite_3 (Sprite2D, shader-based)
│  │     └─ Material: ShaderMaterial with SmogShader.gdshader
│  │
│  └─ FrontLayer (ParallexLayer, motion_scale 0.9)
│     └─ FrontNode (Node2D)
│        └─ Shops & buildings
│
└─ [Other nodes: Road, Player, HUD, etc.]
```

**Key Changes**:
- Sky becomes shader-based (not 3 sprites)
- 3 smog layers BETWEEN parallax layers (not above all)
- Each smog layer has unique motion_scale matching between-layer depth
- All layers use ShaderMaterial with custom fragment shaders

---

## Shader Implementation

### Sky Shader (`sky_shader.gdshader`)

**Type**: CanvasItem (2D)

**Purpose**:
- Render gradient sky with smooth color transitions
- Respond to AQI state changes (bad/ok/clear)
- Support smooth transition animations between states

**Uniforms**:
```glsl
uniform int sky_state : hint_range(0, 2) = 2;  // 0=bad, 1=ok, 2=clear
uniform float transition_progress : hint_range(0.0, 1.0) = 1.0;  // 0→1 for smooth transition

// Sky color presets
uniform vec3 bad_sky_top : hint_color = vec3(0.8, 0.7, 0.6);      // Dark tan (bad AQI)
uniform vec3 bad_sky_bottom : hint_color = vec3(0.6, 0.5, 0.4);   // Darker tan

uniform vec3 ok_sky_top : hint_color = vec3(0.85, 0.8, 0.75);     // Light tan (ok AQI)
uniform vec3 ok_sky_bottom : hint_color = vec3(0.7, 0.65, 0.6);   // Lighter tan

uniform vec3 clear_sky_top : hint_color = vec3(0.5, 0.8, 1.0);    // Light blue (clear)
uniform vec3 clear_sky_bottom : hint_color = vec3(0.3, 0.6, 1.0); // Darker blue
```

**Fragment Logic**:
```glsl
void fragment() {
    // UV.y: 0 = top, 1 = bottom
    // Get current state colors
    vec3 current_top, current_bottom;
    if (sky_state == 0) {           // bad
        current_top = bad_sky_top;
        current_bottom = bad_sky_bottom;
    } else if (sky_state == 1) {    // ok
        current_top = ok_sky_top;
        current_bottom = ok_sky_bottom;
    } else {                         // clear
        current_top = clear_sky_top;
        current_bottom = clear_sky_bottom;
    }

    // Get previous state colors
    vec3 prev_top, prev_bottom;
    if (sky_state == 0) {
        prev_top = ok_sky_top;      // Previous was ok
        prev_bottom = ok_sky_bottom;
    } else if (sky_state == 1) {
        prev_top = clear_sky_top;   // Previous was clear
        prev_bottom = clear_sky_bottom;
    } else {
        prev_top = bad_sky_top;     // Previous was bad
        prev_bottom = bad_sky_bottom;
    }

    // Interpolate between previous and current
    vec3 top = mix(prev_top, current_top, transition_progress);
    vec3 bottom = mix(prev_bottom, current_bottom, transition_progress);

    // Vertical gradient
    vec3 sky_color = mix(bottom, top, UV.y);

    COLOR = vec4(sky_color, 1.0);
}
```

---

### Smog Shader (`smog_shader.gdshader`)

**Type**: CanvasItem (2D)

**Purpose**:
- Generate organic fog effect using noise
- Flow horizontally from right to left at 1.02× camera scroll speed
- Support opacity modulation via AQI
- Create depth illusion when layered

**Uniforms**:
```glsl
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;      // Noise detail level
uniform float noise_speed : hint_range(0.5, 2.0) = 1.02;      // Scroll speed multiplier
uniform float opacity : hint_range(0.0, 1.0) = 0.5;           // Alpha blending
uniform float noise_time = 0.0;                                // Animated via script
```

**Fragment Logic**:
```glsl
// Perlin-like 2D noise function
float noise(vec2 p) {
    // Simple hash-based pseudo-random noise
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Fractal Brownian Motion (FBM) for organic look
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;

    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

void fragment() {
    // Scroll UV at 1.02× speed
    vec2 uv = UV;
    uv.x -= noise_time * noise_speed;

    // Generate noise pattern
    float fog_pattern = fbm(uv * noise_scale);

    // Remap to 0-1 range
    fog_pattern = smoothstep(0.3, 0.7, fog_pattern);

    // Apply opacity
    float final_alpha = fog_pattern * opacity;

    // Smoke-like gray color
    vec3 fog_color = vec3(0.5, 0.5, 0.5);

    COLOR = vec4(fog_color, final_alpha);
}
```

---

## Updated Controller System

### ParallaxController.gd (Updated)

**New Features**:
- Updates smog shader `noise_time` uniform each frame
- Synchronizes smog scroll speed to camera (1.02× for smog layers)
- Calls sky shader state change when AQI transitions

**Key Methods**:
```gdscript
func update_smog_shader_time(delta: float):
    """Update noise animation for all smog layers"""
    for smog_sprite in [smog_sprite_1, smog_sprite_2, smog_sprite_3]:
        var material = smog_sprite.material as ShaderMaterial
        material.set_shader_parameter("noise_time",
            material.get_shader_parameter("noise_time") + delta * scroll_speed * 1.02)

func transition_sky_to_state(new_state: String):
    """Trigger smooth sky shader transition"""
    # old_state = current sky_state
    # new_state = "bad", "ok", or "clear"
    # Tween from transition_progress 0→1 over 1 second
```

### SkyController.gd (New)

**Purpose**: Manage sky shader state and AQI signal

**Key Methods**:
```gdscript
func set_aqi_state(aqi: float):
    """Update sky based on AQI"""
    var new_state = "clear"
    if aqi > 200:
        new_state = "bad"
    elif aqi > 100:
        new_state = "ok"

    if new_state != current_state:
        transition_to_state(new_state)

func transition_to_state(new_state: String):
    """Smooth transition via shader"""
    sky_shader_material.set_shader_parameter("sky_state", state_to_int(new_state))

    # Tween transition_progress from 0 to 1
    var tween = create_tween()
    tween.tween_property(sky_shader_material, "shader_parameter/transition_progress", 1.0, 1.0)
```

### SmogController.gd (Updated)

**New Features**:
- Updates opacity for all 3 smog layers based on AQI
- Different opacities per layer (closer layers more opaque)

**Key Methods**:
```gdscript
func set_aqi_opacity(aqi: float):
    """Update all smog layers opacity based on AQI"""
    var base_opacity = clamp(aqi / 300.0, 0.0, 0.7)

    # Layered opacity: deeper = more transparent
    smog_material_1.set_shader_parameter("opacity", base_opacity * 0.4)  # Far
    smog_material_2.set_shader_parameter("opacity", base_opacity * 0.6)  # Mid
    smog_material_3.set_shader_parameter("opacity", base_opacity * 0.8)  # Near
```

---

## Implementation Phases

### Phase 1: Shader Files
1. Create `sky_shader.gdshader`
2. Create `smog_shader.gdshader`
3. Test shaders in isolation

### Phase 2: Scene Tree Update
1. Remove static sky sprites
2. Add SkyShaderSprite with ShaderMaterial
3. Add 3 SmogShaderSprites with ShaderMaterial at correct layers
4. Configure all shader uniforms

### Phase 3: Controllers
1. Update ParallaxController to manage smog shader time
2. Create new SkyController for state management
3. Update SmogController for multi-layer opacity

### Phase 4: Signal Integration
1. Connect Game.gd AQI updates to SkyController
2. Connect Game.gd AQI updates to SmogController
3. Test smooth transitions between states

### Phase 5: Fine-Tuning
1. Adjust shader colors for visual appeal
2. Adjust noise parameters for organic feel
3. Tune opacity ratios between layers
4. Test depth perception with assets

---

## Depth Illusion Mechanism

**How Smog Between Layers Creates Depth**:

```
┌─────────────────────────────────────┐
│  Sky                                │ motion_scale: 0.1
├─────────────────────────────────────┤
│  Smog Layer 1 (opacity 0.4 × AQI)  │ motion_scale: 0.15
├─────────────────────────────────────┤
│  Far Landmarks                      │ motion_scale: 0.3
├─────────────────────────────────────┤
│  Smog Layer 2 (opacity 0.6 × AQI)  │ motion_scale: 0.45
├─────────────────────────────────────┤
│  Mid Trees                          │ motion_scale: 0.6
├─────────────────────────────────────┤
│  Smog Layer 3 (opacity 0.8 × AQI)  │ motion_scale: 0.75
├─────────────────────────────────────┤
│  Front Shops (sharp, no fog)        │ motion_scale: 0.9
└─────────────────────────────────────┘
```

**Visual Effect**:
- Far landmarks appear hazier (behind Smog1)
- Mid trees slightly hazier (behind Smog2)
- Front shops crystal clear (behind Smog3, minimal haze)
- Each smog layer scrolls slightly faster than objects behind it
- Creates convincing atmospheric perspective

---

## Mathematical Guarantees

### Sky State Transitions
- Smooth interpolation: `final_color = mix(old_color, new_color, transition_progress)`
- Duration: 1.0 second (smooth, not jarring)
- Progress: 0 → 1 linearly

### Smog Opacity Mapping
- Formula: `opacity = clamp(AQI / 300.0, 0.0, 0.7)`
- Per-layer multipliers:
  - Far smog: `base_opacity × 0.4` (lightest)
  - Mid smog: `base_opacity × 0.6` (medium)
  - Near smog: `base_opacity × 0.8` (heaviest)

### Smog Scroll Speed
- Camera scroll: `scroll_speed * delta`
- Smog noise flow: `scroll_speed * delta * 1.02`
- Relative speed: 2% faster = subtle motion enhancement

---

## Key Differences from Previous Plan

| Aspect | Previous | Revised |
|--------|----------|---------|
| **Smog Position** | Above all layers | Between parallax layers |
| **Smog Count** | 1 overlay | 3 layers (far/mid/near) |
| **Smog Effect** | Static alpha sprite | Animated noise shader |
| **Smog Motion** | No parallax | Parallax + 1.02× flow |
| **Sky Rendering** | 3 crossfading sprites | Single shader gradient |
| **Sky State** | Only supports 3 states | Smooth transitions via shader |
| **AQI Integration** | Only fog opacity | Sky state + Smog opacity |
| **Depth Illusion** | Parallax layers only | Parallax + layered smog haze |

---

## Next Steps

1. **Research**: Validate Perlin noise implementation in Godot shaders
2. **Code Shaders**: Write `sky_shader.gdshader` and `smog_shader.gdshader`
3. **Test**: Create test scene with shaders only
4. **Integrate**: Update Main.tscn and controllers
5. **Polish**: Fine-tune colors, opacity, and noise parameters

---

## Resources

- [Godot 2D Fragment Shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/your_first_shader/your_first_2d_shader.html)
- [Customizable Perlin Fog - Godot Shaders](https://godotshaders.com/shader/customizable-perlin-fog/)
- [Animated 2D Fog - Godot Shaders](https://godotshaders.com/shader/procedural-2d-fog-with-pixelation/)
- [CanvasItem Shaders Reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html)
- [ShaderMaterial Parameter Updates](https://docs.godotengine.org/en/stable/classes/class_shadermaterial.html)

---

**Status**: Architecture complete, ready for shader implementation
**Confidence**: High - Addresses all user feedback and creates superior depth illusion
