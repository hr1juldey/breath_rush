#!/usr/bin/env python3
"""Extract region_rect data for all parallax assets"""

import re
import json

with open('scenes/ParallaxScalingEditor.tscn', 'r') as f:
    content = f.read()

# Pattern to extract sprite with region data
pattern = r'\[node name="(\w+)" type="Sprite2D"[^\[]*?texture = ExtResource\("(\d+)_\w+"\)[^\[]*?region_enabled = true[^\[]*?region_rect = Rect2\(([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\)'

matches = re.finditer(pattern, content, re.DOTALL)

regions = {}
for match in matches:
    name = match.group(1)
    x = float(match.group(3))
    y = float(match.group(4))
    w = float(match.group(5))
    h = float(match.group(6))

    regions[name] = {
        "x": x,
        "y": y,
        "width": w,
        "height": h
    }

# Categorize by layer
far_assets = ['LotusPark', 'LaalKila', 'Hauskhas', 'Hanuman']
mid_assets = ['BuildingGeneric', 'TwoStoreyBuilding', 'Restaurant', 'Shop', 'Pharmacy']
front_assets = ['Tree1', 'Tree2', 'Tree3', 'FruitStall', 'Billboard']

print("="*70)
print("REGION RECTANGLES FOR PARALLAX ASSETS")
print("="*70)

for layer_name, asset_list in [('FAR', far_assets), ('MID', mid_assets), ('FRONT', front_assets)]:
    print(f"\n{layer_name} LAYER:")
    for asset in asset_list:
        if asset in regions:
            r = regions[asset]
            print(f"  {asset:20s} Rect2({r['x']:4.0f}, {r['y']:4.0f}, {r['width']:4.0f}, {r['height']:4.0f})")
        else:
            print(f"  {asset:20s} NO REGION (uses full texture)")

# Save to JSON
output = {
    "far": {name: regions.get(name) for name in far_assets},
    "mid": {name: regions.get(name) for name in mid_assets},
    "front": {name: regions.get(name) for name in front_assets}
}

with open('data/parallax_regions.json', 'w') as f:
    json.dump(output, f, indent=2)

print(f"\n{'='*70}")
print("Saved to data/parallax_regions.json")
print(f"{'='*70}")
