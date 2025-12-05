#!/usr/bin/env python3
"""Sample RGB values from different areas in damage sprite"""

from PIL import Image
import numpy as np

print("=== Sampling colors from damage_3 ===\n")

damage = Image.open('assets/ui/health/damage/health_damage_3.webp').convert('RGBA')
arr = np.array(damage)

height, width = arr.shape[:2]

# Sample from 5 lung positions (divide width into 5 sections)
lung_width = width // 5

areas = [
    ("Lung 1 (healthy pink)", lung_width * 0 + lung_width//2, height//2),
    ("Lung 2 (healthy pink)", lung_width * 1 + lung_width//2, height//2),
    ("Lung 3 (damaged dark)", lung_width * 2 + lung_width//2, height//2),
    ("Lung 4 (GONE/beige)", lung_width * 3 + lung_width//2, height//2),
    ("Lung 5 (GONE/beige)", lung_width * 4 + lung_width//2, height//2),
]

for name, x, y in areas:
    x, y = int(x), int(y)

    # Sample 10x10 area around this point
    sample = arr[y-5:y+5, x-5:x+5]

    r_mean = sample[:, :, 0].mean()
    g_mean = sample[:, :, 1].mean()
    b_mean = sample[:, :, 2].mean()
    a_mean = sample[:, :, 3].mean()

    print(f"{name} at ({x}, {y}):")
    print(f"  RGB: ({r_mean:.1f}, {g_mean:.1f}, {b_mean:.1f})")
    print(f"  Alpha: {a_mean:.1f}")
    print()
