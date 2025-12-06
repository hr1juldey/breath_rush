#!/usr/bin/env python3
"""Extract complete asset configurations (texture, region, scale) from ParallaxScalingEditor"""

import re
import json

with open('scenes/ParallaxScalingEditor.tscn', 'r') as f:
    content = f.read()

# Asset categorization
far_assets = ['LotusPark', 'LaalKila', 'Hauskhas', 'Hanuman']
mid_assets = ['BuildingGeneric', 'TwoStoreyBuilding', 'Restaurant', 'Shop', 'Pharmacy']
front_assets = ['Tree1', 'Tree2', 'Tree3', 'FruitStall', 'Billboard']

def extract_asset_config(asset_name):
    """Extract scale, position, and region for an asset"""
    # Pattern to match the entire sprite node
    pattern = rf'\[node name="{asset_name}" type="Sprite2D"[^\[]*?position = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?scale = Vector2\(([\d.]+),\s*([\d.]+)\)[^\[]*?(?:region_enabled = true[^\[]*?region_rect = Rect2\(([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+)\))?'

    match = re.search(pattern, content, re.DOTALL)
    if match:
        x = float(match.group(1))
        y = float(match.group(2))
        scale_x = float(match.group(3))
        scale_y = float(match.group(4))
        scale = (scale_x + scale_y) / 2.0

        region = None
        if match.group(5):  # Has region
            region = {
                "x": float(match.group(5)),
                "y": float(match.group(6)),
                "width": float(match.group(7)),
                "height": float(match.group(8))
            }

        return {
            "scale": scale,
            "y": y,
            "region": region
        }
    return None

configs = {
    "far": {},
    "mid": {},
    "front": {}
}

print("="*70)
print("EXTRACTING COMPLETE ASSET CONFIGURATIONS")
print("="*70)

for layer_name, asset_list in [('far', far_assets), ('mid', mid_assets), ('front', front_assets)]:
    print(f"\n{layer_name.upper()} LAYER:")
    for asset in asset_list:
        config = extract_asset_config(asset)
        if config:
            configs[layer_name][asset] = config
            region_str = f"Rect2({config['region']['x']:.0f}, {config['region']['y']:.0f}, {config['region']['width']:.0f}, {config['region']['height']:.0f})" if config['region'] else "null"
            print(f"  {asset:20s} scale={config['scale']:.4f}  y={config['y']:7.2f}  region={region_str}")
        else:
            print(f"  {asset:20s} NOT FOUND")

# Save to JSON
with open('data/parallax_asset_configs.json', 'w') as f:
    json.dump(configs, f, indent=2)

print(f"\n{'='*70}")
print("Saved to data/parallax_asset_configs.json")
print(f"{'='*70}")
