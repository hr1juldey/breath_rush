#!/usr/bin/env python3
"""
Create HOLE masks for 3-layer sandwich system.
TOP layer: damage sprite with HOLES cut where healthy lungs are (transparent)
MIDDLE layer: breathing sprite (oscillating)
BOTTOM layer: damage sprite (static)

Healthy areas = TRANSPARENT (alpha=0) = hole to see breathing
Damaged areas = OPAQUE (alpha=255) = solid overlay
"""

from PIL import Image
import numpy as np

print("=== Creating HOLE masks (inverted logic) ===\n")

# Load healthy reference
healthy_ref = Image.open('assets/ui/health/health_damage_0_healthy.webp').convert('RGBA')
healthy_array = np.array(healthy_ref)

for level in range(6):
    print(f"Processing damage level {level}:")

    # Load damage sprite
    if level == 0:
        damage_img = healthy_ref.copy()
    else:
        damage_img = Image.open(f'assets/ui/health/health_damage_{level if level < 5 else "5_critical"}.webp').convert('RGBA')

    damage_array = np.array(damage_img)

    # Create hole mask
    # Where pixels MATCH healthy reference = TRANSPARENT (hole)
    # Where pixels DIFFER = OPAQUE (solid overlay)

    diff = np.abs(healthy_array[:, :, :3].astype(float) - damage_array[:, :, :3].astype(float))
    diff_magnitude = np.sum(diff, axis=2)

    threshold = 50
    is_damaged = diff_magnitude > threshold  # True where damaged

    # Create mask for TOP layer of sandwich:
    # Damaged areas = OPAQUE (alpha=255) to cover breathing
    # Healthy areas = TRANSPARENT (alpha=0) to show breathing through hole

    top_layer_mask = np.zeros((damage_array.shape[0], damage_array.shape[1]), dtype=np.uint8)
    top_layer_mask[is_damaged] = 255  # Damaged = opaque
    top_layer_mask[~is_damaged] = 0   # Healthy = transparent (HOLE)

    # Apply mask to damage sprite to create TOP layer with holes
    top_layer = damage_array.copy()
    top_layer[:, :, 3] = top_layer_mask  # Replace alpha with hole mask

    # Where hole (healthy), make completely transparent
    top_layer[~is_damaged, :] = [0, 0, 0, 0]  # RGBA all zero = transparent

    # Save the TOP layer with holes
    top_layer_img = Image.fromarray(top_layer, mode='RGBA')
    output_path = f'assets/ui/health/top_layer_damage_{level}.webp'
    top_layer_img.save(output_path, 'WEBP', lossless=True, quality=100)

    hole_percent = (np.sum(~is_damaged) / is_damaged.size) * 100
    solid_percent = (np.sum(is_damaged) / is_damaged.size) * 100

    print(f"  Holes (healthy): {hole_percent:.1f}%")
    print(f"  Solid (damaged): {solid_percent:.1f}%")
    print(f"  Saved: {output_path}\n")

print("=== HOLE masks created ===")
print("Top layers now have HOLES where healthy lungs are!")
print("Breathing animation will show through the holes.")
