#!/usr/bin/env python3
"""
Extract damage masks from health sprites.
Masks show which lungs are damaged (for occlusion).
"""

from PIL import Image
import numpy as np

# Load the fully healthy reference sprite
healthy_ref = Image.open('assets/ui/health/health_damage_0_healthy.webp')
healthy_array = np.array(healthy_ref)

print(f"Reference sprite size: {healthy_ref.size}")
print(f"Reference shape: {healthy_array.shape}")

# Process each damage state
damage_states = [
    ('health_damage_0_healthy.webp', 0),
    ('health_damage_1.webp', 1),
    ('health_damage_2.webp', 2),
    ('health_damage_3.webp', 3),
    ('health_damage_4.webp', 4),
    ('health_damage_5_critical.webp', 5),
]

for filename, level in damage_states:
    print(f"\n=== Processing damage level {level}: {filename} ===")

    # Load damage sprite
    damage_img = Image.open(f'assets/ui/health/{filename}')
    damage_array = np.array(damage_img)

    # Method 1: Create mask based on pixel difference
    # Where pixels differ significantly from healthy = damaged area
    if damage_array.shape[2] == 4:  # RGBA
        # Compare RGB channels
        diff = np.abs(healthy_array[:, :, :3].astype(float) - damage_array[:, :, :3].astype(float))
        diff_magnitude = np.sum(diff, axis=2)  # Sum across RGB channels

        # Create binary mask: True where damaged (pixels differ)
        threshold = 50  # Adjust this threshold as needed
        damaged_mask = diff_magnitude > threshold

        # Invert: we want 1 where healthy, 0 where damaged
        healthy_mask = ~damaged_mask

        # Count damaged pixels
        damaged_pixels = np.sum(damaged_mask)
        total_pixels = damaged_mask.size
        damaged_percent = (damaged_pixels / total_pixels) * 100

        print(f"  Damaged pixels: {damaged_pixels:,} / {total_pixels:,} ({damaged_percent:.2f}%)")

        # Method 2: Create alpha mask from damage sprite
        # Use the alpha channel to identify which parts are visible
        alpha_mask = damage_array[:, :, 3] > 0

        # Combine: healthy mask AND has alpha (visible)
        final_mask = healthy_mask & alpha_mask

        # Create RGBA mask image
        # White (255) where healthy lungs should show, transparent (0) where damaged
        mask_img_array = np.zeros((damage_array.shape[0], damage_array.shape[1], 4), dtype=np.uint8)
        mask_img_array[:, :, 0] = final_mask * 255  # R
        mask_img_array[:, :, 1] = final_mask * 255  # G
        mask_img_array[:, :, 2] = final_mask * 255  # B
        mask_img_array[:, :, 3] = final_mask * 255  # A (fully opaque where healthy)

        # Save mask
        mask_img = Image.fromarray(mask_img_array, mode='RGBA')
        output_path = f'assets/ui/health/mask_damage_{level}.webp'
        mask_img.save(output_path, 'WEBP', lossless=True, quality=100)
        print(f"  Saved mask to: {output_path}")

        # Also create a preview showing what will be visible
        # Apply mask to healthy breathing sprite
        if level > 0:  # Skip for level 0 (no damage)
            preview_array = healthy_array.copy()
            # Where mask is False (damaged), make transparent
            preview_array[:, :, 3] = np.where(final_mask, preview_array[:, :, 3], 0)

            preview_img = Image.fromarray(preview_array, mode='RGBA')
            preview_path = f'assets/ui/health/preview_masked_{level}.webp'
            preview_img.save(preview_path, 'WEBP', lossless=True, quality=100)
            print(f"  Saved preview to: {preview_path}")

print("\n=== Mask extraction complete ===")
print("\nNext steps:")
print("1. Verify masks look correct")
print("2. Use masks in Godot with CanvasItemMaterial and texture masking")
print("3. Bottom layer: oscillating breathing animation")
print("4. Top layer: damage mask to occlude lost lungs")
