#!/usr/bin/env python3
"""Extract updated asset data from ParallaxScalingEditor.tscn after user edits"""

import re
import json
import numpy as np

# Parse the ParallaxScalingEditor.tscn file
with open('scenes/ParallaxScalingEditor.tscn', 'r') as f:
    content = f.read()

# Extract asset data
assets = {
    'far': {},
    'mid': {},
    'front': {},
    'ground': {}
}

# Asset categorization based on spawner layers
far_assets = ['LotusPark', 'LaalKila', 'Hauskhas', 'Hanuman']
mid_assets = ['BuildingGeneric', 'TwoStoreyBuilding', 'Restaurant', 'Shop', 'Pharmacy']
front_assets = ['Tree1', 'Tree2', 'Tree3', 'FruitStall', 'Billboard']
ground_assets = ['VimBase']

# Regex pattern to extract sprite data
pattern = r'\[node name="(\w+)" type="Sprite2D".*?position = Vector2\(([\d.]+), ([\d.]+)\).*?scale = Vector2\(([\d.]+), ([\d.]+)\)'

matches = re.finditer(pattern, content, re.DOTALL)

for match in matches:
    name = match.group(1)
    x = float(match.group(2))
    y = float(match.group(3))
    scale_x = float(match.group(4))
    scale_y = float(match.group(5))

    # Use average scale if x and y differ slightly
    scale = (scale_x + scale_y) / 2.0

    # Categorize asset
    if name in far_assets:
        assets['far'][name] = {'scale': scale, 'y': y}
    elif name in mid_assets:
        assets['mid'][name] = {'scale': scale, 'y': y}
    elif name in front_assets:
        assets['front'][name] = {'scale': scale, 'y': y}
    elif name in ground_assets:
        assets['ground'][name] = {'scale': scale, 'y': y}
    elif name == 'RoadTile':
        # Extract road tile data
        assets['road'] = {'scale': scale, 'y': y}

# Extract camera position
camera_match = re.search(r'\[node name="Camera2D".*?position = Vector2\(([\d.]+), ([\d.]+)\)', content, re.DOTALL)
camera_x = float(camera_match.group(1))
camera_y = float(camera_match.group(2))

# Extract reference lines
ground_match = re.search(r'\[node name="GroundReference".*?points = PackedVector2Array\([\d.]+, ([\d.]+)', content, re.DOTALL)
horizon_match = re.search(r'\[node name="HorizonReference".*?points = PackedVector2Array\([\d.]+, ([\d.]+)', content, re.DOTALL)

ground_y = float(ground_match.group(1))
horizon_y = float(horizon_match.group(1))

# Collect all scale-y pairs for regression
scale_y_pairs = []
for category in ['far', 'mid', 'front', 'ground']:
    for asset_name, data in assets[category].items():
        scale_y_pairs.append((data['scale'], data['y']))

# Sort by scale for analysis
scale_y_pairs.sort()

# Perform quadratic regression: y = a + b*scale + c*scale²
scales = np.array([p[0] for p in scale_y_pairs])
y_values = np.array([p[1] for p in scale_y_pairs])

# Fit quadratic polynomial
coefficients = np.polyfit(scales, y_values, 2)
quad_c = coefficients[0]  # scale² coefficient
quad_b = coefficients[1]  # scale coefficient
quad_a = coefficients[2]  # constant

# Calculate fit quality
y_predicted = quad_a + quad_b * scales + quad_c * scales * scales
residuals = y_values - y_predicted
mae = np.mean(np.abs(residuals))

print("=" * 60)
print("EXTRACTED ASSET DATA FROM PARALLAXSCALINGEDITOR.TSCN")
print("=" * 60)
print(f"\nCamera Position: ({camera_x}, {camera_y})")
print(f"Ground Line: y = {ground_y}")
print(f"Horizon Line: y = {horizon_y}")

print(f"\n{'='*60}")
print("QUADRATIC REGRESSION RESULTS")
print(f"{'='*60}")
print(f"Formula: y = {quad_a:.2f} + ({quad_b:.2f})*scale + ({quad_c:.2f})*scale²")
print(f"Mean Absolute Error: {mae:.2f} pixels")

print(f"\n{'='*60}")
print("ASSET DATA BY LAYER")
print(f"{'='*60}")

for category in ['far', 'mid', 'front', 'ground']:
    if assets[category]:
        print(f"\n{category.upper()} LAYER:")
        for name, data in sorted(assets[category].items(), key=lambda x: x[1]['scale'], reverse=True):
            predicted_y = quad_a + quad_b * data['scale'] + quad_c * data['scale'] * data['scale']
            error = data['y'] - predicted_y
            print(f"  {name:20s} scale={data['scale']:.3f}  y={data['y']:7.2f}  (error: {error:+6.2f}px)")

if 'road' in assets:
    print(f"\nROAD:")
    print(f"  RoadTile             scale={assets['road']['scale']:.3f}  y={assets['road']['y']:7.2f}")

# Create JSON output
output = {
    "formula": {
        "quad_a": round(quad_a, 2),
        "quad_b": round(quad_b, 2),
        "quad_c": round(quad_c, 2),
        "description": f"y = {quad_a:.2f} + ({quad_b:.2f})*scale + ({quad_c:.2f})*scale²",
        "mae": round(mae, 2)
    },
    "camera": {
        "x": camera_x,
        "y": camera_y
    },
    "reference_lines": {
        "ground_y": ground_y,
        "horizon_y": horizon_y
    },
    "assets": assets
}

# Save to JSON
with open('data/parallax_scales.json', 'w') as f:
    json.dump(output, f, indent=2)

print(f"\n{'='*60}")
print("Saved updated data to data/parallax_scales.json")
print(f"{'='*60}")
