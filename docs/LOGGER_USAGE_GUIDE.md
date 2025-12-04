# Logger System Usage Guide

## Overview
The Logger system provides comprehensive debugging capabilities for Breath Rush game. It tracks player state, spawning, collisions, HUD updates, and performance metrics.

## Configuration

### Enable/Disable Categories
Edit `config/debug.json`:

```json
{
  "log_level": 1,
  "log_to_file": true,
  "performance_log_interval_ms": 1000,
  "categories": {
    "PLAYER": true,      // Player movement, health
    "HUD": true,         // UI updates
    "SPAWNER": true,     // Object spawning/pooling
    "COLLISION": true,   // Collision events
    "WORLD": true,       // World scrolling
    "SKY": true,         // Sky transitions
    "AUDIO": false,      // Audio events
    "INPUT": false,      // Input processing
    "PERSISTENCE": true, // Save/load
    "PERFORMANCE": true  // FPS, memory
  }
}
```

**Log Levels:**
- 0 = DEBUG (verbose, every frame)
- 1 = INFO (important events)
- 2 = WARNING (potential issues)
- 3 = ERROR (critical errors only)

## Usage in Scripts

### Basic Logging

```gdscript
# In any script, use the Logger singleton
func _ready():
    Logger.info(Logger.Category.PLAYER, "Player spawned at position: %v" % position)
```

### Category-Specific Convenience Methods

```gdscript
# Player events
Logger.player("Health changed: %.1f" % health)

# HUD updates
Logger.hud("Health bar updated to %.1f" % value)

# Spawner events
Logger.spawner("Spawned obstacle at (%.1f, %.1f)" % [pos.x, pos.y])

# Collision events
Logger.collision("Player hit obstacle [DMG: %.1f]" % damage)

# Sky transitions
Logger.sky("Sky transitioning from %s to %s" % [old_type, new_type])
```

### Log Levels

```gdscript
# Debug (only shows if log_level = 0 in config)
Logger.debug(Logger.Category.PLAYER, "Frame-by-frame position update")

# Info (default level)
Logger.info(Logger.Category.PLAYER, "Player changed lane to %d" % lane)

# Warning
Logger.warning(Logger.Category.SPAWNER, "Pool exhausted, creating new obstacle")

# Error
Logger.error(Logger.Category.COLLISION, "Invalid collision shape detected")
```

### Object State Logging

Track position, size, z-index automatically:

```gdscript
# Log any Node2D's state
Logger.log_object_state(Logger.Category.SPAWNER, obstacle_node, "Obstacle")

# Output example:
# [00:01.234] [DEBUG] [SPAWNER] Obstacle | Pos:(450.0, 300.0) Z:0 Size:64x48 VISIBLE
```

### Spawn/Despawn Events

```gdscript
# When spawning an object
Logger.log_spawn(obstacle_node, "Car", false)  // false = newly spawned
Logger.log_spawn(pickup_node, "Mask", true)    // true = recycled from pool

# When despawning
Logger.log_despawn(obstacle_node, "Car", "off-screen")
```

### Collision Logging

```gdscript
# Automatic collision logging with damage
Logger.log_collision(player_node, obstacle_node, 15.0)

# Output:
# [00:05.678] [INFO] [COLLISION] COLLISION: Player <-> Obstacle [DMG: 15.0]
```

### Performance Metrics

Performance is logged automatically every 1 second (configurable):

```
[00:10.000] [INFO] [PERFORMANCE] FPS:60 | Process:2.45ms Physics:1.23ms | Mem:45.2MB (Peak:48.1MB) | Objs:234 Nodes:67
```

### Object Tracking

Track objects over time to monitor their lifecycle:

```gdscript
# Start tracking
Logger.track_object(obstacle_node, "Car")

# ... object exists and moves ...

# Stop tracking (logs lifetime)
Logger.untrack_object(obstacle_node)

# Log all tracked objects at once
Logger.log_all_tracked_objects(Logger.Category.SPAWNER)
```

## Log File

Logs are saved to: `user://debug_log.txt`

**Linux location:** `~/.local/share/godot/app_userdata/BreathRush/debug_log.txt`

### Save Snapshot

Create a timestamped copy of current log:

```gdscript
Logger.save_log_snapshot()
// Saves to: user://debug_log_2025-12-04T15-30-45.txt
```

## Example Integration

### Player.gd

```gdscript
extends CharacterBody2D

func _ready():
    Logger.info(Logger.Category.PLAYER, "Player initialized at lane %d" % current_lane)
    Logger.log_object_state(Logger.Category.PLAYER, self, "Player")

func _process(delta):
    # Periodic logging (every second)
    if Engine.get_frames_drawn() % 60 == 0:
        Logger.debug(Logger.Category.PLAYER,
            "Pos:(%.1f,%.1f) Lane:%d HP:%.1f Bat:%.1f" %
            [global_position.x, global_position.y, current_lane, health, battery])

func change_lane(direction):
    var old_lane = current_lane
    current_lane = clamp(current_lane + direction, 0, lane_positions.size() - 1)
    target_y = lane_positions[current_lane]

    Logger.info(Logger.Category.PLAYER,
        "Lane changed: %d -> %d (Target Y: %.1f)" % [old_lane, current_lane, target_y])

func apply_mask():
    health = min(health + mask_hp_restore, max_health)
    mask_time = mask_duration
    Logger.info(Logger.Category.PLAYER,
        "Mask ACTIVATED | Duration: %.1fs | HP restored: +%d" % [mask_duration, mask_hp_restore])
```

### Spawner.gd

```gdscript
extends Node2D

func spawn_obstacle(spawn_point: Dictionary):
    var obstacle = obstacle_pool.get_or_create()
    obstacle.global_position = Vector2(spawn_point.x, spawn_point.y)

    Logger.log_spawn(obstacle, spawn_point.type, obstacle_pool.was_recycled())
    Logger.track_object(obstacle, spawn_point.type)

func recycle_obstacle(obstacle: Node2D):
    Logger.log_despawn(obstacle, "Obstacle", "off-screen")
    Logger.untrack_object(obstacle)
    obstacle_pool.return(obstacle)
```

### HUD.gd

```gdscript
extends CanvasLayer

func _on_health_changed(new_health: float):
    if health_bar:
        health_bar.value = new_health
        Logger.hud("Health bar updated: %.1f/%.1f" % [new_health, health_bar.max_value])

func _ready():
    Logger.info(Logger.Category.HUD, "HUD initialized")
    Logger.log_object_state(Logger.Category.HUD, health_bar, "HealthBar")
    Logger.log_object_state(Logger.Category.HUD, battery_bar, "BatteryBar")
```

### Game.gd

```gdscript
extends Node2D

func spawn_chunk(chunk_index: int):
    var chunk = chunks_data[chunk_index]
    Logger.world("Spawning chunk %d: %s" % [chunk_index, chunk.get("id", "unknown")])

    if sky_manager:
        var sky_type = chunk.get("sky_type", "bad")
        Logger.sky("Sky transition requested: %s" % sky_type)
        sky_manager.set_sky_type(sky_type)
```

## Runtime Controls

### Toggle Categories Dynamically

```gdscript
# Disable player logging temporarily
Logger.set_category_enabled(Logger.Category.PLAYER, false)

# Re-enable
Logger.set_category_enabled(Logger.Category.PLAYER, true)

# Disable all logging
Logger.set_all_categories_enabled(false)

# Re-enable all
Logger.set_all_categories_enabled(true)
```

## Reading Logs

### In-Game Console
Logs appear in Godot's Output panel when running with F5.

### Log File
View the log file during gameplay:

```bash
tail -f ~/.local/share/godot/app_userdata/BreathRush/debug_log.txt
```

### Analyzing Logs

**Find player position over time:**
```bash
grep "PLAYER.*Pos:" debug_log.txt
```

**Find all spawns:**
```bash
grep "SPAWNED\|RECYCLED" debug_log.txt
```

**Find performance issues:**
```bash
grep "PERFORMANCE.*FPS:[0-5][0-9]" debug_log.txt  # FPS < 60
```

**Find collisions:**
```bash
grep "COLLISION" debug_log.txt
```

## Expected Log Output Example

```
[00:00.000] [INFO] [PERFORMANCE] === GAME SESSION START ===
[00:00.001] [INFO] [PERFORMANCE] Godot Version: v4.5.1.stable
[00:00.002] [INFO] [PERFORMANCE] Platform: Linux
[00:00.003] [INFO] [PERFORMANCE] Screen Size: (960, 540)
[00:00.050] [INFO] [PLAYER] Player initialized at lane 1
[00:00.051] [DEBUG] [PLAYER] Player | Pos:(180.0, 300.0) Z:0 Size:38x38 VISIBLE
[00:00.052] [INFO] [HUD] HUD initialized
[00:00.053] [DEBUG] [HUD] HealthBar | Pos:(50.0, 30.0) Z:0 Size:200x25 VISIBLE
[00:00.500] [INFO] [SPAWNER] SPAWNED Car at (960.0, 300.0) z:0
[00:01.000] [DEBUG] [PLAYER] Pos:(180.0,300.0) Lane:1 HP:100.0 Bat:100.0
[00:01.000] [INFO] [PERFORMANCE] FPS:60 | Process:2.45ms Physics:1.23ms | Mem:45.2MB (Peak:45.2MB) | Objs:234 Nodes:67
[00:02.000] [DEBUG] [PLAYER] Pos:(180.0,300.0) Lane:1 HP:95.8 Bat:100.0
[00:02.500] [INFO] [PLAYER] Lane changed: 1 -> 0 (Target Y: 240.0)
[00:03.000] [DEBUG] [PLAYER] Pos:(180.0,270.0) Lane:0 HP:91.6 Bat:100.0
[00:04.200] [INFO] [COLLISION] COLLISION: Player <-> Car [DMG: 15.0]
[00:04.201] [INFO] [PLAYER] Health after collision: 76.6
[00:05.000] [INFO] [PLAYER] Mask ACTIVATED | Duration: 15.0s | HP restored: +10
[00:06.000] [DEBUG] [PLAYER] Pos:(180.0,240.0) Lane:0 HP:86.6 Bat:100.0
[00:10.000] [INFO] [SKY] Sky transition requested: clear
[00:10.001] [INFO] [SKY] Crossfading from bad to clear (duration: 2.0s)
```

## Benefits

1. **No Screenshots Needed** - All game state logged to file
2. **Real-time Debugging** - tail -f the log file while playing
3. **Performance Tracking** - FPS, memory, frame time logged automatically
4. **Spawn Tracking** - See exactly when/where objects appear
5. **Collision Detection** - Every collision logged with damage
6. **Position Debugging** - Track player Y-drift issues
7. **Modular** - Enable only categories you need
8. **Zero Performance Impact** - Disabled categories don't execute

## Troubleshooting

### No Logs Appearing

1. Check `config/debug.json` exists
2. Verify category is enabled in config
3. Check log_level (0=DEBUG, 1=INFO, etc.)
4. Ensure Logger autoload is registered in `project.godot`

### Log File Not Creating

1. Check `log_to_file: true` in config
2. Verify file permissions on user:// directory
3. Check Godot console for "Failed to open log file" errors

### Too Much Logging

1. Increase `log_level` to 2 (WARNING) or 3 (ERROR)
2. Disable verbose categories (PLAYER, SPAWNER)
3. Increase `performance_log_interval_ms` to 5000 (5 seconds)

## Advanced Usage

### Custom Log Formatters

You can extend the Logger class to add custom formatting:

```gdscript
# In your own script
class_name GameLogger
extends Logger

func log_player_full_state(player: Node2D):
    var state_str = "=== PLAYER STATE ===" + \
        "\nPosition: %v" % player.global_position + \
        "\nHealth: %.1f/%d" % [player.health, player.max_health] + \
        "\nBattery: %.1f/%d" % [player.battery, player.max_battery] + \
        "\nLane: %d" % player.current_lane + \
        "\nCarrying: %s" % str(player.carried_item)
    info(Category.PLAYER, state_str)
```

---

**Next Steps:**
1. Add Logger calls to all key game scripts
2. Test with different log levels
3. Analyze logs to fix player Y-drift and health drain issues
4. Use tail -f to monitor real-time gameplay
