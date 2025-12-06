#!/usr/bin/env python3
"""Recalculate offsets accounting for camera y offset"""

# Camera base position
camera_base_y = 180.415
camera_offset_y = -80.915
actual_camera_y = camera_base_y + camera_offset_y  # ≈ 99.5

road_y = 420
horizon_y = 200

print("="*80)
print("RECALCULATING WITH ACTUAL CAMERA OFFSET")
print("="*80)
print(f"\nCamera base Y: {camera_base_y}")
print(f"Camera Y offset: {camera_offset_y}")
print(f"Actual camera Y: {actual_camera_y:.2f}")
print(f"Road Y: {road_y}")
print(f"Horizon Y: {horizon_y}")

# Viewport height is typically 360 pixels (for a 960x360 or similar resolution)
# With camera at y=99.5, viewport shows:
viewport_top = actual_camera_y - 180  # approximately -80
viewport_bottom = actual_camera_y + 180  # approximately 280

print(f"\nViewport visible range:")
print(f"  Top: {viewport_top:.2f}")
print(f"  Bottom: {viewport_bottom:.2f}")
print(f"\nRoad at y={road_y} is {'BELOW' if road_y > viewport_bottom else 'VISIBLE IN'} viewport")

# With camera at y≈99.5, the road at y=420 is way below the viewport
# Objects should appear in the viewport range (-80 to 280)
# For proper parallax:
# - Far objects: near top of viewport (y ≈ 50-100)
# - Mid objects: middle of viewport (y ≈ 150-200)
# - Front objects: lower viewport (y ≈ 220-260)

print(f"\n{'='*80}")
print("TARGET Y POSITIONS FOR PROPER PARALLAX:")
print(f"{'='*80}")
print(f"Far layer:   y ≈ 50-100   (near top of viewport)")
print(f"Mid layer:   y ≈ 150-200  (middle of viewport)")
print(f"Front layer: y ≈ 220-260  (lower viewport, near visible road horizon)")

# Formula constants
quad_a = 428.08
quad_b = -469.51
quad_c = 128.64

# Sample calculations for typical scales
print(f"\n{'='*80}")
print("OFFSET CALCULATIONS:")
print(f"{'='*80}")

# Far layer (scale ≈ 1.0)
far_scale = 1.0
far_formula_y = quad_a + quad_b * far_scale + quad_c * far_scale * far_scale
far_target_y = 75
far_offset = far_target_y - far_formula_y
print(f"\nFar layer (scale={far_scale}):")
print(f"  Formula Y: {far_formula_y:.2f}")
print(f"  Target Y: {far_target_y}")
print(f"  Offset needed: {far_offset:+.2f}")

# Mid layer (scale ≈ 0.4)
mid_scale = 0.4
mid_formula_y = quad_a + quad_b * mid_scale + quad_c * mid_scale * mid_scale
mid_target_y = 175
mid_offset = mid_target_y - mid_formula_y
print(f"\nMid layer (scale={mid_scale}):")
print(f"  Formula Y: {mid_formula_y:.2f}")
print(f"  Target Y: {mid_target_y}")
print(f"  Offset needed: {mid_offset:+.2f}")

# Front layer (scale ≈ 0.2)
front_scale = 0.2
front_formula_y = quad_a + quad_b * front_scale + quad_c * front_scale * front_scale
front_target_y = 240
front_offset = front_target_y - front_formula_y
print(f"\nFront layer (scale={front_scale}):")
print(f"  Formula Y: {front_formula_y:.2f}")
print(f"  Target Y: {front_target_y}")
print(f"  Offset needed: {front_offset:+.2f}")

print(f"\n{'='*80}")
print("RECOMMENDED LAYER OFFSETS:")
print(f"{'='*80}")
print(f"FarLayerSpawner:   layer_y_offset = {far_offset:.2f}")
print(f"MidLayerSpawner:   layer_y_offset = {mid_offset:.2f}")
print(f"FrontLayerSpawner: layer_y_offset = {front_offset:.2f}")
print(f"\nglobal_y_offset: 0.0 (adjust this to move all layers together)")
print("="*80)
