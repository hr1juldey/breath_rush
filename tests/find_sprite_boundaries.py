#!/usr/bin/env python3
"""Find sprite boundaries by detecting alpha=0 separator lines"""

from PIL import Image
import numpy as np
from scipy import ndimage

# Load the image
import sys
filename = sys.argv[1] if len(sys.argv) > 1 else 'assets/ui/charge.webp'
print(f"Analyzing: {filename}\n")
img = Image.open(filename)
img_array = np.array(img)

# Get alpha channel (assuming RGBA)
if img_array.shape[2] == 4:
    alpha = img_array[:, :, 3]
else:
    print("No alpha channel found")
    exit(1)

height, width = alpha.shape

# Create binary mask: True where alpha > 0 (has content)
content_mask = alpha > 0

# Label connected regions (finds all separate sprite blobs)
labeled, num_features = ndimage.label(content_mask)

print(f"Found {num_features} sprite regions\n")

sprite_regions = []
for region_id in range(1, num_features + 1):
    # Find bounding box of this region
    region_pixels = np.where(labeled == region_id)

    if len(region_pixels[0]) == 0:
        continue

    y_min = region_pixels[0].min()
    y_max = region_pixels[0].max()
    x_min = region_pixels[1].min()
    x_max = region_pixels[1].max()

    sprite_width = x_max - x_min + 1
    sprite_height = y_max - y_min + 1

    sprite_regions.append({
        'id': region_id,
        'x': x_min,
        'y': y_min,
        'width': sprite_width,
        'height': sprite_height,
        'x_end': x_max,
        'y_end': y_max
    })

    print(f"Sprite {region_id}:")
    print(f"  Position: x={x_min}, y={y_min}")
    print(f"  Size: {sprite_width}x{sprite_height}")
    print(f"  Bounding box: ({x_min},{y_min}) to ({x_max},{y_max})")
    print(f"  FFmpeg crop: crop={sprite_width}:{sprite_height}:{x_min}:{y_min}")
    print()

# Sort by position (top-to-bottom, left-to-right)
sprite_regions.sort(key=lambda s: (s['y'], s['x']))

print("\n--- Sorted sprite regions (top-to-bottom, left-to-right) ---")
for i, sprite in enumerate(sprite_regions, 1):
    print(f"Sprite {i}: crop={sprite['width']}:{sprite['height']}:{sprite['x']}:{sprite['y']}")