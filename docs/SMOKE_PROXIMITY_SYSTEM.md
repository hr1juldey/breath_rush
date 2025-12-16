# Smoke Proximity AQI System - Technical Documentation

## Overview

The smoke proximity system applies a temporary **+700 AQI spike** when the player passes through active car smoke without a mask. This creates a high-risk mechanic that rewards careful maneuvering and mask usage.

## Game Design

### Smoke Properties
- **Smoke AQI Value**: 700 (extreme pollution)
- **Trigger**: Player proximity to active smoke particles
- **Mask Protection**: 100% damage reduction when wearing mask
- **Duration**: Continuous while in smoke cloud
- **Range**: Based on particle visibility rect (±5000px horizontally, ±1000px vertically)

### Mask Mechanics
- **Current Effect**: Blocks AQI-based health drain (30s duration)
- **New Effect**: Blocks smoke proximity AQI spike (700 AQI)
- **Leak Period**: Last 5 seconds of mask allow smoke damage through
- **Strategic Use**: Use masks before passing smoking cars

### Player Risk vs Reward
```
NO MASK:
- Passing car: +700 AQI temporary
- Health drains faster due to high AQI
- DANGER: Can die quickly if multiple cars smoke simultaneously

WITH MASK:
- Passing car: No AQI spike
- Health stable (mask blocks AQI drain)
- SAFE: Can maneuver freely through traffic
- RISK: Mask expires after 30s, leaves you vulnerable
```

---

## Technical Implementation

### Architecture

```
Player (has PlayerMask component)
    ↓
    Checks mask status
    ↓
SmokeEmitter (on each car)
    ├─ Local Smoke Particles (5s lifetime)
    ├─ Global Smoke Particles (15s lifetime)
    └─ SmokeDamageZone (NEW - proximity detector)
        ↓
        Area2D with visibility-rect-sized collision
        ↓
        Detects player entry/exit
        ↓
        Applies/removes smoke AQI effect
        ↓
AQIManager
    └─ Tracks active smoke sources
    └─ Applies continuous +700 AQI per frame while player in smoke
```

### Components

#### 1. SmokeDamageZone.gd
**Purpose:** Detect player proximity to smoke and manage AQI effect
**Attached to:** SmokeEmitter (node on each car)
**Behavior:**
- Area2D that matches particle visibility rect
- `area_entered` signal when player enters smoke
- `area_exited` signal when player leaves smoke
- Applies/removes AQISmokeSource dynamically

**Key Properties:**
```gdscript
var smoke_aqi_source: AQISmokeSource = null  # Currently active source
var player_in_smoke: bool = false
var base_aqi_effect: float = 700.0  # The smoke AQI value

func _on_area_entered(area):
    if area.is_in_group("player"):
        player_in_smoke = true
        # Check if player has mask protection
        if not _player_has_mask():
            # Create smoke AQI source
            _apply_smoke_aqi_effect()

func _on_area_exited(area):
    if area.is_in_group("player"):
        player_in_smoke = false
        # Remove smoke AQI source
        _remove_smoke_aqi_effect()
```

#### 2. AQISmokeSource.gd
**Purpose:** Temporary AQI source representing active smoke damage
**Extends:** AQISource
**Behavior:**
- Only active when player is in smoke
- Pure additive AQI (700 per frame)
- Automatically destroys when player leaves smoke

**Key Properties:**
```gdscript
class_name AQISmokeSource
extends AQISource

func _init():
    source_type = SourceType.INCREASES_AQI
    range_type = RangeType.NONE  # No distance falloff - direct effect
    base_effect = 700.0  # 700 AQI per minute
```

#### 3. Modified PlayerMask.gd
**New Method:**
```gdscript
func provides_smoke_protection() -> bool:
    """Check if mask is active and NOT in leak period"""
    if not is_wearing_mask():
        return false

    # Leak period (last 5 seconds) allows smoke damage
    if is_leaking():
        return false

    return true
```

---

## Implementation Details

### Step 1: Particle Visibility Bounds

Each car's smoke particles have a visibility rect:
```
LocalSmokeGPU: visibility_rect = Rect2(-5000, -1000, 10000, 2000)
GlobalSmokeGPU: visibility_rect = Rect2(-5000, -1000, 10000, 2000)
```

The SmokeDamageZone uses these same bounds as a CollisionShape2D for detection.

### Step 2: Player Detection

SmokeDamageZone uses Area2D physics:
```gdscript
# Create invisible collision area
var area2d = Area2D.new()
area2d.name = "SmokeDamageZone"

# Add collision shape matching particle bounds
var shape = RectangleShape2D.new()
shape.size = Vector2(10000, 2000)  # Width x Height of visibility rect
area2d.add_child(shape)

# Offset to particle emission center
area2d.position = Vector2(0, -500)  # Center of visibility rect
```

### Step 3: AQI Application

When player enters smoke:
```gdscript
# Create temporary smoke AQI source
var smoke_source = AQISmokeSource.new()
smoke_source.name = "SmokeDamage_" + str(randi())
get_parent().add_child(smoke_source)  # Add to car, so it's grouped

# Track for removal on exit
smoke_aqi_source = smoke_source
```

### Step 4: Mask Protection

Before creating smoke source, check mask:
```gdscript
var player = area.get_parent()  # Area's parent is Player
var mask_component = player.get_node_or_null("PlayerMask")

if mask_component and mask_component.provides_smoke_protection():
    # Mask is active - no smoke damage
    return

# Mask expired or not wearing - apply smoke damage
_apply_smoke_aqi_effect()
```

### Step 5: Continuous Protection Check

Since mask can expire while player is in smoke:
```gdscript
func _process(delta):
    if not player_in_smoke:
        return

    var player = _get_player()
    if not player:
        return

    var mask_component = player.get_node_or_null("PlayerMask")
    var should_have_protection = mask_component and mask_component.provides_smoke_protection()
    var has_source = smoke_aqi_source != null and is_instance_valid(smoke_aqi_source)

    # Mask just activated - remove smoke source
    if should_have_protection and has_source:
        _remove_smoke_aqi_effect()

    # Mask just expired - add smoke source
    if not should_have_protection and not has_source:
        _apply_smoke_aqi_effect()
```

---

## Physics & Collision Setup

### SmokeDamageZone Collision Configuration

```
Area2D (SmokeDamageZone)
├─ collision_layer = 0 (not on any layer)
├─ collision_mask = 1 (only detect player on layer 1)
└─ CollisionShape2D
    └─ RectangleShape2D (10000x2000)
```

**Why this setup:**
- `collision_layer = 0`: Smoke zones don't collide with anything
- `collision_mask = 1`: Only listen for player (layer 1) entry
- Prevents smoke zone from interfering with car/obstacle collision

### Player Detection

Player must be in group "player":
```gdscript
# In Player.gd _ready()
add_to_group("player")
```

---

## AQI Math

### Temporary AQI Spike

When player enters smoke cloud:
```
Current AQI = 100
Player enters smoke with NO mask
→ Smoke applies +700 AQI per second
→ Each frame: aqi += 700 * delta

At 60 FPS (delta = 0.0167):
aqi_per_frame ≈ +11.7 AQI
aqi_after_5_frames ≈ +58.5 AQI
```

### With Mask Active

When player enters smoke cloud:
```
Current AQI = 100
Player enters smoke WITH active mask
→ Mask provides 100% protection
→ No AQI change from smoke
→ Mask allows safe passage
```

### During Mask Leak (Last 5s)

When player enters smoke cloud:
```
Current AQI = 100
Player enters smoke with LEAKING mask
→ Mask leak period allows smoke damage
→ Same as no mask: +700 AQI per second
```

---

## Gameplay Flow

### Safe Passage (With Mask)
1. Pickup mask (30s duration)
2. See car ahead with smoke
3. Drive through smoke cloud
4. **Result**: No AQI increase, safe passage
5. Mask expires, now vulnerable again

### Risky Passage (No Mask)
1. No mask equipped
2. See car ahead with smoke
3. Try to drive through smoke cloud
4. **Result**: +700 AQI per second
5. Health drains rapidly due to high AQI
6. Must exit smoke or use emergency mask

### Multiple Cars (Extreme Risk)
1. No masks
2. Two smoking cars on road
3. Unable to avoid both
4. **Result**: Stacked AQI sources (1400+ AQI per second)
5. Health drains extremely fast
6. **Likely death** without mask intervention

---

## Testing Checklist

- [ ] Smoke damage zone created when car spawns
- [ ] Smoke damage zone destroyed when car despawns
- [ ] Player entering smoke (no mask): AQI increases +700/sec
- [ ] Player exiting smoke: AQI stops increasing
- [ ] Player in smoke (with mask): AQI unchanged
- [ ] Player in smoke (mask expires): AQI starts increasing
- [ ] Health drains faster in heavy smoke
- [ ] Multiple cars = stacked smoke effects
- [ ] Can survive smoke with good mask timing
- [ ] No performance impact from smoke zones

---

## Design Balance

### Difficulty Knobs

**Adjust smoke_aqi_effect for difficulty:**

- **Easy**: 300 AQI (passable without mask if quick)
- **Normal**: 700 AQI (dangerous without mask)
- **Hard**: 1000+ AQI (almost impossible without mask)

**Adjust car smoke lifespan:**

- **Shorter** (5-10s): Smoke clouds dissipate quickly
- **Longer** (20+s): Smoke persists, harder to avoid

**Adjust mask duration:**

- **Shorter** (15s): Masks are precious resource
- **Longer** (45s): More forgiving gameplay

---

## Future Enhancements

1. **Visual Feedback**: Red vignette when in heavy smoke
2. **Audio Cues**: Coughing sound when in smoke without mask
3. **Particle Density**: Thicker smoke = more AQI
4. **Wind System**: Smoke drifts based on wind direction
5. **Mask Upgrades**: Better masks = stronger protection
6. **Poison Damage**: Smoke applies both AQI and direct damage
