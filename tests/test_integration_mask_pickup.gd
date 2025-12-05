extends GutTest
"""
Integration Tests for Mask Pickup System

Tests the complete flow: Pickup → Player → Mask Component
This will expose bugs in the interaction between components!
"""

var player: CharacterBody2D
var pickup: Area2D

func before_each():
	"""Setup player and pickup for integration testing"""
	# Load player scene
	var player_scene = load("res://scenes/Player.tscn")
	player = player_scene.instantiate()
	add_child_autofree(player)

	# Give time for components to initialize
	await wait_frames(2)

	# Load pickup scene
	var pickup_scene = load("res://scenes/Mask.tscn")
	pickup = pickup_scene.instantiate()
	add_child_autofree(pickup)

	await wait_frames(1)

func after_each():
	"""Cleanup"""
	player = null
	pickup = null

# === Basic Integration Tests ===

func test_player_has_mask_component():
	"""Verify player has mask component after refactoring"""
	assert_not_null(player.mask_component, "Player should have mask_component")
	assert_eq(player.mask_component.get_script().resource_path,
		"res://scripts/components/player/PlayerMask.gd",
		"Should be PlayerMask component")

func test_first_mask_pickup_activates():
	"""Test first mask pickup activates immediately"""
	var initial_inventory = player.mask_component.get_inventory_count()
	var initial_time = player.mask_component.get_mask_time()

	var result = player.apply_mask()

	assert_true(result, "Should accept first mask")
	assert_eq(player.mask_component.get_mask_time(), 30.0, "Should activate")
	assert_eq(player.mask_component.get_inventory_count(), initial_inventory, "Should not add to inventory")

func test_second_mask_goes_to_inventory():
	"""Test second mask goes to inventory while wearing first"""
	# First mask
	player.apply_mask()

	# Second mask
	var result = player.apply_mask()

	assert_true(result, "Should accept second mask")
	assert_eq(player.mask_component.get_inventory_count(), 1, "Should add to inventory")

func test_reject_when_inventory_full():
	"""Test rejection when inventory is full"""
	# Fill inventory (1 wearing + 5 inventory = BUG?)
	for i in range(6):
		player.apply_mask()

	# Try 7th mask
	var result = player.apply_mask()

	assert_false(result, "Should reject 7th mask")

# === THE BUG TEST ===

func test_bug_wearing_plus_inventory_exceeds_max():
	"""
	EXPOSE THE BUG: Player can have MORE than 5 masks total!

	Steps:
	1. Pickup mask 1 → Activate (wearing)
	2. Pickup mask 2-6 → Inventory (5/5)
	3. Now player has 1 wearing + 5 inventory = 6 TOTAL!

	Expected: Max 5 masks total
	Actual: 6 masks possible (1 active + 5 inventory)
	"""
	var results = []

	for i in range(6):
		results.append(player.apply_mask())
		gut.p("Pickup %d: inventory=%d, wearing=%s, result=%s" %
			[i+1,
			player.mask_component.get_inventory_count(),
			player.mask_component.is_wearing_mask(),
			results[-1]])

	# Count total masks
	var wearing = 1 if player.mask_component.is_wearing_mask() else 0
	var inventory = player.mask_component.get_inventory_count()
	var total = wearing + inventory

	gut.p("")
	gut.p("=== BUG DETECTED ===")
	gut.p("Wearing: %d" % wearing)
	gut.p("Inventory: %d" % inventory)
	gut.p("TOTAL: %d masks" % total)
	gut.p("MAX ALLOWED: 5 masks")
	gut.p("OVERFLOW: %d masks!" % (total - 5))
	gut.p("===================")

	# THE BUG!
	assert_eq(total, 6, "BUG: Player has 6 masks (should be max 5!)")

	# Proper behavior should be:
	# - Max 5 masks TOTAL (not just inventory)
	# - 1 wearing + 4 inventory = 5 total (correct)
	# - 6th pickup should be REJECTED

func test_bug_fix_verification():
	"""
	This test will FAIL until bug is fixed!

	Correct behavior:
	- Max 5 masks TOTAL (wearing + inventory)
	- Pickup 1: Activate (1 total)
	- Pickup 2-5: Inventory (5 total)
	- Pickup 6: REJECT (would exceed 5)
	"""
	var results = []

	for i in range(6):
		results.append(player.apply_mask())

	# CORRECT behavior
	assert_true(results[0], "Pickup 1 should succeed")
	assert_true(results[1], "Pickup 2 should succeed")
	assert_true(results[2], "Pickup 3 should succeed")
	assert_true(results[3], "Pickup 4 should succeed")
	assert_true(results[4], "Pickup 5 should succeed")

	# THIS SHOULD FAIL (currently passes - BUG!)
	assert_false(results[5], "Pickup 6 should FAIL (max 5 total)")

	var total = (1 if player.mask_component.is_wearing_mask() else 0) + \
				player.mask_component.get_inventory_count()

	assert_eq(total, 5, "Should have exactly 5 masks total")

# === Timer Expiration Tests ===

func test_mask_expires_then_pickup_new():
	"""Test picking up mask after previous expires"""
	# Pickup first mask
	player.apply_mask()
	assert_eq(player.mask_component.get_mask_time(), 30.0)

	# Simulate time passing
	for i in range(35):
		player.mask_component._process(1.0)  # 35 seconds

	assert_eq(player.mask_component.get_mask_time(), 0.0, "Mask should expire")

	# Pickup new mask
	var result = player.apply_mask()

	assert_true(result, "Should accept new mask")
	assert_eq(player.mask_component.get_mask_time(), 30.0, "Should activate")

# === Manual Use Tests ===

func test_manual_use_consumes_inventory():
	"""Test manually using mask from inventory (M key)"""
	# Build inventory
	player.apply_mask()  # Activate
	player.apply_mask()  # Inventory 1/5
	player.apply_mask()  # Inventory 2/5

	# Wait for mask to expire
	for i in range(35):
		player.mask_component._process(1.0)

	assert_eq(player.mask_component.get_inventory_count(), 2)
	assert_false(player.mask_component.is_wearing_mask())

	# Manually use mask
	player.mask_component.use_mask_manually()

	assert_eq(player.mask_component.get_inventory_count(), 1, "Should consume from inventory")
	assert_true(player.mask_component.is_wearing_mask(), "Should activate")

# === Signal Tests ===

func test_signals_emitted_correctly():
	"""Test mask system emits correct signals"""
	watch_signals(player.mask_component)

	# Pickup mask
	player.apply_mask()

	assert_signal_emitted(player.mask_component, "mask_activated")
	assert_signal_emit_count(player.mask_component, "mask_activated", 1)

	# Expire mask
	for i in range(35):
		player.mask_component._process(1.0)

	assert_signal_emitted(player.mask_component, "mask_deactivated")

func test_inventory_changed_signal():
	"""Test inventory_changed signal fires"""
	watch_signals(player.mask_component)

	player.apply_mask()  # Activate (no inventory change)
	player.apply_mask()  # Add to inventory

	assert_signal_emitted(player.mask_component, "mask_inventory_changed")
	assert_signal_emitted_with_parameters(
		player.mask_component,
		"mask_inventory_changed",
		[1]
	)
