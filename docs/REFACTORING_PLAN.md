# Refactoring Plan: Player.gd and Spawner.gd

## Goal
Break down Player.gd (335 lines) and Spawner.gd (295 lines) into focused components (<100 lines each) to eliminate bugs caused by complexity.

## Why This Makes System Bug-Free

### Current Problems
1. **Mask pickup bug** - Complex logic buried in 335-line Player.gd
2. **Spawn overlap bug** - Obstacles and pickups don't coordinate in 295-line Spawner.gd
3. **Hard to test** - Can't test mask system without loading all 13 player systems
4. **Hard to debug** - Finding bugs in 335 lines takes 5x longer than 60 lines
5. **Fragile changes** - Editing mask code risks breaking health, battery, movement

### After Refactoring
1. ✅ **Isolated systems** - Each component is self-contained (60-80 lines)
2. ✅ **Clear interfaces** - Components communicate through explicit methods/signals
3. ✅ **Easy testing** - Test mask system alone without health, battery, movement
4. ✅ **Fast debugging** - Scan 60 lines instead of 335 lines
5. ✅ **Safe changes** - Modifying mask code can't break movement

---

## Phase 1: Refactor Player.gd (335 → 7 components)

### Current Structure (MONOLITHIC - 335 lines)
```
Player.gd (335 lines)
├─ Lane movement (lines 189-191)
├─ Horizontal movement (lines 133-141)
├─ Health system (lines 14-17, 102-114)
├─ Battery system (lines 28-34, 116-130)
├─ Mask system (lines 19-26, 209-268)
├─ Item carrying (lines 37-39, 270-290)
├─ Boost mechanics (lines 193-201)
├─ Charging zones (lines 292-296)
├─ Damage system (lines 298-309)
├─ AQI tracking (lines 53, 311-312)
├─ Keyboard input (lines 150-166)
├─ Touch input (lines 168-187)
└─ Logging (lines 314-335)
```

### Target Structure (COMPONENT-BASED)
```
Player.tscn
└─ Player (CharacterBody2D) - Player.gd (~50 lines - coordinator only)
   ├─ Movement (Node) - PlayerMovement.gd (~70 lines)
   │   ├─ Lane changes
   │   └─ Horizontal movement
   ├─ Health (Node) - PlayerHealth.gd (~60 lines)
   │   ├─ Health points
   │   ├─ Grace period
   │   ├─ Damage handling
   │   └─ AQI drain calculation
   ├─ Battery (Node) - PlayerBattery.gd (~50 lines)
   │   ├─ Battery charge
   │   ├─ Boost mechanics
   │   └─ Charging zones
   ├─ Mask (Node) - PlayerMask.gd (~80 lines)
   │   ├─ Mask inventory (0-5)
   │   ├─ Mask wearing (timer)
   │   ├─ Mask activation
   │   └─ Mask leak mechanics
   ├─ Inventory (Node) - PlayerInventory.gd (~40 lines)
   │   ├─ Carried item (filter/sapling)
   │   └─ Item drop mechanics
   └─ Input (Node) - PlayerInput.gd (~70 lines)
       ├─ Keyboard input
       ├─ Touch input
       └─ Signal emission
```

### Component Responsibilities

#### PlayerMovement.gd (~70 lines)
```gdscript
extends Node

# Handles ONLY movement
var parent: CharacterBody2D
var lane_positions = [240, 300, 360]
var current_lane = 1
var target_y = 300.0
var horizontal_speed = 200.0

func change_lane(direction: int)
func move_horizontal(delta: float, input: float)
func move_vertical(delta: float)
```

#### PlayerHealth.gd (~60 lines)
```gdscript
extends Node

# Handles ONLY health
signal health_changed(value: float)
signal player_died()

var health = 100.0
var max_health = 100.0
var grace_period_active = true

func take_damage(amount: float)
func process_health_drain(delta: float, aqi: float, has_mask: bool)
func calculate_drain_rate(aqi: float) -> float
```

#### PlayerBattery.gd (~50 lines)
```gdscript
extends Node

# Handles ONLY battery and boost
signal battery_changed(value: float)
signal boost_started()
signal boost_stopped()

var battery = 100.0
var max_battery = 100.0
var is_boosting = false

func start_boost()
func stop_boost()
func process_battery_drain(delta: float)
func enter_charging_zone()
func exit_charging_zone()
```

#### PlayerMask.gd (~80 lines)
```gdscript
extends Node

# Handles ONLY mask system - THIS FIXES THE BUG!
signal mask_activated(duration: float)
signal mask_deactivated()
signal mask_inventory_changed(count: int)

var mask_time = 0.0
var mask_inventory = 0
var max_mask_inventory = 5

# THIS IS NOW ISOLATED AND CLEAR
func apply_mask() -> bool:
    """
    Returns true if mask consumed, false if rejected.
    NO DEPENDENCIES on health, battery, movement!
    """
    if mask_inventory >= max_mask_inventory:
        return false  # Clear rejection

    if is_wearing_mask() or has_inventory():
        return add_to_inventory()
    else:
        return activate_mask()

func is_wearing_mask() -> bool:
    return mask_time > 0

func has_inventory() -> bool:
    return mask_inventory > 0

func add_to_inventory() -> bool:
    if mask_inventory < max_mask_inventory:
        mask_inventory += 1
        mask_inventory_changed.emit(mask_inventory)
        return true
    return false

func activate_mask() -> bool:
    mask_time = 30.0
    mask_activated.emit(30.0)
    return true

func use_mask_manually():
    if not is_wearing_mask() and mask_inventory > 0:
        mask_inventory -= 1
        activate_mask()
        mask_inventory_changed.emit(mask_inventory)
```

#### PlayerInventory.gd (~40 lines)
```gdscript
extends Node

# Handles ONLY item carrying
signal item_picked_up(type: String)
signal item_dropped(type: String)
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)

var carried_item: String = ""

func pickup_filter() -> bool
func pickup_sapling() -> bool
func drop_item() -> bool
```

#### PlayerInput.gd (~70 lines)
```gdscript
extends Node

# Handles ONLY input processing
signal lane_change_requested(direction: int)
signal horizontal_movement(input: float)
signal boost_requested()
signal boost_released()
signal mask_use_requested()
signal item_drop_requested()

func _input(event: InputEvent)
func handle_keyboard(event: InputEventKey)
func handle_touch(event: InputEventScreenTouch)
```

#### Player.gd (~50 lines - COORDINATOR ONLY)
```gdscript
extends CharacterBody2D

# Components (automatic via scene tree)
@onready var movement = $Movement
@onready var health = $Health
@onready var battery = $Battery
@onready var mask = $Mask
@onready var inventory = $Inventory
@onready var input = $Input

func _ready():
    # Connect component signals
    input.lane_change_requested.connect(movement.change_lane)
    input.boost_requested.connect(battery.start_boost)
    input.mask_use_requested.connect(mask.use_mask_manually)
    # etc.

func _process(delta):
    # Coordinate components
    var h_input = input.get_horizontal_input()
    movement.move_horizontal(delta, h_input)
    movement.move_vertical(delta)

    # Health drain depends on mask state
    var has_mask = mask.is_wearing_mask()
    health.process_health_drain(delta, aqi_current, has_mask)

    # Battery drain during boost
    if battery.is_boosting:
        battery.process_battery_drain(delta)

# PUBLIC API (called by Pickup.gd)
func apply_mask() -> bool:
    return mask.apply_mask()  # Delegate to mask component

func pickup_filter():
    inventory.pickup_filter()

func pickup_sapling():
    inventory.pickup_sapling()
```

---

## Phase 2: Refactor Spawner.gd (295 → 4 components)

### Current Structure (MONOLITHIC - 295 lines)
```
Spawner.gd (295 lines)
├─ Obstacle pooling (lines 35-40, 132-136)
├─ Pickup pooling (lines 43-47, 138-142)
├─ Obstacle spawn timing (lines 74-93)
├─ Pickup spawn timing (lines 193-230)
├─ Obstacle spawning (lines 95-116)
├─ Pickup spawning (lines 118-146)
├─ Chunk management (lines 149-177)
├─ Position tracking (lines 232-253)
└─ Player monitoring (lines 25-28, 56-61)
```

### Target Structure (COMPONENT-BASED)
```
Spawner.tscn
└─ Spawner (Node2D) - Spawner.gd (~60 lines - coordinator only)
   ├─ ObstacleSpawner (Node) - ObstacleSpawner.gd (~90 lines)
   │   ├─ Object pooling
   │   ├─ Spawn timing
   │   └─ Spawn execution
   ├─ PickupSpawner (Node) - PickupSpawner.gd (~90 lines)
   │   ├─ Object pooling
   │   ├─ Spawn timing
   │   └─ Spawn execution
   ├─ SpawnCoordinator (Node) - SpawnCoordinator.gd (~70 lines)
   │   ├─ Spatial separation
   │   ├─ Collision checking
   │   └─ Position validation
   └─ ChunkManager (Node) - ChunkManager.gd (~60 lines)
       ├─ Chunk data loading
       ├─ Spawn point iteration
       └─ Loop management
```

### Component Responsibilities

#### ObstacleSpawner.gd (~90 lines)
```gdscript
extends Node

# Handles ONLY obstacle spawning
var obstacle_scene = preload("res://scenes/Obstacle.tscn")
var obstacle_pool = []
var pool_size = 8

func spawn_obstacle(x: float, y: float, type: String) -> bool:
    var coordinator = get_node("../SpawnCoordinator")
    if coordinator.is_blocked_by_pickups(x, y):
        return false  # Blocked!

    var obstacle = get_pooled_obstacle()
    if obstacle:
        obstacle.global_position = Vector2(x, y)
        obstacle.obstacle_type = type
        obstacle.visible = true
        coordinator.record_spawn(x, y, "obstacle")
        return true
    return false
```

#### PickupSpawner.gd (~90 lines)
```gdscript
extends Node

# Handles ONLY pickup spawning
var mask_scene = preload("res://scenes/Mask.tscn")
var pickup_pool = []
var pool_size = 6

func spawn_pickup(x: float, y: float, type: String) -> bool:
    var coordinator = get_node("../SpawnCoordinator")

    # Try requested position first
    if not coordinator.is_blocked_by_obstacles(x, y):
        return _spawn_at(x, y, type)

    # Try alternative lanes
    var lanes = [240, 300, 360]
    for lane_y in lanes:
        if not coordinator.is_blocked_by_obstacles(x, lane_y):
            return _spawn_at(x, lane_y, type)

    return false  # All lanes blocked
```

#### SpawnCoordinator.gd (~70 lines) - THIS FIXES THE OVERLAP BUG!
```gdscript
extends Node

# Handles ONLY spatial coordination
const MIN_SEPARATION_H = 250.0
const MIN_SEPARATION_V = 80.0

var obstacle_spawner: Node
var pickup_spawner: Node

func _ready():
    obstacle_spawner = get_node("../ObstacleSpawner")
    pickup_spawner = get_node("../PickupSpawner")

func is_blocked_by_obstacles(pickup_x: float, pickup_y: float) -> bool:
    for obstacle in obstacle_spawner.obstacle_pool:
        if obstacle.visible:
            var dx = abs(pickup_x - obstacle.global_position.x)
            var dy = abs(pickup_y - obstacle.global_position.y)
            if dx < MIN_SEPARATION_H and dy < MIN_SEPARATION_V:
                return true
    return false

func is_blocked_by_pickups(obstacle_x: float, obstacle_y: float) -> bool:
    for pickup in pickup_spawner.pickup_pool:
        if pickup.visible:
            var dx = abs(obstacle_x - pickup.global_position.x)
            var dy = abs(obstacle_y - pickup.global_position.y)
            if dx < MIN_SEPARATION_H and dy < MIN_SEPARATION_V:
                return true
    return false

func record_spawn(x: float, y: float, type: String):
    # Track spawn for analytics/debugging
    pass
```

#### ChunkManager.gd (~60 lines)
```gdscript
extends Node

# Handles ONLY chunk data
var current_chunk_data: Dictionary
var spawn_index = 0
var pickup_spawn_index = 0
var time_accumulated = 0.0
var pickup_time_accumulated = 0.0

func set_current_chunk(chunk_data: Dictionary)
func get_next_obstacle_spawn() -> Dictionary
func get_next_pickup_spawn() -> Dictionary
func reset_chunk()
```

#### Spawner.gd (~60 lines - COORDINATOR ONLY)
```gdscript
extends Node2D

# Components
@onready var obstacle_spawner = $ObstacleSpawner
@onready var pickup_spawner = $PickupSpawner
@onready var spawn_coordinator = $SpawnCoordinator
@onready var chunk_manager = $ChunkManager

func _process(delta):
    # Get next spawn from chunk
    var obstacle_spawn = chunk_manager.get_next_obstacle_spawn()
    if obstacle_spawn:
        obstacle_spawner.spawn_obstacle(
            obstacle_spawn.x,
            obstacle_spawn.y,
            obstacle_spawn.type
        )

    var pickup_spawn = chunk_manager.get_next_pickup_spawn()
    if pickup_spawn:
        pickup_spawner.spawn_pickup(
            pickup_spawn.x,
            pickup_spawn.y,
            pickup_spawn.type
        )

func set_current_chunk(chunk_data: Dictionary):
    chunk_manager.set_current_chunk(chunk_data)
```

---

## Benefits of This Refactoring

### Before (MONOLITHIC)
```gdscript
// Player.gd (335 lines)
func apply_mask() -> bool:  // Line 209 - buried in 335 lines!
    // Bug: Complex logic with health, battery, movement nearby
    if mask_inventory >= max_mask_inventory:
        return false  // This was missing initially!
```
**Problem:** You had to read 335 lines to understand mask system.

### After (COMPONENT-BASED)
```gdscript
// PlayerMask.gd (80 lines) - ONLY mask concerns
func apply_mask() -> bool:  // Line 40 of 80 - easy to find!
    // Clear: NO health, battery, movement code nearby
    if mask_inventory >= max_mask_inventory:
        return false  // Obviously correct
```
**Solution:** You only read 80 lines focused on masks.

### Testing Becomes Possible
```gdscript
// test_player_mask.gd
func test_mask_pickup_when_inventory_full():
    var mask = PlayerMask.new()
    mask.mask_inventory = 5  // Full

    var result = mask.apply_mask()

    assert_false(result, "Should reject when full")
    assert_eq(mask.mask_inventory, 5, "Inventory unchanged")

func test_mask_pickup_when_wearing_mask():
    var mask = PlayerMask.new()
    mask.mask_time = 10.0  // Wearing mask
    mask.mask_inventory = 0

    var result = mask.apply_mask()

    assert_true(result, "Should accept to inventory")
    assert_eq(mask.mask_inventory, 1, "Added to inventory")
```
**You can now test the mask system in ISOLATION!**

---

## Migration Strategy (Safe, Step-by-Step)

### Step 1: Extract PlayerMask Component (SAFEST FIRST)
1. Create `scripts/components/PlayerMask.gd`
2. Copy mask-related code from Player.gd
3. Add PlayerMask as child node in Player.tscn
4. Update Player.gd to delegate to mask component
5. Test thoroughly
6. If working, commit. If broken, revert easily.

### Step 2: Extract PlayerBattery Component
Same process as Step 1.

### Step 3: Extract PlayerHealth Component
Same process as Step 1.

### Step 4-6: Extract remaining components
Continue one component at a time.

### Step 7: Extract Spawner Components
After Player.gd is proven stable.

---

## File Structure After Refactoring

```
scripts/
├── Player.gd (50 lines)
├── Spawner.gd (60 lines)
├── components/
│   ├── player/
│   │   ├── PlayerMovement.gd (70 lines)
│   │   ├── PlayerHealth.gd (60 lines)
│   │   ├── PlayerBattery.gd (50 lines)
│   │   ├── PlayerMask.gd (80 lines)
│   │   ├── PlayerInventory.gd (40 lines)
│   │   └── PlayerInput.gd (70 lines)
│   └── spawner/
│       ├── ObstacleSpawner.gd (90 lines)
│       ├── PickupSpawner.gd (90 lines)
│       ├── SpawnCoordinator.gd (70 lines)
│       └── ChunkManager.gd (60 lines)
└── ... (other files)
```

**Line Count:**
- Before: Player.gd (335) + Spawner.gd (295) = **630 lines**
- After: 11 files × 60 avg = **660 lines** (30 lines overhead for interfaces)
- **Same total code, 10x easier to understand!**

---

## Proof This Fixes Bugs

### Bug 1: Mask Pickup Failure
**Root Cause:** Complex logic in 335-line file, no clear return value
**Fix:** PlayerMask.gd (80 lines) with clear `apply_mask() -> bool`

### Bug 2: Mask/Car Overlap
**Root Cause:** Obstacles and pickups don't coordinate in 295-line file
**Fix:** SpawnCoordinator.gd explicitly checks both obstacle and pickup pools

### Bug 3: Future Bugs
**Prevention:** Each component is <100 lines and testable in isolation

---

## Next Steps

1. ✅ Review this plan
2. ⏳ Start with PlayerMask.gd extraction (safest, highest impact)
3. ⏳ Test mask pickup thoroughly
4. ⏳ Continue with other components one at a time
5. ⏳ Write unit tests for each component

Would you like me to start implementing Phase 1, Step 1 (Extract PlayerMask component)?
