#!/usr/bin/env python3
"""Analyze actual colors in damage sprites to understand the color scheme"""

from PIL import Image
import numpy as np

print("=== Analyzing sprite colors ===\n")

for level in [0, 3, 5]:  # Check levels 0, 3, and 5
    print(f"\n--- Damage level {level} ---")

    if level == 0:
        img = Image.open('assets/ui/health/health_damage_0_healthy.webp').convert('RGBA')
    else:
        img = Image.open(f'assets/ui/health/health_damage_{level if level < 5 else "5_critical"}.webp').convert('RGBA')

    arr = np.array(img)

    # Get pixels with alpha > 0 (visible)
    visible = arr[arr[:, :, 3] > 128]

    if len(visible) == 0:
        print("  No visible pixels!")
        continue

    r = visible[:, 0]
    g = visible[:, 1]
    b = visible[:, 2]

    # Find unique colors (sample)
    unique_colors = np.unique(visible, axis=0)[:20]  # First 20 unique colors

    print(f"  Total visible pixels: {len(visible):,}")
    print(f"  Sample unique colors (R,G,B,A):")
    for color in unique_colors[:10]:
        print(f"    {color}")

    # Statistics
    print(f"\n  RGB ranges:")
    print(f"    R: {r.min()}-{r.max()}, mean={r.mean():.1f}")
    print(f"    G: {g.min()}-{g.max()}, mean={g.mean():.1f}")
    print(f"    B: {b.min()}-{b.max()}, mean={b.mean():.1f}")

    # Brightness distribution
    brightness = (r.astype(float) + g + b) / 3.0
    print(f"    Brightness: {brightness.min():.1f}-{brightness.max():.1f}, mean={brightness.mean():.1f}")

    # Find pixels in different brightness ranges
    very_dark = np.sum(brightness < 50)
    dark = np.sum((brightness >= 50) & (brightness < 100))
    medium = np.sum((brightness >= 100) & (brightness < 150))
    bright = np.sum((brightness >= 150) & (brightness < 200))
    very_bright = np.sum(brightness >= 200)

    print(f"\n  Brightness distribution:")
    print(f"    Very dark (<50): {very_dark/len(visible)*100:.1f}%")
    print(f"    Dark (50-100): {dark/len(visible)*100:.1f}%")
    print(f"    Medium (100-150): {medium/len(visible)*100:.1f}%")
    print(f"    Bright (150-200): {bright/len(visible)*100:.1f}%")
    print(f"    Very bright (200+): {very_bright/len(visible)*100:.1f}%")
