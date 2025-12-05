#!/usr/bin/env python3
"""
Refined HOLE detection: Specifically detect PINK healthy lungs.

Pink lungs: R high, G/B moderate, REDDISH hue (R > G and R > B significantly)
Dark damaged: Low RGB
Beige background: High RGB but neutral (R≈G≈B)
"""

from PIL import Image
import numpy as np

print("=== Creating HOLE masks with PINK detection ===\n")

for level in range(6):
    print(f"Processing damage level {level}:")

    # Load damage sprite
    if level == 0:
        damage_img = Image.open('assets/ui/health/health_damage_0_healthy.webp').convert('RGBA')
    else:
        damage_img = Image.open(f'assets/ui/health/health_damage_{level if level < 5 else "5_critical"}.webp').convert('RGBA')

    damage_array = np.array(damage_img)

    r = damage_array[:, :, 0].astype(float)
    g = damage_array[:, :, 1].astype(float)
    b = damage_array[:, :, 2].astype(float)
    a = damage_array[:, :, 3]

    # Detect PINK healthy lungs:
    # - High R (reddish)
    # - R significantly greater than G and B (not beige/neutral)
    # - Moderate overall brightness (not too dark, not background bright)
    # - Visible (alpha > 0)

    is_reddish = (r > 180) & (r > g + 30) & (r > b + 30)  # R much higher than G/B
    is_pink_range = (r > 180) & (r < 255) & (g > 120) & (g < 200) & (b > 120) & (b < 200)
    is_visible = a > 128

    # Pink = reddish + in pink range + visible
    is_pink_healthy = (is_reddish | is_pink_range) & is_visible

    # NOT pink = everything else that's visible
    is_not_pink = ~is_pink_healthy & is_visible

    # Create TOP layer
    top_layer = damage_array.copy()

    # PINK pixels → CUT HOLE (fully transparent)
    top_layer[is_pink_healthy, :] = [0, 0, 0, 0]

    # NOT pink (damaged + background) → KEEP from original
    # (already has the damage appearance)

    # Completely transparent background → keep transparent
    top_layer[a == 0, :] = [0, 0, 0, 0]

    # Save
    top_layer_img = Image.fromarray(top_layer, mode='RGBA')
    output_path = f'assets/ui/health/top_layer_damage_{level}.webp'
    top_layer_img.save(output_path, 'WEBP', lossless=True, quality=100)

    # Stats
    pink_percent = (np.sum(is_pink_healthy) / (damage_array.shape[0] * damage_array.shape[1])) * 100
    not_pink_percent = (np.sum(is_not_pink) / (damage_array.shape[0] * damage_array.shape[1])) * 100
    transparent_percent = (np.sum(a == 0) / (damage_array.shape[0] * damage_array.shape[1])) * 100

    print(f"  PINK (healthy) - HOLES: {pink_percent:.1f}%")
    print(f"  NOT pink (damaged+bg): {not_pink_percent:.1f}%")
    print(f"  Transparent background: {transparent_percent:.1f}%")
    print(f"  Saved: {output_path}\n")

print("=== DONE ===")
print("Holes cut where PINK (healthy) pixels detected")
