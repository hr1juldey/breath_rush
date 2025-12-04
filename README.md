# Breath Rush — Environmental Action Runner

A mobile-first infinite runner built with **Godot 4.5.1** and **GDScript**, where players dodge pollution, deliver air purifiers, and plant trees to improve local air quality while earning AIR Coins.

## Project Structure

```
breath_rush/
├── assets/                 # Game sprites (WebP format)
│   ├── skies/             # Sky textures
│   ├── road/              # Road tiles
│   ├── player/            # Player sprite
│   ├── vehicles/          # Obstacle sprites
│   ├── pickups/           # Mask, filter, sapling pickups
│   ├── parallax/          # Building and decoration sprites
│   └── ui/                # UI elements
├── scenes/                # Godot scene files (.tscn)
│   ├── Main.tscn          # Main game scene
│   ├── Player.tscn        # Player entity
│   ├── Obstacle.tscn      # Obstacle/vehicle
│   ├── Mask.tscn          # Mask pickup
│   ├── Purifier.tscn      # Filter pickup
│   ├── Sapling.tscn       # Sapling pickup
│   └── HUD.tscn           # UI/HUD layer
├── scripts/               # GDScript files
│   ├── Game.gd            # Main game orchestrator
│   ├── Player.gd          # Player logic and mechanics
│   ├── SkyManager.gd      # Sky transitions
│   ├── RoadScroll.gd      # Road tile recycling
│   ├── Spawner.gd         # Object pooling and spawning
│   ├── Pickup.gd          # Pickup interactions
│   ├── DeliveryZone.gd    # Delivery zone logic
│   ├── Obstacle.gd        # Obstacle behavior
│   ├── HUD.gd             # UI updates and display
│   └── Persistence.gd     # Save/load system
├── data/
│   └── chunks/            # Level chunk definitions
│       └── chunk_001.json # Sample chunk
├── config/                # Configuration files
│   ├── brand.json         # Branding customization
│   └── gameplay.json      # Tuning parameters
├── docs/                  # Documentation
│   ├── GDD.md             # Full technical design document
│   ├── Instruction.md     # Build instructions
│   └── IMPLEMENTATION_LOG.md # Change tracking
├── project.godot          # Godot project configuration
└── README.md              # This file
```

## Quick Start

### Prerequisites

- **Godot 4.5.1** ([Download](https://godotengine.org/download))
- **VS Code** with GDScript extension (optional, for code editing)

### Opening the Project

1. **Clone/download** this repository
2. **Open Godot** and select "Import" → point to this folder
3. **Godot** will load `project.godot` automatically
4. Open the project — it should load `scenes/Main.tscn` as the main scene

### Running the Game

1. **In Godot Editor**, press **F5** (or click Play ▶)
2. The game will launch in the editor viewport
3. **Controls:**
   - **Mobile:** Tap left half for lanes, right half for boost/drop
   - **Desktop:** Arrow keys (lane), Space (boost), D (drop)

## Configuration

### Gameplay Tuning (`config/gameplay.json`)

Edit these values to tune gameplay:

```json
{
  "health": {
    "max_hp": 100,
    "base_drain_multiplier": 0.01666
  },
  "mask": {
    "duration": 15.0,
    "hp_restore": 10
  },
  "filter": {
    "duration": 30.0,
    "cost": 50
  },
  "coins": {
    "base_rate": 0.02
  }
}
```

### Branding (`config/brand.json`)

Customize assets and colors:

```json
{
  "brand": "lilypad",
  "mask_sprite": "res://assets/pickups/mask.webp",
  "ui_tint": [0.1, 0.6, 0.9]
}
```

## Workflow

### Code-First Development

1. **Edit scripts** in VS Code
   - All `.gd` files are plain text
   - GDScript extension provides IntelliSense
2. **Edit scenes** as text (`.tscn` files)
   - Open in VS Code or Godot editor
3. **Test in Godot**
   - Press F5 to run
   - Keep console open to see errors
4. **Iterate**
   - Save files → Press F5 to reload

### Adding New Assets

1. Place WebP/PNG files in appropriate `assets/` subfolder
2. Reference in scenes via `res://assets/path/to/file.webp`
3. Godot auto-imports when editor detects new files

### Persisting Data

Save data is stored at `user://game_state.json` containing:
- Planted trees
- Total AIR coins earned
- Run statistics

## Development Notes

### Key Systems

- **Health Drain:** AQI-based, masks provide temporary relief
- **Coin Economy:** Rewards clean runs (lower AQI, deployed filters, trees)
- **Persistence:** Trees planted in one run persist across sessions and grow
- **Object Pooling:** Obstacles and pickups are reused, not freed (performance)

### Scene Tree

Main scene (`Main.tscn`) structure:

```
Main (Node2D)
├── ParallaxBG (parallax background with three sky types)
├── Road (scrolling tile manager)
├── World (dynamic obstacles, pickups, persistent trees)
├── DeliveryZones (area-based drop zones for filters)
├── Player (main character)
├── Spawner (object pool manager)
└── UI (HUD: health, battery, AQI, coins)
```

### Script Breakdown

| Script | Responsibility |
|--------|-----------------|
| `Game.gd` | Orchestrates parallax, chunks, AQI, config loading |
| `Player.gd` | Lane switching, health, mask, battery, item carrying |
| `SkyManager.gd` | Sky crossfades (bad→ok→clear) |
| `RoadScroll.gd` | Road tile recycling without seams |
| `Spawner.gd` | Object pooling; spawns from chunk JSON |
| `Pickup.gd` | Area2D interaction for masks/filters/saplings |
| `DeliveryZone.gd` | Detects filter delivery; awards coins |
| `Obstacle.gd` | Simple left-scroll + collision damage |
| `HUD.gd` | Updates health/battery/AQI/coin display |
| `Persistence.gd` | Read/write `user://game_state.json` |

## Testing Checklist

- [ ] Player lane switching is responsive (no lag)
- [ ] Mask pickup restores HP and shows timer
- [ ] Filter deployment reduces AQI visually and multiplies coins
- [ ] Trees planted are saved and persist on restart
- [ ] Road scrolls seamlessly (no visible seams)
- [ ] Sky crossfades smoothly at chunk transitions
- [ ] HUD bars update smoothly
- [ ] Battery drains while boosting; recharges at stations
- [ ] Spawner reuses pooled objects (check no GC spikes)
- [ ] HTML5 export runs on mobile browsers

## Exporting

### HTML5 (Mobile)

1. **Godot Editor** → File → Export Project
2. Select "Web"
3. Choose renderer: **GL Compatibility** (better mobile support)
4. Export to `build/` or similar
5. Upload to web server or test locally with `python3 -m http.server`

### Performance Tips

- Keep textures in WebP format (smaller)
- Use VisibilityEnabler2D for off-screen culling
- Test on low-end devices (Chrome on Android)
- Monitor memory via browser DevTools

## Troubleshooting

### Main scene won't load

- Check `project.godot` has `run/main_scene="res://scenes/Main.tscn"`
- Verify `scenes/Main.tscn` exists and is valid

### Script errors

- Check console (View → Toggle Console in Godot)
- Look for typos in script references
- Ensure all `preload()` paths in scripts are correct

### Assets not showing

- Verify asset files exist in `assets/` subfolders
- Check texture paths in `.tscn` files match actual files
- Godot should auto-import; if not, try File → Reload Current Scene

### Performance issues

- Profile with Godot's built-in profiler (Debug menu)
- Reduce spawn rate in `gameplay.json`
- Check for free() in hot loops

## Next Steps

1. **Replace placeholder assets** with actual art
2. **Implement menu system** (start screen, pause, summary)
3. **Add sound/music** (SFX for pickups, ambient)
4. **Backend integration** (leaderboard, session tracking)
5. **Mobile optimization** (touch controls fine-tuning, memory profiling)
6. **Level variety** (more chunk templates, dynamic AQI based on location)

## References

- **GDD:** See `docs/GDD.md` for full technical specifications
- **Visual Reference:** `docs/Lilypad_BreathRush.pdf`
- **Godot Docs:** [docs.godotengine.org](https://docs.godotengine.org)
- **GDScript:** [GDScript Docs](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/index.html)

## License

(Add your license here)

## Contact & Support

For issues or questions, refer to the `docs/` folder or check the implementation log (`docs/IMPLEMENTATION_LOG.md`) for recent changes.
