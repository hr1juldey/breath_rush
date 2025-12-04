## Lilypad — **Full Technical GDD** (mobile-first, Godot 4.5.1, VS Code → Godot testing workflow)

This is a full, developer-focused Game Design Document for **Lilypad — Breath Rush**. It contains all gameplay rules, data format, exact node/tree layout, file/folder naming conventions, tiling & transition strategies for repeated sprites (skies, roads), HUD rendering rules, persistence/auto-save, AIR Coin economics, backend contract, and a recommended VS Code-first workflow so you only open Godot to test & export.

> Reference animatic / design PDF (local): `file://docs/Lilypad_BreathRush.pdf`

---

## Table of contents

1. One-line pitch
2. Pillars & constraints
3. Core loop & session flow
4. Controls (mobile-first + desktop)
5. Lane + movement model
6. Mechanics: health, mask, battery, boost, items
7. AIR Coin economy & formulas
8. World & chunk system (tiling and transitions)
9. Sky types — tiling & transition approach
10. Assets naming conventions & atlas strategy
11. Folder structure (VS Code-first)
12. Godot scene tree (Main.tscn) — node-by-node details
13. Spawner, pooling, and object lifetime rules
14. HUD / UI rendering & animation rules
15. Persistence (autosave) and data schema
16. Brand / reskin JSON schema
17. Backend API contract (FastAPI)
18. Export / HTML5 performance & memory recommendations
19. Dev workflow: edit in VS Code, test in Godot (flatpak wrapper)
20. Tuning, balancing, test checklist, and delivery plan

---

## 1 — One-line pitch

Short, mobile-first, HTML5 runner where you dodge pollution, deliver purifiers & trees, and earn AIR Coins; repeated plays make the local map cleaner (trees persist and grow), creating a meaningful environmental progression loop.

---

## 2 — Pillars & constraints

* **Platform:** Godot 4.5.1 → HTML5 first (mobile browsers)
* **Audience:** 84% mobile users (mobile-first UI & controls)
* **Dev workflow:** code in VS Code; open Godot only for run / export / final adjustments
* **Performance:** target low-end phones — keep textures & memory low
* **Scope:** solo dev, prototype-quality but polished UX, brand-reskin ready

---

## 3 — Core loop & session flow

1. Player starts run → world auto-scrolls.
2. Health drains according to local AQI and collisions.
3. Player collects masks (instant) / filters (carry & deploy) / saplings (carry & plant).
4. Purifiers deployed at DeliveryZone produce immediate AQI drop (temp).
5. Trees planted permanently reduce future AQI (grow across sessions).
6. Earn AIR Coins continuously during run (function of distance × local cleanliness × filter multiplier).
7. End-of-run summary: coins, deliveries, trees planted → optional lead/phone form.

---

## 4 — Controls (mobile-first)

**Mobile (primary):**

* Left half (split vertically):

  * Top half tap → lane up
  * Bottom half tap → lane down
* Right half:

  * Tap → boost (short tap)
  * Hold → sustained boost (drains battery)
* Floating button (bottom-right) → Drop / Deploy carried item
* Optional: swipe up/down for lane change (later)

**Desktop:**

* Arrow keys: Up/Down/Left/Right for lane & micro-shifts
* Space → boost
* D → drop or deploy

---

## 5 — Lane + movement model

* 3 lanes by default (Y positions: [lane_top, lane_mid, lane_bot]) — use variables in `Player.gd`.
* Player X is largely fixed (e.g., x = 180 px). Micro-left/right movement allowed for dodging but not required.
* Lane interpolation uses `lerp` for smooth movement — no physics heavy responses (CharacterBody2D + move_and_slide for micro movement only).
* Collisions only between player collision shape and obstacle/pickup Area2D / Body nodes.

---

## 6 — Game mechanics (detailed)

### Health (HP)

* Range: 0 — 100
* **Base drain** per second:

  ```
  drain_base_sec = max(0.1, AQI_current / 60.0)
  ```

  (tweakable; baseline: ~1 HP per 10 seconds at moderate AQI)
* Collisions with polluting vehicles: `collision_damage = 8–18` (tweak)

### Mask

* Pickup effect:

  * `mask_time = 15.0` seconds
  * Instant +10 HP (capped at 100)
  * During mask_time main drain is suppressed, but last 5s leak happens: `leak = 1 HP / sec`
* UI: pulsing lung indicator; mask icon shows time countdown.

### Purifier (filter)

* Pickup: becomes `carried_item = "filter"`
* Deployment at DeliveryZone:

  * `filter_duration = 30.0` seconds
  * Immediately reduces local AQI at high rate: `filter_clean_rate = 8 AQI/sec` (area radius R)
  * Also multiplies AIR coin gain: `coin_multiplier = 2.5`
* After 30s, effect decays gradually (linear 10s).

### Tree / Sapling

* Pickup: `carried_item = "sapling"`
* Plant (drop) in safe sidewalk area or designated plant pad:

  * Creates a persistent tree object at world coordinate x. Stored to `user://game_state.json`.
  * `tree_base_clean_rate = 0.12 AQI/sec` (small)
  * Growth stages: seed → small → medium → large; each session visited increments growth stage and increases clean_rate by `+0.05` per stage (caps at ~stage 5).
  * Trees are persistent and rendered in `World/Trees`.

### Battery & Boost

* Battery range: 0 — 100
* `boost_speed_mult = 1.35`
* Battery drain while boosting: `battery_drain_per_sec = 8`
* Charging Station: standing inside charging zone for `charge_seconds = 2` restores battery to full (or +50% if you prefer).

### Delivery Zones

* Visual pads at side streets. The purifier must be deployed inside zone circle to succeed (Area2D overlap). Successful delivery gives points + immediate local AQI drop + AIR coins.

---

## 7 — AIR Coin economy & formulas

**Concept:** Coins reward players for cleaning the air. Clean runs (with trees/filters active) yield more coins; dirtier runs yield less.

**Variables:**

* `d` = distance in meters run this session (or px → meters conversion)
* `AQI_base` = base AQI for map stretch
* `AQI_current` = real-time AQI after filters & trees
* `tree_density_factor` = `1 + (num_trees_in_stretch * 0.02)` (small boost)
* `filter_active_multiplier` = 1.0 (none) or 2.5 (active filter)

**Per-run coin formula (continuous per meter):**

```
coin_per_meter = base_rate * ((AQI_base - AQI_current) / AQI_base) * tree_density_factor * filter_active_multiplier
```

* `base_rate` = 0.02 coins / meter (tweak)
* Clip coin_per_meter to `[0.001, 0.2]`

**Distance-based award at run end:**

```
air_coins = Σ( coin_per_meter * meters_traveled )
```

**Examples:**

* If `AQI_base = 250` (bad), `AQI_current = 170` (improved), `base = 0.02`, `tree_density_factor = 1.1`:

  ```
  coin_per_meter = 0.02 * ((250 - 170) / 250) * 1.1 = 0.02 * (80 / 250) * 1.1 ≈ 0.020 * 0.32 * 1.1 ≈ 0.00704 coins/meter
  ```
* For 1000 m → 7.04 coins

**Spending & economy:**

* Masks: cheap, buy in-run for emergency: 5 coins
* Filters: buy in-run for immediate large effect: 50 coins (lasts 30s)
* Tree saplings: 75 coins planted permanently
  (These numbers are tuning starting points — tune for retention.)

---

## 8 — World design: chunks, tiling, and reuse

**World is built from reusable chunks (prefab segments).** Each chunk width ~960–1600 px. A chunk contains:

* Background selection (sky variant)
* Mid-ground building sprites positions
* Foreground shop sprites
* Road obstacles spawn points
* Delivery zone markers
* Removable decoration objects (pigeons, banners)

**Chunk selection at runtime:**

* Use deterministic randomization seeded by `map_seed` + `chunk_index` so that same chunk order can reproduce for testing.
* Chunks are stored as small JSON blueprints (not heavy .tscn files) to be instantiated by a chunk-instancer script.

**Tiling repeating assets (roads, sky strips, shops):**

* **Road (road_tile.webp)**:

  * Use two Sprite2D nodes (or three for safety) with the same texture placed adjacent:

    * `RoadTileA.x = 0`, `RoadTileB.x = texture_width`
  * In `RoadScroll.gd`, move them left by `scroll_speed * delta`. Once a tile.x < -texture_width, add `texture_width * 2` to tile.x to recycle.
  * Alternative: use `ParallaxLayer.motion_mirroring.x = texture_width` and a single Sprite2D child, Godot will mirror the parallax layer automatically. (Use the first approach if you need precise control.)
* **Sky strips (bad_sky.webp, ok_sky.webp, clear_sky.webp)**:

  * Use full-width sprite layers (960–1920 px). Have three `Sky` Sprite2D nodes stacked — one for each sky type — and control `modulate.a` to crossfade.
  * Use parallax motion slower than foreground (ParallaxLayer motion_scale `0.2`).
  * If your sky images are tileable horizontally, you can use mirroring or tile them like roads.

**Why two approaches?**

* Road: precise repeating pattern needs perfect tile seam — recycle method avoids artifacts.
* Sky: crossfade gives smooth change of atmosphere — more natural for AQI transitions.

---

## 9 — Sky types & transitions (detailed)

**Sky assets available:** `bad_sky.webp`, `ok_sky.webp`, `clear_sky.webp` (from assets screenshot).

**Transition rules:**

* Each chunk carries a `sky_type` property `{ "bad","ok","clear" }`.
* When player enters a new chunk:

  * Read target `sky_type`.
  * Start a crossfade animation (2.0 seconds) that tweens `modulate.a` of the three sky Sprite2D nodes:

    * Tween target sky alpha → 1.0
    * Tween previous sky alpha → 0.0
  * Simultaneously, interpolate `AQI_base` to the chunk base. (AQI change is separate; sky is visual only.)
* For a smoother feel when filters active mid-chunk: allow short crossfade of 0.6s on filter deployment (localized), using a vignette/overlay to simulate clearing.

**Implementation (Godot):**

* `ParallaxLayer` named `SkyLayer` with 3 child `Sprite2D` nodes:

  * `Sprite_BadSky`, `Sprite_OkSky`, `Sprite_ClearSky`
* `Game.gd` exposes function `set_sky_type(target: String)` which runs an `AnimationPlayer` or `Tween` to modulate alphas.

---

## 10 — Assets naming conventions (you will follow these)

Use the following naming convention & place in `assets/`:

**Skies**

* `sky_bad.webp` (previously bad_sky.webp)
* `sky_ok.webp` (ok_sky.webp)
* `sky_clear.webp` (clear_sky.webp)

**Road**

* `road_tile.webp` (tileable width 960, height 64)
* `road_shoulder_left.webp` (optional)
* `road_shoulder_right.webp` (optional)

**Player & Vehicles**

* `vim_base.webp` (rider + scooter, 128×64)
* `bike.webp` (enemy vehicle)
* `car.webp` (polluting car)

**Pickups**

* `mask.webp`
* `filter_1.webp`
* `sapling.webp`
* `delivery_pad.webp`

**Buildings & Parallax**

* `skyline_1.webp`, `mid_building_01.webp`, `front_shop_01.webp`, `front_shop_02.webp`, `pharmacy.webp`, `restaurant.webp`, `home_1.webp`, `Select_City_mall.webp`, `CP.webp`, `Laal_kila.webp`, `Lotus_park.webp`, `Hauskhas.webp`

**UI**

* `ui_lung_bg.webp`, `ui_lung_fill.webp` (9patch recommended)
* `ui_battery_bg.webp`, `ui_battery_fill.webp`
* `ui_coin.webp`, `ui_minidot.webp`
* `mask_pulse.png`, `filter_glow.png`, `smog_overlay.png`

**Naming rules**

* Lowercase, underscores, short descriptive names.
* Use WebP for color/size efficiency.
* Put partner-specific assets under `assets/brand/<brandname>/...` for easy swap.

---

## 11 — Folder & file structure (VS Code friendly)

```
project-root/
│
├── assets/                     ## all webp/png sprites (organize by type)
│   ├── skies/
│   │   ├── sky_bad.webp
│   │   ├── sky_ok.webp
│   │   └── sky_clear.webp
│   ├── road/
│   │   └── road_tile.webp
│   ├── player/
│   │   └── vim_base.webp
│   ├── pickups/
│   └── ui/
│
├── scenes/                     ## .tscn scene files (text-editable)
│   ├── Main.tscn
│   ├── Player.tscn
│   ├── Obstacle.tscn
│   ├── Mask.tscn
│   ├── Purifier.tscn
│   ├── Sapling.tscn
│   └── HUD.tscn
│
├── scripts/                    ## GDScript files (edit in VS Code)
│   ├── Game.gd
│   ├── Player.gd
│   ├── Spawner.gd
│   ├── Obstacle.gd
│   ├── Pickup.gd
│   ├── DeliveryZone.gd
│   ├── RoadScroll.gd
│   ├── SkyManager.gd
│   ├── HUD.gd
│   └── Persistence.gd
│
├── data/                       ## prebuilt chunk JSON and seeds
│   ├── chunks/
│   │   └── chunk_001.json
│   └── map_seed.json
│
├── config/
│   ├── brand.json
│   └── gameplay.json
│
├── user/                       ## empty: not committed. Godot user:// persistence writes here
│
├── project.godot
└── README.md
```

**Notes:**

* `.tscn` and `.gd` are plain text; you can edit everything in VS Code.
* Don't commit `.import/` or `user/` folder; add to `.gitignore`.

---

## 12 — Godot scene tree (Main.tscn) — authoritative layout

```
Main (Node2D) — script: scripts/Game.gd
├─ ParallaxBG (ParallaxBackground)
│  ├─ SkyLayer (ParallaxLayer) — script: scripts/SkyManager.gd
│  │  ├─ Sprite_SkyBad (Sprite2D)
│  │  ├─ Sprite_SkyOk  (Sprite2D)
│  │  └─ Sprite_SkyClear (Sprite2D)
│  ├─ MidLayer (ParallaxLayer)
│  │  └─ MidNode (Node2D) -> holds mid buildings nodes
│  └─ FrontLayer (ParallaxLayer)
│     └─ FrontNode (Node2D) -> holds shop sprites (instanced)
│
├─ Road (Node2D)
│  ├─ RoadTileA (Sprite2D)
│  └─ RoadTileB (Sprite2D)
│  script: scripts/RoadScroll.gd
│
├─ World (Node2D)
│  ├─ DynamicObstacles (Node2D)
│  ├─ DynamicPickups (Node2D)
│  └─ Trees (Node2D)          ## persistent tree instances
│
├─ DeliveryZones (Node2D)     ## contains Area2D nodes with scripts
├─ Player (CharacterBody2D)    ## instance Player.tscn (script Player.gd)
├─ Spawner (Node2D)           ## script: Spawner.gd (preloaded scene references)
└─ UI (CanvasLayer)            ## script: HUD.gd
   ├─ HealthBar (TextureProgress)
   ├─ MaskTimer (Label + AnimationPlayer)
   ├─ BatteryBar (TextureProgress)
   ├─ AQIIndicator (Label)
   ├─ AIRCoinCounter (HBox)
   └─ TouchControls (Control)
       ├─ UpButton (TouchScreenButton)
       ├─ DownButton (TouchScreenButton)
       ├─ BoostButton (TouchScreenButton)
       └─ DropButton (TouchScreenButton)
```

**Script responsibilities**

* `Game.gd` — orchestrates parallax offsets, chunk instancing, AQI updates, save/load hooks.
* `SkyManager.gd` — controls sky crossfades & local visual effects.
* `RoadScroll.gd` — recycles road tiles.
* `Spawner.gd` — uses pooling to spawn obstacles/pickups; preloads scenes.
* `Player.gd` — input, lane switching, health, battery, carrying states.
* `HUD.gd` — binds to the player and visualizes status bars and timers.
* `Persistence.gd` — read/write `user://game_state.json` (trees array, coins, runs).

---

## 13 — Spawner, pooling, lifetime rules

* **Pooling**: Pre-instantiate N=8 obstacles and N=6 pickups at startup; recycle via `queue_free()` only if memory low, else reuse by re-activating and setting global_position.
* **Lifetime**: objects that exit left screen `x < -200` are recycled or freed.
* **Spawn logic**: `Spawner` uses chunk-defined spawn points (reads chunk JSON) and a per-chunk config to control density.

---

## 14 — HUD / UI & how to show health and battery

**Widgets**

* Use `TextureProgress` for Health and Battery:

  * `HealthBar.texture_progress = res://assets/ui/ui_lung_fill.webp`
  * `HealthBar.texture_under = res://assets/ui/ui_lung_bg.webp` (9patch or 9-patch to scale)
* Mask timer:

  * `Label` shows integer seconds
  * `AnimationPlayer` pulse on parent Control node scales `MaskPulse` icon while mask_time > 0
* AQIIndicator:

  * Color code: Green (<= 50), Yellow (50–100), Orange (100–200), Red (200–300)
  * Show numeric value and text (e.g., "AQI 210 — Unhealthy")

**Showing smog overlay (visual feedback of health/AQI):**

* Add `ColorRect` above `ParallaxBG` but below `UI`, with `texture = res://assets/ui/smog_overlay.png`.
* Control `modulate.a = clamp((AQI_current - 50) / 450, 0.0, 0.9)` (or map to health).
* Alternatively modify `Sprite_SkyBad.modulate` tint to show subtle desaturation.

**Mask pulse animation logic**

* When `player.mask_time > 0`:

  * `MaskPulse` AnimationPlayer plays `pulse` animation (scale 1.0→1.12→1.0 loop)
  * As mask_time < 5s, change tint to red/orange pulse to indicate leak.

**Performance tip**

* Use TextureProgress with `Stretch Mode = 9-Patch` for crisp scaling on mobile.

---

## 15 — Persistence / Auto-save

**Save path:** `user://game_state.json` (Godot FileAccess)

**Schema**

```json
{
  "trees": [
    {
      "id": "t-0001",
      "x": 12340,
      "stage": 2,
      "planted_at": 1700000000
    }
  ],
  "coins_total": 240,
  "runs_played": 15,
  "best_score": 1245,
  "map_aqi_modifiers": {
    "default": -12
  }
}
```

**When to save**

* On `Game` pause, on run end, and when a tree is planted.
* Periodic autosave every N seconds (30s).

**Load flow**

* On `Game.gd._ready()` call `Persistence.load_game_state()` and instantiate saved trees into `World/Trees`.
* When instantiating trees, set growth stage visuals (swap sprite or scale) and tag node with `tree_id`.

**Tree growth across sessions**

* Each time player plays a run that includes the tree's stretch, increment `stage` by 0 or 1 depending on the session rules. Cap stages at 5. Update `clean_rate` accordingly.

---

## 16 — Brand / reskin JSON schema

`config/brand.json`:

```json
{
  "brand": "AtherX",
  "mask_sprite": "res://assets/brand/atherx/mask_air.png",
  "purifier_sprite": "res://assets/brand/atherx/purifier_air.png",
  "billboard_sprite": "res://assets/brand/atherx/billboard.png",
  "ui_tint": [0.0, 0.6, 0.9]
}
```

**Load** in `Game.gd._ready()` and apply to HUD & pickup sprites using `load()` and `texture = preload(...)` or `texture = load(...)`.

---

## 17 — Backend API (FastAPI) — minimal contract

* `POST /session/start` → returns `session_token`
* `POST /session/end` → send `{ session_token, score, coins, deliveries, trees_planted }`
* `POST /lead` → send `{ name?, phone, email, score }` returns OTP status
* `POST /verify` → verify OTP
* `GET /leaderboard?limit=20` → returns leaderboard array
* `GET /trees?stretch_id=...` → optional map-level tree data if you want server-side shared persistence (optional future feature)

**Godot integration**

* Use `HTTPRequest` node to POST/GET JSON. On HTML5, ensure CORS headers are allowed on server.

---

## 18 — Export & HTML5 performance recommendations

* Use **GLES2** if you need broad compatibility; GLES3 ok if tested on target devices.
* Reduce texture size & pack into atlases.
* Use WebP for images (smaller).
* Use `VisibilityEnabler2D` for off-screen nodes.
* Avoid many particles; use pre-baked overlay for smog.
* Turn off debug logs; enable `Compress PNG`.
* Test on low-end Android (Chrome), mid-range iPhone.
* Prefer `PackedScene` preloads so GC & instancing are predictable.

---

## 19 — VS Code → Godot workflow

**Setup**

* Install `GDScript` extension / `Godot Tools` in VS Code.
* Make a small wrapper: `/usr/local/bin/godot` that runs `flatpak run org.godotengine.Godot "$@"` so `godot` is runnable.

**Editing & running**

* Edit `.gd` and `.tscn` files in VS Code.
* Keep `project.godot` `run/main_scene="res://scenes/Main.tscn"`.
* When ready, run Godot once (open project, press Play). Keep Godot open to see console errors. For fast iterations: edit files → press Play.

**Auto-inject textures**

* Use `scripts/prefs.json` or a small Python helper to patch `.tscn` ext_resource entries to point to files in `assets/`. (I can generate that script.)

**Git**

* Commit all text files; ignore `user/` and `.import/`.

---

## 20 — Tuning & testing checklist

* [ ] Player lane switching feels tight (no float or lag)
* [ ] Mask timer shows countdown and restores HP on pickup
* [ ] Purifier deploy reduces AQI locally for 30s and gives coin multiplier
* [ ] Tree planting instantiates persistent tree and is saved to `user://`
* [ ] Road tiles scroll with no seam; no visual flicker
* [ ] Sky crossfade triggers at chunk boundaries and on filter deploy
* [ ] HUD bars update smoothly and are visible on mobile
* [ ] Battery/boost and charge zone logic works (2s to recharge)
* [ ] Spawner reuses pooled objects and no GC spikes
* [ ] HTML5 export runs in Chrome mobile and memory footprint under 30MB

---

## Implementation notes & quick code pointers

### Tiling road (RoadScroll.gd sketch)

* Use `RoadTileA` and `RoadTileB` and `texture_width = RoadTileA.texture.get_width()`. Move both left `scroll_speed * delta`. If `RoadTileA.position.x < -texture_width`, add `texture_width * 2`.

### Sky crossfade (SkyManager.gd)

* Use `Tween` or `AnimationPlayer` to change `Sprite.modulate.a`. When chunk changes call `set_sky_type("clear")` → tween alphas.

### Persistence (Persistence.gd snippet)

* Use:

```gdscript
var file = FileAccess.open("user://game_state.json", FileAccess.WRITE_READ)
file.store_string(JSON.print(state))
file.close()
```

* On load: `FileAccess.file_exists("user://game_state.json")`, then read & `JSON.parse_string()`.

### Preloading scenes in Spawner

```gdscript
var ObstacleScene := preload("res://scenes/Obstacle.tscn")
var MaskScene := preload("res://scenes/Mask.tscn")
var PurifierScene := preload("res://scenes/Purifier.tscn")
```

---

## Delivery & next steps (practical checklist for you)

1. **Follow folder structure** above and name your WebP assets accordingly into `assets/`.
2. **Implement scripts** (I can produce full GDScript files for Game.gd, SkyManager.gd, RoadScroll.gd, Persistence.gd — tell me and I’ll generate them).
3. **Wire the Spawner to preloads** in `Spawner.gd` to avoid manual inspector steps.
4. **Test locally**: open Godot once and press Play — iterate.
5. **Export HTML5** with the supplied export settings (I can provide exact export preset).

---

If you want, next I will:

* Generate **all the GDScript files** referenced above (Godot 4.5.1–compatible), ready to paste into your `scripts/` folder.
* Or generate the **Python helper** that auto-links your `assets/` images into `.tscn` ext_resource entries so you can keep working in VS Code.
* Or generate a **sample chunk JSON** (chunk_001.json) and a chunk-instancer `Game.gd` snippet.

Which one should I produce now?
