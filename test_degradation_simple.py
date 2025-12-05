#!/usr/bin/env python3
"""
Health degradation 5→1 using SIMPLE 2-layer approach.

Based on the working simple_breathing_masked test.
No 3-layer complexity - just damage + masked breathing oscillation.

Timeline (60 seconds):
- 0-10s:  Level 0 (5 lungs healthy)
- 10-20s: Level 1 (4 healthy, 1 damaged)
- 20-30s: Level 2 (3 healthy, 2 damaged)
- 30-40s: Level 3 (2 healthy, 3 damaged)
- 40-50s: Level 4 (1 healthy, 4 damaged)
- 50-60s: Level 5 (all damaged/critical)
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
FPS = 30
LEVEL_DURATION = 10  # seconds per level
BREATHING_PERIOD = 3.0  # seconds per breath cycle
TOTAL_LEVELS = 6  # Levels 0-5 (5 healthy down to all damaged)
TOTAL_DURATION = LEVEL_DURATION * TOTAL_LEVELS  # 60 seconds
OUTPUT_VIDEO = "degradation_simple_5to1.webm"

print(f"=== SIMPLE DEGRADATION 5→1 ===")
print(f"Using simple 2-layer approach (damage + masked breathing)")
print(f"Duration: {TOTAL_DURATION}s ({TOTAL_LEVELS} levels × {LEVEL_DURATION}s)")
print(f"Breathing period: {BREATHING_PERIOD}s\n")

# Pre-load sprites
print("Loading sprites...")
damage_sprites = []
breathing_masked_sprites = []

for level in range(TOTAL_LEVELS):
    # Damage sprites
    damage_path = f'assets/ui/health/damage/health_damage_{level}.webp'
    damage_sprites.append(Image.open(damage_path).convert('RGBA'))

    # Masked breathing sprites
    breathing_path = f'assets/ui/health/breathing_masked/health_breathing_{level}_masked.webp'
    breathing_masked_sprites.append(Image.open(breathing_path).convert('RGBA'))

print(f"✓ Loaded {TOTAL_LEVELS} damage sprites")
print(f"✓ Loaded {TOTAL_LEVELS} masked breathing sprites\n")

# Create frames
frame_dir = "/tmp/degradation_simple_frames"
os.makedirs(frame_dir, exist_ok=True)

total_frames = FPS * TOTAL_DURATION

print("Generating frames...")
for frame_num in range(total_frames):
    t = frame_num / FPS

    # Determine current level
    current_level = int(t / LEVEL_DURATION)
    if current_level >= TOTAL_LEVELS:
        current_level = TOTAL_LEVELS - 1

    level_start_time = current_level * LEVEL_DURATION
    time_in_level = t - level_start_time

    # Calculate breathing alpha (continuous sinusoidal)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0
    alpha = alpha * 0.6

    # === SIMPLE 2-LAYER OSCILLATION ===
    # BOTTOM: Damage sprite (static)
    composite = damage_sprites[current_level].copy()

    # TOP: Masked breathing sprite (oscillating alpha)
    breathing_modulated = breathing_masked_sprites[current_level].copy()
    breathing_array = np.array(breathing_modulated)
    breathing_array[:, :, 3] = (breathing_array[:, :, 3] * alpha).astype(np.uint8)
    breathing_modulated = Image.fromarray(breathing_array)

    composite = Image.alpha_composite(composite, breathing_modulated)

    # Add background
    background = Image.new('RGBA', composite.size, (60, 60, 60, 255))
    final_frame = Image.alpha_composite(background, composite)

    # Add info overlay
    draw = ImageDraw.Draw(final_frame)

    # Timeline bar
    bar_width = 500
    bar_height = 20
    bar_x = 20
    bar_y = 120

    # Background bar
    draw.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + bar_height], fill=(40, 40, 40))

    # Progress bar
    progress = t / TOTAL_DURATION
    progress_width = int(bar_width * progress)

    # Color based on health level
    if current_level == 0:
        bar_color = (0, 255, 0)  # Green
    elif current_level <= 2:
        bar_color = (255, 255, 0)  # Yellow
    else:
        bar_color = (255, 165, 0)  # Orange

    draw.rectangle([bar_x, bar_y, bar_x + progress_width, bar_y + bar_height], fill=bar_color)

    # Level markers
    for i in range(TOTAL_LEVELS + 1):
        marker_x = bar_x + int((i / TOTAL_LEVELS) * bar_width)
        draw.line([marker_x, bar_y, marker_x, bar_y + bar_height], fill=(255, 255, 255), width=2)

    # Info text
    healthy_count = max(0, 5 - current_level)
    damaged_count = min(5, current_level)
    status = f"{healthy_count} healthy, {damaged_count} damaged" if current_level < 5 else "All damaged/critical"

    info_lines = [
        f"Time: {t:.1f}s / {TOTAL_DURATION}s | Frame {frame_num}/{total_frames}",
        f"Level {current_level}: {status}",
        f"Breathing α: {alpha:.2f} | Period: {BREATHING_PERIOD}s",
        f"SIMPLE 2-layer: damage_{current_level} + breathing_{current_level}_masked"
    ]

    y_offset = 10
    for line in info_lines:
        draw.text((10, y_offset), line, fill=(255, 255, 255))
        y_offset += 20

    # Save frame
    frame_path = f"{frame_dir}/frame_{frame_num:04d}.png"
    final_frame.convert('RGB').save(frame_path)

    # Progress logging
    if frame_num % (FPS * 5) == 0:  # Every 5 seconds
        print(f"  t={t:.1f}s | Level {current_level} | {status} | α={alpha:.2f}")

print(f"\n✓ Generated {total_frames} frames\n")

# Create video
print(f"Creating video: {OUTPUT_VIDEO}")
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
    print(f"\n✓ Video created: {OUTPUT_VIDEO}")
    file_size = os.path.getsize(OUTPUT_VIDEO)
    print(f"  File size: {file_size / 1024:.1f} KB")

    subprocess.run(['rm', '-rf', frame_dir])
    print(f"  Cleaned up frames")
else:
    print(f"\n✗ Error:")
    print(result.stderr)

print("\n=== COMPLETE ===")
print("Video shows full health degradation (5 healthy → all damaged)")
print("Each level held for 10 seconds with continuous breathing animation")
