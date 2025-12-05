#!/usr/bin/env python3
"""
Create test video of breathing animation with damage mask applied.
This verifies the mask extraction is working correctly.
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
DAMAGE_LEVEL = 3  # Test with damage level 3 (2 healthy, 3 damaged)
FPS = 30
DURATION = 4  # seconds
BREATHING_PERIOD = 2.0  # seconds per breath cycle
OUTPUT_VIDEO = "breathing_test.webm"

print(f"=== Creating breathing animation test video ===")
print(f"Damage level: {DAMAGE_LEVEL}")
print(f"Duration: {DURATION}s @ {FPS} fps = {DURATION * FPS} frames")
print(f"Breathing period: {BREATHING_PERIOD}s")

# Load sprites
base_damage = Image.open(f'assets/ui/health/health_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')
breathing_overlay = Image.open(f'assets/ui/health/health_breathing_{DAMAGE_LEVEL}.webp').convert('RGBA')
damage_mask = Image.open(f'assets/ui/health/mask_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')

print(f"\nLoaded sprites:")
print(f"  Base damage: {base_damage.size}")
print(f"  Breathing overlay: {breathing_overlay.size}")
print(f"  Damage mask: {damage_mask.size}")

# Create output directory for frames
frame_dir = "/tmp/breathing_frames"
os.makedirs(frame_dir, exist_ok=True)

# Generate frames
total_frames = FPS * DURATION
for frame_num in range(total_frames):
    # Calculate time
    t = frame_num / FPS

    # Calculate breathing alpha using sine wave (0 to 1)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0

    # Scale to 0-0.6 range (same as Godot implementation)
    alpha = alpha * 0.6

    # Create composite image
    # Start with base damage layer
    composite = base_damage.copy()

    # Create breathing overlay with modulated alpha
    breathing_modulated = breathing_overlay.copy()
    breathing_array = np.array(breathing_modulated)
    breathing_array[:, :, 3] = (breathing_array[:, :, 3] * alpha).astype(np.uint8)
    breathing_modulated = Image.fromarray(breathing_array)

    # Composite breathing on top of base
    composite = Image.alpha_composite(composite, breathing_modulated)

    # Apply damage mask
    # Method 1: Use mask as alpha
    composite_array = np.array(composite)
    mask_array = np.array(damage_mask)

    # Where mask is white (255) = keep, where black (0) = hide
    # Multiply the alpha channel by the mask
    mask_alpha = mask_array[:, :, 0] / 255.0  # Use R channel as mask (grayscale)
    composite_array[:, :, 3] = (composite_array[:, :, 3] * mask_alpha).astype(np.uint8)

    composite_masked = Image.fromarray(composite_array)

    # Add background for visibility
    background = Image.new('RGBA', composite_masked.size, (60, 60, 60, 255))
    final_frame = Image.alpha_composite(background, composite_masked)

    # Add frame info text
    draw = ImageDraw.Draw(final_frame)
    info_text = f"Frame {frame_num}/{total_frames} | t={t:.2f}s | alpha={alpha:.2f} | Damage Level {DAMAGE_LEVEL}"
    draw.text((10, 10), info_text, fill=(255, 255, 255, 255))

    # Save frame
    frame_path = f"{frame_dir}/frame_{frame_num:04d}.png"
    final_frame.convert('RGB').save(frame_path)

    if frame_num % 30 == 0:
        print(f"  Generated frame {frame_num}/{total_frames} (alpha={alpha:.3f})")

print(f"\n=== Generated {total_frames} frames ===")

# Create video using ffmpeg
print(f"\nCreating video: {OUTPUT_VIDEO}")
ffmpeg_cmd = [
    'ffmpeg', '-y',
    '-framerate', str(FPS),
    '-i', f'{frame_dir}/frame_%04d.png',
    '-c:v', 'libvpx-vp9',
    '-pix_fmt', 'yuva420p',
    '-b:v', '1M',
    OUTPUT_VIDEO
]

result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)

if result.returncode == 0:
    print(f"✓ Video created successfully: {OUTPUT_VIDEO}")

    # Get file size
    file_size = os.path.getsize(OUTPUT_VIDEO)
    print(f"  File size: {file_size / 1024:.1f} KB")

    # Clean up frames
    subprocess.run(['rm', '-rf', frame_dir])
    print(f"  Cleaned up temporary frames")
else:
    print(f"✗ Error creating video:")
    print(result.stderr)

print("\n=== Test video complete ===")
print("Check the video to verify:")
print("1. Breathing animation is smooth (sinusoidal)")
print("2. Only healthy lungs are visible")
print("3. Damaged lungs are properly occluded")
print("4. If reversed, we need to flip the mask")
