#!/usr/bin/env python3
"""
FULL HEALTH DEGRADATION with BREATHING ANIMATION

Structure:
- TOP layer: Mask (static alpha) - transitions 0→5 every 10 seconds
- MIDDLE layer: Breathing sprites (oscillating)
- BOTTOM layer: Damage sprites (static base)

Timeline:
- 0-10s: Level 0 (all healthy) - 5 lungs breathing
- 10-20s: Level 1 (1 damaged) - 4 lungs breathing
- 20-30s: Level 2 (2 damaged) - 3 lungs breathing
- 30-40s: Level 3 (3 damaged) - 2 lungs breathing
- 40-50s: Level 4 (4 damaged) - 1 lung breathing
- 50-60s: Level 5 (all damaged) - 0 lungs breathing
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
FPS = 30
LEVEL_DURATION = 10  # seconds per damage level
BREATHING_PERIOD = 3.0  # seconds per breath cycle
TOTAL_LEVELS = 6
TOTAL_DURATION = LEVEL_DURATION * TOTAL_LEVELS  # 60 seconds
OUTPUT_VIDEO = "full_health_degradation.webm"

print(f"=== FULL HEALTH DEGRADATION TEST ===")
print(f"Duration: {TOTAL_DURATION}s ({TOTAL_LEVELS} levels × {LEVEL_DURATION}s)")
print(f"Breathing period: {BREATHING_PERIOD}s")
print(f"FPS: {FPS}\n")

# Pre-load all sprites
print("Loading sprites...")
damage_sprites = []
breathing_sprites = []
top_layers = []

for level in range(TOTAL_LEVELS):
    # Damage sprites
    damage_path = f'assets/ui/health/damage/health_damage_{level}.webp'
    damage_sprites.append(Image.open(damage_path).convert('RGBA'))

    # Breathing sprites (MASKED - only show lungs that exist)
    breathing_path = f'assets/ui/health/breathing_masked/health_breathing_{level}_masked.webp'
    breathing_sprites.append(Image.open(breathing_path).convert('RGBA'))

    # Top layer masks
    top_path = f'assets/ui/health/top_layers/top_layer_damage_{level}.webp'
    top_layers.append(Image.open(top_path).convert('RGBA'))

print(f"✓ Loaded {TOTAL_LEVELS} damage sprites")
print(f"✓ Loaded {TOTAL_LEVELS} breathing sprites")
print(f"✓ Loaded {TOTAL_LEVELS} top layer masks\n")

# Create frames
frame_dir = "/tmp/full_health_frames"
os.makedirs(frame_dir, exist_ok=True)

total_frames = FPS * TOTAL_DURATION

print("Generating frames...")
for frame_num in range(total_frames):
    t = frame_num / FPS

    # Determine current damage level based on time
    current_level = int(t / LEVEL_DURATION)
    if current_level >= TOTAL_LEVELS:
        current_level = TOTAL_LEVELS - 1

    level_start_time = current_level * LEVEL_DURATION
    time_in_level = t - level_start_time

    # Calculate breathing alpha (sinusoidal 0 to 0.6)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0
    alpha = alpha * 0.6

    # === BUILD 3-LAYER SANDWICH ===

    # BOTTOM: Static damage sprite
    composite = damage_sprites[current_level].copy()

    # MIDDLE: Breathing sprite with oscillating alpha
    middle = breathing_sprites[current_level].copy()
    middle_array = np.array(middle)
    middle_array[:, :, 3] = (middle_array[:, :, 3] * alpha).astype(np.uint8)
    middle = Image.fromarray(middle_array)

    composite = Image.alpha_composite(composite, middle)

    # TOP: Mask with holes (static alpha)
    composite = Image.alpha_composite(composite, top_layers[current_level])

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

    # Progress bar with color coding
    progress = t / TOTAL_DURATION
    progress_width = int(bar_width * progress)

    # Color based on health level
    if current_level == 0:
        bar_color = (0, 255, 0)  # Green - healthy
    elif current_level <= 2:
        bar_color = (255, 255, 0)  # Yellow - moderate
    elif current_level <= 4:
        bar_color = (255, 165, 0)  # Orange - critical
    else:
        bar_color = (255, 0, 0)  # Red - dead

    draw.rectangle([bar_x, bar_y, bar_x + progress_width, bar_y + bar_height], fill=bar_color)

    # Level markers
    for i in range(TOTAL_LEVELS + 1):
        marker_x = bar_x + int((i / TOTAL_LEVELS) * bar_width)
        draw.line([marker_x, bar_y, marker_x, bar_y + bar_height], fill=(255, 255, 255), width=2)

    # Info text
    info_lines = [
        f"Time: {t:.1f}s / {TOTAL_DURATION}s | Frame {frame_num}/{total_frames}",
        f"Damage Level: {current_level} ({5-current_level} healthy lungs)",
        f"Breathing Alpha: {alpha:.2f} | Period: {BREATHING_PERIOD}s",
        f"Time in level: {time_in_level:.1f}s / {LEVEL_DURATION}s"
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
        print(f"  t={t:.1f}s | Level {current_level} | {5-current_level} lungs breathing | α={alpha:.2f}")

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
print("Video shows full health degradation from 5 healthy lungs to 0")
print("Each level held for 10 seconds with breathing animation")
