extends GutTest
"""
Unit Tests for PlayerMask Component

Tests the mask system in isolation to ensure:
- Correct inventory management
- Proper mask activation/deactivation
- Return value accuracy
- Edge cases and boundary conditions

This test file will EXPOSE THE BUG if it still exists!
"""

var mask: Node

func before_each():
	"""Setup before each test"""
	mask = load("res://scripts/components/player/PlayerMask.gd").new()
	add_child_autofree(mask)

func after_each():
	"""Cleanup after each test"""
	mask = null

# === Inventory Tests ===

func test_initial_state():
	"""Test initial mask state"""
	assert_eq(mask.mask_inventory, 0, "Should start with 0 masks")
	assert_eq(mask.mask_time, 0.0, "Should start with 0 mask time")
	assert_false(mask.is_wearing_mask(), "Should not be wearing mask initially")
	assert_false(mask.has_inventory(), "Should have no inventory initially")

func test_apply_mask_when_empty():
	"""Test applying mask when inventory and timer are empty"""
	var result = mask.apply_mask()

	assert_true(result, "Should consume mask")
	assert_eq(mask.mask_time, 30.0, "Should activate mask immediately")
	assert_eq(mask.mask_inventory, 0, "Should not add to inventory")
	assert_true(mask.is_wearing_mask(), "Should be wearing mask")

func test_apply_mask_when_wearing_mask():
	"""Test applying mask while already wearing one - CRITICAL BUG TEST"""
	# First mask - activate
	mask.apply_mask()
	assert_eq(mask.mask_time, 30.0, "First mask should activate")
	assert_eq(mask.mask_inventory, 0, "Inventory should be 0")

	# Second mask - should go to inventory
	var result = mask.apply_mask()

	assert_true(result, "Should consume second mask")
	assert_eq(mask.mask_time, 30.0, "Timer should remain at 30")
	assert_eq(mask.mask_inventory, 1, "Should add to inventory")

func test_apply_mask_when_inventory_not_empty():
	"""Test applying mask when inventory > 0 but not wearing mask"""
	# Add a mask to inventory without activating
	mask.mask_inventory = 1

	# Apply new mask
	var result = mask.apply_mask()

	assert_true(result, "Should consume mask")
	assert_eq(mask.mask_inventory, 2, "Should add to inventory")
	assert_eq(mask.mask_time, 0.0, "Should NOT activate")

func test_apply_mask_when_inventory_full():
	"""Test rejecting mask when inventory is full"""
	mask.mask_inventory = 5  # Full

	var result = mask.apply_mask()

	assert_false(result, "Should REJECT mask")
	assert_eq(mask.mask_inventory, 5, "Inventory should remain 5")
	assert_eq(mask.mask_time, 0.0, "Should not activate")

func test_apply_mask_wearing_and_inventory_full():
	"""Test rejecting mask when wearing AND inventory full"""
	mask.mask_time = 15.0  # Wearing mask
	mask.mask_inventory = 5  # Full inventory

	var result = mask.apply_mask()

	assert_false(result, "Should REJECT mask")
	assert_eq(mask.mask_inventory, 5, "Inventory should remain 5")
	assert_eq(mask.mask_time, 15.0, "Timer should not change")

func test_multiple_pickups_sequential():
	"""
	Test picking up multiple masks sequentially - VERIFIES FIX!

	Scenario (FIXED BEHAVIOR):
	1. Pick up mask 1 → activate (total = 1)
	2. Pick up mask 2 → inventory (total = 2)
	3. Pick up mask 3 → inventory (total = 3)
	4. Pick up mask 4 → inventory (total = 4)
	5. Pick up mask 5 → inventory (total = 5) ✅ AT MAX
	6. Pick up mask 6 → REJECT (would exceed max)
	7. Pick up mask 7 → REJECT (would exceed max)
	"""
	var results = []

	# Pickup 1-7
	for i in range(7):
		results.append(mask.apply_mask())
		var total = mask.mask_inventory + (1 if mask.is_wearing_mask() else 0)
		gut.p("After pickup %d: inventory=%d, wearing=%s, total=%d, result=%s" %
			[i+1, mask.mask_inventory, mask.is_wearing_mask(), total, results[-1]])

	# Verify results (CORRECT BEHAVIOR)
	assert_true(results[0], "Pickup 1 should succeed (activate, total=1)")
	assert_true(results[1], "Pickup 2 should succeed (inventory, total=2)")
	assert_true(results[2], "Pickup 3 should succeed (inventory, total=3)")
	assert_true(results[3], "Pickup 4 should succeed (inventory, total=4)")
	assert_true(results[4], "Pickup 5 should succeed (inventory, total=5)")
	assert_false(results[5], "Pickup 6 should FAIL (would exceed max 5)")
	assert_false(results[6], "Pickup 7 should FAIL (would exceed max 5)")

	# Verify final state
	assert_eq(mask.mask_inventory, 4, "Should have 4 masks in inventory")
	assert_true(mask.is_wearing_mask(), "Should be wearing 1 mask")

	# Verify total = 5
	var total = mask.mask_inventory + (1 if mask.is_wearing_mask() else 0)
	assert_eq(total, 5, "Total masks should be exactly 5")

# === Manual Use Tests ===

func test_use_mask_manually_when_available():
	"""Test manually using mask from inventory"""
	mask.mask_inventory = 3

	mask.use_mask_manually()

	assert_eq(mask.mask_inventory, 2, "Should consume from inventory")
	assert_eq(mask.mask_time, 30.0, "Should activate mask")

func test_use_mask_manually_when_empty():
	"""Test manually using mask with empty inventory"""
	mask.mask_inventory = 0

	mask.use_mask_manually()

	assert_eq(mask.mask_inventory, 0, "Inventory should remain 0")
	assert_eq(mask.mask_time, 0.0, "Should not activate")

func test_use_mask_manually_while_wearing():
	"""Test manually using mask while already wearing one"""
	mask.mask_time = 15.0
	mask.mask_inventory = 3

	mask.use_mask_manually()

	assert_eq(mask.mask_inventory, 3, "Should not consume")
	assert_eq(mask.mask_time, 15.0, "Timer should not reset")

# === Timer Tests ===

func test_mask_timer_countdown():
	"""Test mask timer counts down correctly"""
	mask.mask_time = 5.0

	mask._process(1.0)  # 1 second
	assert_almost_eq(mask.mask_time, 4.0, 0.01, "Should count down")

	mask._process(2.0)  # 2 more seconds
	assert_almost_eq(mask.mask_time, 2.0, 0.01, "Should continue counting")

func test_mask_timer_expiration():
	"""Test mask timer expires and signals"""
	mask.mask_time = 0.5

	watch_signals(mask)
	mask._process(1.0)  # More than remaining time

	assert_eq(mask.mask_time, 0.0, "Timer should be 0")
	assert_signal_emitted(mask, "mask_deactivated", "Should emit deactivation signal")

func test_leak_damage_calculation():
	"""Test leak damage during last 5 seconds"""
	# No leak when time > 5
	mask.mask_time = 10.0
	var leak = mask.get_leak_damage(1.0)
	assert_eq(leak, 0.0, "No leak when time > 5")

	# Leak when time < 5
	mask.mask_time = 3.0
	leak = mask.get_leak_damage(1.0)
	assert_eq(leak, 1.0, "Should have leak when time < 5")

# === Edge Cases ===

func test_boundary_inventory_4_to_5():
	"""Test boundary case: inventory going from 4 to 5"""
	mask.mask_inventory = 4

	var result = mask.apply_mask()

	assert_true(result, "Should accept when inventory = 4")
	assert_eq(mask.mask_inventory, 5, "Should reach max")

func test_boundary_inventory_5_reject():
	"""Test boundary case: inventory = 5 rejects"""
	mask.mask_inventory = 5

	var result = mask.apply_mask()

	assert_false(result, "Should reject when inventory = 5")

func test_wearing_mask_with_4_inventory():
	"""
	CRITICAL FIX VERIFICATION: Wearing mask + 4 inventory = 5 total
	Picking up another should be REJECTED!

	Fixed logic: checks (wearing + inventory) >= 5
	Total masks = 1 (wearing) + 4 (inventory) = 5 (at max!)
	Picking up another would = 6 (REJECT!)
	"""
	mask.mask_time = 15.0  # Wearing mask
	mask.mask_inventory = 4  # 4 in inventory

	# Total masks = 1 + 4 = 5 (at max!)
	# Picking up another = 6 total (should REJECT!)

	var result = mask.apply_mask()

	gut.p("VERIFICATION: wearing=%.1f, inventory=%d, result=%s" %
		[mask.mask_time, mask.mask_inventory, result])

	# CORRECT behavior: REJECT (total would exceed 5)
	assert_false(result, "Fixed logic: REJECTS (total would be 6)")
	assert_eq(mask.mask_inventory, 4, "Inventory stays at 4")

	# Verify total = 5 (not 6!)
	var total = mask.mask_inventory + (1 if mask.is_wearing_mask() else 0)
	assert_eq(total, 5, "Total masks = 5 (CORRECT!)")
	gut.p("✅ VERIFIED: Total masks = 5 (fix working!)")

func test_wearing_mask_with_5_inventory():
	"""
	ULTIMATE BUG TEST: What if wearing mask + 5 inventory?
	Total = 6 masks in system!
	"""
	mask.mask_time = 20.0
	mask.mask_inventory = 5

	var result = mask.apply_mask()

	assert_false(result, "Should reject (inventory full)")

	# Current state: 1 wearing + 5 inventory = 6 total masks!
	gut.p("CRITICAL: System has 6 total masks (1 wearing + 5 inventory)!")
