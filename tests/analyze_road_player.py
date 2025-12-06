#!/usr/bin/env python3
"""Analyze road and player configuration from ParallaxScalingEditor"""

import re

# Parse ParallaxScalingEditor.tscn
with open('scenes/ParallaxScalingEditor.tscn', 'r') as f:
    content = f.read()

print("="*70)
print("ROAD AND PLAYER ANALYSIS FROM PARALLAXSCALINGEDITOR.TSCN")
print("="*70)

# Extract RoadTile info
road_pattern = r'\[node name="RoadTile"\s+type="Sprite2D"[^\[]*?position = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?scale = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?region_rect = Rect2\(([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)'

road_match = re.search(road_pattern, content, re.DOTALL)
if road_match:
    road_x = float(road_match.group(1))
    road_y = float(road_match.group(2))
    road_scale_x = float(road_match.group(3))
    road_scale_y = float(road_match.group(4))
    region_x = float(road_match.group(5))
    region_y = float(road_match.group(6))
    region_w = float(road_match.group(7))
    region_h = float(road_match.group(8))

    print(f"\nROAD TILE:")
    print(f"  Position: ({road_x}, {road_y})")
    print(f"  Scale: ({road_scale_x}, {road_scale_y})")
    print(f"  Region: x={region_x}, y={region_y}, w={region_w}, h={region_h}")
    print(f"\n  → In Main.tscn, the Road node should be:")
    print(f"     position = Vector2(0, {road_y})")
    print(f"     scale = Vector2({road_scale_x}, {road_scale_y})")
    print(f"  → And child RoadTileA/B sprites need offset positioning")

# Extract VimBase (player) info
vim_pattern = r'\[node name="VimBase"\s+type="Sprite2D"[^\[]*?position = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?scale = Vector2\(([\d.]+),\s*([\d.]+)\)'

vim_match = re.search(vim_pattern, content, re.DOTALL)
if vim_match:
    vim_x = float(vim_match.group(1))
    vim_y = float(vim_match.group(2))
    vim_scale_x = float(vim_match.group(3))
    vim_scale_y = float(vim_match.group(4))

    print(f"\nPLAYER (VimBase):")
    print(f"  Position: ({vim_x}, {vim_y})")
    print(f"  Scale: ({vim_scale_x}, {vim_scale_y})")
    print(f"\n  → In Main.tscn Player node should be:")
    print(f"     position = Vector2(458, {vim_y})  # Keep x centered for gameplay")
    print(f"     scale = Vector2({vim_scale_x}, {vim_scale_y})")

# Extract Camera info for reference
camera_pattern = r'\[node name="Camera2D"[^\[]*?position = Vector2\(([\d.]+),\s*([\d.]+)\)'
camera_match = re.search(camera_pattern, content, re.DOTALL)
if camera_match:
    cam_x = float(camera_match.group(1))
    cam_y = float(camera_match.group(2))
    print(f"\nCAMERA (for reference):")
    print(f"  Position: ({cam_x}, {cam_y})")

print("\n" + "="*70)
print("CURRENT MAIN.TSCN VALUES (INCORRECT):")
print("="*70)

# Parse current Main.tscn
with open('scenes/Main.tscn', 'r') as f:
    main_content = f.read()

# Find current Road node
road_main_pattern = r'\[node name="Road"[^\[]*?position = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?scale = Vector2\(([\d.]+),\s*([\d.]+)\)'
road_main_match = re.search(road_main_pattern, main_content, re.DOTALL)
if road_main_match:
    print(f"\nCurrent Road in Main.tscn:")
    print(f"  position = Vector2({road_main_match.group(1)}, {road_main_match.group(2)})")
    print(f"  scale = Vector2({road_main_match.group(3)}, {road_main_match.group(4)})")

# Find current Player
player_pattern = r'\[node name="Player"[^\[]*?position = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?scale = Vector2\(([\d.]+),\s*([\d.]+)\)'
player_match = re.search(player_pattern, main_content, re.DOTALL)
if player_match:
    print(f"\nCurrent Player in Main.tscn:")
    print(f"  position = Vector2({player_match.group(1)}, {player_match.group(2)})")
    print(f"  scale = Vector2({player_match.group(3)}, {player_match.group(4)})")

print("\n" + "="*70)
