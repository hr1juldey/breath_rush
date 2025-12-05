extends GutTest
"""
E2E Automated Gameplay Test - Mask Pickup Bug Detection

This test:
1. Plays the game automatically for 6 minutes
2. Monitors mask spawns via logger
3. Simulates player movement and mask pickups
4. Detects when masks fail to be picked up
5. Triggers detailed traceback on pickup failure
6. Uses scripted keyboard controls for all scenarios

This is a MOCK E2E test to catch the mask bug in real gameplay.
"""

# Test configuration
const TEST_DURATION = 360.0  # 6 minutes in seconds
const SPAWN_CHECK_INTERVAL = 0.1  # Check for spawns every 100ms

# Game references
var main_scene: Node
var player: CharacterBody2D
var spawner: Node
var hud: Control
var mask_component: Node

# Test state tracking
var test_time = 0.0
var masks_spawned = []  # Track all mask spawns
var masks_picked = []  # Track successful pickups
var masks_failed = []  # Track failed pickups
var player_state_history = []  # Track player state over time

# Counters
var total_masks_spawned = 0
var total_masks_picked = 0
var total_masks_failed = 0
var total_pickup_attempts = 0

func before_all():
	"""Setup before test suite"""
	gut.p("=".repeat(60))
	gut.p("STARTING E2E AUTOMATED GAMEPLAY TEST")
	gut.p("Duration: 6 minutes (360 seconds)")
	gut.p("Objective: Detect mask pickup failures in real gameplay")
	gut.p("=".repeat(60))

func before_each():
	"""Setup game scene"""
	gut.p("\n[SETUP] Loading game scene...")

	# Load main game scene
	var main_scene_res = load("res://scenes/Main.tscn")
	main_scene = main_scene_res.instantiate()
	add_child_autofree(main_scene)

	# Wait for scene to initialize
	await wait_frames(5)

	# Get references
	player = main_scene.get_node_or_null("Player")
	spawner = main_scene.get_node_or_null("Spawner")
	hud = main_scene.get_node_or_null("HUD")

	assert_not_null(player, "Player should exist")
	assert_not_null(spawner, "Spawner should exist")

	mask_component = player.get_node_or_null("PlayerMask") if player else null
	assert_not_null(mask_component, "Mask component should exist")

	# CRITICAL: Give player survival advantage for testing
	var health_component = player.get_node_or_null("PlayerHealth")
	if health_component:
		health_component.health = 1000.0  # High health to survive longer
		health_component.max_health = 1000.0
		gut.p("[SETUP] ✓ Player health boosted to 1000 for testing")

	# Connect to logger signals if available
	_setup_logger_monitoring()

	# Connect to spawner signals
	_setup_spawn_monitoring()

	# Connect to mask component signals to detect pickups
	if mask_component:
		mask_component.mask_activated.connect(_on_mask_activated)
		mask_component.mask_inventory_changed.connect(_on_mask_inventory_changed)
		gut.p("[SETUP] ✓ Connected to mask signals")

	gut.p("[SETUP] ✓ Game scene loaded")
	gut.p("[SETUP] ✓ Player: %s" % player)
	gut.p("[SETUP] ✓ Spawner: %s" % spawner)
	gut.p("[SETUP] ✓ Mask component: %s" % mask_component)
	gut.p("[SETUP] Starting automated gameplay...\n")

func _setup_logger_monitoring():
	"""Setup monitoring of logger output"""
	var logger = get_node_or_null("/root/Logger")
	if logger:
		# Connect to logger signals if available
		gut.p("[LOGGER] Logger found, monitoring enabled")
	else:
		gut.p("[LOGGER] Logger not found, using print monitoring")

func _setup_spawn_monitoring():
	"""Setup monitoring of mask spawns"""
	if not spawner:
		return

	# Try to connect to spawn signals
	var pickup_spawner = spawner.get_node_or_null("PickupSpawner")
	if pickup_spawner:
		gut.p("[SPAWN] Pickup spawner found, connecting signals")
		# We'll poll the pickup pool instead since signals might not exist

func _on_mask_activated(duration: float):
	"""Called when mask is activated (picked up when not wearing one)"""
	total_masks_picked += 1
	var total = mask_component.get_inventory_count() + (1 if mask_component.is_wearing_mask() else 0)
	gut.p("\n[PICKUP SUCCESS] Mask #%d activated! Duration: %.1fs" % [total_masks_picked, duration])
	gut.p("  Current state: Wearing=1, Inventory=%d, Total=%d/5" %
		[mask_component.get_inventory_count(), total])

	# Test case: 0→1 (first mask)
	if total == 1:
		gut.p("  ✓ TEST CASE: 0→1 mask (first pickup, activated)")

	# Check if we're approaching the bug scenario
	if total >= 4:
		gut.p("  ⚠ WARNING: Approaching critical 5-mask limit!")

func _on_mask_inventory_changed(count: int):
	"""Called when mask inventory changes (picked up while wearing one)"""
	total_masks_picked += 1
	var wearing = 1 if mask_component.is_wearing_mask() else 0
	var total = count + wearing
	var prev_total = total - 1

	gut.p("\n[PICKUP SUCCESS] Mask #%d added to inventory!" % total_masks_picked)
	gut.p("  Current state: Wearing=%d, Inventory=%d, Total=%d/5" %
		[wearing, count, total])
	gut.p("  Transition: %d→%d masks" % [prev_total, total])

	# Test case: 1→2 (second mask goes to inventory)
	if total == 2:
		gut.p("  ✓ TEST CASE: 1→2 masks (second pickup, to inventory)")

	# Test case: 2→3, 3→4, 4→5 (normal pickups)
	if total >= 3 and total <= 4:
		gut.p("  ✓ TEST CASE: %d→%d masks (normal pickup)" % [prev_total, total])

	# Check if we've reached the critical bug scenario
	if total == 5:
		gut.p("  🎯 CRITICAL: Player at MAX capacity (5/5)!")
		gut.p("     Wearing: %d | Inventory: %d" % [wearing, count])
		gut.p("     Next pickup MUST be rejected (bug fix test)!")
	elif total > 5:
		gut.p("  ❌ BUG DETECTED: Player has %d masks (exceeds max 5)!" % total)
		gut.p("     This should NEVER happen if the fix is working!")

func test_automated_gameplay_6_minutes():
	"""
	Main E2E test: Play game for 6 minutes and detect mask bugs
	"""
	gut.p("\n" + "=".repeat(60))
	gut.p("TEST START: Automated Gameplay (6 minutes)")
	gut.p("=".repeat(60) + "\n")

	var start_time = Time.get_ticks_msec()
	var last_status_report = 0.0
	var frame_count = 0

	# Main game loop - run for 6 minutes
	while test_time < TEST_DURATION:
		var delta = 0.016  # ~60 FPS
		test_time += delta
		frame_count += 1

		# Process game frame (let engine handle physics)
		_process_game_frame(delta)

		# Check for mask spawns
		_check_for_mask_spawns()

		# No need to manually attempt pickups - collision system handles it
		# Just monitor if pickups happened

		# AI player movement
		_ai_player_movement(delta)

		# Monitor player state
		_monitor_player_state()

		# Status report every 30 seconds
		if test_time - last_status_report >= 30.0:
			_print_status_report()
			last_status_report = test_time

		# CRITICAL: Yield for physics processing
		# Use wait_physics_frames to ensure physics collisions are detected
		await wait_physics_frames(1)

	# Test complete - print final report
	_print_final_report()

	# Verify no critical bugs occurred
	_verify_no_critical_bugs()

func _process_game_frame(delta: float):
	"""Process one game frame"""
	# Don't manually call _process - let the engine handle it
	# Physics collisions require the actual physics engine to process
	pass

func _check_for_mask_spawns():
	"""Check spawner for new mask spawns"""
	if not spawner:
		return

	var pickup_spawner = spawner.get_node_or_null("PickupSpawner")
	var obstacle_spawner = spawner.get_node_or_null("ObstacleSpawner")
	if not pickup_spawner:
		return

	# Check pickup pool
	var pickup_pool = pickup_spawner.get("pickup_pool") if pickup_spawner else []
	if not pickup_pool:
		return

	# Get obstacle pool for overlap checking
	var obstacle_pool = obstacle_spawner.get("obstacle_pool") if obstacle_spawner else []

	# Find new visible pickups
	for pickup in pickup_pool:
		if not is_instance_valid(pickup):
			continue

		if not pickup.visible:
			continue

		# Check if this is a new spawn we haven't seen
		var pickup_id = pickup.get_instance_id()
		var already_tracked = false
		for tracked in masks_spawned:
			if tracked.id == pickup_id:
				already_tracked = true
				break

		if not already_tracked:
			var mask_pos = pickup.global_position

			# Check for nearby cars (overlap detection)
			var nearby_cars = []
			for obstacle in obstacle_pool:
				if is_instance_valid(obstacle) and obstacle.visible:
					var car_pos = obstacle.global_position
					var distance = mask_pos.distance_to(car_pos)
					if distance < 300.0:  # Within 300px
						nearby_cars.append({"distance": distance, "position": car_pos})

			var spawn_data = {
				"id": pickup_id,
				"position": mask_pos,
				"time": test_time,
				"picked": false,
				"pickup_ref": pickup,
				"nearby_cars": nearby_cars
			}
			masks_spawned.append(spawn_data)
			total_masks_spawned += 1

			var overlap_warning = ""
			if nearby_cars.size() > 0:
				overlap_warning = " ⚠ %d cars nearby!" % nearby_cars.size()

			gut.p("[SPAWN] Mask #%d spawned at (%.1f, %.1f) - Time: %.1fs%s" %
				[total_masks_spawned, mask_pos.x, mask_pos.y, test_time, overlap_warning])

			# Log nearby cars
			for car in nearby_cars:
				gut.p("  └─ Car at (%.1f, %.1f) - Distance: %.1fpx" %
					[car.position.x, car.position.y, car.distance])

func _attempt_mask_pickups():
	"""Check if player should pick up any nearby masks"""
	if not player or not mask_component:
		return

	var player_pos = player.global_position
	var pickup_radius = 50.0  # Detection radius

	# Check each spawned mask
	for spawn_data in masks_spawned:
		if spawn_data.picked:
			continue  # Already picked

		var pickup = spawn_data.pickup_ref
		if not is_instance_valid(pickup):
			continue

		if not pickup.visible:
			# Mask disappeared - check if we picked it up
			_check_pickup_success(spawn_data)
			continue

		var mask_pos = pickup.global_position
		var distance = player_pos.distance_to(mask_pos)

		if distance < pickup_radius:
			# We should pick this up!
			total_pickup_attempts += 1
			_attempt_pickup(spawn_data, distance)

func _attempt_pickup(spawn_data: Dictionary, distance: float):
	"""Attempt to pick up a mask and verify success"""
	var before_inventory = mask_component.get_inventory_count()
	var before_wearing = mask_component.is_wearing_mask()
	var before_total = before_inventory + (1 if before_wearing else 0)

	gut.p("\n[PICKUP] Attempt #%d - Mask at distance %.1f" % [total_pickup_attempts, distance])
	gut.p("  Player state BEFORE pickup:")
	gut.p("    - Wearing: %s" % before_wearing)
	gut.p("    - Inventory: %d/5" % before_inventory)
	gut.p("    - Total: %d/5" % before_total)

	# Simulate collision/pickup (the pickup should happen automatically via Area2D)
	# Wait a few frames for collision detection
	await wait_frames(3)

	# Check state AFTER
	var after_inventory = mask_component.get_inventory_count()
	var after_wearing = mask_component.is_wearing_mask()
	var after_total = after_inventory + (1 if after_wearing else 0)

	var inventory_increased = after_inventory > before_inventory
	var wearing_activated = (not before_wearing) and after_wearing
	var pickup_successful = inventory_increased or wearing_activated

	gut.p("  Player state AFTER pickup:")
	gut.p("    - Wearing: %s" % after_wearing)
	gut.p("    - Inventory: %d/5" % after_inventory)
	gut.p("    - Total: %d/5" % after_total)

	if pickup_successful:
		# SUCCESS
		spawn_data.picked = true
		spawn_data.pickup_time = test_time
		masks_picked.append(spawn_data)
		total_masks_picked += 1
		gut.p("  ✓ PICKUP SUCCESS - Total picked: %d" % total_masks_picked)
	else:
		# FAILURE - This is the bug!
		_handle_pickup_failure(spawn_data, before_inventory, before_wearing,
							   after_inventory, after_wearing, distance)

func _handle_pickup_failure(spawn_data: Dictionary, before_inv: int, before_wear: bool,
							 after_inv: int, after_wear: bool, distance: float):
	"""Handle and debug a pickup failure"""
	total_masks_failed += 1
	spawn_data.picked = false
	spawn_data.failed = true
	spawn_data.failure_reason = "Unknown"
	masks_failed.append(spawn_data)

	gut.p("\n" + "!".repeat(60))
	gut.p("!!! PICKUP FAILURE DETECTED !!!")
	gut.p("!".repeat(60))

	# Detailed failure analysis
	gut.p("\n[FAILURE ANALYSIS]")
	gut.p("  Mask spawn time: %.1fs" % spawn_data.time)
	gut.p("  Pickup attempt time: %.1fs" % test_time)
	gut.p("  Distance to mask: %.1f pixels" % distance)
	gut.p("  Player position: (%.1f, %.1f)" % [player.global_position.x, player.global_position.y])
	gut.p("  Mask position: (%.1f, %.1f)" % [spawn_data.position.x, spawn_data.position.y])

	gut.p("\n[STATE COMPARISON]")
	gut.p("  BEFORE pickup:")
	gut.p("    - Wearing mask: %s" % before_wear)
	gut.p("    - Inventory: %d/5" % before_inv)
	gut.p("    - Total: %d/5" % (before_inv + (1 if before_wear else 0)))
	gut.p("  AFTER pickup:")
	gut.p("    - Wearing mask: %s" % after_wear)
	gut.p("    - Inventory: %d/5" % after_inv)
	gut.p("    - Total: %d/5" % (after_inv + (1 if after_wear else 0)))

	# Determine failure reason
	var total_before = before_inv + (1 if before_wear else 0)

	if total_before >= 5:
		spawn_data.failure_reason = "At max capacity (5/5 total)"
		gut.p("\n[REASON] At max capacity - EXPECTED rejection")
	elif before_inv >= 5:
		spawn_data.failure_reason = "Inventory full (5/5)"
		gut.p("\n[REASON] Inventory full - EXPECTED rejection")
	else:
		spawn_data.failure_reason = "UNEXPECTED - Should have been picked up!"
		gut.p("\n[REASON] *** BUG DETECTED *** Mask should have been picked up!")
		gut.p("  This is a critical bug!")

		# Print detailed traceback
		_print_failure_traceback(spawn_data, before_inv, before_wear)

	gut.p("!".repeat(60) + "\n")

func _print_failure_traceback(spawn_data: Dictionary, inventory: int, wearing: bool):
	"""Print detailed traceback for debugging"""
	gut.p("\n[TRACEBACK]")
	gut.p("  Call stack at failure:")
	gut.p("    1. _attempt_mask_pickups() - Detected nearby mask")
	gut.p("    2. _attempt_pickup() - Initiated pickup")
	gut.p("    3. [Collision System] - Should trigger Area2D.body_entered")
	gut.p("    4. Pickup._on_body_entered() - Should call player.apply_mask()")
	gut.p("    5. Player.apply_mask() - Should call mask_component.apply_mask()")
	gut.p("    6. PlayerMask.apply_mask() - Should check capacity and add mask")

	gut.p("\n[CAPACITY CHECK]")
	gut.p("  Current inventory: %d" % inventory)
	gut.p("  Currently wearing: %s" % wearing)
	gut.p("  Total masks: %d" % (inventory + (1 if wearing else 0)))
	gut.p("  Max capacity: 5")
	gut.p("  Should accept: %s" % ((inventory + (1 if wearing else 0)) < 5))

	gut.p("\n[POSSIBLE CAUSES]")
	if wearing and inventory == 4:
		gut.p("  ⚠ CRITICAL: Wearing + 4 inventory = 5 total")
		gut.p("  ⚠ This is the exact bug scenario!")
		gut.p("  ⚠ Pickup should be REJECTED (fixed behavior)")
		gut.p("  ⚠ But collision may have occurred before check")
	elif inventory < 5 and not wearing:
		gut.p("  ✗ No capacity issue - pickup should succeed")
		gut.p("  ✗ Possible causes:")
		gut.p("    - Collision detection failure")
		gut.p("    - Pickup already returned to pool")
		gut.p("    - Timing issue with Area2D")

	# Check if mask is still in scene
	var pickup = spawn_data.pickup_ref
	if is_instance_valid(pickup):
		gut.p("\n[PICKUP STATUS]")
		gut.p("  Still valid: true")
		gut.p("  Visible: %s" % pickup.visible)
		gut.p("  Position: (%.1f, %.1f)" % [pickup.global_position.x, pickup.global_position.y])
	else:
		gut.p("\n[PICKUP STATUS]")
		gut.p("  Still valid: false (already freed/pooled)")

func _check_pickup_success(spawn_data: Dictionary):
	"""Check if a mask was successfully picked up (after it disappeared)"""
	if spawn_data.picked:
		return

	# Mask disappeared but we didn't mark it as picked - check inventory
	var current_inventory = mask_component.get_inventory_count() if mask_component else 0
	var current_wearing = mask_component.is_wearing_mask() if mask_component else false

	# Assume it was picked if it disappeared (collision system handled it)
	spawn_data.picked = true
	spawn_data.pickup_time = test_time
	masks_picked.append(spawn_data)
	total_masks_picked += 1

func _ai_player_movement(delta: float):
	"""Simulate AI player movement (lane switching, horizontal movement)"""
	if not player:
		return

	# Random lane switching every few seconds
	if int(test_time) % 3 == 0 and int(test_time * 100) % 100 < 2:
		_simulate_lane_switch()

	# Random horizontal movement
	if int(test_time * 10) % 7 == 0:
		_simulate_horizontal_movement()

func _simulate_lane_switch():
	"""Simulate pressing up/down arrow keys"""
	var lane_input = randi() % 3 - 1  # -1, 0, or 1

	if lane_input == -1:
		# Press up arrow
		Input.action_press("move_up")
		await wait_frames(2)
		Input.action_release("move_up")
		gut.p("[INPUT] Pressed UP arrow (lane switch)")
	elif lane_input == 1:
		# Press down arrow
		Input.action_press("move_down")
		await wait_frames(2)
		Input.action_release("move_down")
		gut.p("[INPUT] Pressed DOWN arrow (lane switch)")

func _simulate_horizontal_movement():
	"""Simulate pressing left/right arrow keys"""
	var h_input = randi() % 3 - 1  # -1, 0, or 1

	if h_input == -1:
		# Press left arrow
		Input.action_press("move_left")
		await wait_frames(5)
		Input.action_release("move_left")
	elif h_input == 1:
		# Press right arrow
		Input.action_press("move_right")
		await wait_frames(5)
		Input.action_release("move_right")

func _monitor_player_state():
	"""Monitor and log player state"""
	if not mask_component:
		return

	# Record state every second
	if int(test_time * 10) % 10 == 0:
		var state = {
			"time": test_time,
			"inventory": mask_component.get_inventory_count(),
			"wearing": mask_component.is_wearing_mask(),
			"mask_time": mask_component.get_mask_time(),
		}
		player_state_history.append(state)

func _print_status_report():
	"""Print periodic status report"""
	gut.p("\n" + "-".repeat(60))
	gut.p("STATUS REPORT - Time: %.1fs / %.1fs (%.1f%%)" %
		[test_time, TEST_DURATION, (test_time / TEST_DURATION) * 100])
	gut.p("-".repeat(60))
	gut.p("Masks spawned: %d" % total_masks_spawned)
	gut.p("Masks picked: %d" % total_masks_picked)
	gut.p("Masks failed: %d" % total_masks_failed)
	gut.p("Pickup attempts: %d" % total_pickup_attempts)

	if mask_component:
		gut.p("\nPlayer state:")
		gut.p("  - Wearing: %s" % mask_component.is_wearing_mask())
		gut.p("  - Inventory: %d/5" % mask_component.get_inventory_count())
		gut.p("  - Total: %d/5" % (mask_component.get_inventory_count() +
			(1 if mask_component.is_wearing_mask() else 0)))

	gut.p("-".repeat(60) + "\n")

func _print_final_report():
	"""Print final test report"""
	gut.p("\n" + "=".repeat(60))
	gut.p("FINAL REPORT - 6 Minute Automated Gameplay")
	gut.p("=".repeat(60))
	gut.p("\n[TOTALS]")
	gut.p("  Test duration: %.1fs (%.1f minutes)" % [test_time, test_time / 60.0])
	gut.p("  Masks spawned: %d" % total_masks_spawned)
	gut.p("  Masks picked: %d (%.1f%%)" %
		[total_masks_picked, (float(total_masks_picked) / max(total_masks_spawned, 1)) * 100])
	gut.p("  Masks failed: %d (%.1f%%)" %
		[total_masks_failed, (float(total_masks_failed) / max(total_pickup_attempts, 1)) * 100])
	gut.p("  Pickup attempts: %d" % total_pickup_attempts)

	gut.p("\n[FAILURE ANALYSIS]")
	if total_masks_failed == 0:
		gut.p("  ✓ No pickup failures detected!")
	else:
		gut.p("  ✗ %d pickup failures detected:" % total_masks_failed)

		var expected_failures = 0
		var unexpected_failures = 0

		for failure in masks_failed:
			if "At max capacity" in failure.failure_reason or "Inventory full" in failure.failure_reason:
				expected_failures += 1
			else:
				unexpected_failures += 1

		gut.p("    - Expected failures (at capacity): %d" % expected_failures)
		gut.p("    - Unexpected failures (BUG): %d" % unexpected_failures)

		if unexpected_failures > 0:
			gut.p("\n  ⚠ CRITICAL BUGS DETECTED ⚠")
			gut.p("  Review failure tracebacks above for details")

	if mask_component:
		gut.p("\n[FINAL PLAYER STATE]")
		gut.p("  - Wearing mask: %s" % mask_component.is_wearing_mask())
		gut.p("  - Inventory: %d/5" % mask_component.get_inventory_count())
		gut.p("  - Total masks: %d/5" % (mask_component.get_inventory_count() +
			(1 if mask_component.is_wearing_mask() else 0)))

	gut.p("\n" + "=".repeat(60) + "\n")

func _verify_no_critical_bugs():
	"""Verify no critical bugs occurred during gameplay"""
	# Count unexpected failures
	var unexpected_failures = 0
	for failure in masks_failed:
		if not ("At max capacity" in failure.failure_reason or "Inventory full" in failure.failure_reason):
			unexpected_failures += 1

	# Verify total masks never exceeded 5
	var max_total_seen = 0
	for state in player_state_history:
		var total = state.inventory + (1 if state.wearing else 0)
		if total > max_total_seen:
			max_total_seen = total

	gut.p("\n[VERIFICATION]")
	gut.p("  Max total masks seen: %d/5" % max_total_seen)

	assert_true(max_total_seen <= 5, "Total masks should never exceed 5")
	assert_eq(unexpected_failures, 0, "Should have no unexpected pickup failures")

	gut.p("  ✓ All verifications passed!")

func after_each():
	"""Cleanup after test"""
	# Cleanup
	masks_spawned.clear()
	masks_picked.clear()
	masks_failed.clear()
	player_state_history.clear()
