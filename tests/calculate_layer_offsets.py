#!/usr/bin/env python3
"""Calculate layer-specific offsets from actual asset positions"""

import json

# Load the extracted data
with open('data/parallax_scales.json', 'r') as f:
    data = json.load(f)

formula = data['formula']
quad_a = formula['quad_a']
quad_b = formula['quad_b']
quad_c = formula['quad_c']

print("="*60)
print("CALCULATING LAYER-SPECIFIC OFFSETS")
print("="*60)
print(f"\nBase Formula: y = {quad_a} + ({quad_b})*scale + ({quad_c})*scale²")

# Calculate average error (offset needed) for each layer
for layer_name in ['far', 'mid', 'front']:
    assets = data['assets'][layer_name]

    if not assets:
        continue

    errors = []
    print(f"\n{layer_name.upper()} LAYER:")

    for asset_name, asset_data in assets.items():
        scale = asset_data['scale']
        actual_y = asset_data['y']

        # Calculate predicted y using formula
        predicted_y = quad_a + quad_b * scale + quad_c * scale * scale

        # Error = actual - predicted (positive means asset is lower/closer to ground)
        error = actual_y - predicted_y
        errors.append(error)

        print(f"  {asset_name:20s} actual={actual_y:7.2f}  predicted={predicted_y:7.2f}  error={error:+7.2f}")

    # Calculate average offset for this layer
    avg_offset = sum(errors) / len(errors)
    print(f"  --> Average offset for {layer_name}: {avg_offset:+.2f} pixels")

print("\n" + "="*60)
print("RECOMMENDED layer_y_offset VALUES:")
print("="*60)
print(f"FarLayerSpawner:   layer_y_offset = {sum([(data['assets']['far'][k]['y'] - (quad_a + quad_b * data['assets']['far'][k]['scale'] + quad_c * data['assets']['far'][k]['scale']**2)) for k in data['assets']['far']]) / len(data['assets']['far']):.2f}")
print(f"MidLayerSpawner:   layer_y_offset = {sum([(data['assets']['mid'][k]['y'] - (quad_a + quad_b * data['assets']['mid'][k]['scale'] + quad_c * data['assets']['mid'][k]['scale']**2)) for k in data['assets']['mid']]) / len(data['assets']['mid']):.2f}")
print(f"FrontLayerSpawner: layer_y_offset = {sum([(data['assets']['front'][k]['y'] - (quad_a + quad_b * data['assets']['front'][k]['scale'] + quad_c * data['assets']['front'][k]['scale']**2)) for k in data['assets']['front']]) / len(data['assets']['front']):.2f}")
print("="*60)
