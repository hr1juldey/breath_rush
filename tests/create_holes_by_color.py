#!/usr/bin/env python3
"""
Create HOLE masks by COLOR analysis (not comparison).

Analyze the damage sprite directly:
- PINK pixels (healthy lungs) → CUT HOLE (transparent α=0)
- DARK pixels (damaged lungs) → KEEP SOLID (opaque α=255)
"""

from PIL import Image
import numpy as np

print("=== Creating HOLE masks by COLOR analysis ===\n")

for level in range(6):
    print(f"Processing damage level {level}:")

    # Load damage sprite
    if level == 0:
        damage_img = Image.open('assets/ui/health/health_damage_0_healthy.webp').convert('RGBA')
    else:
        damage_img = Image.open(f'assets/ui/health/health_damage_{level if level < 5 else "5_critical"}.webp').convert('RGBA')

    damage_array = np.array(damage_img)

    # Analyze pixel colors to detect healthy (pink) vs damaged (dark)
    # Healthy lungs: PINK color (high R, medium-high G, medium-high B)
    # Damaged lungs: DARK color (low R, low G, low B) or crosshatch pattern

    r = damage_array[:, :, 0].astype(float)
    g = damage_array[:, :, 1].astype(float)
    b = damage_array[:, :, 2].astype(float)
    a = damage_array[:, :, 3]

    # Calculate brightness (grayscale value)
    brightness = (r + g + b) / 3.0

    # Detect pink/healthy pixels:
    # - High brightness (bright, not dark)
    # - Reddish tint (R > G and R > B)
    # - Not too saturated (not pure red)

    is_bright = brightness > 150  # Bright pixels
    is_reddish = (r > g * 0.8) & (r > b * 0.8)  # Reddish tint
    is_visible = a > 128  # Has alpha (visible)

    # Healthy = bright + reddish + visible
    is_healthy = is_bright & is_reddish & is_visible

    # Damaged = NOT healthy (dark or non-reddish)
    is_damaged = ~is_healthy & is_visible

    # Create TOP layer with holes
    top_layer = damage_array.copy()

    # Where HEALTHY (pink) → CUT HOLE (transparent)
    top_layer[is_healthy, :] = [0, 0, 0, 0]  # Fully transparent

    # Where DAMAGED (dark) → KEEP SOLID (opaque, show damage)
    # Already have the damage pixels from original sprite, just ensure alpha is solid
    top_layer[is_damaged, 3] = 255  # Fully opaque

    # Where completely transparent in original → keep transparent
    top_layer[a == 0, :] = [0, 0, 0, 0]

    # Save TOP layer
    top_layer_img = Image.fromarray(top_layer, mode='RGBA')
    output_path = f'assets/ui/health/top_layer_damage_{level}.webp'
    top_layer_img.save(output_path, 'WEBP', lossless=True, quality=100)

    # Calculate statistics
    healthy_percent = (np.sum(is_healthy) / (damage_array.shape[0] * damage_array.shape[1])) * 100
    damaged_percent = (np.sum(is_damaged) / (damage_array.shape[0] * damage_array.shape[1])) * 100
    transparent_percent = (np.sum(a == 0) / (damage_array.shape[0] * damage_array.shape[1])) * 100

    print(f"  Healthy pixels (HOLES): {healthy_percent:.1f}%")
    print(f"  Damaged pixels (SOLID): {damaged_percent:.1f}%")
    print(f"  Background (transparent): {transparent_percent:.1f}%")
    print(f"  Saved: {output_path}\n")

print("=== DONE ===")
print("Top layers created with HOLES where pixels are PINK (healthy)")
print("Damaged (dark) areas remain SOLID")
