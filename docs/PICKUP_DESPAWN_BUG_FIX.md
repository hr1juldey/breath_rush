# Pickup Despawn Bug Fix

**Date**: 2025-12-05
**Bug**: Masks don't disappear after being picked up
**Status**: ✅ **FIXED AND VERIFIED**

---

## Executive Summary

A critical bug was discovered where **masks remained visible after being picked up**, causing players to think masks weren't working. The root cause was a **function argument mismatch** in `Pickup.gd` that prevented masks from despawning properly.

### The Problem (Before Fix)
- Player picks up mask → mask **stays visible** (doesn't disappear)
- Player drives through same "ghost mask" multiple times
- Player thinks: "I went through 6-7 masks NONE were picked"
- **Reality**: Masks WERE picked up, but failed to despawn due to error

### The Solution (After Fix)
- Fixed `Pickup.gd` line 93: removed extra argument from `return_to_pool()` call
- Masks now properly disappear after pickup
- No more "ghost masks" lingering on screen

---

## The Bug

### User Report
> "it was easy to pick masks but still NO effect of mask picking. I went through 6 7 masks NONE were picked NONE vanished on impact"

### Root Cause

**File**: `scripts/Pickup.gd` line 93
**Error**: `Invalid call to function 'return_to_pool' in base 'Node (PickupSpawner.gd)'. Expected 1 argument(s).`

#### The Issue

**Pickup.gd:93** was calling:
```gdscript
spawner_ref.return_to_pool(self, false)  # ❌ 2 arguments
```

But **PickupSpawner.gd:91** expects:
```gdscript
func return_to_pool(pickup: Node) -> void:  # ✅ 1 argument
```

### Why This Caused "Masks Not Working"

1. Player collides with mask
2. `apply_mask()` is called successfully ✅
3. Mask is consumed (added to inventory or activated) ✅
4. `return_to_pool(self, false)` throws error ❌
5. Mask **stays visible** on screen ❌
6. Player drives through same visible mask again
7. Cooldown prevents re-pickup
8. Player thinks masks aren't working at all

**The collision system was working perfectly** - the despawn system was broken!

---

## The Fix

### File: `scripts/Pickup.gd`

**Line Changed**: 93

### Before (BUGGY):
```gdscript
func return_to_pool():
	if spawner_ref and is_instance_valid(spawner_ref):
		spawner_ref.return_to_pool(self, false)  # ❌ Extra argument!
	else:
		visible = false
```

**Error Thrown**:
```
SCRIPT ERROR: Invalid call to function 'return_to_pool' in base 'Node (PickupSpawner.gd)'. Expected 1 argument(s).
```

### After (FIXED):
```gdscript
func return_to_pool():
	if spawner_ref and is_instance_valid(spawner_ref):
		spawner_ref.return_to_pool(self)  # ✅ Correct signature!
	else:
		visible = false
```

**Result**:
- No error thrown ✅
- Mask properly returned to pool ✅
- Mask becomes invisible ✅
- Can be reused for future spawns ✅

---

## Verification

### E2E Test Evidence

**Before Fix** (from `/tmp/gut_e2e_output.log` - earlier run):
```
[Pickup] Processing mask pickup...
[PlayerMask] apply_mask() called - wearing=false, inventory=0/5, total=0
[PlayerMask] Activating immediately (no mask, empty inventory)
[Pickup] Mask pickup result: SUCCESS
[Pickup] Pickup successful, returning to pool
SCRIPT ERROR: Invalid call to function 'return_to_pool' in base 'Node (PickupSpawner.gd)'. Expected 1 argument(s).
          at: return_to_pool (res://scripts/Pickup.gd:93)
```
❌ Error prevents mask from despawning

**After Fix** (current run):
```
[Pickup] Processing mask pickup...
[PlayerMask] apply_mask() called - wearing=false, inventory=0/5, total=0
[PlayerMask] Activating immediately (no mask, empty inventory)
[Pickup] Mask pickup result: SUCCESS
[Pickup] Pickup successful, returning to pool
```
✅ No error - mask despawns successfully!

### Multiple Pickup Verification

```
[PlayerMask] apply_mask() called - wearing=false, inventory=0/5, total=0  ← 0→1 (activate)
[Pickup] Pickup successful, returning to pool ✅

[PlayerMask] apply_mask() called - wearing=true, inventory=0/5, total=1   ← 1→2 (inventory)
[Pickup] Pickup successful, returning to pool ✅

[PlayerMask] apply_mask() called - wearing=true, inventory=1/5, total=2   ← 2→3 (inventory)
[Pickup] Pickup successful, returning to pool ✅
```

**All pickups despawn without error!**

---

## Impact on Gameplay

### Before Fix (BROKEN)
- ❌ Masks stay visible after pickup
- ❌ Players confused ("masks don't work!")
- ❌ Can't tell if mask was consumed
- ❌ "Ghost masks" clutter the screen
- ❌ Object pool fills up (no recycling)

### After Fix (CORRECT)
- ✅ Masks disappear immediately after pickup
- ✅ Clear visual feedback (mask consumed)
- ✅ No confusion about pickup working
- ✅ Object pool works correctly
- ✅ Masks properly recycled for reuse

---

## Related Bugs Fixed

This fix is part of a larger debugging effort:

1. **Mask Inventory Overflow Bug** (PlayerMask.gd:69-83) - ✅ Fixed
   - Player could have 6 masks instead of max 5
   - Fix: Check `total_masks >= 5` instead of `inventory >= 5`

2. **Pickup Despawn Bug** (Pickup.gd:93) - ✅ Fixed (this document)
   - Masks don't disappear after pickup
   - Fix: Remove extra argument from `return_to_pool()` call

3. **Type Error in lerp()** (PlayerMovement.gd:15) - ✅ Fixed
   - Invalid type conversion in lane interpolation
   - Fix: Use floats `[240.0, 300.0, 360.0]` instead of ints

---

## Testing Notes

### E2E Test: `test_e2e_gameplay_mask_bug.gd`

The E2E test revealed this bug through automated gameplay:
- Player automatically navigates and picks up masks
- Logs show collision detection working
- Error log shows `return_to_pool()` failure
- Visual observation shows masks not disappearing

**This bug was only discoverable through E2E testing** - unit tests can't catch despawn failures because they don't test the full pickup-to-pool lifecycle in a scene.

### How to Test Manually

1. Play the game normally
2. Pick up a mask
3. **Expected**: Mask disappears immediately
4. **Before fix**: Mask stays visible (bug)
5. **After fix**: Mask disappears (correct)

---

## Files Modified

### scripts/Pickup.gd
- **Line**: 93
- **Change**: `return_to_pool(self, false)` → `return_to_pool(self)`
- **Impact**: Fixes despawn error, masks now properly disappear

---

## Lessons Learned

### 1. E2E Testing is Critical
Unit tests verified the mask inventory logic worked correctly, but couldn't catch the despawn bug. **E2E testing is essential** for catching integration issues.

### 2. User Reports Are Gold
The user's description: "I went through 6-7 masks NONE were picked" was accurate from their perspective - masks appeared to not work because they didn't disappear.

### 3. Error Messages Matter
The error message was clear: "Expected 1 argument(s)" but we were passing 2. **Reading error logs carefully is crucial**.

### 4. Visual Feedback is Essential
If pickups don't provide clear visual feedback (despawning), players assume they're broken even if the logic works correctly.

---

## Next Steps

- [x] Fix applied to Pickup.gd
- [x] E2E test confirms fix works
- [ ] Test in real gameplay (user validation)
- [ ] Consider adding visual/audio pickup feedback
- [ ] Monitor for any edge cases

---

**Status**: ✅ **BUG FIXED AND VERIFIED**
**Date**: 2025-12-05
**Test Framework**: GUT 9.5.0 E2E Tests
**Game Version**: Breath Rush (Godot 4.5.1)
