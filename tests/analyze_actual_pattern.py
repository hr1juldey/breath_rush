#!/usr/bin/env python3
"""
Reverse-engineer the ACTUAL formula used in the manual positioning.

The standard formulas don't match, so let's find what DOES match.
"""

# Scene constants
CAMERA_Y = 180.415
GROUND_Y = 420
HORIZON_Y = 200
PLAYER_Y = 427.72
PLAYER_SCALE = 0.154

# Asset data: (name, scale, y_position, layer)
ASSET_DATA = [
    # Far layer
    ("Lotus_park", 1.73, -4, "far"),
    ("Laal_kila", 1.59, 5, "far"),
    ("Hauskhas", 0.75, 109, "far"),
    ("Hanuman", 0.40, 234, "far"),

    # Mid layer
    ("building_generic", 0.75, 178, "mid"),
    ("two_storey", 0.44, 231, "mid"),
    ("restaurant", 0.30, 320, "mid"),
    ("shop", 0.25, 311, "mid"),
    ("pharmacy", 0.22, 319, "mid"),

    # Front layer
    ("tree_3", 0.34, 289, "front"),
    ("tree_2", 0.25, 310, "front"),
    ("tree_1", 0.19, 337, "front"),
    ("fruit_stall", 0.11, 353, "front"),
    ("billboard", 0.09, 378, "front"),

    # Reference
    ("player", PLAYER_SCALE, PLAYER_Y, "ground"),
]


def find_inverse_relationship():
    """
    Test the observation: larger scale -> lower y (higher on screen)
    This suggests an INVERSE relationship: y = A - B*scale or y = A - B/scale
    """
    print("=" * 80)
    print("REVERSE-ENGINEERING THE ACTUAL PATTERN")
    print("=" * 80)
    print()

    print("Key Observation:")
    print("  - Larger scale -> LOWER y (appears HIGHER on screen)")
    print("  - Smaller scale -> HIGHER y (appears LOWER on screen)")
    print()

    # Test: y = A + B * scale (linear)
    print("-" * 80)
    print("PATTERN 1: Linear y = A + B * scale")
    print("-" * 80)

    # Using player as one data point: 427.72 = A + B * 0.154
    # Using largest scale (Lotus): -4 = A + B * 1.73
    # Solving: B = (y2 - y1) / (scale2 - scale1)

    y1, scale1 = PLAYER_Y, PLAYER_SCALE
    y2, scale2 = -4, 1.73

    B = (y2 - y1) / (scale2 - scale1)
    A = y1 - B * scale1

    print(f"Using two points (Player and Lotus_park):")
    print(f"  y = {A:.2f} + ({B:.2f}) * scale")
    print()

    total_error = 0
    for name, scale, actual_y, _layer in ASSET_DATA:
        predicted_y = A + B * scale
        error = actual_y - predicted_y
        total_error += abs(error)
        print(f"{name:20s} | scale={scale:5.2f} | actual={actual_y:7.2f} | pred={predicted_y:7.2f} | error={error:7.2f}")

    print(f"\nTotal Absolute Error: {total_error:.2f}")
    print(f"Mean Absolute Error: {total_error/len(ASSET_DATA):.2f}")
    print()

    # Test: y = A - B / scale (hyperbolic)
    print("-" * 80)
    print("PATTERN 2: Inverse y = A - B / scale")
    print("-" * 80)

    # Test various combinations
    best_A, best_B, best_error = 0, 0, float('inf')

    for A_test in range(300, 500, 5):
        for B_test in range(10, 200, 5):
            total_err = 0
            for _name, scale, actual_y, _layer in ASSET_DATA:
                if scale > 0:
                    predicted_y = A_test - B_test / scale
                    total_err += abs(actual_y - predicted_y)

            if total_err < best_error:
                best_error = total_err
                best_A = A_test
                best_B = B_test

    print(f"Best fit: y = {best_A} - {best_B}/scale")
    print(f"Total Absolute Error: {best_error:.2f}")
    print(f"Mean Absolute Error: {best_error/len(ASSET_DATA):.2f}")
    print()

    for name, scale, actual_y, _layer in ASSET_DATA:
        if scale > 0:
            predicted_y = best_A - best_B / scale
            error = actual_y - predicted_y
            print(f"{name:20s} | scale={scale:5.2f} | actual={actual_y:7.2f} | pred={predicted_y:7.2f} | error={error:7.2f}")

    print()

    # Test: Quadratic y = A + B*scale + C*scale^2
    print("-" * 80)
    print("PATTERN 3: Quadratic y = A + B*scale + C*scale^2")
    print("-" * 80)

    # Simple grid search for best fit
    best_params = (0, 0, 0)
    best_error = float('inf')

    for A in range(350, 450, 10):
        for B in range(-400, -100, 20):
            for C in range(0, 100, 10):
                total_err = 0
                for _name, scale, actual_y, _layer in ASSET_DATA:
                    predicted_y = A + B * scale + C * scale * scale
                    total_err += abs(actual_y - predicted_y)

                if total_err < best_error:
                    best_error = total_err
                    best_params = (A, B, C)

    A, B, C = best_params
    print(f"Best fit: y = {A} + ({B})*scale + {C}*scale^2")
    print(f"Total Absolute Error: {best_error:.2f}")
    print(f"Mean Absolute Error: {best_error/len(ASSET_DATA):.2f}")
    print()

    for name, scale, actual_y, _layer in ASSET_DATA:
        predicted_y = A + B * scale + C * scale * scale
        error = actual_y - predicted_y
        print(f"{name:20s} | scale={scale:5.2f} | actual={actual_y:7.2f} | pred={predicted_y:7.2f} | error={error:7.2f}")

    print()

    return best_A, best_B


def analyze_by_layer():
    """
    Check if different layers follow different formulas or constants.
    """
    print("=" * 80)
    print("LAYER-BY-LAYER ANALYSIS")
    print("=" * 80)
    print()

    layers = {
        'far': [],
        'mid': [],
        'front': [],
        'ground': []
    }

    for name, scale, y, layer_name in ASSET_DATA:
        layers[layer_name].append((name, scale, y))

    for layer_name, items in layers.items():
        print(f"\n{layer_name.upper()} LAYER:")
        print("-" * 40)

        if len(items) < 2:
            print("  Not enough data points")
            continue

        # Calculate linear fit for this layer
        y1, scale1 = items[0][2], items[0][1]
        y2, scale2 = items[1][2], items[1][1]

        if abs(scale2 - scale1) > 0.001:
            B = (y2 - y1) / (scale2 - scale1)
            A = y1 - B * scale1

            print(f"  Linear fit: y = {A:.2f} + ({B:.2f}) * scale")

            for name, scale, actual_y in items:
                predicted_y = A + B * scale
                error = actual_y - predicted_y
                print(f"    {name:20s} | scale={scale:5.2f} | actual={actual_y:7.2f} | pred={predicted_y:7.2f} | error={error:7.2f}")

        # Check if there's a pattern in the layer assignments
        print(f"  Scale range: {min(item[1] for item in items):.2f} - {max(item[1] for item in items):.2f}")
        print(f"  Y range: {min(item[2] for item in items):.2f} - {max(item[2] for item in items):.2f}")


def check_parallax_motion_scale():
    """
    The user mentioned motion_scale values in their scene:
    - Far: 0.3
    - Mid: 0.6
    - Front: 0.9

    Maybe there's a relationship between sprite scale and the layer's motion_scale?
    """
    print()
    print("=" * 80)
    print("RELATIONSHIP TO PARALLAX MOTION_SCALE")
    print("=" * 80)
    print()

    motion_scales = {
        'far': 0.3,
        'mid': 0.6,
        'front': 0.9,
        'ground': 1.0  # Player moves with the world
    }

    print("Layer motion_scale values:")
    for layer, ms in motion_scales.items():
        print(f"  {layer:10s}: {ms}")

    print()
    print("Checking if y-position relates to motion_scale...")
    print()

    # For each asset, what's the relationship to its layer's motion_scale?
    for name, scale, y, layer_name in ASSET_DATA:
        ms = motion_scales.get(layer_name, 0)

        # Test: y = f(scale, motion_scale)
        # Maybe: y = horizon + (ground - horizon) * (1 - motion_scale) + adjustment based on scale

        # Or: maybe the sprite scale should be COMBINED with motion_scale?
        effective_depth = scale * (1 / ms) if ms > 0 else 0

        print(f"{name:20s} | sprite_scale={scale:5.2f} | motion_scale={ms:4.2f} | effective_depth={effective_depth:7.2f} | y={y:7.2f}")


if __name__ == "__main__":
    find_inverse_relationship()
    analyze_by_layer()
    check_parallax_motion_scale()

    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print()
    print("The manual positioning does NOT follow standard perspective formulas.")
    print("This is likely because the user:")
    print("1. Manually placed assets at 'real-world roadside scaling'")
    print("2. The assets were NOT positioned using camera projection math")
    print("3. Instead, larger assets were placed higher to 'look right' visually")
    print()
    print("To create proper parallax layers, we need to TRANSFORM these positions")
    print("using the derived formula from the analysis above.")
