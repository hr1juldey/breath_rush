#!/usr/bin/env python3
"""Debug parallax positioning to understand the floating issue"""

import json

# Load the data
with open('data/parallax_scales.json', 'r') as f:
    data = json.load(f)

formula = data['formula']
quad_a = formula['quad_a']
quad_b = formula['quad_b']
quad_c = formula['quad_c']

camera_y = data['camera']['y']
ground_y = data['reference_lines']['ground_y']
road_y = 458  # From updated Main.tscn

print("="*70)
print("PARALLAX POSITIONING DEBUG")
print("="*70)
print(f"\nCamera Y: {camera_y}")
print(f"Ground Reference Y: {ground_y}")
print(f"Road Y (in Main.tscn): {road_y}")
print(f"\nFormula: y = {quad_a} + ({quad_b})*scale + ({quad_c})*scale²")

# Layer offsets
layer_offsets = {
    'far': -23.01,
    'mid': 8.51,
    'front': -8.51
}

global_y_offset = 210.0  # Current global offset

print(f"\n{'='*70}")
print("SPAWNED POSITIONS AT TYPICAL SCALES")
print(f"{'='*70}")
print(f"Global Y Offset: {global_y_offset}")

# Test positions for typical scales in each layer
test_cases = [
    ('Far', 0.35, 'far'),
    ('Mid', 0.30, 'mid'),
    ('Front', 0.25, 'front'),
]

for layer_name, scale, layer_key in test_cases:
    layer_offset = layer_offsets[layer_key]

    # Calculate as done in spawner
    calculated_y = quad_a + quad_b * scale + quad_c * scale * scale
    final_y = calculated_y + layer_offset + global_y_offset

    distance_from_camera = final_y - camera_y
    distance_from_road = final_y - road_y

    print(f"\n{layer_name} Layer (scale={scale}):")
    print(f"  Base formula result: {calculated_y:.2f}")
    print(f"  + Layer offset ({layer_offset:+.2f}): {calculated_y + layer_offset:.2f}")
    print(f"  + Global offset ({global_y_offset:+.2f}): {final_y:.2f}")
    print(f"  Distance from camera ({camera_y}): {distance_from_camera:+.2f}")
    print(f"  Distance from road ({road_y}): {distance_from_road:+.2f}")

    if final_y < camera_y:
        print(f"  ⚠️  ABOVE camera viewport (floating in sky!)")
    elif final_y > road_y:
        print(f"  ⚠️  BELOW road (underground!)")
    else:
        print(f"  ✓ Between camera and road (visible area)")

print(f"\n{'='*70}")
print("DIAGNOSIS:")
print(f"{'='*70}")

# The issue: formula gives positions in ParallaxScalingEditor coords
# But we need positions relative to Main.tscn viewport
print("\nThe formula calculates Y positions from ParallaxScalingEditor.tscn,")
print("where assets were manually positioned between horizon (y=200) and ground (y=420).")
print("\nBut in Main.tscn gameplay:")
print(f"  - Camera is at y={camera_y}")
print(f"  - Road is at y={road_y}")
print(f"  - Visible viewport is roughly y={camera_y - 180} to y={camera_y + 180}")
print("\nCurrent spawned positions are in the SKY (y=200-400 range),")
print("which is ABOVE the camera viewport!")

print(f"\n{'='*70}")
print("SOLUTION:")
print(f"{'='*70}")
print("We need to REMOVE the global_y_offset (currently +210)")
print("and possibly make it NEGATIVE to bring objects into view.")
print("\nRecommended: Set global_y_offset = 0 and test")
print("If still too high, set global_y_offset = -100 or lower")
