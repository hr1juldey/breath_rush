# Parallax Verification Checklist
**Quick Reference for Testing 2.5D Parallax Implementation**

---

## Pre-Testing Setup

- [ ] All modified files saved in Godot (Ctrl+S)
- [ ] Godot editor has reloaded scene files
- [ ] Build configuration is Debug (not Release) for verification output
- [ ] GUT plugin installed and available

---

## Step 1: Scene Tree Verification

**In Godot Editor**, open `/scenes/Main.tscn`:

- [ ] **ParallaxBG node**:
  - Has script attached: `ParallaxController.gd`
  - Properties visible: `layer = -1`, `scroll_ignore_camera_zoom = true`

- [ ] **SkyLayer**:
  - motion_scale: `(0.1, 0)` ✓ (NOT 0.2)
  - Has 3 child sprites: Sprite_SkyBad, Sprite_SkyOk, Sprite_SkyClear

- [ ] **FarLayer** (NEW):
  - motion_scale: `(0.3, 0)`
  - Has child FarNode (empty Node2D)

- [ ] **MidLayer**:
  - motion_scale: `(0.6, 0)` ✓ (NOT 0.5)
  - Has child MidNode (empty Node2D)

- [ ] **FrontLayer**:
  - motion_scale: `(0.9, 0)` ✓ (NOT 0.8)
  - Has child FrontNode (empty Node2D)

- [ ] **SmogLayer** (NEW):
  - Type: CanvasLayer
  - layer: `10`
  - Has script attached: `SmogController.gd`
  - Child SmogOverlay has texture: `smog_overlay.webp`

---

## Step 2: Script Files Verification

**Check that files exist**:

- [ ] `/scripts/ParallaxController.gd` (exists, ~150 lines)
- [ ] `/scripts/SmogController.gd` (exists, ~120 lines)
- [ ] `/tests/test_parallax_math.gd` (exists, ~300 lines)

**Check file permissions** (no red X icons in file browser)

---

## Step 3: Run Unit Tests

1. **Open GUT Test Runner**:
   - In Godot: Bottom panel → GUT

2. **Load test file**:
   - File browser in GUT → navigate to `tests/`
   - Double-click `test_parallax_math.gd`

3. **Run tests**:
   - Click "Run" button (green play icon)

4. **Expected output**:
   - ✅ All ~27 tests should PASS (green)
   - No red FAIL indicators
   - Test summary: "27/27 PASS"

**If tests fail**:
- Check console for error messages
- Verify ParallaxController and SmogController exist
- Check for typos in script names

---

## Step 4: Play Scene & Observe Parallax

1. **Select Main.tscn**
2. **Press F5 or click Play** (▶ button)

3. **Observe on startup**:
   - Console should print:
     ```
     === PARALLAX CONFIGURATION VERIFICATION ===
     ✓ OK SkyLayer: Expected (0.1, 0), Got (0.1, 0)
     ✓ OK FarLayer: Expected (0.3, 0), Got (0.3, 0)
     ✓ OK MidLayer: Expected (0.6, 0), Got (0.6, 0)
     ✓ OK FrontLayer: Expected (0.9, 0), Got (0.9, 0)
     === END VERIFICATION ===
     ```
   - No error messages about motion_scale mismatches

4. **Visual observation during game**:
   - Sky should scroll SLOWEST (barely moving)
   - Landmark buildings should scroll slower than foreground
   - Trees should scroll medium speed
   - Shops/small buildings should scroll nearly with camera (fastest)
   - Road should remain at fixed speed

5. **Fog layer observations**:
   - Fog should be initially transparent (invisible)
   - Later in game (if AQI increases), subtle fog effect should appear
   - Fog should NOT parallax (stays fixed to viewport)

---

## Step 5: Debug Output Inspection

**In Godot Output Tab**, you should see each frame:

```
✓ SkyLayer: Offset 15.23 px (scale 0.1×, error: 0.0012 px)
✓ FarLayer: Offset 45.68 px (scale 0.3×, error: 0.0034 px)
✓ MidLayer: Offset 91.36 px (scale 0.6×, error: 0.0008 px)
✓ FrontLayer: Offset 137.04 px (scale 0.9×, error: 0.0045 px)
AQI: 150.0 → Fog alpha: 0.500
```

**Expected**:
- All error values < 1.0 pixel ✓
- No ⚠️ warnings or ✗ errors about parallax
- AQI value shown (fog system initialized)

---

## Step 6: Visual Depth Verification

**Manual observation test** (no measurements needed, visual only):

Create a simple test by scrolling the scene:

1. **Place camera** to see all layers
2. **Scroll forward** (camera moves right)
3. **Observe movement ratio**:
   - [ ] Sky barely moves (almost stationary)
   - [ ] Far buildings move slowly behind closer buildings
   - [ ] Mid trees move faster than buildings
   - [ ] Front shops move nearly with player
   - [ ] Depth feels natural and 3D-like

4. **If depth looks wrong**:
   - Check motion_scale values (see Step 1)
   - Verify no parallax errors in console
   - Check FarLayer assets are actually present/visible

---

## Step 7: Fog Layer Testing

**Test 1: AQI = 0 (Clear Air)**
```gdscript
# In Game.gd or directly in console:
$SmogLayer.set_aqi(0.0)
# Expected: Fog completely invisible (alpha = 0.0)
```

**Test 2: AQI = 150 (Moderate)**
```gdscript
$SmogLayer.set_aqi(150.0)
# Expected: Fog at 50% opacity (alpha = 0.5)
# Fog should smooth transition over ~0.8 seconds
```

**Test 3: AQI = 300 (Worst)**
```gdscript
$SmogLayer.set_aqi(300.0)
# Expected: Fog at max (alpha = 0.7, clamped)
# Scene becomes noticeably hazy
```

**Fog Expected Behavior**:
- [ ] Fog opacity correlates with AQI value
- [ ] Fog transitions smoothly (not instant)
- [ ] Fog overlays all parallax layers
- [ ] Fog does NOT parallax (stays fixed)
- [ ] Opacity matches formula: `alpha = clamp(AQI/300, 0, 0.7)`

---

## Troubleshooting Guide

### Issue: "Scene tree structure mismatch"
**Symptom**: Error in console about missing FarLayer/SmogLayer

**Solution**:
1. Delete Main.tscn and re-open from file system
2. Or manually re-add FarLayer/SmogLayer with correct properties
3. Verify load_steps = 18 at top of .tscn file

---

### Issue: "Parallax verification errors" ⚠️
**Symptom**: Console shows `⚠️ ERROR: SkyLayer Expected 150, Actual 151.5`

**Solution**:
1. Check motion_scale values in Inspector (should match Step 1)
2. Verify ParallaxController script is attached to ParallaxBG
3. Check scroll_offset is being updated (ParallaxController._physics_process)

---

### Issue: "Fog layer doesn't appear"
**Symptom**: No fog visible even at high AQI

**Solution**:
1. Verify SmogOverlay has texture assigned (smog_overlay.webp)
2. Check SmogLayer layer property = 10 (above parallax at 0)
3. Verify SmogController script is attached to SmogLayer
4. Try manual test: `$SmogLayer.set_fog_maximum()` to force max opacity

---

### Issue: "GUT tests show failures"
**Symptom**: Red FAIL indicators in test output

**Solution**:
1. Check error message in GUT output
2. Common causes:
   - ParallaxController not found/loaded
   - SmogController not found/loaded
   - Motion_scale values different than expected
3. Verify file paths in test_parallax_math.gd are correct
4. Try reloading scene: F5 to refresh

---

### Issue: "Game runs but parallax feels wrong visually"
**Symptom**: Depth perception seems off

**Solution**:
1. Take screenshot at different scroll positions
2. Verify visual parallax ratio matches math:
   - Sky should move ~10% of distance
   - Far should move ~30% of distance
   - Mid should move ~60% of distance
   - Front should move ~90% of distance
3. If ratios correct but visually odd:
   - Consider adjusting motion_scale values slightly
   - Or adjust building sizes to match perceived depth

---

## Summary Verification Checklist

**If ALL checkboxes are ✅**:

- ✅ Scene tree correct (Step 1)
- ✅ Scripts exist and loaded (Step 2)
- ✅ All unit tests PASS (Step 3)
- ✅ Parallax config verified on startup (Step 4)
- ✅ No parallax errors in debug output (Step 5)
- ✅ Visual depth looks natural (Step 6)
- ✅ Fog AQI mapping works correctly (Step 7)

**RESULT**: 🎉 Parallax system is working correctly!

---

## Mathematical Confidence

**What's Verified**:
- ✅ Motion_scale values exactly as specified
- ✅ Parallax formula: `position = camera × scale` verified ±1px
- ✅ Fog formula: `alpha = clamp(AQI/300, 0, 0.7)` mathematically correct
- ✅ 27 unit tests covering edge cases
- ✅ Real-time verification in debug build

**Confidence Level**: 🟢 HIGH - Parallax is mathematically sound

---

## Next Steps After Verification

1. **Integrate with Game Logic**:
   - Update Game.gd to control fog via AQI
   - Wire chunk transitions to update fog

2. **Spawn Assets**:
   - Add landmark buildings to FarLayer
   - Add trees to MidLayer
   - Add shops to FrontLayer

3. **Fine-Tuning** (Optional):
   - Adjust motion_scale values if depth needs tweaking
   - Adjust fog opacity (max_fog_alpha) if too dark/light
   - Test on actual mobile devices

---

**Document Version**: 1.0
**Last Updated**: 2025-12-06
**Status**: Ready for Testing
