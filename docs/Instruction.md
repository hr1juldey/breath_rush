# **AGENT PROMPT — Build the Breath_Rush code-first Godot skeleton from the GDD**

Working directory (agent): `~/Documents/Code/Games/breath_rush`
Files already present:

```bash
./docs/GDD.md
./project.godot
```

Reference file (visual animatic / PPT) — use this as a visual reference:

```bash
docs/Lilypad_BreathRush.pdf
```

(Use that exact local path when the system needs to fetch the original PPT/animatic. The system will convert it to a downloadable URL.)

**Agent objective (summary)**
Read the design doc `./docs/GDD.md` and the visual reference at `docs/Lilypad_BreathRush.pdf`. Then build a complete, code-first Godot 4.5.1 project skeleton in this repo that:

* Is ready to be opened in Godot later for testing / export.
* Follows the naming conventions and folder layout in the GDD (assets, scenes, scripts, data, config).
* Creates all `.gd` scripts and `.tscn` scene text files described in the GDD so the project is self-contained and testable later in Godot.
* Adds sample chunk JSON, brand json, and minimal placeholder image files (small webp or empty files as placeholders) using the exact asset names described in the GDD.
* Uses preloads for scene references in spawner scripts so Godot Inspector changes are not required.
* Saves everything to disk and prints a verification report (tree, created files list, and sample file tails/heads for quick sanity check).

**Constraints / assumptions**

* The agent runs only on the local host and can read/write files under `~/Documents/Code/Games/breath_rush`.
* The agent must not open Godot (GUI). All work is file-based in VS Code style.
* Use Godot 4.5.1 node types and GDScript syntax compatible with Godot 4.x.
* Keep all GDScript files under ~300 lines and modular.
* Use paths exactly as below (`res://...` mapping is not required now; create regular file paths relative to repo).
* Provide clear README on how to open and test in Godot.

---

## 1) Read references

1. Read (parse) `./docs/GDD.md`. Use it as the authoritative spec.
2. Read `docs/Lilypad_BreathRush.pdf` for visual guidance (sky variations, mask pulse, assets). If the agent cannot open the PDF, still proceed using the GDD.

---

## 2) Create folder structure (exact)

Create these folders (if they do not exist):

```bash
assets/
assets/skies/
assets/road/
assets/player/
assets/pickups/
assets/vehicles/
assets/parallax/
assets/ui/
scenes/
scripts/
data/chunks/
config/
docs/
```

---

## 3) Place placeholder asset files (exact names)

Create small placeholder WebP (or PNG) files — 1x1 or tiny images are OK as placeholders. Use these exact filenames in the matching folders:

**Skies**

* `assets/skies/sky_bad.webp`
* `assets/skies/sky_ok.webp`
* `assets/skies/sky_clear.webp`

**Road**

* `assets/road/road_tile.webp`

**Player & vehicles**

* `assets/player/vim_base.webp`
* `assets/vehicles/car.webp`
* `assets/vehicles/bike.webp`

**Pickups & UI**

* `assets/pickups/mask.webp`
* `assets/pickups/filter_1.webp`
* `assets/pickups/sapling.webp`
* `assets/pickups/delivery_pad.webp`
* `assets/ui/ui_lung_bg.webp`
* `assets/ui/ui_lung_fill.webp`
* `assets/ui/ui_battery_bg.webp`
* `assets/ui/ui_battery_fill.webp`
* `assets/ui/ui_coin.webp`
* `assets/ui/mask_pulse.png`
* `assets/ui/smog_overlay.png`

**Parallax / buildings**

* `assets/parallax/skyline_1.webp`
* `assets/parallax/mid_building_01.webp`
* `assets/parallax/front_shop_01.webp`
* `assets/parallax/pharmacy.webp`
* `assets/parallax/Select_City_mall.webp`

> Implementation detail: If writing WebP is not available, create empty files with correct names and minimal text (will be replaced by designer later).

---

## 4) Create config files

Create `config/brand.json` (example content):

```json
{
  "brand": "placeholder",
  "mask_sprite": "res://assets/pickups/mask.webp",
  "purifier_sprite": "res://assets/pickups/filter_1.webp",
  "billboard_sprite": "res://assets/parallax/Select_City_mall.webp",
  "ui_tint": [0.1, 0.6, 0.9]
}
```

Create `config/gameplay.json` with base tunables (reference GDD). Provide values for:

* mask_duration, filter_duration, base_rates, coin_base_rate, pollution_base, lane_y_positions.

---

## 5) Create sample chunk JSON (data/chunks/chunk_001.json)

Write one example chunk JSON with these keys:

* `id`, `width`, `sky_type` (“bad”/“ok”/“clear”), `spawn_points` list (with x,y,type), `delivery_zones` list (x,y,radius), `mid_buildings` (list of sprite names + x offsets).

Example minimal content (match GDD semantics).

---

## 6) Create Godot scene .tscn files (text) in `scenes/`

Create **text-based** `.tscn` files (Godot 4 format) for:

* `scenes/Main.tscn`
* `scenes/Player.tscn`
* `scenes/Obstacle.tscn`
* `scenes/Mask.tscn`
* `scenes/Purifier.tscn`
* `scenes/Sapling.tscn`
* `scenes/HUD.tscn`

Each `.tscn` should:

* Reference the scripts (from `scripts/`) via `ext_resource` script ids.
* Reference the placeholder textures created above via `ext_resource` entries (texture paths).
* Use proper node types: `Node2D`, `ParallaxBackground`, `ParallaxLayer`, `Sprite2D`, `CharacterBody2D`, `Area2D`, `CanvasLayer`, `TextureProgress`, `TouchScreenButton` (for touch), etc.
* Set initial node positions that match the GDD default (lanes around Y = 240 / 300 / 360; player X = 180; Road at Y ~420).

**Important**: Use ext_resource IDs consistently and ensure the scene files are valid text (format=4).

*Note:* The agent may reuse earlier generated scene templates; ensure the ext_resource indices align inside each tscn.

---

## 7) Create GDScript files in `scripts/` (exact filenames & required behavior)

Create these scripts with the functionality described in the GDD. Each file must be Godot 4 compatible:

* `scripts/Game.gd` — orchestrator: parallax scrolling, chunk instancing, AQI, save/load callouts to Persistence.gd, sky transitions via SkyManager, routing spawner calls.
* `scripts/SkyManager.gd` — crossfade code for three sky sprites, `set_sky_type("bad"|"ok"|"clear")`.
* `scripts/RoadScroll.gd` — road tile recycling (two tiles, using texture width).
* `scripts/Player.gd` — lane switching, micro shift, health, mask_time, battery, boost, carrying item states, apply_mask(), pickup_purifier(), deliver_purifier(), pickup_sapling(), planting logic (emit signals as needed).
* `scripts/Spawner.gd` — preloads scenes with `preload("res://scenes/Obstacle.tscn")`, `Mask.tscn`, `Purifier.tscn`, and spawns based on chunk JSON spawn points. Use a simple RNG seeded by `map_seed`.
* `scripts/Pickup.gd` — Area2D script for mask/purifier/sapling interactions, calls Player methods and queue_free or pool return.
* `scripts/DeliveryZone.gd` — Area2D script to detect deliveries and call `deliver_purifier()` on Player.
* `scripts/HUD.gd` — CanvasLayer binding to Player with `HealthBar`, `BatteryBar`, `MaskLabel`, `AQIIndicator`, `AIRCoinCounter`.
* `scripts/Persistence.gd` — read/write `user://game_state.json`, functions `save_game_state(state)` and `load_game_state()` returning the tree list & coins.
* `scripts/Obstacle.gd` — simple move-left & recycle logic.

**Implementation notes**

* Preload scenes in `Spawner.gd` to remove the need for manual Inspector wiring.
* Emit signals for important events (e.g., `signal purifier_delivered(x, y)`).
* Keep each file modular and under 300 lines.

---

## 8) Update `project.godot`

Ensure `project.godot` has an `[application]` section with:

```bash
run/main_scene="res://scenes/Main.tscn"
```

If the file exists, update the value; if not, create or patch accordingly.

---

## 9) Add README and docs

Create `README.md` in repo root with instructions:

* How to open in Godot (flatpak wrapper example `/usr/bin/flatpak run org.godotengine.Godot` or `godot` wrapper).
* Input map suggestions (ui_up, ui_down, ui_accept).
* How to replace placeholder assets in `assets/`.
* How to run quick checks (see step 11).

Also create `docs/IMPLEMENTATION_LOG.md` and append a summary of every change you make with timestamp.

---

## 10) Tests & sanity checks (file-only)

After file creation, run these checks and report results:

1. Print the repository tree (depth 3).
2. For every `.tscn` file created, verify referenced `ext_resource` paths exist (grep `ext_resource path="...` and confirm the file exists). Print any missing resources.
3. For every `.gd` file created, run a **lightweight syntax check**: ensure `func` appears at least once in each script and no tab characters (enforce spaces). (If `gdtool` / Godot CLI parser is available, run `godot --script` or `godot --check` if possible — otherwise skip.)
4. Print the first 80 lines of `scenes/Main.tscn` and `scripts/Game.gd` for quick verification.
5. Print the content of `config/brand.json` and `data/chunks/chunk_001.json`.

---

## 11) Final outputs (agent must print these)

At the end of run, print a short JSON report on stdout with keys:

```json
{
  "status": "ok",
  "files_created": ["list", "of", "files"],
  "files_modified": ["project.godot"],
  "missing_resources": [],
  "todo_notes": ["any additional steps to finish"],
  "verify_tree": "path/to/zip/optional"
}
```

Also print instructions on how to open the project in Godot and the exact command to run Godot (use `/usr/bin/flatpak run org.godotengine.Godot` or `godot` wrapper if created).

---

## 12) Behavior / etiquette rules for the agent

* **Idempotent:** Running the agent twice should not duplicate content in an uncontrolled way — overwrite files if they exist with updated content and append log entries to IMPLEMENTATION_LOG.md.
* **No GUI actions:** Do not attempt to launch the Godot GUI or interact with display; only create files.
* **Be explicit:** If any step cannot be completed (missing permissions, cannot write to path), stop and print a clear error message and the partial progress.
* **Document decisions:** For any value you choose (AQI base numbers, coin rates), note it in `docs/IMPLEMENTATION_LOG.md`.
* **No network calls** unless explicitly necessary — all work is local.

---

## 13) Priority order (what to create first)

1. folders + placeholder assets
2. scripts (skeletons)
3. scenes (.tscn) referencing scripts & assets
4. config & chunk JSON
5. update project.godot + README
6. tests & verification
7. final report JSON + tree output

---

## 14) Developer note for converting local PDF path to web URL

When you need to present the visual reference to a downstream tool or human, the path to pass is:

```bash
docs/Lilypad_BreathRush.pdf
```

(Transformation to a URL is handled externally.)

---

### Run this now

**Important**: After executing, the agent must print the final JSON report and a `tree -a` of the created files and `tail -n 20 docs/IMPLEMENTATION_LOG.md` for review.

If anything fails, do NOT proceed to clean-up — print the error and the partial results so a human can inspect.

---

End of prompt.
