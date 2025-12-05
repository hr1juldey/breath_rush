#!/usr/bin/env python3
"""Check alpha channel in damage sprites"""

from PIL import Image
import numpy as np

for level in [0, 3, 5]:
    print(f"\n=== Damage level {level} ===")

    damage = Image.open(f'assets/ui/health/damage/health_damage_{level}.webp').convert('RGBA')
    arr = np.array(damage)
    alpha = arr[:, :, 3]

    print(f"Alpha channel stats:")
    print(f"  Min: {alpha.min()}")
    print(f"  Max: {alpha.max()}")
    print(f"  Unique values: {len(np.unique(alpha))}")

    # Count pixels by alpha value
    fully_transparent = np.sum(alpha == 0)
    fully_opaque = np.sum(alpha == 255)
    partial = np.sum((alpha > 0) & (alpha < 255))

    total = alpha.size

    print(f"  Fully transparent (α=0): {fully_transparent:,} ({fully_transparent/total*100:.1f}%)")
    print(f"  Fully opaque (α=255): {fully_opaque:,} ({fully_opaque/total*100:.1f}%)")
    print(f"  Partial alpha: {partial:,} ({partial/total*100:.1f}%)")
