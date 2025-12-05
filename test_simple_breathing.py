#!/usr/bin/env python3
"""
Simple test: Just show pair-wise oscillation between damage and breathing sprites.
NO masking - just verify the sinusoidal cross-fade works.
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
DAMAGE_LEVEL = 3  # Test with damage level 3
FPS = 30
DURATION = 4  # seconds
BREATHING_PERIOD = 2.0  # seconds per breath cycle
OUTPUT_VIDEO = "simple_breathing_test.webm"

print(f"=== Simple breathing oscillation test ===")
print(f"Damage level: {DAMAGE_LEVEL}")
print(f"Just oscillating between base and breathing sprites")
print(f"NO masking - pure sinusoidal cross-fade\n")

# Load sprites - just the pair
base_damage = Image.open(f'assets/ui/health/health_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')
breathing_overlay = Image.open(f'assets/ui/health/health_breathing_{DAMAGE_LEVEL}.webp').convert('RGBA')

print(f"Loaded pair:")
print(f"  Base: health_damage_{DAMAGE_LEVEL}.webp")
print(f"  Breathing: health_breathing_{DAMAGE_LEVEL}.webp\n")

# Create output directory for frames
frame_dir = "/tmp/simple_breathing_frames"
os.makedirs(frame_dir, exist_ok=True)

# Generate frames
total_frames = FPS * DURATION
for frame_num in range(total_frames):
    # Calculate time
    t = frame_num / FPS

    # Calculate breathing alpha using sine wave (0 to 1)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0

    # Scale to 0-0.6 range
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

    # Add background for visibility
    background = Image.new('RGBA', composite.size, (60, 60, 60, 255))
    final_frame = Image.alpha_composite(background, composite)

    # Add frame info
    draw = ImageDraw.Draw(final_frame)
    info_text = f"Frame {frame_num}/{total_frames} | t={t:.2f}s | alpha={alpha:.2f}"
    draw.text((10, 10), info_text, fill=(255, 255, 255, 255))

    # Save frame
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
    '-b:v', '1M',
    OUTPUT_VIDEO
]

result = subprocess.run(ffmpeg_cmd, capture_output=True, text=True)

if result.returncode == 0:
    print(f"✓ Video created: {OUTPUT_VIDEO}")
    file_size = os.path.getsize(OUTPUT_VIDEO)
    print(f"  File size: {file_size / 1024:.1f} KB")

    # Clean up
    subprocess.run(['rm', '-rf', frame_dir])
    print(f"  Cleaned up frames")
else:
    print(f"✗ Error:")
    print(result.stderr)

print("\n=== Done ===")
print("This video shows ONLY the oscillation between the two sprites.")
print("Check if the breathing looks smooth and natural.")
