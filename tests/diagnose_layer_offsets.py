#!/usr/bin/env python3
"""Diagnose layer offset issues"""

import json

# Load asset configs
with open('data/parallax_asset_configs.json', 'r') as f:
    data = json.load(f)

# Formula constants
quad_a = 428.08
quad_b = -469.51
quad_c = 128.64

# Current layer offsets
layer_offsets = {
    'far': -23.01,
    'mid': 8.51,
    'front': -8.51
}

# Game coordinates
camera_y = 180.415
road_y = 420
global_y_offset = 240  # Current setting

print("="*80)
print("DIAGNOSING LAYER OFFSET PROBLEMS")
print("="*80)
print(f"\nGame Setup:")
print(f"  Camera Y: {camera_y}")
print(f"  Road Y: {road_y}")
print(f"  Global Y Offset: {global_y_offset}")
print(f"\nFormula: y = {quad_a} + ({quad_b})*scale + ({quad_c})*scale²")

for layer_name in ['far', 'mid', 'front']:
    print(f"\n{'='*80}")
    print(f"{layer_name.upper()} LAYER (layer_y_offset = {layer_offsets[layer_name]})")
    print(f"{'='*80}")

    assets = data[layer_name]
    for asset_name, config in assets.items():
        scale = config['scale']
        reference_y = config['y']  # Y position in ParallaxScalingEditor

        # Calculate what spawner will produce
        formula_y = quad_a + quad_b * scale + quad_c * scale * scale
        spawned_y = formula_y + layer_offsets[layer_name] + global_y_offset

        # Distance from road (positive = below road/underground, negative = above road/floating)
        distance_from_road = spawned_y - road_y

        print(f"\n  {asset_name}:")
        print(f"    Scale: {scale:.4f}")
        print(f"    Reference Y (in editor): {reference_y:.2f}")
        print(f"    Formula Y: {formula_y:.2f}")
        print(f"    Spawned Y: {spawned_y:.2f}")
        print(f"    Distance from road ({road_y}): {distance_from_road:+.2f}")

        if distance_from_road < -100:
            print(f"    ❌ FLOATING HIGH in sky (way above road)")
        elif distance_from_road < -20:
            print(f"    ⚠️  Floating above road")
        elif distance_from_road > 20:
            print(f"    ❌ SUNK below road")
        else:
            print(f"    ✓ Near road level (correct)")

print(f"\n{'='*80}")
print("ANALYSIS:")
print(f"{'='*80}")
print("\nThe ParallaxScalingEditor Y positions (200-350 range) were designed")
print("for visual reference with camera at 180.415 and horizon at 200.")
print("\nBut these Y values don't directly translate to gameplay positions!")
print("The road is at y=420 in the game, so objects should spawn around 350-420")
print("to appear properly positioned relative to the player.")
