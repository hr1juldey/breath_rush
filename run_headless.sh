#!/usr/bin/env bash
# Breath Rush - Headless Debug & Testing Script
# Runs the game in headless mode for testing and debugging
# Supports both standalone Godot and Flatpak versions

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT_STANDALONE="/home/riju279/Documents/Godot/Godot_v4.5.1-stable_linux.x86_64"
GODOT_FLATPAK="flatpak run org.godotengine.Godot"
USE_FLATPAK="${1:-auto}"
VERBOSE="${2:-no}"

# Determine which Godot to use
select_godot() {
    local choice="$1"

    if [ "$choice" = "auto" ]; then
        if [ -x "$GODOT_STANDALONE" ]; then
            echo -e "${GREEN}✓ Using standalone Godot${NC}"
            GODOT_CMD="$GODOT_STANDALONE"
        elif command -v flatpak &> /dev/null; then
            echo -e "${GREEN}✓ Using Flatpak Godot${NC}"
            GODOT_CMD="$GODOT_FLATPAK"
        else
            echo -e "${RED}✗ ERROR: No Godot installation found${NC}"
            exit 1
        fi
    elif [ "$choice" = "flatpak" ]; then
        if command -v flatpak &> /dev/null; then
            GODOT_CMD="$GODOT_FLATPAK"
            echo -e "${GREEN}✓ Using Flatpak Godot${NC}"
        else
            echo -e "${RED}✗ ERROR: Flatpak not installed${NC}"
            exit 1
        fi
    elif [ "$choice" = "standalone" ]; then
        if [ -x "$GODOT_STANDALONE" ]; then
            GODOT_CMD="$GODOT_STANDALONE"
            echo -e "${GREEN}✓ Using standalone Godot${NC}"
        else
            echo -e "${RED}✗ ERROR: Standalone Godot not found at $GODOT_STANDALONE${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ Invalid choice: $choice${NC}"
        echo "Usage: $0 [auto|flatpak|standalone] [verbose|quiet]"
        exit 1
    fi
}

# Build command with proper flags
build_command() {
    local cmd="$GODOT_CMD"

    # Add headless flag
    cmd="$cmd --headless"

    # Add project path
    cmd="$cmd --path \"$PROJECT_ROOT\""

    # Add verbose if requested
    if [ "$VERBOSE" = "verbose" ]; then
        cmd="$cmd --verbose"
    fi

    echo "$cmd"
}

# Print banner
print_banner() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Breath Rush - Headless Debug Mode   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Check project validity
check_project() {
    echo -e "${YELLOW}→ Checking project structure...${NC}"

    local checks_passed=0
    local checks_total=4

    if [ -f "$PROJECT_ROOT/project.godot" ]; then
        echo -e "${GREEN}  ✓ project.godot found${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}  ✗ project.godot not found${NC}"
    fi

    if [ -d "$PROJECT_ROOT/scripts" ]; then
        echo -e "${GREEN}  ✓ scripts/ directory found${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}  ✗ scripts/ directory not found${NC}"
    fi

    if [ -d "$PROJECT_ROOT/scenes" ]; then
        echo -e "${GREEN}  ✓ scenes/ directory found${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}  ✗ scenes/ directory not found${NC}"
    fi

    if [ -d "$PROJECT_ROOT/assets" ]; then
        echo -e "${GREEN}  ✓ assets/ directory found${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}  ✗ assets/ directory not found${NC}"
    fi

    echo ""
    echo -e "${YELLOW}Project checks: $checks_passed/$checks_total passed${NC}"

    if [ $checks_passed -lt $checks_total ]; then
        echo -e "${RED}✗ Project validation failed${NC}"
        return 1
    fi

    return 0
}

# Check for script errors
check_syntax() {
    echo -e "${YELLOW}→ Checking GDScript syntax...${NC}"

    if python3 "$PROJECT_ROOT/scripts/check_gd_quickscan.py" "$PROJECT_ROOT" 2>&1 | tee /tmp/gd_check.log; then
        echo -e "${GREEN}✓ Syntax check passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Syntax errors found (see above)${NC}"
        return 1
    fi
}

# Run the game in headless mode
run_game() {
    echo ""
    echo -e "${YELLOW}→ Starting headless game...${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""

    local cmd=$(build_command)

    echo "Command: $cmd"
    echo ""

    # Run the command
    eval "$cmd" 2>&1
    local exit_code=$?

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ Game completed successfully${NC}"
    else
        echo -e "${RED}✗ Game exited with code $exit_code${NC}"
    fi

    return $exit_code
}

# Show help
show_help() {
    cat << EOF
${BLUE}Breath Rush Headless Debug Script${NC}

Usage: $0 [OPTIONS]

Options:
  auto              Auto-detect Godot installation (default)
  standalone        Use standalone Godot from ~/Documents/Godot/
  flatpak           Use Flatpak Godot

  verbose           Enable verbose output
  quiet             Disable verbose output (default)

Examples:
  $0                          # Auto-detect, quiet mode
  $0 standalone               # Use standalone Godot
  $0 flatpak verbose          # Use Flatpak with verbose output
  $0 auto verbose             # Auto-detect with verbose output

Features:
  ✓ Headless game execution (no graphics window)
  ✓ Project structure validation
  ✓ GDScript syntax checking
  ✓ Verbose error logging
  ✓ Automatic Godot detection

EOF
}

# Main execution
main() {
    print_banner

    # Parse arguments
    if [ "$USE_FLATPAK" = "help" ] || [ "$USE_FLATPAK" = "-h" ] || [ "$USE_FLATPAK" = "--help" ]; then
        show_help
        exit 0
    fi

    # Select Godot version
    select_godot "$USE_FLATPAK"
    echo ""

    # Validate project
    if ! check_project; then
        exit 1
    fi
    echo ""

    # Check syntax (optional - can fail without stopping)
    if ! check_syntax; then
        echo -e "${YELLOW}⚠ Continuing despite syntax warnings...${NC}"
    fi
    echo ""

    # Run the game
    run_game
}

# Run main function
main
