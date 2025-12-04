#!/usr/bin/env python3
"""
Quick test script for Breath Rush game
Runs game in headless mode and captures output
"""

import subprocess
import sys
import time

GODOT_PATH = "/home/riju279/Documents/Godot/Godot_v4.5.1-stable_linux.x86_64"
PROJECT_PATH = "/home/riju279/Documents/Code/Games/breath_rush"
TIMEOUT = 360  # seconds


def run_game():
    """Run the game in headless mode with timeout"""
    print("=" * 60)
    print("Breath Rush - Quick Test")
    print("=" * 60)
    print()

    cmd = [GODOT_PATH, "--headless", "--path", PROJECT_PATH]

    print(f"Running: {' '.join(cmd)}")
    print(f"Timeout: {TIMEOUT} seconds")
    print()
    print("-" * 60)

    try:
        result = subprocess.run(cmd, timeout=TIMEOUT, capture_output=True, text=True)
        
        print(result.stdout)
        time.sleep(TIMEOUT)
        if result.stderr:
            print("STDERR:", result.stderr)

        print("-" * 60)
        print(f"\nExit code: {result.returncode}")

    except subprocess.TimeoutExpired as e:
        print(f"\n[TIMEOUT] Game ran for {TIMEOUT} seconds and was terminated")
        print("-" * 60)

        if e.stdout:
            print("\nCaptured output:")
            print(e.stdout.decode() if isinstance(e.stdout, bytes) else e.stdout)

        if e.stderr:
            print("\nCaptured errors:")
            print(e.stderr.decode() if isinstance(e.stderr, bytes) else e.stderr)

    except Exception as e:
        print(f"\n[ERROR] {e}")
        sys.exit(1)


if __name__ == "__main__":
    run_game()
