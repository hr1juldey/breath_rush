# Filter Particle Path Following System

## Overview

The filter now uses a custom particle shader (`intake_particle_path.gdshader`) to make intake particles follow curved paths toward the filter center and disappear when they "collide" with the filter.

## How It Works

### 1. **Particle Attraction System**

Instead of relying only on gravity, particles are attracted to a target point (the filter center) via shader-based forces:

```gdshader
// Calculate direction and distance to target (filter center)
vec2 direction_to_target = target_point - current_pos;
float distance = length(direction_to_target);

// Apply attraction force toward filter
vec2 normalized_direction = normalize(direction_to_target);
float attraction = attraction_strength;

// Boost attraction as particle gets closer (proximity effect)
float proximity_factor = 1.0 - (distance / 500.0);
attraction += proximity_factor * attraction_strength * proximity_boost;

// Apply force to velocity
VELOCITY.xy += normalized_direction * attraction * DELTA;
```

### 2. **Proximity Boosting**

As particles approach the filter, attraction strength increases. This creates a "funnel" effect that pulls particles faster as they near the center:

- At 500 units away: Normal attraction
- At 250 units away: ~50% stronger attraction
- At 0 units away: ~100% stronger attraction (max boost)

This makes particles accelerate into the filter naturally, creating a visual "suction" effect.

### 3. **Particle Death/Collision**

Particles are "killed" (made invisible) in two ways:

**Near-Field Fade** (60 units from center):
```gdshader
if (distance < kill_distance) {
    COLOR.a *= 0.8;  // Fade each frame

    if (distance < kill_distance * 0.5) {  // 30 units
        VELOCITY = vec3(0.0);
        COLOR.a = 0.0;  // Completely invisible
    }
}
```

**Late-Life Fade** (final 15% of particle lifetime):
```gdshader
if (CUSTOM.y > 0.85) {
    float fade_factor = (1.0 - CUSTOM.y) / 0.15;
    COLOR.a *= fade_factor;
}
```

This ensures particles disappear even if they don't reach the filter.

### 4. **Visual Guides (Intake_1 & Intake_2)**

The Path2D nodes in Filter.tscn are purely visual guides:

- **Intake_1**: Curved path from upper-left into filter
- **Intake_2**: Curved path from lower-left into filter

With the custom shader applying proximity-boosted attraction toward the filter center, particles approximately follow the geometry of these curved paths while being pulled inward.

## Shader Parameters

All shader parameters are configured in `Filter.gd::_setup_intake_particle_shader()`:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `target_point` | `Vector2(0, 0)` | Filter center (in local coordinates) |
| `attraction_strength` | `400.0` | Base pulling force toward filter |
| `kill_distance` | `60.0` | Distance at which particles start fading |
| `proximity_boost` | `0.3` | 30% strength increase at close range |

### Tuning Parameters

To adjust particle behavior, modify values in `Filter.gd::_setup_intake_particle_shader()`:

```gdscript
# Stronger pulling effect - increases acceleration toward filter
shader_material.set_shader_parameter("attraction_strength", 500.0)  # Increase from 400

# Particles die earlier (when further away)
shader_material.set_shader_parameter("kill_distance", 100.0)  # Increase from 60

# More aggressive acceleration as particles approach
shader_material.set_shader_parameter("proximity_boost", 0.5)  # Increase from 0.3
```

## Particle Lifetime

In `Filter.tscn`, intake particles have:

- **Lifetime**: 3.0 seconds
- **Amount**: 50 particles
- **Initial Velocity**: 69-195 units/sec (spreads them outward initially)
- **Damping**: 15-25 (slows particles as they travel)

With the custom shader, particles:
1. Spawn at IntakeSmokeParticles position (-604, -44)
2. Initial velocity spreads them in all directions
3. Attraction force immediately pulls them toward filter (0, 0)
4. Damping slows their outward motion while they're redirected
5. As they approach, proximity boost accelerates them inward
6. At 60 units away, they start fading
7. At 30 units away, they're completely invisible/dead

This creates a smooth "suction" visual effect.

## Kill Zone (Visual Only)

`FilterKillZone` is an invisible Area2D node created in `Filter.gd::_create_filter_kill_zone()`:

- **Position**: Filter center
- **Radius**: 50.0 units (detection zone)
- **Purpose**: Visual reference for particle collision (currently not active for physics)
- **Future**: Can be used to trigger visual effects (glow, sound effects, etc.)

Currently, particle death is handled entirely by the shader. The kill zone can be enhanced to:
- Trigger a "pop" sound effect
- Create flash/glow effects
- Add screen shake on particle impact
- Modify AQI more dynamically based on particle count

## Performance Characteristics

✅ **Advantages:**
- GPU-accelerated (particles processed on graphics card)
- Supports 50+ particles without frame drops
- Shader handles all path-following calculations
- No individual particle tracking needed

⚠️ **Considerations:**
- Shader runs on ALL particles (can't selectively disable)
- All particles attracted to single point (can't path to different endpoints)
- Proximity boost increases GPU load as particles cluster

## Visual Effect Sequence

```
0-3 seconds of intake particle lifetime:
├─ 0.0s: Particles spawn at (-604, -44)
├─ 0.1s: Initial velocity spreads them outward (69-195 units/sec)
├─ 0.5s: Attraction forces redirect them toward (0, 0)
├─ 1.0s: Particles curving inward, trails show path
├─ 1.5s: Proximity boost increases, particles accelerate toward center
├─ 2.4s: Particles within 60 units, start fading
├─ 2.7s: Particles within 30 units, become invisible
└─ 3.0s: All particles either dead or naturally expired
```

## Integration with Game Systems

### AQI System
- Filter deployed → Game pauses
- Intake particles visualize air being cleaned
- CleanAirEmission particles show clean air released
- 15 seconds of cleanup, then game resumes

### Particle Emission Control
In `Filter.gd::_update_cleanup_progress()`:

```gdscript
# Gradually increase particle emission intensity
if intake_particles:
    intake_particles.amount_ratio = lerp(0.3, 1.0, progress)
```

This ramps up particle intensity from 30% to 100% over the 15-second cleanup period.

## Troubleshooting

### Particles not reaching filter
- **Check**: Shader is loaded (`_setup_intake_particle_shader()` debug output)
- **Check**: `target_point` is set to (0, 0) in shader
- **Increase**: `attraction_strength` parameter
- **Decrease**: `damping_max` in Filter.tscn (damping resists attraction)

### Particles disappearing too early
- **Check**: `kill_distance` parameter (currently 60 units)
- **Increase**: `kill_distance` to allow particles to travel further before fading

### Particles not following curved paths
- **Note**: This is expected - shader uses point attraction, not path tracking
- **Workaround**: Particles approximately follow intake curves due to geometry
- **Enhancement**: Could implement waypoint-based path following with custom shader

### Visual glitches or performance drops
- **Check**: Shader syntax in debug console
- **Reduce**: `amount` parameter in Filter.tscn (currently 50)
- **Check**: `visibility_rect` is set to Rect2(-600, -300, 1200, 600)

## Future Enhancements

1. **Multi-Point Attraction**: Waypoint system to follow curves more precisely
2. **Particle Trails**: Enhanced visual representation of intake paths
3. **Impact Effects**: Screen shake, glow, or sound when particles collide with filter
4. **Dynamic Strength**: Adjust attraction based on AQI level
5. **Smoke Density**: More particles when smoke is thicker (higher AQI source)

## Related Files

- **Shader**: `shaders/intake_particle_path.gdshader`
- **Script**: `scripts/Filter.gd` (particles setup)
- **Scene**: `scenes/Filter.tscn` (particle emitter setup)
- **Documentation**: `docs/FILTER_VISUAL_SYSTEM.md` (overall filter design)
