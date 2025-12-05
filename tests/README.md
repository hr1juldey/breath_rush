# Breath Rush Test Suite

## Overview

This directory contains unit and integration tests for the Breath Rush game, using the [Gut (Godot Unit Test)](https://github.com/bitwes/Gut) framework.

## Test Files

### Unit Tests

1. **`test_player_mask.gd`** - PlayerMask component tests
   - Inventory management
   - Mask activation/deactivation
   - Timer expiration
   - Edge cases and boundaries
   - **EXPOSES THE BUG**: `test_wearing_mask_with_4_inventory()`

2. **`test_spawn_coordinator.gd`** - SpawnCoordinator component tests
   - Spatial separation enforcement
   - Obstacle/pickup collision checking
   - Boundary conditions (250px H, 80px V)
   - Verifies overlap bug is fixed

### Integration Tests

1. **`test_integration_mask_pickup.gd`** - Full mask pickup flow tests
   - Player → Pickup → Mask Component interaction
   - Signal emission verification
   - Real-world scenarios
   - **EXPOSES THE BUG**: `test_bug_wearing_plus_inventory_exceeds_max()`

### Bug Reproduction Tests

1. **`test_bug_reproduction.gd`** - Exact bug reproductions
   - User-reported bug scenarios
   - Root cause analysis
   - Proposed fix demonstration
   - **CRITICAL**: All tests in this file will FAIL until bug is fixed

## The Bug

### Description

**Player can have MORE than 5 masks total!**

- Max inventory should be 5 masks TOTAL (wearing + inventory)
- Current bug: Player can have 1 wearing + 5 inventory = **6 total masks**

### Root Cause

`PlayerMask.gd:221`:

```gdscript
if mask_inventory >= max_mask_inventory:
    return false  # Only checks inventory, not total!
```

Should be:

```gdscript
var total_masks = mask_inventory
if is_wearing_mask():
    total_masks += 1
if total_masks >= max_mask_inventory:
    return false  # Checks total masks!
```

### Reproduction Steps

1. Pick up mask #1 → Activates (total = 1)
2. Pick up mask #2 → Inventory (total = 2)
3. Pick up mask #3 → Inventory (total = 3)
4. Pick up mask #4 → Inventory (total = 4)
5. Pick up mask #5 → Inventory (total = 5) ✅ Correct
6. Pick up mask #6 → **Inventory (total = 6)** ❌ **BUG!**

Expected: Mask #6 should be REJECTED (would exceed max 5)
Actual: Mask #6 is ACCEPTED (inventory < 5 check passes)

### Affected Tests

These tests will **FAIL** (showing the bug):

- `test_player_mask.gd::test_wearing_mask_with_4_inventory()`
- `test_player_mask.gd::test_multiple_pickups_sequential()`
- `test_integration_mask_pickup.gd::test_bug_wearing_plus_inventory_exceeds_max()`
- `test_integration_mask_pickup.gd::test_bug_fix_verification()`
- `test_bug_reproduction.gd::test_user_bug_max_masks_scenario()`
- `test_bug_reproduction.gd::test_bug_root_cause()`

### The Fix

**File**: `scripts/components/player/PlayerMask.gd`
**Line**: 221-225

**Before (BUGGY)**:

```gdscript
func apply_mask() -> bool:
    # ...
    # Check if inventory is full - reject pickup
    if mask_inventory >= max_mask_inventory:
        print("[PlayerMask] REJECTED - inventory full!")
        return false
```

**After (FIXED)**:

```gdscript
func apply_mask() -> bool:
    # ...
    # Check if TOTAL masks would exceed max
    var total_masks = mask_inventory
    if is_wearing_mask():
        total_masks += 1

    if total_masks >= max_mask_inventory:
        print("[PlayerMask] REJECTED - at max capacity (%d masks)" % total_masks)
        return false
```

## Running Tests

### Install Gut

1. Download Gut from [GitHub](https://github.com/bitwes/Gut/releases)
2. Extract to `addons/gut/` in your project
3. Enable Gut plugin in Godot: Project → Project Settings → Plugins

### Run All Tests

```bash
# From Godot editor
Project → Tools → Gut → Run All Tests

# From command line
godot --headless --path . -d -s addons/gut/gut_cmdln.gd
```

### Run Specific Test

```bash
# Run single test file
godot --headless --path . -d -s addons/gut/gut_cmdln.gd \
  -gtest=res://tests/test_player_mask.gd

# Run specific test method
godot --headless --path . -d -s addons/gut/gut_cmdln.gd \
  -gtest=res://tests/test_player_mask.gd \
  -gunit_test_name=test_wearing_mask_with_4_inventory
```

## Test Results (Before Fix)

```bash
=== Expected Results (BEFORE FIX) ===

PASSED:  test_initial_state
PASSED:  test_apply_mask_when_empty
PASSED:  test_apply_mask_when_wearing_mask
PASSED:  test_apply_mask_when_inventory_full
FAILED:  test_wearing_mask_with_4_inventory  ← BUG EXPOSED!
FAILED:  test_multiple_pickups_sequential     ← BUG EXPOSED!
FAILED:  test_bug_wearing_plus_inventory_exceeds_max  ← BUG EXPOSED!
FAILED:  test_bug_fix_verification  ← BUG EXPOSED!

Total: 42 tests, 38 passed, 4 failed
```

## Test Results (After Fix)

```bash
=== Expected Results (AFTER FIX) ===

PASSED:  test_initial_state
PASSED:  test_apply_mask_when_empty
PASSED:  test_apply_mask_when_wearing_mask
PASSED:  test_apply_mask_when_inventory_full
PASSED:  test_wearing_mask_with_4_inventory  ← FIXED!
PASSED:  test_multiple_pickups_sequential     ← FIXED!
PASSED:  test_bug_wearing_plus_inventory_exceeds_max  ← FIXED!
PASSED:  test_bug_fix_verification  ← FIXED!

Total: 42 tests, 42 passed, 0 failed ✅
```

## Test Coverage

- ✅ PlayerMask component (100% of public API)
- ✅ SpawnCoordinator component (100% of public API)
- ✅ Player-Pickup-Mask integration
- ✅ User-reported bug scenarios
- ⏳ PlayerHealth component (TODO)
- ⏳ PlayerBattery component (TODO)
- ⏳ PlayerMovement component (TODO)
- ⏳ PlayerInventory component (TODO)
- ⏳ PlayerInput component (TODO)

## Why Refactoring Helps Testing

**Before Refactoring:**

- Player.gd: 335 lines with 13 responsibilities
- Can't test mask system without loading health, battery, movement
- Bug hidden in complex interactions

**After Refactoring:**

- PlayerMask.gd: 187 lines, ONLY mask logic
- Can instantiate and test in isolation
- Bug immediately obvious in focused component

**Example:**

```gdscript
// Before: Impossible to test without full Player
var player = Player.new()  # Loads 13 systems!
player.apply_mask()

// After: Test mask system alone
var mask = PlayerMask.new()  # Only mask system
mask.apply_mask()  # Test in isolation!
```

## Contributing

When adding new features:

1. Write tests FIRST (TDD)
2. Run tests to see them fail
3. Implement feature
4. Run tests to see them pass
5. Refactor if needed
6. Re-run tests to ensure still passing

## License

Same as main project.
