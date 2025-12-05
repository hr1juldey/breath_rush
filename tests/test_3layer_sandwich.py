#!/usr/bin/env python3
"""
3-LAYER SANDWICH TEST

TOP:    damage sprite with HOLES (transparent where healthy)
MIDDLE: breathing sprite (oscillating alpha 0-0.6)
BOTTOM: damage sprite (static)

Result: Breathing shows through holes, damaged areas show solid
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
DAMAGE_LEVEL = 5  # Test with level 5 as user requested
FPS = 30
DURATION = 6
BREATHING_PERIOD = 3.0
OUTPUT_VIDEO = "sandwich_3layer_test.webm"

print(f"=== 3-LAYER SANDWICH TEST ===")
print(f"Damage level: {DAMAGE_LEVEL}")
print(f"Duration: {DURATION}s, Period: {BREATHING_PERIOD}s\n")

# Load layers
bottom_layer = Image.open(f'assets/ui/health/health_damage_{DAMAGE_LEVEL if DAMAGE_LEVEL < 5 else "5_critical"}.webp').convert('RGBA')
middle_layer = Image.open(f'assets/ui/health/health_breathing_{DAMAGE_LEVEL}.webp').convert('RGBA')
top_layer = Image.open(f'assets/ui/health/top_layer_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')

print(f"Loaded 3 layers:")
print(f"  BOTTOM (static): health_damage_{DAMAGE_LEVEL if DAMAGE_LEVEL < 5 else '5_critical'}.webp")
print(f"  MIDDLE (oscillating): health_breathing_{DAMAGE_LEVEL}.webp")
print(f"  TOP (with holes): top_layer_damage_{DAMAGE_LEVEL}.webp\n")

# Analyze top layer holes
top_array = np.array(top_layer)
transparent_pixels = np.sum(top_array[:, :, 3] == 0)
total_pixels = top_array.shape[0] * top_array.shape[1]
hole_percent = (transparent_pixels / total_pixels) * 100
print(f"Top layer: {hole_percent:.1f}% transparent (holes)")
print(f"Through holes, breathing animation will be visible\n")

# Create frames
frame_dir = "/tmp/sandwich_frames"
os.makedirs(frame_dir, exist_ok=True)

total_frames = FPS * DURATION
for frame_num in range(total_frames):
    t = frame_num / FPS

    # Calculate breathing alpha (sinusoidal 0 to 0.6)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0
    alpha = alpha * 0.6

    # === BUILD THE SANDWICH ===

    # 1. Start with BOTTOM layer (static)
    composite = bottom_layer.copy()

    # 2. Add MIDDLE layer (breathing with oscillating alpha)
    middle_modulated = middle_layer.copy()
    middle_array = np.array(middle_modulated)
    middle_array[:, :, 3] = (middle_array[:, :, 3] * alpha).astype(np.uint8)
    middle_modulated = Image.fromarray(middle_array)

    composite = Image.alpha_composite(composite, middle_modulated)

    # 3. Add TOP layer (with holes)
    composite = Image.alpha_composite(composite, top_layer)

    # Add background
    background = Image.new('RGBA', composite.size, (60, 60, 60, 255))
    final_frame = Image.alpha_composite(background, composite)

    # Add info
    draw = ImageDraw.Draw(final_frame)
    info_text = f"Frame {frame_num}/{total_frames} | t={t:.2f}s | breathing_alpha={alpha:.2f}"
    draw.text((10, 10), info_text, fill=(255, 255, 255))
    layer_text = f"3-LAYER: BOTTOM(static) + MIDDLE(breath α={alpha:.2f}) + TOP(holes)"
    draw.text((10, 30), layer_text, fill=(255, 255, 0))

    # Save
    frame_path = f"{frame_dir}/frame_{frame_num:04d}.png"
    final_frame.convert('RGB').save(frame_path)

    if frame_num % 30 == 0:
        print(f"  Frame {frame_num}/{total_frames} (alpha={alpha:.3f})")

print(f"\n=== Generated {total_frames} frames ===")

# Create video
print(f"\nCreating video: {OUTPUT_VIDEO}")
ffmpeg_cmd = [
    'ffmpeg', '-y',
    '-framerate', str(FPS),
    '-i', f'{frame_dir}/frame_%04d.png',
    '-c:v', 'libvpx-vp9',
    '-pix_fmt', 'yuv420p',
    '-b:v', '2M',
    OUTPUT_VIDEO
]

result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)

if result.returncode == 0:
    print(f"✓ Video created: {OUTPUT_VIDEO}")
    print(f"  File size: {os.path.getsize(OUTPUT_VIDEO) / 1024:.1f} KB")
    subprocess.run(['rm', '-rf', frame_dir])
    print(f"  Cleaned up frames")
else:
    print(f"✗ Error:")
    print(result.stderr)

print("\n=== 3-LAYER SANDWICH TEST COMPLETE ===")
print("Check: Only healthy lungs should breathe through holes in top layer")
