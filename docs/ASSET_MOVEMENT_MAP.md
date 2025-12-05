# Asset Movement & Placement Map (REVISED)

**Date**: 2025-12-06
**Purpose**: Define where each asset from `ALL_assets/NEW/` should be placed in the project
**Status**: ✅ DUPLICATES REMOVED - Only unique assets listed

---

## ⚠️ CRITICAL: Duplicate Detection Results

**Analysis**: Many assets in NEW/ are **EXACT DUPLICATES** of existing assets in `assets/`.
These duplicates will **NOT** be copied to avoid redundancy.

### ❌ DUPLICATES FOUND (DO NOT COPY)

| NEW/ Asset | Existing Asset | Status |
|-----------|----------------|--------|
| `backgrounds/cp.webp` | `assets/parallax/CP.webp` | ✗ SKIP |
| `backgrounds/hanumaan.webp` | `assets/parallax/Hanuman.webp` | ✗ SKIP |
| `backgrounds/hausk_has.webp` | `assets/parallax/Hauskhas.webp` | ✗ SKIP |
| `backgrounds/laal_kila.webp` | `assets/parallax/Laal_kila.webp` | ✗ SKIP |
| `backgrounds/lotus_park.webp` | `assets/parallax/Lotus_park.webp` | ✗ SKIP |
| `backgrounds/select_mall.webp` | `assets/parallax/Select_City_mall.webp` | ✗ SKIP |
| `atmosphere/best_sky.webp` | `assets/skies/sky_clear.webp` | ✗ SKIP |
| `atmosphere/ok_sky.webp` | `assets/skies/sky_ok.webp` | ✗ SKIP |
| `atmosphere/worst_sky.webp` | `assets/skies/sky_bad.webp` | ✗ SKIP |
| `buildings/pharamcy_building_83.webp` | `assets/parallax/pharmacy.webp` | ✗ SKIP |
| `buildings/restarurent_building_81.webp` | `assets/parallax/restaurant.webp` | ✗ SKIP |
| `buildings/shop_building_87.webp` | `assets/parallax/shop.webp` | ✗ SKIP |

**Total Duplicates**: 12 files (will not be copied)

---

## 📋 Movement Categories (Unique Assets Only)

### Category 1: ✅ REPLACE FAKE ASSETS (3 files) - HIGH PRIORITY

These assets will **OVERWRITE** fake placeholder sprites (bike images).

| Source (NEW/) | Destination (assets/) | Action |
|--------------|----------------------|--------|
| `pickups/delivery_pad.webp` | `assets/pickups/delivery_pad.webp` | **OVERWRITE** fake bike sprite |
| `pickups/sapling.webp` | `assets/pickups/sapling.webp` | **OVERWRITE** fake bike sprite |
| `ui/smog_overlay.webp` | `assets/ui/smog_overlay.webp` | **OVERWRITE** fake bike sprite |

**Commands**:
```bash
# Backup originals (optional)
mkdir -p assets/backups/fake_replaced/
cp assets/pickups/delivery_pad.webp assets/backups/fake_replaced/
cp assets/pickups/sapling.webp assets/backups/fake_replaced/
cp assets/ui/smog_overlay.webp assets/backups/fake_replaced/

# Replace with real assets
cp ALL_assets/NEW/pickups/delivery_pad.webp assets/pickups/
cp ALL_assets/NEW/pickups/sapling.webp assets/pickups/
cp ALL_assets/NEW/ui/smog_overlay.webp assets/ui/

echo "✅ Replaced 3 fake assets with real sprites"
```

---

### Category 2: 🆕 ADD NEW UNIQUE ASSETS (7 files) - NEXT PRIORITY

These are brand new assets that **DO NOT** exist in the project.

#### 2.1 Trees (3 files) - NEW DECORATION TYPE

| Source (NEW/) | Destination (assets/) | Description |
|--------------|----------------------|-------------|
| `trees/tree_1.webp` | `assets/parallax/tree_1.webp` | Large tree decoration |
| `trees/tree_2.webp` | `assets/parallax/tree_2.webp` | Medium tree variant |
| `trees/tree_3.webp` | `assets/parallax/tree_3.webp` | Small tree variant |

**Commands**:
```bash
cp ALL_assets/NEW/trees/*.webp assets/parallax/
echo "✅ Added 3 new tree decoration assets"
```

#### 2.2 Buildings (4 files) - NEW VARIETY

| Source (NEW/) | Destination (assets/) | Description |
|--------------|----------------------|-------------|
| `buildings/fruit_stall.webp` | `assets/parallax/fruit_stall.webp` | 🎨 **High quality** colorful fruit vendor |
| `buildings/billboard.webp` | `assets/parallax/billboard.webp` | Advertisement billboard (new type) |
| `buildings/building_generic.webp` | `assets/parallax/building_generic.webp` | Generic building variant |
| `buildings/two_storey_building_84.webp` | `assets/parallax/two_storey_building.webp` | Two-story building variant |

**Commands**:
```bash
# Copy unique buildings only (skip duplicates)
cp ALL_assets/NEW/buildings/fruit_stall.webp assets/parallax/
cp ALL_assets/NEW/buildings/billboard.webp assets/parallax/
cp ALL_assets/NEW/buildings/building_generic.webp assets/parallax/
cp ALL_assets/NEW/buildings/two_storey_building_84.webp assets/parallax/two_storey_building.webp

echo "✅ Added 4 new building assets"
```

**Total New Assets**: 7 unique environment assets

---

### Category 3: ⚠️ KEEP AS-IS (Do Not Touch)

These existing assets in `assets/` are **REAL** and should **NOT** be modified.

#### 3.1 Real Pickups
- ✅ `assets/pickups/mask.webp` - Real mask sprite
- ✅ `assets/pickups/filter_1.webp` - Real filter sprite

#### 3.2 Real Parallax Buildings (13 files)
- ✅ `assets/parallax/CP.webp` - Connaught Place
- ✅ `assets/parallax/Hanuman.webp` - Hanuman temple
- ✅ `assets/parallax/Hauskhas.webp` - Hauz Khas
- ✅ `assets/parallax/home_1.webp` - Home building
- ✅ `assets/parallax/Laal_kila.webp` - Red Fort
- ✅ `assets/parallax/Lotus_park.webp` - Lotus Temple
- ✅ `assets/parallax/pharmacy.webp` - Pharmacy
- ✅ `assets/parallax/pigeon.webp` - Pigeon decoration
- ✅ `assets/parallax/restaurant.webp` - Restaurant
- ✅ `assets/parallax/Select_City_mall.webp` - Select City Mall
- ✅ `assets/parallax/shop.webp` - Shop
- ✅ `assets/parallax/front_shop_01.webp` - Front shop
- ✅ `assets/parallax/mid_building_01.webp` - Mid building

#### 3.3 Real Skies (3 files)
- ✅ `assets/skies/sky_bad.webp` - Bad AQI sky
- ✅ `assets/skies/sky_clear.webp` - Clear sky
- ✅ `assets/skies/sky_ok.webp` - OK AQI sky

#### 3.4 Real UI Assets (30+ files)
- ✅ All battery/health/charge sprites working correctly
- ✅ Do not modify existing UI elements

---

### Category 4: ❌ STILL FAKE (No Replacement Available)

These remain as bike placeholders until proper assets are created.

| File | Status | Priority | Notes |
|------|--------|----------|-------|
| `assets/ui/filter_glow.webp` | FAKE | Low | Visual effect only |
| `assets/ui/mask_pulse.webp` | FAKE | Low | Visual effect only |
| `assets/ui/ui_battery_bg.webp` | FAKE | Medium | UI element |
| `assets/ui/ui_battery_fill.webp` | FAKE | Medium | UI element |
| `assets/ui/ui_coin.webp` | FAKE | Medium | Currency UI |
| `assets/ui/ui_lung_bg.webp` | FAKE | Low | Have breathing sprites |
| `assets/ui/ui_lung_fill.webp` | FAKE | Low | Have damage sprites |
| `assets/ui/ui_minidot.webp` | FAKE | Low | Decoration |
| `assets/parallax/skyline_1.webp` | FAKE | Low | Bike sprite placeholder |

**Total Still Fake**: 9 UI/parallax assets

---

## 📦 Complete Execution Plan

### Phase 1: Replace Fake Assets (3 files) - EXECUTE FIRST ⭐
```bash
#!/bin/bash
# PHASE 1: Replace fake placeholders with real assets

# Optional: Backup originals
mkdir -p assets/backups/fake_replaced/
cp assets/pickups/delivery_pad.webp assets/backups/fake_replaced/
cp assets/pickups/sapling.webp assets/backups/fake_replaced/
cp assets/ui/smog_overlay.webp assets/backups/fake_replaced/

# Replace with real assets
cp ALL_assets/NEW/pickups/delivery_pad.webp assets/pickups/
cp ALL_assets/NEW/pickups/sapling.webp assets/pickups/
cp ALL_assets/NEW/ui/smog_overlay.webp assets/ui/

echo "✅ Phase 1 Complete: Replaced 3 fake assets"
```

### Phase 2: Add New Unique Assets (7 files) - EXECUTE SECOND
```bash
#!/bin/bash
# PHASE 2: Add new unique environment assets

# Add trees (3 files)
cp ALL_assets/NEW/trees/tree_1.webp assets/parallax/
cp ALL_assets/NEW/trees/tree_2.webp assets/parallax/
cp ALL_assets/NEW/trees/tree_3.webp assets/parallax/

# Add unique buildings (4 files) - skip duplicates!
cp ALL_assets/NEW/buildings/fruit_stall.webp assets/parallax/
cp ALL_assets/NEW/buildings/billboard.webp assets/parallax/
cp ALL_assets/NEW/buildings/building_generic.webp assets/parallax/
cp ALL_assets/NEW/buildings/two_storey_building_84.webp assets/parallax/two_storey_building.webp

echo "✅ Phase 2 Complete: Added 7 new unique assets"
```

### Phase 3: Godot Reimport - EXECUTE THIRD
1. Open Godot Editor
2. Godot will auto-detect changed/new files and reimport
3. Verify import settings:
   - Filter: Enabled
   - Mipmaps: Disabled (pixel art)
   - Compression: Lossless
4. Check for import errors in Output tab

### Phase 4: Test & Update Game Code - FINAL
- **Test pickups**: delivery_pad and sapling should show real sprites
- **Test smog overlay**: Should show fog texture in UI
- **Chunk updates** (optional): Add new buildings/trees to chunk JSON files:
  ```json
  "decorations": [
    {"sprite": "tree_1.webp", "x": 300, "y": 200},
    {"sprite": "fruit_stall.webp", "x": 500, "y": 300}
  ]
  ```

---

## 🎯 Summary

| Category | Count | Action |
|----------|-------|--------|
| **Fake → Real Replacements** | 3 | OVERWRITE fake files |
| **New Unique Assets** | 7 | ADD to parallax/ |
| **Duplicates (Skipped)** | 12 | DO NOT COPY |
| **Keep Existing Real Assets** | 50+ | NO CHANGES |
| **Still Fake (No Replacement)** | 9 | MARK in code |

**Assets to Move**: 10 files total (3 replacements + 7 new)
**Assets Skipped**: 12 duplicates
**Fake Assets Remaining**: 9 (UI elements - low priority)

---

## ✅ Verification Checklist

After executing movement plan:

### Phase 1 Verification (Replacements)
- [ ] `delivery_pad.webp` shows EV charger (not bike) ✅
- [ ] `sapling.webp` shows hands with tree (not bike) ✅
- [ ] `smog_overlay.webp` shows fog texture (not bike) ✅

### Phase 2 Verification (New Assets)
- [ ] `tree_1.webp`, `tree_2.webp`, `tree_3.webp` in parallax/ ✅
- [ ] `fruit_stall.webp` in parallax/ (colorful fruit stand) ✅
- [ ] `billboard.webp` in parallax/ ✅
- [ ] `building_generic.webp` in parallax/ ✅
- [ ] `two_storey_building.webp` in parallax/ ✅

### Godot Verification
- [ ] All imports successful (no errors)
- [ ] Pickup scenes show correct sprites
- [ ] New parallax assets available in editor
- [ ] Game runs without errors

---

## 📊 Duplicate Detection Log

**Method**: Visual comparison + filename matching
**Date**: 2025-12-06
**Result**: 12 exact duplicates identified and excluded from movement plan

**Duplicate Pairs**:
1. backgrounds/cp.webp = parallax/CP.webp
2. backgrounds/hanumaan.webp = parallax/Hanuman.webp
3. backgrounds/hausk_has.webp = parallax/Hauskhas.webp
4. backgrounds/laal_kila.webp = parallax/Laal_kila.webp
5. backgrounds/lotus_park.webp = parallax/Lotus_park.webp
6. backgrounds/select_mall.webp = parallax/Select_City_mall.webp
7. atmosphere/best_sky.webp = skies/sky_clear.webp
8. atmosphere/ok_sky.webp = skies/sky_ok.webp
9. atmosphere/worst_sky.webp = skies/sky_bad.webp
10. buildings/pharamcy_building_83.webp = parallax/pharmacy.webp
11. buildings/restarurent_building_81.webp = parallax/restaurant.webp
12. buildings/shop_building_87.webp = parallax/shop.webp

---

*Last Updated: 2025-12-06*
*Status: ✅ Ready for Execution (Duplicates Removed)*
*Project: Breath Rush - Asset Organization Phase*