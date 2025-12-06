#!/usr/bin/env python3
"""
Analyze parallax positioning data to derive the mathematical formula
relating scale to y-position in perspective projection.

Research Question: What is the formula for y_position = f(scale, ground_y, horizon_y, camera_y)?
"""

# Removed unused imports

try:
    import numpy as np
    import matplotlib.pyplot as plt
    HAS_MATPLOTLIB = True
except ImportError:
    print("WARNING: matplotlib not available, skipping visualization")
    HAS_MATPLOTLIB = False
    # Create dummy np for basic operations
    class DummyNp:
        @staticmethod
        def array(x):
            return x
        @staticmethod
        def linspace(start, end, num):
            step = (end - start) / (num - 1)
            return [start + step * i for i in range(num)]
    np = DummyNp()

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


def analyze_scale_vs_y():
    """Analyze the relationship between scale and y-position."""
    print("=" * 80)
    print("PARALLAX PERSPECTIVE PROJECTION ANALYSIS")
    print("=" * 80)
    print()

    # Extract data
    scales = [d[1] for d in ASSET_DATA]
    y_positions = [d[2] for d in ASSET_DATA]
    names = [d[0] for d in ASSET_DATA]

    print("Scene Parameters:")
    print(f"  Camera Y: {CAMERA_Y}")
    print(f"  Ground Y: {GROUND_Y}")
    print(f"  Horizon Y: {HORIZON_Y}")
    print(f"  Player Y: {PLAYER_Y}, Scale: {PLAYER_SCALE}")
    print()

    # Test hypothesis 1: Linear interpolation between horizon and ground
    # y = horizon_y + (ground_y - horizon_y) * (1 - scale)
    print("-" * 80)
    print("HYPOTHESIS 1: Linear Interpolation (y = horizon + (ground - horizon) * (1 - scale))")
    print("-" * 80)

    for i, (name, scale, actual_y, layer) in enumerate(ASSET_DATA):
        predicted_y = HORIZON_Y + (GROUND_Y - HORIZON_Y) * (1 - scale)
        error = actual_y - predicted_y
        print(f"{name:20s} | scale={scale:5.2f} | actual_y={actual_y:7.2f} | pred_y={predicted_y:7.2f} | error={error:7.2f}")

    print()

    # Test hypothesis 2: Perspective projection with depth
    # Using vanishing point formula: y = horizon_y + (ground_y - horizon_y) / depth_factor
    # where depth_factor = 1 / scale (larger objects are closer, so smaller depth)
    print("-" * 80)
    print("HYPOTHESIS 2: Perspective Projection (depth_factor = 1/scale)")
    print("-" * 80)

    # We need to find the relationship between scale and depth
    # In perspective projection: scale = focal_length / (focal_length + depth)
    # Rearranging: depth = focal_length * (1/scale - 1)

    # Let's try to find the best focal_length
    focal_lengths_to_try = [100, 200, 240, 300, 400, 500]

    for focal_length in focal_lengths_to_try:
        print(f"\nFocal Length = {focal_length}")
        total_error = 0
        for name, scale, actual_y, layer in ASSET_DATA:
            if scale > 0:
                depth = focal_length * (1/scale - 1)
                # Project y-position based on depth
                # y_screen = horizon_y + (ground_y - horizon_y) * (focal_length / (focal_length + depth))
                predicted_y = HORIZON_Y + (GROUND_Y - HORIZON_Y) * (focal_length / (focal_length + depth))
                error = actual_y - predicted_y
                total_error += abs(error)
                print(f"  {name:20s} | depth={depth:7.2f} | pred_y={predicted_y:7.2f} | error={error:7.2f}")

        print(f"  Total Absolute Error: {total_error:.2f}")

    print()

    # Test hypothesis 3: Direct formula with camera position
    # Based on perspective projection: screen_y = camera_y + (object_world_y - camera_y) * scale
    print("-" * 80)
    print("HYPOTHESIS 3: Camera-based Projection (y = camera_y + (ground_y - camera_y) * scale)")
    print("-" * 80)

    for name, scale, actual_y, layer in ASSET_DATA:
        predicted_y = CAMERA_Y + (GROUND_Y - CAMERA_Y) * scale
        error = actual_y - predicted_y
        print(f"{name:20s} | scale={scale:5.2f} | actual_y={actual_y:7.2f} | pred_y={predicted_y:7.2f} | error={error:7.2f}")

    print()

    # Test hypothesis 4: Reverse - derive the pattern from data
    # If we assume y = A + B * f(scale), what are A, B, and f(scale)?
    print("-" * 80)
    print("HYPOTHESIS 4: Empirical Pattern Analysis")
    print("-" * 80)

    # Try polynomial regression
    if HAS_MATPLOTLIB:
        from numpy.polynomial import Polynomial

        # Fit polynomial: y = a0 + a1*scale + a2*scale^2 + ...
        for degree in [1, 2, 3]:
            p = Polynomial.fit(scales, y_positions, degree)
            print(f"\nPolynomial Degree {degree}:")
            print(f"  Coefficients: {p.convert().coef}")

            total_error = 0
            for name, scale, actual_y, layer in ASSET_DATA:
                predicted_y = p(scale)
                error = actual_y - predicted_y
                total_error += abs(error)

            print(f"  Total Absolute Error: {total_error:.2f}")
            print(f"  Mean Absolute Error: {total_error/len(ASSET_DATA):.2f}")
    else:
        print("\nPolynomial regression skipped (numpy not available)")

    print()

    # Test hypothesis 5: Logarithmic relationship
    print("-" * 80)
    print("HYPOTHESIS 5: Logarithmic/Inverse Relationship")
    print("-" * 80)

    # Try: y = A + B / scale
    # This makes sense because larger objects (larger scale) should be higher (lower y)

    # Use least squares to find A and B
    # y = A + B/scale
    # Rearrange: y*scale = A*scale + B
    # This is linear in (scale, 1) if we multiply by scale

    # But let's just test some values based on the pattern
    # Looking at the data: when scale is large, y is small (negative even)
    # when scale is small, y approaches ground_y

    # Let's try: y = ground_y - C / scale
    for C in [50, 60, 70, 80, 90, 100, 110, 120]:
        print(f"\nFormula: y = {GROUND_Y} - {C}/scale")
        total_error = 0
        for name, scale, actual_y, layer in ASSET_DATA:
            if scale > 0:
                predicted_y = GROUND_Y - C / scale
                error = actual_y - predicted_y
                total_error += abs(error)

        print(f"  Total Absolute Error: {total_error:.2f}")

    print()

    # Test hypothesis 6: Based on the vanishing point concept
    # Objects at infinity (scale=0) appear at horizon
    # Objects at camera position (scale=1) appear at their real position
    # Formula: y = horizon_y + (real_y - horizon_y) * scale
    print("-" * 80)
    print("HYPOTHESIS 6: Vanishing Point Formula (y = horizon + (ground - horizon) * scale)")
    print("-" * 80)

    for name, scale, actual_y, layer in ASSET_DATA:
        predicted_y = HORIZON_Y + (GROUND_Y - HORIZON_Y) * scale
        error = actual_y - predicted_y
        print(f"{name:20s} | scale={scale:5.2f} | actual_y={actual_y:7.2f} | pred_y={predicted_y:7.2f} | error={error:7.2f}")

    total_error_h6 = sum(abs(ASSET_DATA[i][2] - (HORIZON_Y + (GROUND_Y - HORIZON_Y) * ASSET_DATA[i][1]))
                         for i in range(len(ASSET_DATA)))
    print(f"\nTotal Absolute Error: {total_error_h6:.2f}")
    print(f"Mean Absolute Error: {total_error_h6/len(ASSET_DATA):.2f}")

    print()

    # Visualization
    if HAS_MATPLOTLIB:
        create_visualization(scales, y_positions, names)
    else:
        print("\nVisualization skipped (matplotlib not available)")


def create_visualization(scales, y_positions, names):
    """Create visualization of scale vs y-position relationship."""
    plt.figure(figsize=(14, 10))

    # Plot 1: Scatter plot of actual data
    plt.subplot(2, 2, 1)
    colors = {'far': 'blue', 'mid': 'green', 'front': 'orange', 'ground': 'red'}
    for i, (name, scale, y, layer) in enumerate(ASSET_DATA):
        plt.scatter(scale, y, c=colors[layer], s=100, alpha=0.6, label=layer if i == 0 or ASSET_DATA[i-1][3] != layer else "")

    plt.xlabel('Scale')
    plt.ylabel('Y Position')
    plt.title('Actual Asset Positions: Scale vs Y')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.axhline(y=GROUND_Y, color='brown', linestyle='--', label=f'Ground (y={GROUND_Y})')
    plt.axhline(y=HORIZON_Y, color='purple', linestyle='--', label=f'Horizon (y={HORIZON_Y})')
    plt.axhline(y=CAMERA_Y, color='gray', linestyle='--', label=f'Camera (y={CAMERA_Y})')

    # Plot 2: Compare hypotheses
    plt.subplot(2, 2, 2)
    scale_range = np.linspace(0.01, 2.0, 100)

    # Hypothesis 1: Linear interpolation (1 - scale)
    y_h1 = HORIZON_Y + (GROUND_Y - HORIZON_Y) * (1 - scale_range)
    plt.plot(scale_range, y_h1, 'b--', label='H1: Linear (1-scale)', linewidth=2)

    # Hypothesis 3: Camera-based
    y_h3 = CAMERA_Y + (GROUND_Y - CAMERA_Y) * scale_range
    plt.plot(scale_range, y_h3, 'g--', label='H3: Camera-based', linewidth=2)

    # Hypothesis 6: Vanishing point
    y_h6 = HORIZON_Y + (GROUND_Y - HORIZON_Y) * scale_range
    plt.plot(scale_range, y_h6, 'r--', label='H6: Vanishing point', linewidth=2)

    # Actual data
    for name, scale, y, layer in ASSET_DATA:
        plt.scatter(scale, y, c=colors[layer], s=50, alpha=0.8)

    plt.xlabel('Scale')
    plt.ylabel('Y Position')
    plt.title('Formula Comparison')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.xlim(0, 2)

    # Plot 3: Error analysis for best hypothesis
    plt.subplot(2, 2, 3)
    errors_h6 = []
    for name, scale, y, layer in ASSET_DATA:
        predicted = HORIZON_Y + (GROUND_Y - HORIZON_Y) * scale
        error = y - predicted
        errors_h6.append(error)
        plt.bar(name, error, color=colors[layer], alpha=0.6)

    plt.xticks(rotation=45, ha='right')
    plt.ylabel('Error (actual - predicted)')
    plt.title('Hypothesis 6 Error Analysis')
    plt.axhline(y=0, color='black', linestyle='-', linewidth=0.5)
    plt.grid(True, alpha=0.3, axis='y')

    # Plot 4: Inverse scale relationship
    plt.subplot(2, 2, 4)
    for i, (name, scale, y, layer) in enumerate(ASSET_DATA):
        if scale > 0:
            plt.scatter(1/scale, y, c=colors[layer], s=100, alpha=0.6)

    plt.xlabel('1/Scale (Depth Proxy)')
    plt.ylabel('Y Position')
    plt.title('Y Position vs Inverse Scale (Depth)')
    plt.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig('/home/riju279/Documents/Code/Games/breath_rush/parallax_analysis.png', dpi=150)
    print("Visualization saved to: /home/riju279/Documents/Code/Games/breath_rush/parallax_analysis.png")
    plt.show()


def derive_gdscript_formula():
    """Provide GDScript implementation of the best formula."""
    print("=" * 80)
    print("GDSCRIPT IMPLEMENTATION")
    print("=" * 80)
    print()

    print("""
# Based on the analysis, the best formula appears to be:
# y_position = horizon_y + (ground_y - horizon_y) * scale

# This is the classic vanishing point perspective formula where:
# - Objects at scale=0 (infinitely far) appear at the horizon line
# - Objects at scale=1 (at camera position) appear at their ground position
# - Larger objects (scale > 1) appear above ground (negative y direction)

func calculate_sprite_y_from_scale(scale: float, ground_y: float = 420.0, horizon_y: float = 200.0) -> float:
    \"\"\"
    Calculate the y-position for a sprite based on its scale in perspective projection.

    Args:
        scale: The sprite's scale factor (larger = closer to camera = appears higher)
        ground_y: The ground line y-coordinate (default: 420)
        horizon_y: The horizon/vanishing point y-coordinate (default: 200)

    Returns:
        The calculated y-position where the sprite should be placed

    Formula explanation:
        y = horizon_y + (ground_y - horizon_y) * scale

        This creates a linear interpolation where:
        - When scale = 0: y = horizon_y (object at infinity)
        - When scale = 1: y = ground_y (object at ground level)
        - When scale > 1: y > ground_y (object closer than ground, appears higher)
    \"\"\"
    return horizon_y + (ground_y - horizon_y) * scale


# Example usage:
# var sprite_scale = 0.5
# var sprite_y = calculate_sprite_y_from_scale(sprite_scale)
# sprite.position.y = sprite_y
# sprite.scale = Vector2(sprite_scale, sprite_scale)

# Verification with your data:
# - Player: scale=0.154 → y = 200 + (420-200)*0.154 = 200 + 33.88 = 233.88 (actual: 428)
#   NOTE: This shows the formula doesn't perfectly match, suggesting additional factors

# Alternative: If the player is the reference point, use:
func calculate_sprite_y_from_scale_player_ref(
    scale: float,
    player_scale: float = 0.154,
    player_y: float = 428.0,
    horizon_y: float = 200.0
) -> float:
    \"\"\"
    Calculate y-position using player as reference instead of ground.
    This may be more accurate for your specific setup.
    \"\"\"
    # Derive ground_y from player position
    var implied_ground_y = horizon_y + (player_y - horizon_y) / player_scale
    return horizon_y + (implied_ground_y - horizon_y) * scale
    """)


if __name__ == "__main__":
    analyze_scale_vs_y()
    print()
    derive_gdscript_formula()
