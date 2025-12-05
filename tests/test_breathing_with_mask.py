#!/usr/bin/env python3
"""
Complex test: Breathing oscillation WITH damage masking.
- Bottom layer: Oscillating breathing animation (working perfectly)
- Top layer: Damage mask to hide damaged lungs completely
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
DAMAGE_LEVEL = 3  # Test with damage level 3 (2 healthy, 3 damaged)
FPS = 30
DURATION = 6  # Longer duration to see full cycles
BREATHING_PERIOD = 3.0  # Slower breathing (3 seconds per cycle)
OUTPUT_VIDEO = "masked_breathing_test.webm"

print(f"=== Breathing animation WITH masking test ===")
print(f"Damage level: {DAMAGE_LEVEL}")
print(f"Duration: {DURATION}s @ {FPS}fps")
print(f"Breathing period: {BREATHING_PERIOD}s (slower)")
print()

# Load sprites
base_damage = Image.open(f'assets/ui/health/health_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')
breathing_overlay = Image.open(f'assets/ui/health/health_breathing_{DAMAGE_LEVEL}.webp').convert('RGBA')
damage_mask = Image.open(f'assets/ui/health/mask_damage_{DAMAGE_LEVEL}.webp').convert('RGBA')

print(f"Loaded sprites:")
print(f"  Base: health_damage_{DAMAGE_LEVEL}.webp ({base_damage.size})")
print(f"  Breathing: health_breathing_{DAMAGE_LEVEL}.webp ({breathing_overlay.size})")
print(f"  Mask: mask_damage_{DAMAGE_LEVEL}.webp ({damage_mask.size})")
print()

# Analyze mask to understand its values
mask_array = np.array(damage_mask)
mask_r = mask_array[:, :, 0]
unique_values = np.unique(mask_r)
print(f"Mask unique values (R channel): {unique_values[:10]}...")  # Show first 10
mask_white_percent = (np.sum(mask_r > 128) / mask_r.size) * 100
mask_black_percent = (np.sum(mask_r < 128) / mask_r.size) * 100
print(f"Mask composition: {mask_white_percent:.1f}% white, {mask_black_percent:.1f}% black")
print()

# Test both masking approaches
print("Testing TWO masking approaches:")
print("  Approach A: White = show, Black = hide")
print("  Approach B: Black = show, White = hide")
print()

# Create output directory
frame_dir = "/tmp/masked_breathing_frames"
os.makedirs(frame_dir, exist_ok=True)

# Generate frames
total_frames = FPS * DURATION
for frame_num in range(total_frames):
    t = frame_num / FPS

    # Calculate breathing alpha (sinusoidal, 0 to 0.6)
    alpha = (np.sin(t * 2 * np.pi / BREATHING_PERIOD) + 1.0) / 2.0
    alpha = alpha * 0.6

    # === BOTTOM LAYER: Breathing oscillation ===
    composite = base_damage.copy()

    breathing_modulated = breathing_overlay.copy()
    breathing_array = np.array(breathing_modulated)
    breathing_array[:, :, 3] = (breathing_array[:, :, 3] * alpha).astype(np.uint8)
    breathing_modulated = Image.fromarray(breathing_array)

    composite = Image.alpha_composite(composite, breathing_modulated)

    # === Apply mask - create TWO versions for comparison ===
    composite_array = np.array(composite)

    # Approach A: White = show, Black = hide
    composite_A = composite_array.copy()
    mask_alpha_A = mask_r / 255.0  # White (255) = 1.0 = show, Black (0) = 0.0 = hide
    composite_A[:, :, 3] = (composite_A[:, :, 3] * mask_alpha_A).astype(np.uint8)

    # Approach B: Black = show, White = hide (inverted)
    composite_B = composite_array.copy()
    mask_alpha_B = 1.0 - (mask_r / 255.0)  # Black (0) = 1.0 = show, White (255) = 0.0 = hide
    composite_B[:, :, 3] = (composite_B[:, :, 3] * mask_alpha_B).astype(np.uint8)

    # Create split-screen comparison
    img_A = Image.fromarray(composite_A)
    img_B = Image.fromarray(composite_B)

    # Add background
    bg_A = Image.new('RGBA', img_A.size, (60, 60, 60, 255))
    bg_B = Image.new('RGBA', img_B.size, (60, 60, 60, 255))

    final_A = Image.alpha_composite(bg_A, img_A)
    final_B = Image.alpha_composite(bg_B, img_B)

    # Create side-by-side comparison
    width, height = final_A.size
    comparison = Image.new('RGB', (width * 2 + 20, height + 80), (30, 30, 30))

    comparison.paste(final_A.convert('RGB'), (0, 60))
    comparison.paste(final_B.convert('RGB'), (width + 20, 60))

    # Add labels
    draw = ImageDraw.Draw(comparison)
    draw.text((10, 10), f"Frame {frame_num}/{total_frames} | t={t:.2f}s | alpha={alpha:.2f} | Period={BREATHING_PERIOD}s",
              fill=(255, 255, 255))
    draw.text((10, 35), "Approach A: White=show, Black=hide", fill=(255, 255, 0))
    draw.text((width + 30, 35), "Approach B: Black=show, White=hide", fill=(0, 255, 255))

    # Save frame
    frame_path = f"{frame_dir}/frame_{frame_num:04d}.png"
    comparison.save(frame_path)

    if frame_num % 30 == 0:
        print(f"  Frame {frame_num}/{total_frames} (t={t:.2f}s, alpha={alpha:.3f})")

print(f"\n=== Generated {total_frames} frames ===")

# Create video
print(f"\nCreating comparison video: {OUTPUT_VIDEO}")
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
    file_size = os.path.getsize(OUTPUT_VIDEO)
    print(f"  File size: {file_size / 1024:.1f} KB")

    subprocess.run(['rm', '-rf', frame_dir])
    print(f"  Cleaned up frames")
else:
    print(f"✗ Error:")
    print(result.stderr)

print("\n=== Test complete ===")
print("The video shows BOTH approaches side-by-side:")
print("  LEFT: White in mask = show, Black = hide")
print("  RIGHT: Black in mask = show, White = hide")
print()
print("Check which side is correct:")
print("  - Only 2 healthy lungs should breathe")
print("  - 3 damaged lungs should be completely hidden")
