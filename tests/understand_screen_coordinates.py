#!/usr/bin/env python3
"""Understand the screen coordinate system for parallax positioning"""

# Camera setup
camera_y = 180.415
viewport_height = 360  # Typical Godot 2D viewport (can be 270, 360, 540, etc.)

# Calculate visible screen range in world coordinates
viewport_half_height = viewport_height / 2
screen_top_world = camera_y - viewport_half_height
screen_bottom_world = camera_y + viewport_half_height

print("="*80)
print("SCREEN COORDINATE ANALYSIS")
print("="*80)
print(f"\nCamera Y position: {camera_y}")
print(f"Viewport height: {viewport_height}")
print(f"\nVisible screen range (world coords):")
print(f"  Top: {screen_top_world:.2f}")
print(f"  Center: {camera_y:.2f}")
print(f"  Bottom: {screen_bottom_world:.2f}")

print(f"\n{'='*80}")
print("SCREEN-SPACE COORDINATES (relative to camera)")
print(f"{'='*80}")
print(f"\nFor objects in ParallaxLayers, Y position should be relative to camera:")
print(f"  Top of screen:    y = {-viewport_half_height:.2f} (relative to camera)")
print(f"  Middle of screen: y = 0.0 (camera position)")
print(f"  Bottom of screen: y = {viewport_half_height:.2f}")

print(f"\n{'='*80}")
print("RECOMMENDED Y POSITIONS FOR PARALLAX OBJECTS")
print(f"{'='*80}")

# For a 2.5D game, objects should appear at different heights on screen
# based on their perceived distance

# Sky: at very top
sky_y = -90  # What you already have
print(f"\nSky layer (motion_scale=0.1):")
print(f"  Y position: {sky_y} (top of screen)")

# Far buildings: upper portion of screen (appear on horizon)
far_y_min = -50
far_y_max = 50
print(f"\nFar layer (motion_scale=0.3):")
print(f"  Y position range: {far_y_min} to {far_y_max}")
print(f"  (upper-middle of screen, at horizon)")

# Mid buildings: middle portion
mid_y_min = 50
mid_y_max = 120
print(f"\nMid layer (motion_scale=0.6):")
print(f"  Y position range: {mid_y_min} to {mid_y_max}")
print(f"  (middle of screen)")

# Front objects: lower portion (near ground/road level visible on screen)
front_y_min = 120
front_y_max = 180
print(f"\nFront layer (motion_scale=0.9):")
print(f"  Y position range: {front_y_min} to {front_y_max}")
print(f"  (lower-middle of screen, just above visible road)")

# Road/ground at screen bottom
road_screen_y = viewport_half_height  # Bottom of screen
print(f"\nRoad (no parallax, world object):")
print(f"  Y position: {camera_y + road_screen_y:.2f} (world coords)")
print(f"  Screen position: {road_screen_y:.2f} (bottom of screen)")

print(f"\n{'='*80}")
print("KEY INSIGHT:")
print(f"{'='*80}")
print("\nIn ParallaxLayers, Y positions should be:")
print("  - RELATIVE TO CAMERA CENTER (y=0 means camera height)")
print("  - SCREEN-SPACE (where object appears on screen)")
print("  - NOT world-space absolute positions")
print("\nThe quadratic formula from ParallaxScalingEditor gives world coords.")
print("We need to CONVERT to screen-relative coords for ParallaxLayers!")

print(f"\n{'='*80}")
print("CONVERSION APPROACH:")
print(f"{'='*80}")
print("\n1. ParallaxScalingEditor positions are in world space (y=0 to 458)")
print(f"2. Camera is at y={camera_y}")
print("3. Objects in ParallaxLayers need screen-relative positions")
print("4. Conversion: screen_y = world_y - camera_y")
print("\nExample:")
print(f"  - Building at world y=250")
print(f"  - Screen-relative y = 250 - {camera_y} = {250 - camera_y:.2f}")
print(f"  - This appears {250 - camera_y:.2f}px below camera center")
