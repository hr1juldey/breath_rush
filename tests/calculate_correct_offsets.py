#!/usr/bin/env python3
"""Calculate correct layer offsets for proper parallax positioning"""

import json

with open('data/parallax_asset_configs.json', 'r') as f:
    data = json.load(f)

quad_a = 428.08
quad_b = -469.51
quad_c = 128.64

road_y = 420
horizon_y = 200  # Horizon line from ParallaxScalingEditor

print("="*80)
print("CALCULATING CORRECT LAYER OFFSETS")
print("="*80)
print(f"\nTarget: All assets should sit ON or slightly ABOVE the road at y={road_y}")
print(f"Horizon reference: y={horizon_y}")
print()

for layer_name in ['far', 'mid', 'front']:
    print(f"\n{layer_name.upper()} LAYER:")
    print("-" * 80)

    assets = data[layer_name]
    offsets_needed = []

    for asset_name, config in assets.items():
        scale = config['scale']
        reference_y = config['y']  # Y in ParallaxScalingEditor

        # What the formula gives
        formula_y = quad_a + quad_b * scale + quad_c * scale * scale

        # Where we want it (on or near horizon/road)
        # Far assets: near horizon (y=200-250)
        # Mid assets: between horizon and road (y=300-380)
        # Front assets: at road level (y=380-420)
        if layer_name == 'far':
            target_y = horizon_y + 50  # Slightly below horizon
        elif layer_name == 'mid':
            target_y = (horizon_y + road_y) / 2 + 50  # Between horizon and road
        else:  # front
            target_y = road_y - 20  # Just above road

        # Offset needed
        offset_needed = target_y - formula_y
        offsets_needed.append(offset_needed)

        print(f"  {asset_name:20s} formula_y={formula_y:6.2f}  target={target_y:6.2f}  offset={offset_needed:+7.2f}")

    avg_offset = sum(offsets_needed) / len(offsets_needed)
    print(f"\n  → Recommended layer_y_offset: {avg_offset:.2f}")

print(f"\n{'='*80}")
print("RECOMMENDED SETTINGS:")
print(f"{'='*80}")
print("Update in spawner scripts:")
print(f"  FarLayerSpawner:   layer_y_offset = {(horizon_y + 50 - (quad_a + quad_b * 1.0 + quad_c * 1.0 * 1.0)):.2f}")
print(f"  MidLayerSpawner:   layer_y_offset = {((horizon_y + road_y) / 2 + 50 - (quad_a + quad_b * 0.5 + quad_c * 0.5 * 0.5)):.2f}")
print(f"  FrontLayerSpawner: layer_y_offset = {(road_y - 20 - (quad_a + quad_b * 0.2 + quad_c * 0.2 * 0.2)):.2f}")
print(f"\nglobal_y_offset should remain at: 0.0")
print("="*80)
