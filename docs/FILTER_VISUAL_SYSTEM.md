# Filter Visual System - Air Purification Effect

## Overview

The dropped filter shows active air purification with two particle systems:
1. **Intake System**: Dark smoke particles sucked INTO the filter via curved paths
2. **Emission System**: Light blue clean air particles emitted outward

## Filter Components

### Visual Elements
- **Sprite**: Air purifier device (filter_1.webp)
- **Intake_1 & Intake_2**: Path2D curves showing suction flow lines
- **IntakeSmokeParticles**: Dark particles pulled toward filter
- **CleanAirEmission**: Light blue particles flowing outward

### Intake Particle Flow

```
Intake Position: (-491, -44) from filter center
    ↓
Particles spawn at left intake opening
    ↓
Spread outward initially (spread: 180°)
    ↓
Gravity (300, 100) pulls them toward center
    ↓
Trail effects show curved path into filter
    ↓
3-second lifetime → particles die at center
    ↓
Visual "collision" with filter - smoke disappears
```

## Technical Details

### IntakeSmokeParticles Settings

```gdscript
position = (-491, -44)              # Offset from filter (left side intake)
amount = 50                         # Particle count
lifetime = 3.0                      # Seconds before dying at center
local_coords = true                 # Relative to filter position
trail_enabled = true                # Shows curving path
trail_lifetime = 2.5                # Trail visibility duration
trail_sections = 8                  # Smooth curved trail
gravity = Vector3(300, 100, 0)     # Pulls toward filter center
```

### Particle Material (Dark Smoke)

```
- Color: Dark gray (0.2, 0.2, 0.2) - pollution/bad air
- Initial Velocity: 69-195 units/sec
- Damping: 15-25 (slows as pulled in)
- Turbulence: Enabled (organic flow effect)
- Direction: Spread in all directions, then pulled to center
```

### CleanAirEmission Settings

```gdscript
position = (100, 0)                 # Center-right emission point
amount = 300
lifetime = 3.0
emitting = true (activated at cleanup start)
```

### Particle Material (Clean Air)

```
- Color: Light blue (0.3, 0.8, 1.0) - clean air
- Initial Velocity: 80-180 units/sec
- Damping: 1-3 (travels far)
- Direction: Spread outward from filter
```

## Visual Effect Sequence

### 0-15 Second Cleanup Cycle

```
Dark Smoke Intake:
├─ Particles spawn at left intake opening
├─ High initial velocity spreads them outward
├─ Gravity (300, 100) immediately starts pulling them
├─ Particles follow curved paths toward center
├─ Trails show smooth intake flow
├─ Damping slows particles as they approach center
└─ Disappear after 3 seconds (at filter surface)

Clean Air Emission:
├─ Particles spawn from center-right area
├─ Spread outward in all directions
├─ Lower damping allows them to travel far
├─ Persist for 3 seconds showing clean air released
└─ Fade out gradually at lifetime end

Overall Effect:
├─ Bad air being pulled into filter via curves
├─ Good air being released from filter
├─ Shows active purification happening
└─ Visual representation of AQI reduction
```

## Path Curves

The Intake_1 and Intake_2 Path2D nodes define the intake geometry:

```
Intake_1:
  position = (9, 34) + scale (1.5, 1.5688187)
  curve = Bezier path from (-279, -169) to (-33.666668, -80.39831)

Intake_2:
  position = (-7.4390163, -21.364582) + scale (1.3729372, 1.6354169)
  curve = Another intake stream path
```

These curves visually show where the air is being sucked in from, and gravity pulls particles approximately along these paths.

## Gameplay Context

### During Filter Cleanup (15 seconds)

```
Game State:
✓ Game paused (no scrolling)
✓ Player can still move
✓ AQI decreasing (-700/minute from FilterAQISource)
✓ Mask timer still counting down
✓ Particles actively show purification

Player Experience:
1. Drops filter - game pauses
2. Sees dark smoke being pulled into device
3. Sees clean blue air being released
4. Watches for 15 seconds as AQI drops
5. Game resumes when cleanup complete
```

### AQI Effect

While filter is active:
- **FilterAQISource** applied: -700 AQI per minute
- Particles visualize this reduction
- Smoke being removed = AQI dropping
- Clean air released = visible success

## Tuning Parameters

### To adjust intake intensity:
- `gravity = Vector3(300, 100, 0)` - increase for stronger pull
- `damping_min/max` - increase for more drag effect
- `lifetime = 3.0` - shorten to make particles die faster

### To adjust clean air intensity:
- `amount` for CleanAirEmission - increase for more visible flow
- `initial_velocity_min/max` - adjust spread speed
- `lifetime` - longer for more persistent effect

### Trail customization:
- `trail_lifetime` - how long trails persist
- `trail_sections` - more sections = smoother curves
- `trail_section_subdivisions` - finer detail in trails

## Visual Metaphor

The filter shows:
- **Intake curves**: The suction pathways (like real air purifiers)
- **Dark particles disappearing**: Pollution being captured/removed
- **Blue particles emanating**: Clean air being released
- **Paused game**: The player is waiting for purification to happen
- **15-second duration**: Realistic cleanup time

The visual feedback makes the mechanical act of air purification feel tangible and rewarding.
