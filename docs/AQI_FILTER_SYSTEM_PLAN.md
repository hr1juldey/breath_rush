# AQI & Air Quality System - Complete Implementation Plan

## Executive Summary

A strategic air quality management system where the player must travel a set distance while managing AQI using:
- **3 Air Filters** (manual drop with 'D' key, temporary 60s, strong r^-2 effect)
- **Sapling Pickups** (increase tree spawn probability)
- **Trees** (spawned via FrontLayerSpawner, permanent, weak r^-1 effect)
- **3 EV Chargers** (limited to 3 total in entire game)

---

## Current Codebase Analysis

### Existing Components We Will Integrate With

| Component | File | Current Function | Integration Point |
|-----------|------|------------------|-------------------|
| Player | `scripts/Player.gd` | Coordinator for player components | Add AQI signals, filter inventory |
| PlayerInventory | `scripts/components/player/PlayerInventory.gd` | Already handles filter/sapling pickup & drop! | Modify to support 3 filters |
| Pickup | `scripts/Pickup.gd` | Handles mask/filter/sapling pickups | Add sapling spawn boost |
| PickupSpawner | `scripts/components/spawner/PickupSpawner.gd` | Spawns pickups, EV chargers | Limit EV chargers to 3 |
| ObstacleSpawner | `scripts/components/spawner/ObstacleSpawner.gd` | Spawns cars | Add CarAQISource auto-registration |
| FrontLayerSpawner | `scripts/components/parallax/FrontLayerSpawner.gd` | Spawns trees (tree_1, tree_2, tree_3) | Add TreeAQISource, probability boost |
| SkyController | `scripts/SkyController.gd` | Sky transitions based on AQI | Already works! No changes needed |
| SmogController | `scripts/SmogController.gd` | Smog opacity based on AQI | Already works! No changes needed |
| Game | `scripts/Game.gd` | Main game coordinator | Add AQIManager, distance tracking |
| HUD | `scripts/HUD.gd` + `scenes/HUD.tscn` | UI display | Add distance bar, filter markers |

### Key Discovery: PlayerInventory Already Supports Filter/Sapling!

```gdscript
# From PlayerInventory.gd - already exists!
signal purifier_deployed(x: float, y: float)
signal sapling_planted(x: float, y: float)

func pickup_filter() -> bool:
func pickup_sapling() -> bool:
func drop_item() -> bool:  # Emits purifier_deployed or sapling_planted
```

**Action**: Modify to support 3 filters instead of single item.

---

## Architecture Overview

### Modular AQI Source System

```
scripts/aqi/
├── AQISource.gd           # Base class for all AQI-affecting entities
├── AQIManager.gd          # Singleton - central AQI calculation & tracking
├── CarAQISource.gd        # Attached to cars (increases AQI)
├── TreeAQISource.gd       # Attached to trees (decreases AQI, r^-1)
├── FilterAQISource.gd     # Dropped filters (decreases AQI, r^-2, 60s lifespan)
└── TreeSpawnManager.gd    # Manages tree spawn probabilities based on saplings
```

### Integration Flow

```
Game.gd
   │
   ├── AQIManager (new autoload)
   │      │
   │      ├── Receives distance updates from Game.gd
   │      ├── Calculates AQI from all registered sources
   │      └── Emits aqi_changed signal
   │
   ├── ObstacleSpawner
   │      └── Cars auto-register CarAQISource on spawn
   │
   ├── FrontLayerSpawner
   │      └── Trees auto-register TreeAQISource on spawn
   │
   ├── Player → PlayerInventory
   │      └── Drop filter → creates FilterAQISource
   │
   └── HUD
          └── Listens to aqi_changed, displays distance bar
```

---

## Detailed Module Specifications

### 1. AQISource.gd (Base Class)

```gdscript
# scripts/aqi/AQISource.gd
class_name AQISource
extends Node

enum SourceType { INCREASES_AQI, DECREASES_AQI }
enum RangeType { NONE, LINEAR, INVERSE, INVERSE_SQUARE }

@export var source_type: SourceType = SourceType.DECREASES_AQI
@export var range_type: RangeType = RangeType.NONE
@export var base_effect: float = 1.0
@export var effective_range: float = 1000.0

var spawn_distance: float = 0.0  # Distance when this source was created
var is_active: bool = true

func _ready():
    # Auto-register with AQIManager
    var aqi_manager = _get_aqi_manager()
    if aqi_manager:
        spawn_distance = aqi_manager.distance_traveled
        aqi_manager.register_source(self)

func _exit_tree():
    var aqi_manager = _get_aqi_manager()
    if aqi_manager:
        aqi_manager.unregister_source(self)

func _get_aqi_manager() -> Node:
    # Try autoload first
    if Engine.has_singleton("AQIManager"):
        return Engine.get_singleton("AQIManager")
    # Fallback to group
    var managers = get_tree().get_nodes_in_group("aqi_manager")
    return managers[0] if managers.size() > 0 else null

func calculate_effect(player_distance: float, delta: float) -> float:
    """Calculate AQI change contribution for this frame"""
    if not is_active:
        return 0.0

    var distance_from_source = abs(player_distance - spawn_distance)
    var range_multiplier = _get_range_multiplier(distance_from_source)
    var effect = base_effect * range_multiplier * delta

    # Return positive for decrease, negative for increase
    return effect if source_type == SourceType.DECREASES_AQI else -effect

func _get_range_multiplier(distance: float) -> float:
    match range_type:
        RangeType.NONE:
            return 1.0
        RangeType.LINEAR:
            return max(0.0, 1.0 - (distance / effective_range))
        RangeType.INVERSE:  # r^-1 for trees
            var d = max(distance / 100.0, 0.1)
            return 1.0 / d
        RangeType.INVERSE_SQUARE:  # r^-2 for filters
            var d = max(distance / 100.0, 0.1)
            return 1.0 / (d * d)
    return 1.0
```

---

### 2. AQIManager.gd (Singleton)

```gdscript
# scripts/aqi/AQIManager.gd
extends Node

signal aqi_changed(new_aqi: float, delta_aqi: float)
signal distance_changed(new_distance: float, progress: float)
signal filter_dropped(filter: AQISource, drop_progress: float)
signal filter_expired(filter: AQISource)
signal tree_spawned(tree: AQISource, spawn_progress: float)
signal game_won()
signal game_lost(reason: String)

# === Configuration ===
@export var starting_aqi: float = 100.0
@export var min_aqi: float = 15.0
@export var max_aqi: float = 500.0
@export var natural_decay_percent: float = 1.0  # % per minute
@export var total_distance: float = 5000.0      # Goal distance
@export var win_aqi_threshold: float = 150.0    # Max AQI for win

# === State ===
var current_aqi: float = 100.0
var distance_traveled: float = 0.0
var is_paused: bool = false

# === Sources ===
var aqi_sources: Array = []  # All registered AQISource nodes
var dropped_filters: Array = []  # FilterAQISource references

# === Filter Tracking ===
var filters_remaining: int = 3
var filters_dropped: int = 0

# === EV Charger Tracking ===
var ev_chargers_spawned: int = 0
var ev_chargers_max: int = 3

func _ready():
    add_to_group("aqi_manager")
    current_aqi = starting_aqi
    print("[AQIManager] Initialized - Starting AQI: %.1f, Goal: %.0fm" % [current_aqi, total_distance])

func _process(delta: float):
    if is_paused:
        return

    var aqi_delta = 0.0

    # Natural decay (1% per minute)
    aqi_delta -= current_aqi * (natural_decay_percent / 100.0) * (delta / 60.0)

    # Sum all source contributions
    for source in aqi_sources:
        if source and is_instance_valid(source) and source.is_active:
            aqi_delta += source.calculate_effect(distance_traveled, delta)

    # Apply changes
    var old_aqi = current_aqi
    current_aqi = clamp(current_aqi + aqi_delta, min_aqi, max_aqi)

    if abs(current_aqi - old_aqi) > 0.01:
        aqi_changed.emit(current_aqi, current_aqi - old_aqi)

    # Check lose condition (AQI too high)
    if current_aqi >= max_aqi:
        game_lost.emit("AQI reached critical level!")

func register_source(source: AQISource):
    if source not in aqi_sources:
        aqi_sources.append(source)
        print("[AQIManager] Registered source: %s (total: %d)" % [source.name, aqi_sources.size()])

func unregister_source(source: AQISource):
    aqi_sources.erase(source)

func update_distance(delta_distance: float):
    """Called by Game.gd each frame"""
    distance_traveled += delta_distance
    var progress = distance_traveled / total_distance
    distance_changed.emit(distance_traveled, progress)

    # Check win condition
    if distance_traveled >= total_distance:
        _check_win_condition()

func _check_win_condition():
    # Must have dropped all 3 filters
    if filters_dropped < 3:
        game_lost.emit("Did not deploy all 3 filters!")
        return

    # All filters must still be active
    var active_filters = 0
    for filter in dropped_filters:
        if filter and is_instance_valid(filter) and filter.is_active:
            active_filters += 1

    if active_filters < 3:
        game_lost.emit("Filters expired before reaching goal!")
        return

    # AQI must be below threshold
    if current_aqi > win_aqi_threshold:
        game_lost.emit("AQI too high at finish!")
        return

    game_won.emit()

# === Filter Management ===

func can_drop_filter() -> bool:
    return filters_remaining > 0

func drop_filter() -> AQISource:
    """Create and register a new filter at current position"""
    if filters_remaining <= 0:
        return null

    filters_remaining -= 1
    filters_dropped += 1

    var filter = load("res://scripts/aqi/FilterAQISource.gd").new()
    filter.name = "Filter_%d" % filters_dropped
    add_child(filter)
    dropped_filters.append(filter)

    var progress = distance_traveled / total_distance
    filter_dropped.emit(filter, progress)

    # Connect expiry signal
    filter.filter_expired.connect(func(): filter_expired.emit(filter))

    print("[AQIManager] Filter dropped! Remaining: %d" % filters_remaining)
    return filter

func get_filters_remaining() -> int:
    return filters_remaining

func get_active_filter_count() -> int:
    var count = 0
    for filter in dropped_filters:
        if filter and is_instance_valid(filter) and filter.is_active:
            count += 1
    return count

# === EV Charger Management ===

func can_spawn_ev_charger() -> bool:
    return ev_chargers_spawned < ev_chargers_max

func record_ev_charger_spawn():
    ev_chargers_spawned += 1
    print("[AQIManager] EV Charger spawned (%d/%d)" % [ev_chargers_spawned, ev_chargers_max])

func get_ev_chargers_remaining() -> int:
    return ev_chargers_max - ev_chargers_spawned

# === Pause Control ===

func pause():
    is_paused = true

func resume():
    is_paused = false
```

---

### 3. CarAQISource.gd

```gdscript
# scripts/aqi/CarAQISource.gd
class_name CarAQISource
extends AQISource

## Attached to obstacle cars - increases AQI while in range

func _init():
    source_type = SourceType.INCREASES_AQI
    range_type = RangeType.LINEAR
    base_effect = 5.0  # 5% per minute base
    effective_range = 800.0  # Effect radius
```

**Integration**: Add to `ObstacleSpawner._spawn_at()`:
```gdscript
# After configuring obstacle
var car_aqi = CarAQISource.new()
obstacle.add_child(car_aqi)
```

---

### 4. TreeAQISource.gd

```gdscript
# scripts/aqi/TreeAQISource.gd
class_name TreeAQISource
extends AQISource

## Attached to spawned trees - decreases AQI with r^-1 falloff

@export var tree_type: int = 1  # 1, 2, or 3

const TREE_MULTIPLIERS = {
    1: 1.0,   # tree_1 - basic
    2: 1.5,   # tree_2 - medium
    3: 2.0    # tree_3 - large
}

func _init():
    source_type = SourceType.DECREASES_AQI
    range_type = RangeType.INVERSE
    effective_range = 5000.0

func _ready():
    # Apply tree type multiplier
    base_effect = 2.5 * TREE_MULTIPLIERS.get(tree_type, 1.0)
    super._ready()
```

**Integration**: Add to `FrontLayerSpawner._spawn_element()`:
```gdscript
# After creating sprite for tree_1, tree_2, or tree_3
if texture_path.contains("tree_"):
    var tree_aqi = TreeAQISource.new()
    tree_aqi.tree_type = _get_tree_type_from_path(texture_path)
    sprite.add_child(tree_aqi)
```

---

### 5. FilterAQISource.gd

```gdscript
# scripts/aqi/FilterAQISource.gd
class_name FilterAQISource
extends AQISource

signal filter_expired()

@export var lifespan: float = 60.0  # 60 seconds

var time_alive: float = 0.0

func _init():
    source_type = SourceType.DECREASES_AQI
    range_type = RangeType.INVERSE_SQUARE
    base_effect = 50.0  # Strong effect
    effective_range = 3000.0

func _process(delta: float):
    if not is_active:
        return

    time_alive += delta

    if time_alive >= lifespan:
        is_active = false
        filter_expired.emit()
        print("[FilterAQISource] Filter expired after %.1fs" % lifespan)

func get_remaining_time() -> float:
    return max(0.0, lifespan - time_alive)

func get_lifespan_progress() -> float:
    return time_alive / lifespan
```

---

### 6. TreeSpawnManager.gd

```gdscript
# scripts/aqi/TreeSpawnManager.gd
class_name TreeSpawnManager
extends Node

signal sapling_collected(total: int)
signal spawn_probability_changed(probs: Dictionary)

var saplings_collected: int = 0

# Base probabilities (per spawn attempt in FrontLayerSpawner)
@export var base_tree1_chance: float = 0.15  # 15% tree_1
@export var base_tree2_chance: float = 0.08  # 8% tree_2
@export var base_tree3_chance: float = 0.04  # 4% tree_3

# Boost per sapling collected
@export var sapling_boost: float = 0.03  # +3% per sapling

func _ready():
    add_to_group("tree_spawn_manager")

func collect_sapling():
    saplings_collected += 1
    sapling_collected.emit(saplings_collected)
    spawn_probability_changed.emit(get_spawn_probabilities())
    print("[TreeSpawnManager] Sapling collected! Total: %d" % saplings_collected)

func get_spawn_probabilities() -> Dictionary:
    var boost = saplings_collected * sapling_boost
    return {
        "tree_1": min(base_tree1_chance + boost, 0.50),
        "tree_2": min(base_tree2_chance + boost * 0.75, 0.35),
        "tree_3": min(base_tree3_chance + boost * 0.5, 0.25)
    }

func should_spawn_tree_type() -> String:
    """Called by FrontLayerSpawner to determine what to spawn"""
    var probs = get_spawn_probabilities()
    var roll = randf()

    var cumulative = 0.0
    for tree_type in ["tree_3", "tree_2", "tree_1"]:  # Best first
        cumulative += probs[tree_type]
        if roll < cumulative:
            return tree_type

    return ""  # No tree (spawn other element)

func get_saplings_collected() -> int:
    return saplings_collected
```

---

## File Modifications Required

### 1. Game.gd Changes

```gdscript
# Add to _ready():
add_to_group("game")

# Add AQIManager reference
@onready var aqi_manager = $AQIManager  # Or get from autoload

# Modify _process():
func _process(delta):
    if world_paused:
        return

    # Update distance in AQIManager
    var distance_delta = scroll_speed * delta
    if aqi_manager:
        aqi_manager.update_distance(distance_delta)
        current_aqi = aqi_manager.current_aqi

    # Rest of existing code...
```

### 2. PlayerInventory.gd Changes

```gdscript
# Change from single item to filter count
var filter_count: int = 3  # Start with 3 filters
var sapling_count: int = 0

func drop_filter() -> bool:
    if filter_count <= 0:
        return false

    var aqi_manager = _get_aqi_manager()
    if aqi_manager:
        aqi_manager.drop_filter()

    filter_count -= 1
    var pos = player_ref.global_position if player_ref else Vector2.ZERO
    purifier_deployed.emit(pos.x, pos.y)
    return true

func pickup_sapling() -> bool:
    sapling_count += 1
    var tree_manager = _get_tree_spawn_manager()
    if tree_manager:
        tree_manager.collect_sapling()
    item_picked_up.emit("sapling")
    return true
```

### 3. PickupSpawner.gd Changes

```gdscript
# Modify should_spawn_ev_charger():
func should_spawn_ev_charger() -> bool:
    # Check with AQIManager for charger limit
    var aqi_manager = _get_aqi_manager()
    if aqi_manager and not aqi_manager.can_spawn_ev_charger():
        return false

    # Existing battery check...
    if ev_charger_active and is_instance_valid(ev_charger_active):
        return false

    # ... rest of existing code

# Modify spawn_ev_charger():
func spawn_ev_charger() -> void:
    var aqi_manager = _get_aqi_manager()
    if aqi_manager:
        aqi_manager.record_ev_charger_spawn()

    # ... rest of existing code
```

### 4. FrontLayerSpawner.gd Changes

```gdscript
# Modify texture selection to use TreeSpawnManager
func _select_texture_config() -> Dictionary:
    var tree_manager = _get_tree_spawn_manager()
    if tree_manager:
        var tree_type = tree_manager.should_spawn_tree_type()
        if tree_type != "":
            return _get_config_for_tree(tree_type)

    # Fall back to random selection
    return texture_configs[randi() % texture_configs.size()]

# After spawning tree, attach TreeAQISource
func _spawn_element():
    # ... existing spawn code ...

    # If spawned a tree, attach AQI source
    if config.texture.resource_path.contains("tree_"):
        var tree_aqi = TreeAQISource.new()
        tree_aqi.tree_type = _get_tree_type(config.texture.resource_path)
        sprite.add_child(tree_aqi)
```

---

## HUD Updates

### New UI Elements in HUD.tscn

```
HUD (CanvasLayer)
├── ... existing nodes ...
│
├── BottomCenter (Control)
│   └── DistanceContainer (HBoxContainer)
│       ├── DistanceBar (ProgressBar)  # Main progress bar
│       ├── FilterMarkers (Control)    # Overlay for filter positions
│       └── TreeMarkers (Control)      # Overlay for tree positions
│
└── BottomRight (VBoxContainer)
    ├── ... existing AQI, Masks, Coins ...
    ├── FilterCount (Label)            # "Filters: 2/3"
    ├── SaplingCount (Label)           # "Saplings: 5"
    └── ChargerCount (Label)           # "Chargers: 1/3"
```

### HUD.gd Additions

```gdscript
# New references
@onready var distance_bar = $BottomCenter/DistanceContainer/DistanceBar
@onready var filter_markers = $BottomCenter/DistanceContainer/FilterMarkers
@onready var filter_count_label = $BottomRight/FilterCount
@onready var sapling_count_label = $BottomRight/SaplingCount
@onready var charger_count_label = $BottomRight/ChargerCount

var filter_marker_scene = preload("res://scenes/ui/FilterMarker.tscn")

func _ready():
    # ... existing code ...

    # Connect to AQIManager signals
    var aqi_manager = _get_aqi_manager()
    if aqi_manager:
        aqi_manager.distance_changed.connect(_on_distance_changed)
        aqi_manager.filter_dropped.connect(_on_filter_dropped)
        aqi_manager.filter_expired.connect(_on_filter_expired)

func _on_distance_changed(distance: float, progress: float):
    if distance_bar:
        distance_bar.value = progress * 100

func _on_filter_dropped(filter: AQISource, drop_progress: float):
    # Create marker on progress bar
    var marker = filter_marker_scene.instantiate()
    marker.position.x = distance_bar.size.x * drop_progress
    marker.filter_ref = filter
    filter_markers.add_child(marker)

    # Update filter count
    _update_filter_count()

func _on_filter_expired(filter: AQISource):
    # Find and fade out marker
    for marker in filter_markers.get_children():
        if marker.filter_ref == filter:
            marker.fade_out()
            break

func _update_filter_count():
    var aqi_manager = _get_aqi_manager()
    if aqi_manager and filter_count_label:
        var remaining = aqi_manager.get_filters_remaining()
        var active = aqi_manager.get_active_filter_count()
        filter_count_label.text = "Filters: %d/%d (Active: %d)" % [remaining, 3, active]
```

---

## AQI Math Summary

### Per-Frame Calculation
```
Natural Decay:   -1% of current AQI per minute
Car Effect:      +5% base * LINEAR(distance) per minute per car
Tree Effect:     -2.5% base * tree_multiplier * (1/distance) per minute per tree
Filter Effect:   -50 base * (1/distance^2) per minute per filter (60s lifespan)
```

### Range Comparison Table

| Distance | Filter (r^-2) | Tree (r^-1) |
|----------|---------------|-------------|
| 100m | 100% | 100% |
| 200m | 25% | 50% |
| 400m | 6.25% | 25% |
| 800m | 1.56% | 12.5% |
| 1600m | 0.39% | 6.25% |

---

## Implementation Phases

### Phase 1: Core AQI System
1. Create `scripts/aqi/` directory
2. Implement `AQISource.gd`
3. Implement `AQIManager.gd`
4. Add AQIManager to Main.tscn
5. Connect Game.gd to AQIManager

### Phase 2: Car Integration
1. Create `CarAQISource.gd`
2. Modify `ObstacleSpawner.gd` to attach CarAQISource
3. Test AQI increases when cars pass

### Phase 3: Tree System
1. Create `TreeAQISource.gd`
2. Create `TreeSpawnManager.gd`
3. Modify `FrontLayerSpawner.gd` for probability system
4. Modify `Pickup.gd` for sapling collection
5. Test tree spawning and AQI reduction

### Phase 4: Filter System
1. Create `FilterAQISource.gd`
2. Modify `PlayerInventory.gd` for 3 filters
3. Connect filter drop to AQIManager
4. Test filter activation and expiry

### Phase 5: HUD & Distance
1. Add distance bar to HUD.tscn
2. Create FilterMarker.tscn scene
3. Implement marker positioning
4. Add filter/sapling/charger counts

### Phase 6: EV Charger Limit
1. Modify `PickupSpawner.gd` to check limit
2. Add charger count to HUD

### Phase 7: Win/Lose Conditions
1. Implement win condition in AQIManager
2. Implement lose conditions
3. Create end game UI

---

## Testing Checklist

- [ ] AQIManager initializes correctly
- [ ] Natural decay works (1% per minute)
- [ ] Cars register and increase AQI
- [ ] Trees register and decrease AQI with r^-1
- [ ] Saplings increase tree spawn probability
- [ ] Filters can be dropped (3 total)
- [ ] Filters decrease AQI with r^-2
- [ ] Filters expire after 60 seconds
- [ ] Distance bar updates correctly
- [ ] Filter markers appear and fade
- [ ] Only 3 EV chargers spawn
- [ ] Win condition triggers correctly
- [ ] Lose conditions trigger correctly
- [ ] Sky transitions still work
- [ ] Smog opacity still works
