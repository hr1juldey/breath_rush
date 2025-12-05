#!/usr/bin/env python3
"""
Invert the damage masks - flip white and black.
White should be where DAMAGED (to hide), Black where HEALTHY (to show).
"""

from PIL import Image
import numpy as np

print("=== Inverting damage masks ===\n")

for level in range(6):
    mask_path = f'assets/ui/health/mask_damage_{level}.webp'

    # Load mask
    mask_img = Image.open(mask_path).convert('RGBA')
    mask_array = np.array(mask_img)

    # Invert RGB channels (keep alpha as is)
    mask_array[:, :, 0] = 255 - mask_array[:, :, 0]  # R
    mask_array[:, :, 1] = 255 - mask_array[:, :, 1]  # G
    mask_array[:, :, 2] = 255 - mask_array[:, :, 2]  # B

    # Create inverted image
    inverted_mask = Image.fromarray(mask_array, mode='RGBA')

    # Save back
    inverted_mask.save(mask_path, 'WEBP', lossless=True, quality=100)
    print(f"✓ Inverted mask_damage_{level}.webp")

print("\n=== Masks inverted ===")
print("Now: White = damaged (hide), Black = healthy (show)")
