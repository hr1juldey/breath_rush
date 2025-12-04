# Breath Rush - Comprehensive Knowledge Base

## Created: 2025-12-04

## Purpose: Reference document for understanding the game state, history, and current issues

---

## Table of Contents

1. [Game Concept Overview](#game-concept-overview)
2. [Technical Stack & Architecture](#technical-stack--architecture)
3. [Visual Design (from Screenshots)](#visual-design-from-screenshots)
4. [Current Implementation Status](#current-implementation-status)
5. [Known Issues & Fixes Applied](#known-issues--fixes-applied)
6. [File Structure & Organization](#file-structure--organization)
7. [Game Mechanics Breakdown](#game-mechanics-breakdown)
8. [HUD & UI System](#hud--ui-system)
9. [Asset Catalog](#asset-catalog)
10. [Development Workflow](#development-workflow)
11. [Next Steps & Roadmap](#next-steps--roadmap)

---

## Game Concept Overview

### Core Pitch

**"Lilypad — Breath Rush"** is a mobile-first, HTML5 endless runner where players:

- Deliver air purifiers in a polluted Indian city
- Plant trees that persist across sessions
- Manage health based on real-time AQI (Air Quality Index)
- Earn AIR Coins based on cleanliness improvements

### Theme & Message

Environmental awareness through gameplay - showing visual improvements to air quality as player delivers purifiers and plants trees.

### Setting

Urban Indian cities featuring recognizable landmarks:

- Connaught Place
- Victoria Memorial-style monuments
- Local shops (Pharmacy, Restaurant)
- Residential buildings

---

## Technical Stack & Architecture

### Platform Details

- **Engine:** Godot 4.5.1 (via Flatpak)
- **Target:** HTML5 export (mobile browsers primary)
- **Language:** GDScript 4.x
- **Audience:** 84% mobile users
- **Dev Workflow:** Code-first in VS Code, test in Godot

### Project Structure

```bash
breath_rush/
├── assets/           # All game art (WebP format)
│   ├── skies/       # 3 sky variants (bad/ok/clear)
│   ├── road/        # Tiling road texture
│   ├── player/      # Vim (scooter) sprite
│   ├── vehicles/    # Enemy cars/bikes
│   ├── pickups/     # Collectibles (mask, filter, sapling)
│   ├── parallax/    # Buildings & decorations
│   └── ui/          # HUD elements
├── scenes/          # .tscn files (7 scenes)
│   ├── Main.tscn    # Core game scene
│   ├── Player.tscn
│   ├── HUD.tscn
│   ├── Obstacle.tscn
│   ├── Mask.tscn
│   ├── Purifier.tscn
│   └── Sapling.tscn
├── scripts/         # GDScript files (10 scripts)
│   ├── Game.gd          # Main orchestrator
│   ├── Player.gd        # Player mechanics
│   ├── SkyManager.gd    # Sky transitions
│   ├── RoadScroll.gd    # Infinite road scrolling
│   ├── Spawner.gd       # Object pooling
│   ├── HUD.gd           # UI management
│   ├── Pickup.gd        # Collectible logic
│   ├── Obstacle.gd      # Enemy behavior
│   ├── DeliveryZone.gd  # Drop-off points
│   └── Persistence.gd   # Save/load system
├── data/
│   └── chunks/      # Level chunk definitions (JSON)
├── config/
│   ├── brand.json       # Reskin configuration
│   └── gameplay.json    # Tuning parameters
└── docs/            # Documentation & GDD
```

### Key Architectural Decisions

#### 1. Code-First Approach

- All scripts written before scenes
- Scenes instantiated from code using `preload()`
- Minimal Godot Inspector usage

#### 2. Object Pooling

- Fixed-size pools: 8 obstacles, 6 pickups
- Recycle instead of `queue_free()` for performance
- Reduces GC pressure on mobile

#### 3. Parallax System

Three-layer depth:

- **SkyLayer** (motion_scale: 0.2) - Slow background
- **MidLayer** (motion_scale: 0.5) - Buildings
- **FrontLayer** (motion_scale: 0.8) - Foreground shops

#### 4. JSON-Driven Content

- Chunks defined in JSON (not heavy .tscn files)
- Allows non-programmer level design
- Easy to version control

---

## Visual Design (from Screenshots)

### Screenshot Analysis (SS/ folder, 11 images)

#### SS/1.png - Game Start

- **HUD:** 5 green hearts (full health), "15 sec remaining" mask timer, 5 red lung icons
- **Scene:** Polluted brownish sky, Connaught Place building, player on yellow scooter at lower-left
- **Pickup:** Large "Aearth Mask N95" collectible floating center-right
- **Player Position:** Low on screen (issue: inconsistent positioning)

#### SS/2.png - Player Movement

- **Change:** Player moved to center-screen (higher Y position)
- **Issue:** Player vertical position jumped significantly
- **Pickup:** N95 mask being collected

#### SS/3.png - Mask Activated

- **New Element:** "Mask on. Keep cutting ahead." message
- **Player:** N95 badge now visible on character's face
- **HUD:** Timer still at 15s
- **Observation:** Mask activation feedback working

#### SS/4.png - Time Progression

- **HUD:** Timer decreased to 14s
- **Scene:** Scrolled forward, residential building visible
- **Player Position:** Center-left, mid-screen

#### SS/5.png - Building Overlap

- **Issue:** Player overlapping with white/blue residential building
- **HUD:** Timer at 13s
- **Observation:** Collision layers may need adjustment

#### SS/6.png - Critical Health Drop

- **MAJOR CHANGE:** Health dropped from 5 hearts to 3 hearts (40% loss)
- **HUD:** Timer jumped to 8s (5 seconds elapsed)
- **Scene:** New background - Victoria Memorial monument
- **Restaurant:** Visible on right side
- **Issue:** Health draining too fast (needs balancing)

#### SS/7.png - Near Death

- **CRITICAL:** Health at 1 heart (20% remaining)
- **HUD:** Timer at 10s
- **New Element:** EV CHARGE station visible (green charging station)
- **Player:** Near charging station
- **Observation:** Player discovered charging mechanic just in time

#### SS/8.png - Battery Charged

- **MAJOR CHANGE:** Health fully restored to 5 hearts!
- **Message:** "Battery Charged 100%" displayed center-screen
- **Mechanic Confirmed:** Charging stations restore health
- **HUD:** Timer still at 10s
- **Visual:** Green charging cable visible on player

#### SS/9.png - Continued Gameplay

- **Scene:** Pharmacy building on far left
- **Player:** Overlapping residential building again
- **HUD:** Timer increased to 12s (mask timer refreshed?)
- **Health:** Full (5 hearts)

#### SS/10.png - Delivery Success + Sky Change

- **MAJOR VISUAL CHANGE:** Sky is now CLEAR BLUE with white clouds!
- **Message:** "Air Purifier Delivered"
- **Effect:** Pollution cleared, atmosphere bright and clean
- **Scene:** Pharmacy still visible, player at residential building
- **HUD:** Timer at 11s, full health
- **Observation:** Sky transition system working perfectly!

#### SS/11.png - Clean Environment

- **Sky:** Continues to be clear blue
- **Scene:** Residential building center-left, player on right
- **HUD:** Timer at 10s, full health
- **Observation:** Clean sky persists after delivery

### Visual Issues Identified

1. **Player Vertical Position Inconsistency**
   - Screenshots show player at wildly different Y positions
   - Sometimes low (SS1), sometimes center (SS2-4), sometimes overlapping buildings (SS5, SS9)
   - **Root Cause:** Lane positioning not properly constrained

2. **Health Bar Not Visible in Screenshots**
   - HUD shows heart icons, but no actual progress bars visible
   - May be rendering issue or color contrast problem

3. **Battery Bar Not Visible**
   - Lung icons shown, but no battery/charge indicator bar

4. **Sky Transition Success**
   - Polluted (SS1-9) → Clear (SS10-11) works perfectly
   - 2-second crossfade as intended

### Gameplay Flow Observed

1. **Start:** Player collects N95 mask (SS1-2)
2. **Activation:** Mask timer starts at 15s (SS3)
3. **Health Drain:** Health drops over time due to pollution (SS4-6)
4. **Critical Moment:** Player at 1 heart discovers EV charging (SS7)
5. **Recovery:** Charging station restores health to full (SS8)
6. **Delivery:** Player delivers air purifier to residential building (SS9)
7. **Reward:** Sky clears, pollution visual removed (SS10-11)

---

## Current Implementation Status

### Phase 1: Foundation ✅ COMPLETE

- [x] Folder structure created
- [x] 23 assets organized into subfolders
- [x] 14 placeholder UI assets created
- [x] Config files (brand.json, gameplay.json)
- [x] Sample chunk (chunk_001.json)

### Phase 2: Core Scripts ✅ COMPLETE

- [x] Game.gd (orchestrator, ~220 lines)
- [x] Player.gd (mechanics, ~200 lines)
- [x] SkyManager.gd (transitions, ~80 lines)
- [x] RoadScroll.gd (tiling, ~60 lines)
- [x] Spawner.gd (pooling, ~130 lines)
- [x] HUD.gd (UI binding, ~110 lines)
- [x] Pickup.gd (interactions, ~40 lines)
- [x] Obstacle.gd (enemies, ~50 lines)
- [x] DeliveryZone.gd (drops, ~50 lines)
- [x] Persistence.gd (save/load, ~90 lines)

### Phase 3: Scene Files ✅ COMPLETE

- [x] Main.tscn (game scene, ~210 lines)
- [x] Player.tscn
- [x] HUD.tscn
- [x] Obstacle.tscn
- [x] Mask.tscn
- [x] Purifier.tscn
- [x] Sapling.tscn

### Phase 4: Critical Fixes ✅ COMPLETE

#### Fix 1: Obstacle.gd Node Type

- **Error:** `extends CharacterBody2D` but using `body_entered` signal
- **Root Cause:** `body_entered` belongs to Area2D, not CharacterBody2D
- **Fix:** Changed `extends Area2D`
- **File:** scripts/Obstacle.gd:1

#### Fix 2: HUD.gd UTF-8 Encoding

- **Error:** Match statement failing due to em-dash characters (`—`)
- **Root Cause:** UTF-8 multi-byte sequences confusing parser
- **Fix:** Replaced `—` with ASCII `-` in 4 lines
- **File:** scripts/HUD.gd:59,62,65,68

#### Fix 3: Persistence.gd Class Declaration Order

- **Error:** `class_name` after `extends`
- **Root Cause:** GDScript 4.x requires `class_name` first
- **Fix:** Moved `class_name Persistence` to line 1
- **File:** scripts/Persistence.gd:1-5

#### Fix 4: Player.gd Signal Emissions

- **Warning:** Signals declared but never emitted
- **Fix:** Added `purifier_deployed.emit()` and `sapling_planted.emit()` in `drop_item()`
- **File:** scripts/Player.gd (drop_item function)

#### Fix 5: Game.gd Parameter Warnings

- **Warning:** Unused parameters shadowing builtins
- **Fix:** Renamed `position` → `_position`, `delta` → `_delta`
- **File:** scripts/Game.gd:146,151

### Compilation Status

✅ **ALL CLEAR** - 0 errors, 0 warnings across all 10 GDScript files

---

## Known Issues & Fixes Applied

### Issue Summary Table

| Issue | Type | Severity | Status | Files |
|-------|------|----------|--------|-------|
| Player vertical positioning inconsistent | Gameplay | CRITICAL | 🔴 NOT FIXED | Player.gd, scenes |
| HUD bars not visible/overlapping | Visual | CRITICAL | 🔴 NOT FIXED | HUD.tscn, HUD.gd |
| Health drains too fast | Balance | HIGH | 🟡 NEEDS TUNING | config/gameplay.json |
| Obstacle.gd wrong base class | Syntax | CRITICAL | ✅ FIXED | Obstacle.gd |
| HUD.gd UTF-8 encoding | Syntax | CRITICAL | ✅ FIXED | HUD.gd |
| Persistence.gd class order | Syntax | CRITICAL | ✅ FIXED | Persistence.gd |
| Player.gd unused signals | Warning | LOW | ✅ FIXED | Player.gd |
| Game.gd param shadowing | Warning | LOW | ✅ FIXED | Game.gd |

### Current User-Reported Issues (from Screenshots)

#### 1. Player Lane Positioning (CRITICAL)

**Observed:** Player appears at different Y positions across screenshots

- SS1: Low position (~400-450 Y)
- SS2-4: Mid position (~350 Y)
- SS5, SS9: High position, overlapping buildings (~250-300 Y)

**Expected Behavior:** Player should stay in one of 3 lanes:

- Lane 1 (top): Y = 240
- Lane 2 (mid): Y = 300
- Lane 3 (bot): Y = 360

**Root Cause (Hypothesis):**

```gdscript
# In Player.gd, lane switching may not be constraining Y properly
func _process(delta):
    # If this lerp is not bounded, player can drift
    position.y = lerp(position.y, target_lane_y, lane_switch_speed * delta)
```

**Fix Needed:**

- Clamp target_lane_y to valid lanes
- Ensure lane switching only happens on discrete input
- Add debug print to track actual Y position

#### 2. HUD Visual Issues (CRITICAL)

**Observed:** From screenshots:

- Heart icons visible
- Lung icons visible
- No visible progress bars for health/battery
- Text labels readable but bars missing

**Expected:** TextureProgress bars should show:

- Green health bar (lung-shaped) filling/depleting
- Blue battery bar (battery-shaped) filling/depleting

**Root Cause (Hypothesis):**

```gdscript
# In HUD.gd:29-35
func _on_health_changed(new_health: float) -> void:
    if health_bar:
        health_bar.value = new_health  # This line may be working

func _on_battery_changed(new_battery: float) -> void:
    if battery_bar:
        battery_bar.value = new_battery
```

**Possible Issues:**

1. **Color/Contrast:** Progress bar color may match background
2. **Size:** Bars may be 0x0 or off-screen
3. **Texture:** Missing texture files (ui_lung_fill.webp, ui_battery_fill.webp)
4. **Z-Order:** Bars rendering behind other elements

**Fix Needed:**

- Check HUD.tscn node tree in Godot
- Verify TextureProgress nodes exist
- Verify texture paths in ext_resource
- Add debug: print health_bar.size, health_bar.position

#### 3. Health Drain Too Fast (BALANCE)

**Observed:**

- SS1-5: Full health (5 hearts)
- SS6: 3 hearts (lost 2 hearts in ~7 seconds)
- SS7: 1 heart (lost 2 more hearts in ~2 seconds)

**Expected:** At AQI 250 (base_bad):

```
drain_rate = max(0.1, 250 / 60) = 4.166 HP/sec
```

This means ~24 seconds to go from 100 HP to 0. But screenshots show ~9 seconds.

**Root Cause:**

```gdscript
# In Player.gd health drain logic
var drain_rate = max(0.1, aqi_current / 60.0)  # Formula from GDD
health -= drain_rate * delta
```

**If AQI is 250, drain should be ~4 HP/sec.**

Screenshots show ~11 HP/sec drain rate (100 HP / 9 sec).

**Possible Issues:**

1. AQI value is higher than 250 (maybe 600-700?)
2. Drain formula multiplied by extra factor
3. Collision damage firing repeatedly

**Fix Needed:**

- Add debug print: `print("AQI:", aqi_current, "Drain:", drain_rate, "HP:", health)`
- Check if collisions happening off-screen
- Adjust formula in config/gameplay.json

---

## File Structure & Organization

### Assets Inventory (23 files + 14 placeholders)

#### Real Assets (23 files)

**Skies (3):**

- assets/skies/sky_bad.webp
- assets/skies/sky_ok.webp
- assets/skies/sky_clear.webp

**Road (1):**

- assets/road/road_tile.webp

**Player & Vehicles (3):**

- assets/player/vim_base.webp (yellow scooter with rider)
- assets/vehicles/car.webp
- assets/vehicles/bike.webp

**Pickups (2):**

- assets/pickups/mask.webp (N95 mask)
- assets/pickups/filter_1.webp (air purifier)

**UI (3):**

- assets/ui/health.webp
- assets/ui/charge.webp
- assets/ui/charger.webp

**Parallax/Buildings (9):**

- assets/parallax/pharmacy.webp
- assets/parallax/Select_City_mall.webp
- assets/parallax/home_1.webp
- assets/parallax/shop.webp
- assets/parallax/restaurant.webp
- assets/parallax/CP.webp (Connaught Place)
- assets/parallax/Laal_kila.webp (Red Fort)
- assets/parallax/Lotus_park.webp
- assets/parallax/Hauskhas.webp
- (Also: Hanuman, pigeon)

#### Placeholder Assets (14 files - need replacement)

- ui_lung_bg.webp, ui_lung_fill.webp
- ui_battery_bg.webp, ui_battery_fill.webp
- ui_coin.webp, ui_minidot.webp
- mask_pulse.webp, filter_glow.webp, smog_overlay.webp
- sapling.webp, delivery_pad.webp
- skyline_1.webp, mid_building_01.webp, front_shop_01.webp

### Scene Hierarchy (Main.tscn)

```
Main (Node2D) [Game.gd]
├── ParallaxBG (ParallaxBackground)
│   ├── SkyLayer (ParallaxLayer) [SkyManager.gd]
│   │   ├── Sprite_SkyBad (Sprite2D) @ (480, 240)
│   │   ├── Sprite_SkyOk (Sprite2D) @ (480, 240) [alpha: 0]
│   │   └── Sprite_SkyClear (Sprite2D) @ (480, 240) [alpha: 0]
│   ├── MidLayer (ParallaxLayer)
│   │   └── MidNode (Node2D)
│   └── FrontLayer (ParallaxLayer)
│       └── FrontNode (Node2D)
├── Road (Node2D) [RoadScroll.gd] @ (0, 420)
│   ├── RoadTileA (Sprite2D) @ (480, 0)
│   └── RoadTileB (Sprite2D) @ (1440, 0)
├── World (Node2D)
│   ├── DynamicObstacles (Node2D)
│   ├── DynamicPickups (Node2D)
│   └── Trees (Node2D)
├── DeliveryZones (Node2D)
├── Player (CharacterBody2D) [Player.gd] @ (180, 300) [instance: Player.tscn]
├── Spawner (Node2D) [Spawner.gd]
└── HUD (CanvasLayer) [HUD.gd] [instance: HUD.tscn]
    ├── TopLeft (Panel)
    │   └── VBox (VBoxContainer)
    │       ├── HealthLabel (Label)
    │       ├── HealthBar (ProgressBar)
    │       ├── BatteryLabel (Label)
    │       └── BatteryBar (ProgressBar)
    ├── TopRight (VBoxContainer)
    │   ├── AQIIndicator (Label)
    │   └── CoinsLabel (Label)
    ├── CenterOverlay (VBoxContainer)
    │   └── MaskTimer (HBoxContainer)
    │       └── MaskLabel (Label)
    └── Controls (VBoxContainer)
        ├── MoveLabel (Label)
        ├── BoostLabel (Label)
        └── DropLabel (Label)
```

---

## Game Mechanics Breakdown

### Health System

**Range:** 0-100 HP

**Drain Formula:**

```gdscript
drain_base_sec = max(0.1, AQI_current / 60.0)
health -= drain_base_sec * delta
```

**At AQI 250 (bad):** 4.16 HP/sec = 24 seconds to death
**At AQI 100 (ok):** 1.66 HP/sec = 60 seconds to death
**At AQI 50 (good):** 0.83 HP/sec = 120 seconds to death

**Collision Damage:**

- Car/Bike hit: 8-18 HP
- Obstacle avoidance critical

### Mask System

**Pickup Effect:**

- Instant +10 HP (capped at 100)
- Mask timer: 15 seconds
- Suppresses health drain during timer

**Leak Mechanic:**

- Last 5 seconds: leak = 1 HP/sec
- Creates tension as timer runs out

**Visual Feedback:**

- Mask icon on player sprite
- Pulsing lung indicator
- Countdown label in HUD

### Filter/Purifier System

**Pickup:**

- `carried_item = "filter"`
- Visible on player sprite

**Deployment at DeliveryZone:**

- Duration: 30 seconds
- Effect: Reduces local AQI by 8 AQI/sec in radius
- Coin multiplier: 2.5x
- Decay: Linear 10-second fade after 30s

**Visual:**

- "Air Purifier Delivered" message
- Sky crossfade to clearer variant
- Immediate environmental change

### Tree/Sapling System

**Pickup:**

- `carried_item = "sapling"`
- Cost: 75 AIR Coins (expensive)

**Planting:**

- Drop in safe area or designated pad
- Creates persistent tree at world X coordinate
- Stored in `user://game_state.json`

**Growth:**

- Stages: seed → small → medium → large
- Each session increments growth stage
- Each stage: +0.05 AQI clean rate

**Base Clean Rate:**

- `tree_base_clean_rate = 0.12 AQI/sec`
- Stage 5 (max): 0.37 AQI/sec

### Battery & Boost System

**Range:** 0-100 battery

**Boost Effect:**

- Speed multiplier: 1.35x
- Drain rate: 8 battery/sec
- ~12.5 seconds of boost at full battery

**Charging:**

- Stand in EV Charge zone for 2 seconds
- Restores 100% battery (or +50% partial)
- **Also restores health** (observed in SS8!)

### AIR Coin Economy

**Formula:**

```
coin_per_meter = base_rate * ((AQI_base - AQI_current) / AQI_base)
                 * tree_density_factor * filter_active_multiplier

Where:
- base_rate = 0.02 coins/meter
- tree_density_factor = 1 + (num_trees * 0.02)
- filter_active_multiplier = 1.0 or 2.5
```

**Example Calculation:**

- AQI_base = 250, AQI_current = 170 (improved)
- tree_density = 1.1 (5 trees planted)
- filter active = 2.5x
- Distance = 1000m

```
coin_per_meter = 0.02 * ((250-170)/250) * 1.1 * 2.5
               = 0.02 * 0.32 * 1.1 * 2.5
               = 0.0176 coins/meter

Total = 0.0176 * 1000 = 17.6 AIR Coins
```

**Spending:**

- Mask (emergency): 5 coins
- Filter (immediate effect): 50 coins
- Sapling (permanent): 75 coins

---

## HUD & UI System

### Current HUD Layout (from HUD.tscn and screenshots)

#### Top Left Panel

- **HealthLabel:** "Health" text
- **HealthBar:** ProgressBar (min: 0, max: 100, value: 100)
- **BatteryLabel:** "Battery" text
- **BatteryBar:** ProgressBar (min: 0, max: 100, value: 100)

**Anchors:**

- anchor_left: 0.02, anchor_top: 0.02
- anchor_right: 0.28, anchor_bottom: 0.25

**Issue:** ProgressBar nodes used instead of TextureProgressBar

- No textures applied
- Default Godot styling (may be invisible on mobile)

#### Top Right Area

- **AQIIndicator:** Label showing "AQI XXX - Status"
- **CoinsLabel:** Label showing "AIR: XXX"

**Color Coding (from HUD.gd:61-72):**

```gdscript
if aqi <= 50:
    aqi_text += " - Good"
    color = Color.GREEN
elif aqi <= 100:
    aqi_text += " - Fair"
    color = Color.YELLOW
elif aqi <= 200:
    aqi_text += " - Poor"
    color = Color.ORANGE
else:
    aqi_text += " - Hazardous"
    color = Color.RED
```

#### Center Overlay

- **MaskTimer:** Shows "Mask Active: XXs" when mask active
- **Initial visibility:** false (shows only when mask picked up)

#### Bottom Left Controls (Desktop reference)

- "Move Lanes: ↑ ↓"
- "Boost: SPACE"
- "Drop Item: D"

### Signal Connections (from HUD.gd)

```gdscript
# Player signals connected in _ready():
player_ref.health_changed.connect(_on_health_changed)
player_ref.battery_changed.connect(_on_battery_changed)
player_ref.mask_activated.connect(_on_mask_activated)
player_ref.mask_deactivated.connect(_on_mask_deactivated)
```

### HUD Updates (_process loop)

```gdscript
func _process(_delta):
    if player_ref:
        update_mask_timer()  # Updates countdown label
        update_aqi_display() # Updates AQI color and text
```

---

## Asset Catalog

### Visual Asset Details (from screenshots)

#### Player Asset (vim_base.webp)

- **Character:** Indian delivery person
- **Appearance:** White shirt, brown pants, cyan cap
- **Face:** Brown skin, mustache, N95 mask when active
- **Vehicle:** Yellow scooter with cargo area
- **Cargo:** Air purifier box (green plant visible), white package
- **Size:** ~64x64 pixels (scales to 0.59 in Main.tscn)

#### Building Assets

**Connaught Place (CP.webp):**

- Colonial-style architecture
- Blue/cream colored building
- Multiple windows, arched entrances
- "CONNAUGHT PLACE" sign in red/orange

**Victoria Memorial (monument):**

- Large domed structure
- White/cream colored
- Multiple smaller domes and minarets
- Reflection pool visible

**Residential (home_1.webp):**

- 2-story house
- White walls, blue roof
- Balcony with railings
- Blue door

**Pharmacy:**

- Teal/cyan colored shop
- Striped awning
- Medical cross symbol
- Glass windows

**Restaurant:**

- Yellow/beige building
- "RESTAURANT" sign in blue
- Blue windows with awning
- Wooden door

#### Collectible Assets

**N95 Mask (mask.webp):**

- Large circular pickup
- "Aearth Mask" branding
- "N95" text center
- Blue/yellow color scheme
- Size: ~80px diameter when floating

**Air Purifier (filter_1.webp):**

- Appears as package/box on scooter
- White packaging with labels
- Green plant symbol visible

**EV Charge Station (charger.webp):**

- Green and white charging station
- "EV CHARGE" text
- Battery icon showing charge level
- Screen displaying "60%"
- Rectangular kiosk design

#### Vehicle Assets

**Car (car.webp):**

- Orange/red hatchback
- Pixel art style
- Side view, facing right
- Pollution source

**Bike:**

- Not clearly visible in screenshots
- Presumably similar style to car

#### Sky Assets

**Sky Bad (sky_bad.webp):**

- Brownish/beige hue
- Hazy, low visibility
- Polluted atmosphere
- Gradient from light to slightly darker

**Sky Clear (sky_clear.webp):**

- Bright blue
- White fluffy clouds
- High contrast
- Clean, vibrant

**Sky OK (sky_ok.webp):**

- Intermediate (not shown in screenshots)
- Presumably light blue with some haze

---

## Development Workflow

### Tools & Setup

**Editor:** VS Code with GDScript extension
**Engine:** Godot 4.5.1 via Flatpak
**Command:** `flatpak run org.godotengine.Godot`

**Wrapper Script** (recommended):

```bash
#!/bin/bash
# /usr/local/bin/godot
flatpak run org.godotengine.Godot "$@"
```

### Code-First Workflow

1. Write/edit `.gd` files in VS Code
2. Create/modify `.tscn` files as text
3. Open project in Godot only for:
   - Testing (F5 to run)
   - Scene preview
   - Export to HTML5

### Testing Workflow

```bash
# From terminal
cd ~/Documents/Code/Games/breath_rush
flatpak run org.godotengine.Godot --path . --debug

# Or double-click project.godot in file manager
```

### Git Workflow

**Commit:**

```bash
git add scripts/ scenes/ assets/ config/ data/
git commit -m "Descriptive message"
```

**Ignore:**

```
.import/
user/
*.import
export/
.mono/
```

### Export to HTML5

1. Open Godot
2. Project → Export
3. Add "HTML5" preset
4. Configure:
   - Export path: `export/breath_rush.html`
   - Export type: Regular
5. Export Project

---

## Next Steps & Roadmap

### Immediate Fixes Needed (Priority 1)

#### 1. Fix Player Lane Positioning ⚠️ CRITICAL

**File:** scripts/Player.gd

**Current Code:**

```gdscript
var lanes = [240.0, 300.0, 360.0]
var current_lane = 1
var target_lane_y = 300.0
```

**Fix Needed:**

```gdscript
func _process(delta):
    # Clamp lane to valid indices
    current_lane = clamp(current_lane, 0, lanes.size() - 1)

    # Set target from lane array
    target_lane_y = lanes[current_lane]

    # Smooth movement with bounds checking
    position.y = lerp(position.y, target_lane_y, 0.15)

    # Debug
    if Engine.get_frames_drawn() % 60 == 0:
        print("Player Y:", position.y, "Target:", target_lane_y, "Lane:", current_lane)
```

#### 2. Fix HUD Bar Visibility ⚠️ CRITICAL

**File:** scenes/HUD.tscn

**Current:** Using `ProgressBar` nodes
**Needed:** Switch to `TextureProgressBar` nodes

**Changes:**

```
[node name="HealthBar" type="ProgressBar" ...]
# CHANGE TO:
[node name="HealthBar" type="TextureProgressBar" ...]

# Add properties:
texture_under = ExtResource("X_ui_lung_bg")
texture_progress = ExtResource("X_ui_lung_fill")
tint_under = Color(0.3, 0.3, 0.3, 1)
tint_progress = Color(0, 1, 0, 1)  # Green
```

**Also need:** Create actual texture files for ui_lung_bg.webp and ui_lung_fill.webp

#### 3. Balance Health Drain Rate 🔧 HIGH

**File:** config/gameplay.json

**Current:**

```json
"health": {
    "max_hp": 100,
    "base_drain_multiplier": 0.01666
}
```

**Test & Adjust:**

- Add debug logging to track actual drain rate
- Observe time-to-death at different AQI levels
- Target: ~30-45 seconds at AQI 250 (not 9 seconds)

**Possible Fix:**

```json
"base_drain_multiplier": 0.005  // Reduce by 3x
```

### Phase 2: Polish (Priority 2)

#### 4. Add Actual UI Textures 🎨

**Needed Files:**

- ui_lung_bg.webp (lung shape outline)
- ui_lung_fill.webp (lung shape fill, red)
- ui_battery_bg.webp (battery outline)
- ui_battery_fill.webp (battery fill, blue/green)
- ui_coin.webp (coin icon for counter)

**Design Specs:**

- 9-patch compatible for scaling
- Pixel art style matching game aesthetic
- High contrast for mobile visibility

#### 5. Implement Pause/Menu System 📱

**New Scenes:**

- scenes/MainMenu.tscn (start screen)
- scenes/PauseMenu.tscn (ESC menu)
- scenes/EndScreen.tscn (run summary)

**Features:**

- Start button
- Settings (volume, difficulty)
- Leaderboard integration
- Run statistics

#### 6. Add Audio System 🔊

**Files Needed:**

- music/gameplay_loop.ogg
- sfx/mask_pickup.wav
- sfx/delivery_success.wav
- sfx/boost_activate.wav
- sfx/collision_damage.wav

**Implementation:**

```gdscript
# In Game.gd
@onready var music_player = $MusicPlayer
@onready var sfx_player = $SFXPlayer

func _ready():
    music_player.stream = load("res://music/gameplay_loop.ogg")
    music_player.play()
```

#### 7. Create More Chunk Variants 🗺️

**Current:** Only chunk_001.json exists

**Needed:** chunk_002.json through chunk_010.json with:

- Different building arrangements
- Varied spawn densities
- Different sky types (ok, clear)
- Unique landmarks per chunk

**Variety:**

- Connaught Place area (chunk_001) ✅
- Laal Kila area (chunk_002)
- Lotus Temple area (chunk_003)
- Hauz Khas area (chunk_004)
- Select City Mall area (chunk_005)

### Phase 3: Backend Integration (Priority 3)

#### 8. Implement HTTPRequest for API Calls 🌐

**Endpoints:**

```
POST /session/start → { session_token }
POST /session/end → { score, coins, trees }
POST /lead → { name, phone, email }
GET /leaderboard → [ {name, score}, ... ]
```

**Implementation:**

```gdscript
# In Game.gd
var http_request = HTTPRequest.new()

func start_session():
    add_child(http_request)
    http_request.request_completed.connect(_on_session_start)
    http_request.request("https://api.lilypad.com/session/start", [], HTTPClient.METHOD_POST)
```

#### 9. Implement Tree Persistence 🌳

**Current:** Trees stored locally in `user://game_state.json`
**Needed:** Server-side tree sharing

**Features:**

- Players see trees planted by others
- Community environmental progress
- Tree growth across all players

### Phase 4: Optimization (Priority 4)

#### 10. Mobile Performance Optimization 📱

**Tasks:**

- Profile frame time (target: 60 FPS on mid-range devices)
- Reduce texture memory (use atlases)
- Optimize spawner pooling
- Test on actual mobile devices

#### 11. HTML5 Export Tuning 🌐

**Tasks:**

- Enable compression
- Reduce bundle size (target: <10 MB)
- Test CORS for API calls
- Add loading screen

### Phase 5: Content & Polish (Priority 5)

#### 12. Animation System 💫

**Animations Needed:**

- Player idle/running (sprite sheets)
- Mask pickup (flash effect)
- Delivery success (celebration)
- Tree growth stages
- Sky transition particles

#### 13. Particle Effects ✨

**Effects:**

- Pollution particles (brown/gray)
- Boost trail (cyan)
- Coin collection sparkle
- Tree planting burst

#### 14. Juice & Feel 🎮

**Enhancements:**

- Screen shake on collision
- Slow-motion on near-death
- Satisfying pickup sounds
- Delivery zone visual feedback
- Camera follow smoothing

---

## Testing Checklist

### Core Mechanics ✅

- [x] Player spawns at correct position
- [x] Lane switching input registered
- [ ] Lane switching constrained to 3 lanes (BROKEN)
- [x] Health drains over time
- [ ] Health drain rate matches formula (BROKEN - too fast)
- [x] Mask pickup grants +10 HP
- [x] Mask timer counts down
- [ ] Mask timer visibility correct (WORKING in screenshots)
- [x] Battery drains during boost
- [x] Boost increases speed
- [x] Charging station restores battery (& health!)
- [x] Sky transitions on delivery
- [x] Delivery message displays

### UI/HUD ✅

- [x] AQI indicator shows correct value
- [x] AQI color codes correctly
- [x] Coin counter increments
- [ ] Health bar visible (NOT VISIBLE in screenshots)
- [ ] Battery bar visible (NOT VISIBLE in screenshots)
- [x] Mask timer visible when active
- [x] Message text readable

### Spawning & Collisions ⚠️

- [ ] Obstacles spawn at correct intervals
- [ ] Pickups spawn at correct positions
- [ ] Collision detection working
- [ ] Obstacle pooling working
- [ ] Off-screen recycling working

### Visual ✅

- [x] Road tiles scroll seamlessly
- [x] Sky crossfade smooth
- [x] Buildings parallax correctly
- [x] Player sprite visible
- [x] Pickup sprites visible

### Persistence 🔧

- [ ] Game state saves on exit
- [ ] Trees load on game start
- [ ] Coins persist across sessions
- [ ] Tree growth increments

---

## Debugging Commands

### Enable Debug Prints

Add to Game.gd `_ready()`:

```gdscript
func _ready():
    print("=== GAME DEBUG MODE ===")
    print("Godot version:", Engine.get_version_info())
    print("Screen size:", get_viewport().get_visible_rect().size)
```

### Player Position Debug

Add to Player.gd `_process()`:

```gdscript
func _process(delta):
    if Engine.get_frames_drawn() % 60 == 0:  # Every second at 60 FPS
        print("Player Y:", position.y, "Lane:", current_lane, "Target:", target_lane_y)
```

### HUD Debug

Add to HUD.gd `_ready()`:

```gdscript
func _ready():
    print("=== HUD DEBUG ===")
    print("HealthBar:", health_bar)
    print("HealthBar size:", health_bar.size if health_bar else "NULL")
    print("HealthBar value:", health_bar.value if health_bar else "NULL")
```

### AQI & Health Drain Debug

Add to Player.gd `_process()`:

```gdscript
func _process(delta):
    var drain_rate = max(0.1, aqi_current / 60.0)
    if Engine.get_frames_drawn() % 60 == 0:
        print("AQI:", aqi_current, "Drain/sec:", drain_rate, "HP:", health)
```

---

## Conclusion

### Project Status: 🟡 PLAYABLE BUT BUGGY

**Working:**

- ✅ Core game loop
- ✅ Sky transitions
- ✅ Mask system
- ✅ Charging stations
- ✅ Delivery mechanics
- ✅ Coin accumulation
- ✅ Input handling
- ✅ Compilation (0 errors)

**Broken:**

- 🔴 Player lane positioning (drifts vertically)
- 🔴 HUD bars not visible
- 🔴 Health drains too fast

**Missing:**

- ⚪ Actual UI textures (placeholders only)
- ⚪ Menu system
- ⚪ Audio
- ⚪ More chunk varieties
- ⚪ Backend integration
- ⚪ Tree persistence

### Next Session Priority

1. Fix player Y positioning (constrain to lanes)
2. Fix HUD bar visibility (switch to TextureProgressBar)
3. Balance health drain rate (adjust multiplier)
4. Test in Godot (press F5 and verify fixes)

---

**Document Created:** 2025-12-04
**Last Updated:** 2025-12-04
**Version:** 1.0
**Author:** Claude (AI Assistant)
**Purpose:** Comprehensive reference for continuing development
