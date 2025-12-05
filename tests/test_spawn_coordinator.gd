extends GutTest
"""
Unit Tests for SpawnCoordinator Component

Tests spatial separation enforcement to prevent mask/car overlap bugs.
This will verify the overlap bug is actually fixed!
"""

var coordinator: Node
var obstacle_spawner: Node
var pickup_spawner: Node

# Mock obstacle/pickup for testing
class MockSpawnedObject:
	var global_position: Vector2
	var visible: bool = true

	func _init(x: float, y: float):
		global_position = Vector2(x, y)

func before_each():
	"""Setup before each test"""
	coordinator = load("res://scripts/components/spawner/SpawnCoordinator.gd").new()
	obstacle_spawner = Node.new()
	pickup_spawner = Node.new()

	# Add mock methods
	obstacle_spawner.set_script(load("res://scripts/components/spawner/ObstacleSpawner.gd"))
	pickup_spawner.set_script(load("res://scripts/components/spawner/PickupSpawner.gd"))

	add_child_autofree(coordinator)
	add_child_autofree(obstacle_spawner)
	add_child_autofree(pickup_spawner)

	coordinator.setup(obstacle_spawner, pickup_spawner)

func after_each():
	"""Cleanup"""
	coordinator = null
	obstacle_spawner = null
	pickup_spawner = null

# === Separation Distance Tests ===

func test_separation_constants():
	"""Test minimum separation values"""
	assert_eq(coordinator.MIN_SEPARATION_HORIZONTAL, 250.0, "Horizontal separation = 250px")
	assert_eq(coordinator.MIN_SEPARATION_VERTICAL, 80.0, "Vertical separation = 80px")

func test_no_obstacles_allows_pickup():
	"""Test pickup spawn when no obstacles present"""
	# No obstacles in pool
	obstacle_spawner.obstacle_pool = []

	var blocked = coordinator.is_blocked_by_obstacles(500, 300)

	assert_false(blocked, "Should not be blocked when no obstacles")

func test_far_obstacle_allows_pickup():
	"""Test pickup spawn when obstacle is far away"""
	# Create obstacle at (100, 300)
	var obstacle = MockSpawnedObject.new(100, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Try to spawn pickup at (500, 300) - 400px away
	var blocked = coordinator.is_blocked_by_obstacles(500, 300)

	assert_false(blocked, "Should not be blocked when 400px away")

func test_close_obstacle_blocks_pickup_horizontal():
	"""Test pickup blocked when obstacle too close horizontally"""
	# Create obstacle at (500, 300)
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Try to spawn pickup at (600, 300) - only 100px away (< 250)
	var blocked = coordinator.is_blocked_by_obstacles(600, 300)

	assert_true(blocked, "Should be blocked when only 100px away")

func test_close_obstacle_blocks_pickup_vertical():
	"""Test pickup blocked when obstacle too close vertically"""
	# Create obstacle at (500, 300)
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Try to spawn pickup at (600, 340) - 100px H, 40px V
	var blocked = coordinator.is_blocked_by_obstacles(600, 340)

	assert_true(blocked, "Should be blocked when within both thresholds")

func test_exact_separation_boundary_horizontal():
	"""Test exact boundary: 250px horizontal"""
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Exactly 250px away
	var blocked = coordinator.is_blocked_by_obstacles(750, 300)

	assert_false(blocked, "Should NOT be blocked at exactly 250px")

func test_exact_separation_boundary_vertical():
	"""Test exact boundary: 80px vertical"""
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Exactly 80px away vertically, but close horizontally
	var blocked = coordinator.is_blocked_by_obstacles(550, 380)

	assert_false(blocked, "Should NOT be blocked at exactly 80px vertical")

func test_overlap_scenario_same_position():
	"""
	CRITICAL BUG TEST: Obstacle and pickup at SAME position
	This is the bug scenario reported by user!
	"""
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Try to spawn pickup at EXACT same position
	var blocked = coordinator.is_blocked_by_obstacles(500, 300)

	assert_true(blocked, "Should BLOCK when at exact same position")

func test_overlap_scenario_adjacent_lanes():
	"""Test obstacle in lane 1, pickup in lane 2 (60px apart)"""
	# Obstacle at lane 1 (240px Y)
	var obstacle = MockSpawnedObject.new(500, 240)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Pickup at lane 2 (300px Y) - 60px vertical, same X
	var blocked = coordinator.is_blocked_by_obstacles(500, 300)

	assert_true(blocked, "Should BLOCK - lanes too close (60 < 80)")

func test_overlap_scenario_skip_lane():
	"""Test obstacle in lane 1, pickup in lane 3 (120px apart)"""
	# Obstacle at lane 1 (240px Y)
	var obstacle = MockSpawnedObject.new(500, 240)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Pickup at lane 3 (360px Y) - 120px vertical, same X
	var blocked = coordinator.is_blocked_by_obstacles(500, 360)

	# 120px vertical > 80px, so should be allowed IF horizontal > 250
	# But same X = 0px horizontal < 250, so should block
	assert_true(blocked, "Should BLOCK - horizontal too close (0 < 250)")

func test_diagonal_separation():
	"""Test diagonal separation (both H and V matter)"""
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [obstacle]

	# Spawn at (600, 360) - 100px H, 60px V
	var blocked = coordinator.is_blocked_by_obstacles(600, 360)

	assert_true(blocked, "Should BLOCK - both within thresholds")

func test_multiple_obstacles():
	"""Test with multiple obstacles on screen"""
	obstacle_spawner.obstacle_pool = [
		MockSpawnedObject.new(300, 240),
		MockSpawnedObject.new(500, 300),
		MockSpawnedObject.new(700, 360)
	]

	# Try positions near each obstacle
	assert_true(coordinator.is_blocked_by_obstacles(320, 240), "Blocked by obstacle 1")
	assert_true(coordinator.is_blocked_by_obstacles(520, 300), "Blocked by obstacle 2")
	assert_true(coordinator.is_blocked_by_obstacles(720, 360), "Blocked by obstacle 3")

	# Try position far from all
	assert_false(coordinator.is_blocked_by_obstacles(100, 300), "Not blocked when far")

func test_invisible_obstacle_ignored():
	"""Test that invisible obstacles don't block"""
	var obstacle = MockSpawnedObject.new(500, 300)
	obstacle.visible = false
	obstacle_spawner.obstacle_pool = [obstacle]

	var blocked = coordinator.is_blocked_by_obstacles(520, 300)

	assert_false(blocked, "Should NOT block invisible obstacles")

# === Reverse Direction Tests ===

func test_pickup_blocks_obstacle():
	"""Test obstacle blocked by nearby pickup"""
	var pickup = MockSpawnedObject.new(500, 300)
	pickup_spawner.pickup_pool = [pickup]

	var blocked = coordinator.is_blocked_by_pickups(520, 300)

	assert_true(blocked, "Should block obstacle near pickup")

func test_far_pickup_allows_obstacle():
	"""Test obstacle allowed when pickup far away"""
	var pickup = MockSpawnedObject.new(100, 300)
	pickup_spawner.pickup_pool = [pickup]

	var blocked = coordinator.is_blocked_by_pickups(500, 300)

	assert_false(blocked, "Should not block when 400px away")

# === Real-World Scenarios ===

func test_scenario_user_reported_bug():
	"""
	Reproduce user's bug report:
	'when cars and masks overlap even at the collision boundary level mask pickup fails'

	Scenario: Car at (500, 300), mask spawns at (520, 300)
	"""
	var car = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [car]

	# Try to spawn mask 20px away
	var mask_blocked = coordinator.is_blocked_by_obstacles(520, 300)

	assert_true(mask_blocked, "Mask should be BLOCKED when 20px from car")

	gut.p("USER BUG VERIFIED: Mask at (520, 300) blocked by car at (500, 300)")
	gut.p("Horizontal distance: 20px < 250px threshold")
	gut.p("This is CORRECT behavior - prevents overlap!")

func test_scenario_safe_spawn_distance():
	"""Test safe spawn distance after car passes"""
	var car = MockSpawnedObject.new(500, 300)
	obstacle_spawner.obstacle_pool = [car]

	# Try to spawn mask 260px away (> 250 threshold)
	var mask_blocked = coordinator.is_blocked_by_obstacles(760, 300)

	assert_false(mask_blocked, "Mask should spawn when 260px from car")
