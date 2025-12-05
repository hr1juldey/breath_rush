#!/usr/bin/env python3
"""
Battery charge transition animation test - BIDIRECTIONAL

Shows both discharge and charge animations:
- Discharge (5→4→3→2→1→0): Old level blinks and fades out, new level appears below
- Charge (0→1→2→3→4→5): New level appears above and fades in, old level fades out

Timeline (60 seconds total):
- 0-30s: DISCHARGE 5→0 (5 seconds per level transition)
- 30-60s: CHARGE 0→5 (5 seconds per level transition)

Transition Animation:
- Duration: 1.5 seconds per transition
- Phase 1 (0.0-0.5s): Old blinks rapidly (5 blinks), new appears at target position
- Phase 2 (0.5-1.5s): Old fades out, new fades in simultaneously
"""

from PIL import Image, ImageDraw
import numpy as np
import subprocess
import os

# Configuration
FPS = 30
TRANSITION_DURATION = 1.5  # seconds for each level transition
STABLE_DURATION = 3.5  # seconds showing stable level before next transition
LEVEL_DURATION = TRANSITION_DURATION + STABLE_DURATION  # 5 seconds total per level

TOTAL_LEVELS = 7  # 6 charge levels + empty (5, 4, 3, 2, 1, 0_red, empty)
DISCHARGE_DURATION = LEVEL_DURATION * 6  # 30 seconds
CHARGE_DURATION = LEVEL_DURATION * 6  # 30 seconds
TOTAL_DURATION = DISCHARGE_DURATION + CHARGE_DURATION  # 60 seconds

OUTPUT_VIDEO = "battery_transitions_bidirectional.webm"

print(f"=== BATTERY CHARGE TRANSITIONS - BIDIRECTIONAL ===")
print(f"Total duration: {TOTAL_DURATION}s")
print(f"  Discharge phase: 0-{DISCHARGE_DURATION}s (5→0)")
print(f"  Charge phase: {DISCHARGE_DURATION}-{TOTAL_DURATION}s (0→5)")
print(f"Transition duration: {TRANSITION_DURATION}s per level")
print(f"Stable duration: {STABLE_DURATION}s per level\n")

# Load battery sprites
print("Loading battery sprites...")
CHARGE_SPRITES = [
    'assets/ui/charge/charge_5_full.webp',      # Level 5 (100%)
    'assets/ui/charge/charge_4_cells.webp',     # Level 4 (80%)
    'assets/ui/charge/charge_3_cells.webp',     # Level 3 (60%)
    'assets/ui/charge/charge_2_cells.webp',     # Level 2 (40%)
    'assets/ui/charge/charge_1_cell.webp',      # Level 1 (20%)
    'assets/ui/charge/charge_0_red.webp',       # Level 0 (critical - red)
    'assets/ui/charge/charge_empty.webp',       # Empty
]

charge_images = []
for sprite_path in CHARGE_SPRITES:
    charge_images.append(Image.open(sprite_path).convert('RGBA'))

print(f"✓ Loaded {len(charge_images)} charge sprites\n")

# Get sprite dimensions (assume all same size)
sprite_width, sprite_height = charge_images[0].size
canvas_width = sprite_width * 3  # Extra space for positioning
canvas_height = sprite_height * 3  # Extra space for transitions

# Create frames
frame_dir = "/tmp/battery_transition_frames"
os.makedirs(frame_dir, exist_ok=True)

total_frames = int(FPS * TOTAL_DURATION)

print("Generating frames...")

def get_blink_alpha(t_transition):
    """Generate sinusoidal blinking alpha matching breathing pace during first 0.5s"""
    if t_transition > 0.5:
        return 1.0
    # Sinusoidal oscillation matching 3-second breathing period
    # During 0.5s we want ~1 oscillation
    breathing_period = 3.0
    # Scale time to get visible oscillation in 0.5s window
    scaled_time = t_transition * (breathing_period / 0.5)  # Speed up to fit in 0.5s
    alpha = (np.sin(scaled_time * 2 * np.pi / breathing_period) + 1.0) / 2.0
    # Map from 0-1 to 0.3-1.0 range (like breathing 0.0-0.6 scaled)
    return 0.3 + alpha * 0.7

def get_fade_out_alpha(t_transition):
    """Fade out from 1.0 to 0.0 during 0.5-1.5s of transition"""
    if t_transition < 0.5:
        return 1.0  # Still blinking
    elif t_transition >= TRANSITION_DURATION:
        return 0.0  # Fully faded
    else:
        # Linear fade from 1.0 to 0.0 over 1 second (0.5s to 1.5s)
        progress = (t_transition - 0.5) / 1.0
        return 1.0 - progress

def get_fade_in_alpha(t_transition):
    """Fade in from 0.0 to 1.0 during 0.5-1.5s of transition"""
    if t_transition < 0.5:
        return 0.0  # Not visible yet (old is blinking)
    elif t_transition >= TRANSITION_DURATION:
        return 1.0  # Fully visible
    else:
        # Linear fade from 0.0 to 1.0 over 1 second (0.5s to 1.5s)
        progress = (t_transition - 0.5) / 1.0
        return progress

for frame_num in range(total_frames):
    t = frame_num / FPS

    # Determine phase: DISCHARGE or CHARGE
    if t < DISCHARGE_DURATION:
        # DISCHARGE phase: charge_5_full → charge_0_red → charge_empty
        # Array indices: 0 (full) → 1 → 2 → 3 → 4 → 5 (0_red) → 6 (empty)
        phase = "DISCHARGE"
        phase_time = t
        level_index = int(phase_time / LEVEL_DURATION)
        level_index = min(level_index, 5)  # 0-5 (6 transitions)

        # Use array index directly: start at 0 (full), go to 6 (empty)
        current_level = level_index  # 0, 1, 2, 3, 4, 5
        next_level = min(current_level + 1, 6)  # Next lower charge (higher index)

    else:
        # CHARGE phase: charge_empty → charge_0_red → charge_1_cell → ... → charge_5_full
        # Array indices: 6 (empty) → 5 (0_red) → 4 → 3 → 2 → 1 → 0 (full)
        phase = "CHARGE"
        phase_time = t - DISCHARGE_DURATION
        level_index = int(phase_time / LEVEL_DURATION)
        level_index = min(level_index, 5)  # 0-5 (6 transitions)

        # Start at 6 (empty), go backwards to 0 (full)
        current_level = 6 - level_index  # 6, 5, 4, 3, 2, 1
        next_level = max(current_level - 1, 0)  # Next higher charge (lower index)

    # Time within current level transition
    time_in_level = phase_time % LEVEL_DURATION

    # Create canvas
    canvas = Image.new('RGBA', (canvas_width, canvas_height), (60, 60, 60, 255))

    if time_in_level < TRANSITION_DURATION:
        # TRANSITIONING between levels
        t_transition = time_in_level

        if phase == "DISCHARGE":
            # DISCHARGE: Old blinks AND fades at center, new fades in at same position (crossfade with blink)
            old_sprite = charge_images[current_level]
            new_sprite = charge_images[next_level]

            center_x = (canvas_width - sprite_width) // 2
            center_y = (canvas_height - sprite_height) // 2

            # Old sprite: at center, BLINKING then fading out
            old_alpha = get_blink_alpha(t_transition) * get_fade_out_alpha(t_transition)
            old_array = np.array(old_sprite)
            old_array[:, :, 3] = (old_array[:, :, 3] * old_alpha).astype(np.uint8)
            old_modulated = Image.fromarray(old_array)

            canvas.paste(old_modulated, (center_x, center_y), old_modulated)

            # New sprite: at SAME position, fading in (NO blinking, NO sliding)
            new_alpha = get_fade_in_alpha(t_transition)

            new_array = np.array(new_sprite)
            new_array[:, :, 3] = (new_array[:, :, 3] * new_alpha).astype(np.uint8)
            new_modulated = Image.fromarray(new_array)

            canvas.paste(new_modulated, (center_x, center_y), new_modulated)

            level_names = ["5 full", "4 cells", "3 cells", "2 cells", "1 cell", "0 red", "empty"]
            status = f"DISCHARGE: {level_names[current_level]}→{level_names[next_level]} | Transition: {t_transition:.2f}s | Blink+crossfade"

        else:  # CHARGE
            # CHARGE: New fades in at center, old fades out at same position
            old_sprite = charge_images[current_level]
            new_sprite = charge_images[next_level]

            # Old sprite: fading out (no blinking on charge)
            old_alpha = get_fade_out_alpha(t_transition)
            old_array = np.array(old_sprite)
            old_array[:, :, 3] = (old_array[:, :, 3] * old_alpha).astype(np.uint8)
            old_modulated = Image.fromarray(old_array)

            old_x = (canvas_width - sprite_width) // 2
            old_y = (canvas_height - sprite_height) // 2
            canvas.paste(old_modulated, (old_x, old_y), old_modulated)

            # New sprite: fading in at same position
            new_alpha = get_fade_in_alpha(t_transition)
            new_array = np.array(new_sprite)
            new_array[:, :, 3] = (new_array[:, :, 3] * new_alpha).astype(np.uint8)
            new_modulated = Image.fromarray(new_array)

            new_x = old_x
            new_y = old_y
            canvas.paste(new_modulated, (new_x, new_y), new_modulated)

            # Map back to charge level labels
            level_names = ["5 cells", "4 cells", "3 cells", "2 cells", "1 cell", "0 red", "empty"]
            status = f"CHARGE: {level_names[current_level]}→{level_names[next_level]} | Transition: {t_transition:.2f}s"

    else:
        # STABLE - showing current level only
        if phase == "DISCHARGE":
            # In discharge, after transition we show next_level (the lower one)
            stable_level = next_level
        else:
            # In charge, after transition we show next_level (the higher one)
            stable_level = next_level

        sprite = charge_images[stable_level]

        x = (canvas_width - sprite_width) // 2
        y = (canvas_height - sprite_height) // 2
        canvas.paste(sprite, (x, y), sprite)

        level_names = ["5 cells", "4 cells", "3 cells", "2 cells", "1 cell", "0 red", "empty"]
        status = f"{phase}: {level_names[stable_level]} (stable)"

    # Add info overlay
    draw = ImageDraw.Draw(canvas)

    # Timeline bar
    bar_width = canvas_width - 40
    bar_height = 20
    bar_x = 20
    bar_y = canvas_height - 40

    # Background bar
    draw.rectangle([bar_x, bar_y, bar_x + bar_width, bar_y + bar_height], fill=(40, 40, 40))

    # Progress bar
    progress = t / TOTAL_DURATION
    progress_width = int(bar_width * progress)
    bar_color = (255, 100, 0) if phase == "DISCHARGE" else (0, 255, 100)
    draw.rectangle([bar_x, bar_y, bar_x + progress_width, bar_y + bar_height], fill=bar_color)

    # Phase divider at 50%
    divider_x = bar_x + bar_width // 2
    draw.line([divider_x, bar_y, divider_x, bar_y + bar_height], fill=(255, 255, 255), width=3)

    # Info text
    info_lines = [
        f"Time: {t:.1f}s / {TOTAL_DURATION}s | Frame {frame_num}/{total_frames}",
        f"Phase: {phase}",
        status,
        f"Transition: {TRANSITION_DURATION}s (0.5s blink + 1.0s fade) | Stable: {STABLE_DURATION}s"
    ]

    y_offset = 10
    for line in info_lines:
        draw.text((10, y_offset), line, fill=(255, 255, 255))
        y_offset += 20

    # Save frame
    frame_path = f"{frame_dir}/frame_{frame_num:04d}.png"
    canvas.convert('RGB').save(frame_path)

    # Progress logging
    if frame_num % (FPS * 5) == 0:  # Every 5 seconds
        print(f"  t={t:.1f}s | {status}")

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
print("Video shows battery charge transitions:")
print("  0-30s: DISCHARGE 5→0 (old blinks/fades, new appears)")
print("  30-60s: CHARGE 0→5 (new fades in, old fades out)")
