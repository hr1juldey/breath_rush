#!/usr/bin/env python3
"""
Create MASKED breathing sprites by COLOR detection.

Detect lung pixels in damage sprite (pink OR dark) vs background (beige).
Mask breathing sprite to only show where lungs exist.
"""

from PIL import Image
import numpy as np
import os

print("=== Creating MASKED breathing by COLOR ===\n")

os.makedirs('assets/ui/health/breathing_masked', exist_ok=True)

for level in range(6):
    print(f"Processing level {level}:")

    # Load sprites
    damage = Image.open(f'assets/ui/health/damage/health_damage_{level}.webp').convert('RGBA')
    breathing = Image.open(f'assets/ui/health/breathing/health_breathing_{level}.webp').convert('RGBA')

    damage_array = np.array(damage)
    breathing_array = np.array(breathing)

    # Detect LUNG pixels in damage sprite (not background/gone)
    # Lungs are either PINK (healthy) or DARK (damaged)
    # Background is BEIGE (high RGB, neutral)

    r = damage_array[:, :, 0].astype(float)
    g = damage_array[:, :, 1].astype(float)
    b = damage_array[:, :, 2].astype(float)
    a = damage_array[:, :, 3]

    # Background/gone areas: beige color RGB(247, 232, 210) ± tolerance
    # Detected from sampling: (247.0, 232.0, 210.0)
    beige_r, beige_g, beige_b = 247, 232, 210
    tolerance = 20

    is_beige = (
        (np.abs(r - beige_r) < tolerance) &
        (np.abs(g - beige_g) < tolerance) &
        (np.abs(b - beige_b) < tolerance)
    )

    # Lung pixels = NOT beige AND visible
    is_lung = ~is_beige & (a > 128)

    # Create masked breathing
    masked_breathing = breathing_array.copy()

    # Where NO lung in damage sprite → make breathing transparent
    masked_breathing[~is_lung] = [0, 0, 0, 0]

    # Save
    masked_img = Image.fromarray(masked_breathing, mode='RGBA')
    output_path = f'assets/ui/health/breathing_masked/health_breathing_{level}_masked.webp'
    masked_img.save(output_path, 'WEBP', lossless=True, quality=100)

    # Stats
    total_pixels = damage_array.shape[0] * damage_array.shape[1]
    lung_pixels = np.sum(is_lung)
    beige_pixels = np.sum(is_beige)
    lung_percent = (lung_pixels / total_pixels) * 100
    beige_percent = (beige_pixels / total_pixels) * 100

    print(f"  Lung pixels (kept): {lung_pixels:,} ({lung_percent:.1f}%)")
    print(f"  Beige/gone (removed): {beige_pixels:,} ({beige_percent:.1f}%)")
    print(f"  Saved: {output_path}\n")

print("=== DONE ===")
print("Breathing sprites now only show where lungs exist!")
