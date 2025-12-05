# Battery Charge Transition Animation - Godot Implementation Guide

**Date**: 2025-12-05
**Reference**: `test_battery_transitions.py` (Python prototype)
**Target**: Godot 4.5.1 implementation

---

## Python Prototype Behavior Summary

Based on `test_battery_transitions.py`:

### Animation Requirements

**DISCHARGE (battery draining):**

1. Old sprite (current level) **blinks** with sinusoidal oscillation (0.5s)
2. Old sprite **fades out** while new sprite **fades in** (1.0s crossfade)
3. New sprite shown stable (3.5s)
4. Total per transition: 1.5s + 3.5s = 5.0s

**CHARGE (battery charging):**

1. Old sprite **fades out** smoothly (no blinking)
2. New sprite **fades in** simultaneously (1.5s crossfade)
3. New sprite shown stable (3.5s)
4. Total per transition: 1.5s + 3.5s = 5.0s

### Timing Details

- **Blink phase**: 0.0-0.5s (discharge only)
- **Fade phase**: 0.5-1.5s (both directions)
- **Stable phase**: 1.5-5.0s (both directions)
- **Blink oscillation**: Sinusoidal, matching 3-second breathing period
- **Alpha range**: 0.3-1.0 during blink, 0.0-1.0 during fade

---

## Godot Implementation Approaches

Research sources:

- [Scene Transitions - GDQuest](https://www.gdquest.com/tutorial/godot/2d/scene-transition-rect/)
- [Shader vs Animation - Godot Forums](https://godotforums.org/d/29350-shader-vs-animation)
- [Godot 4 Tweens Tutorial](https://www.gotut.net/tweens-in-godot-4/)
- [Stack Overflow: Crossfade Textures](https://stackoverflow.com/questions/68765045/tween-the-texture-on-a-texturebutton-texturerect-fade-out-image1-while-simult)

### Approach Comparison

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| **Tween + Modulate** | Simple, built-in, no shader code | Requires 2 overlapping sprites | Basic crossfades |
| **Shader-based** | Single sprite, GPU-efficient | More complex setup | Complex effects |
| **AnimationPlayer** | Visual editor, reusable | Less dynamic | Pre-planned animations |
| **Hybrid (Recommended)** | Tween for logic, shader for visuals | Requires both skills | Production-ready |

---

## Recommended Implementation: Hybrid Approach

### Why Hybrid?

1. **Shader handles crossfade** - Efficient GPU-based blending between two textures
2. **GDScript handles timing** - Dynamic response to battery changes
3. **Tween manages transitions** - Smooth interpolation of shader parameters
4. **Matches health system** - Consistent architecture with breathing animation

### Architecture

```bash
ChargeDisplay (Sprite2D)
├── ShaderMaterial (crossfade shader)
├── BatteryTransitionUI.gd (GDScript manager)
└── Tween (for transition animation)
```

---

## Implementation Plan

### Step 1: Create Crossfade Shader

**File**: `assets/shaders/battery_crossfade.gdshader`

Based on [Stack Overflow crossfade shader example](https://stackoverflow.com/questions/68765045/tween-the-texture-on-a-texturebutton-texturerect-fade-out-image1-while-simult):

```glsl
shader_type canvas_item;

// Current battery level texture
uniform sampler2D current_texture : hint_default_white;

// Next battery level texture (for transition)
uniform sampler2D next_texture : hint_default_white;

// Crossfade weight: 0.0 = show current, 1.0 = show next
uniform float crossfade_weight : hint_range(0.0, 1.0) = 0.0;

// Blink alpha modulation (for discharge)
uniform float blink_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
 // Sample both textures
 vec4 current_color = texture(current_texture, UV);
 vec4 next_color = texture(next_texture, UV);

 // Apply blink alpha to current texture (discharge only)
 current_color.a *= blink_alpha;

 // Crossfade between current and next
 vec4 blended = mix(current_color, next_color, crossfade_weight);

 COLOR = blended;
}
```

**Key Features:**

- `current_texture`: Currently displayed battery level
- `next_texture`: Target battery level during transition
- `crossfade_weight`: 0→1 animates the crossfade
- `blink_alpha`: 0.3→1.0 creates blink effect (discharge only)

---

### Step 2: Create GDScript Manager

**File**: `scripts/BatteryTransitionUI.gd`

Based on [Godot 4 Tween documentation](https://docs.godotengine.org/en/stable/classes/class_tween.html):

```gdscript
extends Node
"""
Battery Charge Transition Animation Manager

Manages battery display transitions with:
- Discharge: Blink (0.5s) + Crossfade (1.0s)
- Charge: Smooth crossfade (1.5s)
"""

# References
var charge_display: Sprite2D
var player_ref: Node

# Charge sprite paths (7 levels: 5, 4, 3, 2, 1, 0_red, empty)
const CHARGE_SPRITES = [
 "res://assets/ui/charge/charge_5_full.webp",      # Index 0
 "res://assets/ui/charge/charge_4_cells.webp",     # Index 1
 "res://assets/ui/charge/charge_3_cells.webp",     # Index 2
 "res://assets/ui/charge/charge_2_cells.webp",     # Index 3
 "res://assets/ui/charge/charge_1_cell.webp",      # Index 4
 "res://assets/ui/charge/charge_0_red.webp",       # Index 5 (critical)
 "res://assets/ui/charge/charge_empty.webp",       # Index 6
]

# Transition timing (matching Python prototype)
const BLINK_DURATION = 0.5      # Blink phase (discharge only)
const FADE_DURATION = 1.0       # Fade phase (both directions)
const TOTAL_TRANSITION = 1.5    # Total transition time
const BREATHING_PERIOD = 3.0    # Match lung breathing period

# State
var current_charge_level = 0    # Array index (0-6)
var shader_material: ShaderMaterial
var active_tween: Tween = null

func _ready():
 print("[BatteryTransitionUI] Initializing...")

 # Find charge display reference
 var parent = get_parent()
 if parent:
  charge_display = parent.find_child("ChargeDisplay")

 if not charge_display:
  push_error("[BatteryTransitionUI] Could not find ChargeDisplay sprite")
  return

 # Create shader material
 var shader = load("res://assets/shaders/battery_crossfade.gdshader")
 if not shader:
  push_error("[BatteryTransitionUI] Could not load battery_crossfade.gdshader")
  return

 shader_material = ShaderMaterial.new()
 shader_material.shader = shader

 # Apply shader material
 charge_display.material = shader_material

 # Set initial state (full battery)
 _set_stable_level(0)

 print("[BatteryTransitionUI] Initialization complete")

func setup_player_reference(player: Node) -> void:
 """Setup player reference and connect battery signal"""
 print("[BatteryTransitionUI] setup_player_reference called")
 player_ref = player

 if player_ref:
  player_ref.battery_changed.connect(_on_battery_changed)
  print("[BatteryTransitionUI] ✓ Connected to player battery_changed signal")

  # Initialize with current battery
  if "battery" in player_ref:
   var current_battery = player_ref.battery
   _on_battery_changed(current_battery)

func _on_battery_changed(new_battery: float) -> void:
 """Called when player battery changes"""
 print("[BatteryTransitionUI] ━━━ Battery changed: ", new_battery, "% ━━━")

 # Map battery percentage to charge level (0-6)
 var new_level = _get_charge_level(new_battery)
 print("[BatteryTransitionUI] Mapped to level: ", new_level)

 if new_level != current_charge_level:
  var direction = "DISCHARGE" if new_level > current_charge_level else "CHARGE"
  print("[BatteryTransitionUI] Level changed: ", current_charge_level, " → ", new_level, " (", direction, ")")

  _start_transition(current_charge_level, new_level, direction)

func _get_charge_level(battery_percent: float) -> int:
 """Map battery percentage to charge level (array index 0-6)"""
 if battery_percent >= 90: return 0    # 5 cells (full)
 elif battery_percent >= 70: return 1  # 4 cells
 elif battery_percent >= 50: return 2  # 3 cells
 elif battery_percent >= 30: return 3  # 2 cells
 elif battery_percent >= 15: return 4  # 1 cell (green)
 elif battery_percent > 0: return 5    # 1 cell (red - critical)
 else: return 6                         # Empty

func _start_transition(from_level: int, to_level: int, direction: String) -> void:
 """Start battery level transition animation"""
 print("[BatteryTransitionUI] Starting transition: ", from_level, "→", to_level, " (", direction, ")")

 # Kill existing tween
 if active_tween:
  active_tween.kill()

 # Load textures
 var from_texture = load(CHARGE_SPRITES[from_level])
 var to_texture = load(CHARGE_SPRITES[to_level])

 # Set shader textures
 shader_material.set_shader_parameter("current_texture", from_texture)
 shader_material.set_shader_parameter("next_texture", to_texture)

 # Reset shader parameters
 shader_material.set_shader_parameter("crossfade_weight", 0.0)
 shader_material.set_shader_parameter("blink_alpha", 1.0)

 # Create transition based on direction
 if direction == "DISCHARGE":
  _animate_discharge_transition()
 else:
  _animate_charge_transition()

 # Update current level
 current_charge_level = to_level

func _animate_discharge_transition() -> void:
 """Discharge: Blink (0.5s) + Crossfade (1.0s)"""
 active_tween = create_tween()

 # Phase 1: Blink (0.0-0.5s) - Use process callback for sinusoidal blink
 var blink_tween = create_tween()
 blink_tween.tween_method(_update_blink_alpha, 0.0, BLINK_DURATION, BLINK_DURATION)

 # Phase 2: Crossfade (0.5-1.5s) - Fade current out, new in
 active_tween.tween_property(shader_material, "shader_parameter/crossfade_weight", 1.0, FADE_DURATION).set_delay(BLINK_DURATION)

 # When done, set stable state
 active_tween.finished.connect(_on_transition_finished)

func _animate_charge_transition() -> void:
 """Charge: Smooth crossfade (1.5s)"""
 active_tween = create_tween()

 # No blink for charging - just smooth crossfade
 shader_material.set_shader_parameter("blink_alpha", 1.0)

 # Crossfade from old to new
 active_tween.tween_property(shader_material, "shader_parameter/crossfade_weight", 1.0, TOTAL_TRANSITION)

 # When done, set stable state
 active_tween.finished.connect(_on_transition_finished)

func _update_blink_alpha(time: float) -> void:
 """Update blink alpha with sinusoidal oscillation (matches breathing)"""
 # Sinusoidal oscillation matching 3-second breathing period
 var scaled_time = time * (BREATHING_PERIOD / BLINK_DURATION)
 var alpha = (sin(scaled_time * 2.0 * PI / BREATHING_PERIOD) + 1.0) / 2.0
 # Map from 0-1 to 0.3-1.0 range
 alpha = 0.3 + alpha * 0.7

 shader_material.set_shader_parameter("blink_alpha", alpha)

func _on_transition_finished() -> void:
 """Transition complete - set stable state"""
 print("[BatteryTransitionUI] Transition finished, setting stable state")
 _set_stable_level(current_charge_level)

func _set_stable_level(level: int) -> void:
 """Set stable battery level (no transition)"""
 var texture = load(CHARGE_SPRITES[level])

 # Set both textures to same (no crossfade)
 shader_material.set_shader_parameter("current_texture", texture)
 shader_material.set_shader_parameter("next_texture", texture)
 shader_material.set_shader_parameter("crossfade_weight", 0.0)
 shader_material.set_shader_parameter("blink_alpha", 1.0)

 print("[BatteryTransitionUI] ✓ Stable level set: ", level)
```

---

### Step 3: Integrate into HUD

**File**: `scripts/HUD.gd` (modifications)

```gdscript
# Add variable for battery transition UI
var battery_transition_ui: Node

func _ready():
 # ... existing code ...

 # Create and add battery transition UI
 battery_transition_ui = load("res://scripts/BatteryTransitionUI.gd").new()
 add_child(battery_transition_ui)
 print("[HUD] BatteryTransitionUI created and added as child")

 # Setup player reference for battery transition UI
 if player_ref:
  battery_transition_ui.setup_player_reference(player_ref)

 # ... existing code ...
```

---

### Step 4: Update HUD Scene

**File**: `scenes/HUD.tscn` (ChargeDisplay node)

Current:

```bash
[node name="ChargeDisplay" type="TextureRect" parent="TopLeft"]
```

Change to:

```bash
[node name="ChargeDisplay" type="Sprite2D" parent="TopLeft"]
position = Vector2(100, 50)  # Adjust as needed
scale = Vector2(1.0, 1.0)    # Adjust as needed
```

**Why Sprite2D?**

- Better for shader materials
- Consistent with LungBase (health display)
- Easier to manage single texture with shader

---

## Alternative: Pure Tween Approach (Simpler)

If you prefer simpler implementation without shaders:

### Two-Sprite Overlay Method

Based on [Godot Forums: Crossfade](https://godotforums.org/d/30677-crossfade-transition-between-two-nodes):

**Scene structure:**

```bash
ChargeDisplay (Node2D)
├── CurrentSprite (Sprite2D) - modulate.a = 1.0
└── NextSprite (Sprite2D) - modulate.a = 0.0 (hidden)
```

**Transition code:**

```gdscript
func _animate_crossfade(from_texture, to_texture, is_discharge):
 current_sprite.texture = from_texture
 next_sprite.texture = to_texture
 next_sprite.modulate.a = 0.0

 var tween = create_tween().set_parallel(true)

 # Discharge: Add blink to current sprite
 if is_discharge:
  # Blink phase (0.0-0.5s)
  var blink_tween = create_tween()
  for i in range(3):  # 3 blinks
   blink_tween.tween_property(current_sprite, "modulate:a", 0.3, 0.083)
   blink_tween.tween_property(current_sprite, "modulate:a", 1.0, 0.083)

 # Fade phase (0.5-1.5s or 0.0-1.5s for charge)
 var delay = BLINK_DURATION if is_discharge else 0.0
 tween.tween_property(current_sprite, "modulate:a", 0.0, FADE_DURATION).set_delay(delay)
 tween.tween_property(next_sprite, "modulate:a", 1.0, FADE_DURATION).set_delay(delay)

 await tween.finished
 current_sprite.texture = to_texture
 current_sprite.modulate.a = 1.0
 next_sprite.modulate.a = 0.0
```

**Pros:**

- No shader code required
- Easy to understand
- Good for prototyping

**Cons:**

- Requires two sprite nodes
- More scene complexity
- Less efficient than shader approach

---

## Testing Checklist

After implementation, verify:

- [ ] **Discharge animation**:
  - [ ] Starts with charge_5_full.webp (full battery)
  - [ ] Old sprite blinks (sinusoidal, breathing-pace)
  - [ ] Crossfades to lower charge level
  - [ ] Works for all transitions (5→4, 4→3, ..., 0_red→empty)

- [ ] **Charge animation**:
  - [ ] Starts with current level
  - [ ] Smooth crossfade (no blinking)
  - [ ] Works for all transitions (empty→0_red, 0_red→1, ...)

- [ ] **Timing**:
  - [ ] Blink lasts ~0.5s (discharge only)
  - [ ] Crossfade lasts ~1.0s
  - [ ] Total transition ~1.5s
  - [ ] Blink matches breathing period (3s)

- [ ] **Integration**:
  - [ ] Responds to player.battery_changed signal
  - [ ] Maps battery % correctly to charge levels
  - [ ] Handles rapid battery changes gracefully
  - [ ] No errors in console

---

## Performance Considerations

### Shader Approach (Recommended)

- **GPU Usage**: Minimal - simple texture sampling and mixing
- **Memory**: 2 textures loaded during transition, 1 otherwise
- **CPU**: Only for updating shader uniforms (very low)

### Tween Approach

- **GPU Usage**: Same as shader
- **Memory**: 2 sprite nodes always in memory
- **CPU**: Tween calculations + dual sprite rendering

**Verdict**: Shader approach is slightly more efficient and matches the health system architecture.

---

## Debugging Tips

### Common Issues

1. **Blink too fast/slow**:
   - Adjust `BREATHING_PERIOD` constant
   - Check `_update_blink_alpha()` formula

2. **Crossfade not smooth**:
   - Verify shader uniforms are being set
   - Check Tween easing (use default linear for now)
   - Ensure textures are loaded correctly

3. **Signal not firing**:
   - Add logging to `_on_battery_changed()`
   - Verify Player emits `battery_changed` signal
   - Check player reference is valid

4. **Shader not applying**:
   - Verify shader file loads (check error console)
   - Check ShaderMaterial is applied to sprite
   - Use Remote inspector to view shader parameters at runtime

---

## References

- [Scene Transitions - GDQuest](https://www.gdquest.com/tutorial/godot/2d/scene-transition-rect/)
- [Shader vs Animation - Godot Forums](https://godotforums.org/d/29350-shader-vs-animation)
- [Godot Blink Effect Using Tween](https://code.luasoftware.com/tutorials/godot/godot-blink-and-knockback-effect-using-tween/)
- [Stack Overflow: Crossfade Textures in Godot](https://stackoverflow.com/questions/68765045/tween-the-texture-on-a-texturebutton-texturerect-fade-out-image1-while-simult)
- [Godot 4 Tween Documentation](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [Tweens in Godot 4 Tutorial](https://www.gotut.net/tweens-in-godot-4/)
- [Parallel Tweens - Stack Overflow](https://stackoverflow.com/questions/74791182/godot-tween-transition-parallel-to-2-other-chained-transitions)

---

## Summary

**Recommended Implementation**: Hybrid shader + Tween approach

**Why?**

- ✅ Matches health system architecture (consistency)
- ✅ GPU-efficient crossfade
- ✅ Dynamic Tween-based timing
- ✅ Clean separation: shader for visuals, GDScript for logic
- ✅ Production-ready and maintainable

**Next Steps**:

1. Create shader file
2. Create BatteryTransitionUI script
3. Integrate into HUD
4. Test with battery changes
5. Tune timing to match Python prototype exactly
