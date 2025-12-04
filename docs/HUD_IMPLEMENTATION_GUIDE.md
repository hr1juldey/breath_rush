# HUD Implementation Guide - Breath Rush

## Executive Summary

This document details the bugs identified in the current HUD implementation and provides a complete recovery plan using the CORRECT sprite sheet assets.

---

## Part 1: Bug Analysis

### Critical Bug #1: Placeholder Motorbike Assets

**Problem**: Multiple UI asset files contain a **MOTORBIKE placeholder image** instead of actual UI elements. These were created when the real assets weren't available.

**Affected Files** (ALL show motorbike):
| File | Expected Content | Actual Content |
|------|------------------|----------------|
| `ui_minidot.webp` | Health dot indicator | MOTORBIKE |
| `ui_lung_bg.webp` | Lung background | MOTORBIKE |
| `ui_lung_fill.webp` | Lung fill overlay | MOTORBIKE |
| `ui_battery_bg.webp` | Battery background | MOTORBIKE |
| `ui_battery_fill.webp` | Battery fill | MOTORBIKE |
| `ui_coin.webp` | Coin icon | MOTORBIKE |
| `filter_glow.webp` | Filter effect | MOTORBIKE |
| `mask_pulse.webp` | Mask pulse effect | MOTORBIKE |
| `smog_overlay.webp` | Smog overlay | MOTORBIKE |

### Critical Bug #2: Wrong Asset References in HUD.tscn

**Problem**: The HUD scene references the placeholder assets with fake UIDs:
```gdscript
[ext_resource type="Texture2D" uid="uid://c1234567890a" path="res://assets/ui/ui_minidot.webp" id="2_health_dot"]
[ext_resource type="Texture2D" uid="uid://c1234567890b" path="res://assets/ui/ui_lung_bg.webp" id="3_lung_bg"]
[ext_resource type="Texture2D" uid="uid://c1234567890c" path="res://assets/ui/ui_lung_fill.webp" id="4_lung_fill"]
```

These UIDs (`c1234567890a`, etc.) are manually crafted and will cause import errors.

### Critical Bug #3: Wrong Implementation Approach

**Problem**: Current HUD.gd uses individual TextureRect nodes for each health/lung indicator:
- 5 separate HealthDot nodes
- 5 separate Lung nodes with Fill children
- Each modulated individually via code

**Correct Approach**: Use sprite sheets with AtlasTexture for frame selection:
- Single TextureRect with charge.webp (battery display)
- Single TextureRect with health.webp (lung display)
- UV/region rect shifting to select correct frame

### Critical Bug #4: Missing Battery Display

**Problem**: The `_on_battery_changed()` function does nothing:
```gdscript
func _on_battery_changed(new_battery: float) -> void:
    # Battery is no longer displayed visually in the new HUD
    pass
```

Battery/charge display is completely missing from the HUD.

---

## Part 2: Correct Assets Analysis

### Asset: `charge.webp` (Battery/Boost Display)

**Visual Structure**: Vertical sprite sheet with 7 rows + 1 empty bar template
- Row 0: 5 green cells (100% charge)
- Row 1: 4 green cells (80% charge)
- Row 2: 3 green cells (60% charge)
- Row 3: 2 green cells (40% charge)
- Row 4: 1 green cell (20% charge)
- Row 5: 1 RED cell (critical - below 20%)
- Row 6: Empty bar (0% charge)
- Bottom-right: Empty bar template

**Usage**: Select row based on battery percentage using AtlasTexture region.

**Estimated Dimensions** (from visual):
- Total image: ~658 x 516 pixels (7 rows left side + empty template bottom-right)
- Each row height: ~73 pixels
- Bar width: ~520 pixels

### Asset: `health.webp` (Lung Health Display)

**Visual Structure**: Two-column sprite sheet
- **LEFT COLUMN** (6 rows): Progressive damage states
  - Row 0: 5 healthy pink lungs
  - Row 1: 4 healthy + 1 damaged (brown)
  - Row 2: 3 healthy + 2 damaged
  - Row 3: 2 healthy + 3 damaged
  - Row 4: 1 healthy + 4 damaged
  - Row 5: All 5 damaged (near death)

- **RIGHT COLUMN** (6 rows): Breathing animation frames
  - All rows show 5 healthy lungs in different breathing phases
  - Used for pulsing/breathing animation overlay

**Usage Strategy - Dual Layer**:
1. BASE LAYER: Show damage state from LEFT column (static, changes with health)
2. OVERLAY LAYER: Animate through RIGHT column frames (continuous breathing effect)
3. Superimpose RIGHT on LEFT to create "damaged lungs that still breathe"

**Estimated Dimensions**:
- Total image: ~928 x 462 pixels (2 columns x 6 rows)
- Each column: ~464 pixels wide
- Each row: ~77 pixels tall
- Each lung bar: ~380 x 50 pixels

### Asset: `mask_timer.webp` (Mask Active Indicator)

**Visual Structure**: Single pre-rendered UI panel
- Teal/cyan rounded rectangle background
- Left side: N95 mask icon in circular badge
- Right side: Text area with "sec remaining.." placeholder

**Usage**:
- Display as background TextureRect
- Overlay Label for countdown text
- Use "Press Start 2P" font for retro aesthetic

**Dimensions**: ~500 x 50 pixels

---

## Part 3: Recovery Implementation Plan

### Step 1: Delete Placeholder Assets

Remove or replace these motorbike placeholder files:
```bash
# Files to delete (all contain motorbike placeholder):
rm assets/ui/ui_minidot.webp
rm assets/ui/ui_lung_bg.webp
rm assets/ui/ui_lung_fill.webp
rm assets/ui/ui_battery_bg.webp
rm assets/ui/ui_battery_fill.webp
rm assets/ui/ui_coin.webp
rm assets/ui/filter_glow.webp
rm assets/ui/mask_pulse.webp
rm assets/ui/smog_overlay.webp
```

### Step 2: Download Press Start 2P Font

```bash
mkdir -p assets/fonts
# Download from Google Fonts:
# https://fonts.google.com/specimen/Press+Start+2P
# Place PressStart2P-Regular.ttf in assets/fonts/
```

### Step 3: Rewrite HUD.tscn

**New Scene Structure**:
```
HUD (CanvasLayer)
├── TopLeft (Control)
│   └── ChargeDisplay (TextureRect)  → charge.webp with AtlasTexture
│
├── TopRight (Control)
│   ├── LungBase (TextureRect)       → health.webp LEFT column
│   └── LungBreathing (TextureRect)  → health.webp RIGHT column (animated)
│
├── CenterTop (CenterContainer)
│   └── MaskTimer (Control)
│       ├── Background (TextureRect) → mask_timer.webp
│       └── TimerLabel (Label)       → Press Start 2P font
│
├── BottomLeft (VBoxContainer)       → Control hints (text labels)
│
└── BottomRight (VBoxContainer)      → AQI, Masks inventory, Coins
```

### Step 4: Rewrite HUD.gd

**Key Implementation Details**:

#### Battery/Charge Display:
```gdscript
@onready var charge_display = $TopLeft/ChargeDisplay
var charge_atlas: AtlasTexture

const CHARGE_ROW_HEIGHT = 73.0
const CHARGE_BAR_WIDTH = 520.0

func _ready():
    # Create AtlasTexture for charge display
    charge_atlas = AtlasTexture.new()
    charge_atlas.atlas = load("res://assets/ui/charge.webp")
    charge_display.texture = charge_atlas
    update_charge_display(100.0)  # Initial full charge

func get_charge_row(battery_percent: float) -> int:
    if battery_percent >= 85: return 0  # 5 cells
    elif battery_percent >= 65: return 1  # 4 cells
    elif battery_percent >= 45: return 2  # 3 cells
    elif battery_percent >= 25: return 3  # 2 cells
    elif battery_percent >= 10: return 4  # 1 green cell
    elif battery_percent > 0: return 5    # 1 red cell (critical)
    else: return 6                         # empty

func update_charge_display(battery: float) -> void:
    var row = get_charge_row(battery)
    charge_atlas.region = Rect2(0, row * CHARGE_ROW_HEIGHT, CHARGE_BAR_WIDTH, CHARGE_ROW_HEIGHT)
```

#### Health/Lung Display:
```gdscript
@onready var lung_base = $TopRight/LungBase
@onready var lung_breathing = $TopRight/LungBreathing

var lung_base_atlas: AtlasTexture
var lung_breathing_atlas: AtlasTexture

const LUNG_COLUMN_WIDTH = 464.0
const LUNG_ROW_HEIGHT = 77.0
const LUNG_BAR_WIDTH = 380.0

var breathing_frame = 0
var breathing_timer = 0.0
const BREATHING_SPEED = 0.15  # seconds per frame

func _ready():
    # Base layer (damage state) - LEFT column
    lung_base_atlas = AtlasTexture.new()
    lung_base_atlas.atlas = load("res://assets/ui/health.webp")
    lung_base.texture = lung_base_atlas

    # Breathing overlay - RIGHT column
    lung_breathing_atlas = AtlasTexture.new()
    lung_breathing_atlas.atlas = load("res://assets/ui/health.webp")
    lung_breathing.texture = lung_breathing_atlas

    update_lung_display(100.0)

func get_health_row(health_percent: float) -> int:
    if health_percent > 80: return 0   # 5 healthy lungs
    elif health_percent > 60: return 1  # 4 healthy, 1 damaged
    elif health_percent > 40: return 2  # 3 healthy, 2 damaged
    elif health_percent > 20: return 3  # 2 healthy, 3 damaged
    elif health_percent > 0: return 4   # 1 healthy, 4 damaged
    else: return 5                      # all damaged

func update_lung_display(health: float) -> void:
    var row = get_health_row(health)
    # LEFT column for damage state (x = 0)
    lung_base_atlas.region = Rect2(0, row * LUNG_ROW_HEIGHT, LUNG_BAR_WIDTH, LUNG_ROW_HEIGHT)
    # Keep breathing on same row for consistency
    lung_breathing_atlas.region = Rect2(LUNG_COLUMN_WIDTH, breathing_frame * LUNG_ROW_HEIGHT, LUNG_BAR_WIDTH, LUNG_ROW_HEIGHT)

func _process(delta):
    # Animate breathing
    breathing_timer += delta
    if breathing_timer >= BREATHING_SPEED:
        breathing_timer = 0.0
        breathing_frame = (breathing_frame + 1) % 6
        # Update breathing frame (RIGHT column)
        lung_breathing_atlas.region.position.y = breathing_frame * LUNG_ROW_HEIGHT
```

#### Mask Timer Display:
```gdscript
@onready var mask_timer_bg = $CenterTop/MaskTimer/Background
@onready var mask_timer_label = $CenterTop/MaskTimer/TimerLabel
@onready var mask_timer_container = $CenterTop/MaskTimer

func _ready():
    mask_timer_bg.texture = load("res://assets/ui/mask_timer.webp")
    mask_timer_container.visible = false

    # Apply Press Start 2P font
    var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
    mask_timer_label.add_theme_font_override("font", font)
    mask_timer_label.add_theme_font_size_override("font_size", 12)

func update_mask_timer() -> void:
    if player_ref and player_ref.mask_time > 0:
        var seconds = int(ceil(player_ref.mask_time))
        mask_timer_label.text = "%d" % seconds
        mask_timer_container.visible = true
    else:
        mask_timer_container.visible = false
```

---

## Part 4: Sprite Sheet Measurements

### Precise Measurements Needed

Before implementation, measure exact dimensions using Godot or image editor:

```gdscript
# In Godot, load and measure:
var charge_tex = load("res://assets/ui/charge.webp")
print("charge.webp: ", charge_tex.get_width(), "x", charge_tex.get_height())

var health_tex = load("res://assets/ui/health.webp")
print("health.webp: ", health_tex.get_width(), "x", health_tex.get_height())

var mask_tex = load("res://assets/ui/mask_timer.webp")
print("mask_timer.webp: ", mask_tex.get_width(), "x", mask_tex.get_height())
```

### Visual Measurement from Screenshots

**charge.webp** (7 rows left + empty bar bottom-right):
- Left side bars appear to have black border (4px each side?)
- Green cells are uniform squares with dark outline
- Total rows: 7 on left side
- Bottom-right: empty bar template

**health.webp** (2 columns x 6 rows):
- LEFT column: Damage progression (5→4→3→2→1→0 healthy)
- RIGHT column: Breathing animation (all 5 healthy, different phases)
- Each bar has black rounded border
- Lungs are pink (healthy) or brown (damaged)

**mask_timer.webp**:
- Teal background with rounded corners
- N95 mask icon on left in circular badge
- Text area on right: "sec remaining.."
- Pixel art style consistent with other UI

---

## Part 5: Implementation Checklist

### Pre-Implementation
- [ ] Measure exact dimensions of charge.webp
- [ ] Measure exact dimensions of health.webp
- [ ] Measure exact dimensions of mask_timer.webp
- [ ] Download Press Start 2P font (.ttf)
- [ ] Backup current HUD.tscn and HUD.gd

### Implementation
- [ ] Delete/ignore motorbike placeholder assets
- [ ] Create new HUD.tscn with correct structure
- [ ] Create AtlasTexture resources for sprite sheets
- [ ] Implement charge display row selection
- [ ] Implement health display dual-layer system
- [ ] Implement breathing animation
- [ ] Implement mask timer with font
- [ ] Connect all signals from Player

### Testing
- [ ] Verify charge display updates with battery changes
- [ ] Verify lung display updates with health changes
- [ ] Verify breathing animation runs continuously
- [ ] Verify mask timer shows/hides correctly
- [ ] Verify countdown text is readable
- [ ] Test on mobile viewport (960x600)

---

## Part 6: Notes on Sprite Sheet Technical Approach

### Why AtlasTexture?

AtlasTexture allows selecting a rectangular region from a larger texture:
- Single texture load (efficient)
- Dynamic region selection via code
- No need for AnimatedSprite or multiple TextureRect nodes

### Breathing Animation Approach

Two options for the breathing overlay:

**Option A: Frame Cycling (Recommended)**
- Cycle through rows 0-5 of RIGHT column continuously
- Simple timer-based frame advancement
- Works regardless of health state

**Option B: Sine Wave Modulation**
- Modulate opacity using sin() wave
- Simpler code but less control
- May not match intended visual

### Blend Mode for Overlay

The breathing overlay on top of damage base should use:
- `CanvasItem.blend_mode = BLEND_MODE_ADD` for glow effect, OR
- `CanvasItem.blend_mode = BLEND_MODE_MIX` (default) with modulated alpha

Test both to see which matches the intended visual.

---

## Appendix: File Reference

### Correct Assets (USE THESE)
| File | Purpose | Type |
|------|---------|------|
| `charge.webp` | Battery/boost display | Sprite sheet (7 rows) |
| `health.webp` | Lung health display | Sprite sheet (2 cols x 6 rows) |
| `mask_timer.webp` | Mask active background | Single image |

### Placeholder Assets (DO NOT USE - Contains Motorbike)
| File | Status |
|------|--------|
| `ui_minidot.webp` | MOTORBIKE placeholder |
| `ui_lung_bg.webp` | MOTORBIKE placeholder |
| `ui_lung_fill.webp` | MOTORBIKE placeholder |
| `ui_battery_bg.webp` | MOTORBIKE placeholder |
| `ui_battery_fill.webp` | MOTORBIKE placeholder |
| `ui_coin.webp` | MOTORBIKE placeholder |
| `filter_glow.webp` | MOTORBIKE placeholder |
| `mask_pulse.webp` | MOTORBIKE placeholder |
| `smog_overlay.webp` | MOTORBIKE placeholder |

---

*Document created: 2025-12-05*
*For: Breath Rush HUD Recovery*