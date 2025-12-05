#!/usr/bin/env python3
"""
Simple breathing test with MASKED breathing sprite.

Based on test_simple_breathing.py but uses masked breathing sprite
to hide the 2 gone lungs on the right.

Shows oscillation between:
- damage_3: 2 healthy pink + 1 damaged dark + 2 gone (beige)
- breathing_3_masked: 2 healthy + 1 damaged + 2 transparent (gone lungs removed)

This should show only the 3 existing lungs breathing, with the nice
crosshatch effect on the damaged lung.
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
DAMAGE_LEVEL = 3  # 2 healthy, 1 damaged, 2 gone
FPS = 30
DURATION = 6  # seconds
BREATHING_PERIOD = 3.0  # seconds per breath cycle
OUTPUT_VIDEO = "simple_breathing_masked_test.webm"

print(f"=== SIMPLE BREATHING TEST (with masking) ===")
print(f"Damage level: {DAMAGE_LEVEL}")
print(f"Using MASKED breathing sprite (gone lungs removed)")
print(f"Duration: {DURATION}s, Period: {BREATHING_PERIOD}s\n")

# Load sprites
base_damage = Image.open(f'assets/ui/health/damage/health_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')
breathing_masked = Image.open(f'assets/ui/health/breathing_masked/health_breathing_{DAMAGE_LEVEL}_masked.webp').convert('RGBA')

print(f"Loaded:")
print(f"  Base: health_damage_{DAMAGE_LEVEL}.webp")
print(f"  Breathing (MASKED): health_breathing_{DAMAGE_LEVEL}_masked.webp\n")

# Create frames
frame_dir = "/tmp/simple_breathing_masked_frames"
os.makedirs(frame_dir, exist_ok=True)

total_frames = FPS * DURATION

print("Generating frames...")
for frame_num in range(total_frames):
    t = frame_num / FPS

    # Calculate breathing alpha (sinusoidal 0 to 0.6)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0
    alpha = alpha * 0.6

    # === SIMPLE 2-LAYER OSCILLATION ===
    # Bottom: damage sprite (static)
    composite = base_damage.copy()

    # Top: breathing sprite (MASKED) with oscillating alpha
    breathing_modulated = breathing_masked.copy()
    breathing_array = np.array(breathing_modulated)
    breathing_array[:, :, 3] = (breathing_array[:, :, 3] * alpha).astype(np.uint8)
    breathing_modulated = Image.fromarray(breathing_array)

    composite = Image.alpha_composite(composite, breathing_modulated)

    # Add background
    background = Image.new('RGBA', composite.size, (60, 60, 60, 255))
    final_frame = Image.alpha_composite(background, composite)

    # Add info
    draw = ImageDraw.Draw(final_frame)
    info_text = f"Frame {frame_num}/{total_frames} | t={t:.2f}s | breathing_alpha={alpha:.2f}"
    draw.text((10, 10), info_text, fill=(255, 255, 255))
    draw.text((10, 30), "2 healthy + 1 damaged breathing | 2 gone (masked out)", fill=(255, 255, 0))

    # Save
    frame_path = f"{frame_dir}/frame_{frame_num:04d}.png"
    final_frame.convert('RGB').save(frame_path)

    if frame_num % 30 == 0:
        print(f"  Frame {frame_num}/{total_frames} (alpha={alpha:.3f})")

print(f"\n✓ Generated {total_frames} frames\n")

# Create video
print(f"Creating video: {OUTPUT_VIDEO}")
ffmpeg_cmd = [
    'ffmpeg', '-y',
    '-framerate', str(FPS),
    '-i', f'{frame_dir}/frame_%04d.png',
    '-c:v', 'libvpx-vp9',
    '-pix_fmt', 'yuv420p',
    '-b:v', '1M',
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

print("\n=== DONE ===")
print("Video shows simple breathing oscillation with masked breathing sprite")
print("Should show:")
print("  ✓ 2 healthy lungs breathing (nice crosshatch effect)")
print("  ✓ 1 damaged lung breathing (crosshatch on damaged tissue)")
print("  ✓ 2 gone lungs - NOTHING (transparent, no breathing leak)")
