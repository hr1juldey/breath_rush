#!/usr/bin/env python3
"""
Create MASKED breathing sprites.

For each damage level:
- Take the breathing sprite (shows all 5 lungs)
- Mask it using the damage sprite's alpha channel
- Where damage sprite is transparent (gone lungs) → breathing is transparent
- Where damage sprite has content → breathing stays visible
"""

from PIL import Image
import numpy as np
import os

print("=== Creating MASKED breathing sprites ===\n")

# Create output directory
os.makedirs('assets/ui/health/breathing_masked', exist_ok=True)

for level in range(6):
    print(f"Processing level {level}:")

    # Load sprites
    damage_path = f'assets/ui/health/damage/health_damage_{level}.webp'
    breathing_path = f'assets/ui/health/breathing/health_breathing_{level}.webp'

    damage = Image.open(damage_path).convert('RGBA')
    breathing = Image.open(breathing_path).convert('RGBA')

    # Convert to arrays
    damage_array = np.array(damage)
    breathing_array = np.array(breathing)

    # Extract alpha channels
    damage_alpha = damage_array[:, :, 3]
    breathing_alpha = breathing_array[:, :, 3]

    # Create masked breathing sprite
    # Use damage sprite's alpha as mask
    # Where damage is transparent (α=0) → breathing should be transparent
    # Where damage has content (α>0) → breathing keeps its content

    masked_breathing = breathing_array.copy()

    # Apply damage alpha as mask
    # Only show breathing where damage sprite has content
    masked_breathing[:, :, 3] = np.minimum(breathing_alpha, damage_alpha)

    # Where damage is transparent, make breathing fully transparent
    masked_breathing[damage_alpha == 0] = [0, 0, 0, 0]

    # Create image
    masked_breathing_img = Image.fromarray(masked_breathing, mode='RGBA')

    # Save
    output_path = f'assets/ui/health/breathing_masked/health_breathing_{level}_masked.webp'
    masked_breathing_img.save(output_path, 'WEBP', lossless=True, quality=100)

    # Stats
    original_pixels = np.sum(breathing_alpha > 0)
    masked_pixels = np.sum(masked_breathing[:, :, 3] > 0)
    removed_percent = ((original_pixels - masked_pixels) / original_pixels * 100) if original_pixels > 0 else 0

    print(f"  Original breathing pixels: {original_pixels:,}")
    print(f"  Masked breathing pixels: {masked_pixels:,}")
    print(f"  Removed: {removed_percent:.1f}%")
    print(f"  Saved: {output_path}\n")

print("=== DONE ===")
print("Masked breathing sprites created!")
print("Now breathing sprites only show lungs that exist at each damage level")
