#!/usr/bin/env bash
# claude-check-syntax.sh
# Try to run Godot native syntax check; fallback to quick static scan (python).
# Usage: ./claude-check-syntax.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT_CMD=""

# Prefer a direct godot binary if present
if command -v godot >/dev/null 2>&1 ; then
  GODOT_CMD="$(command -v godot)"
fi

# If no direct binary, use Flatpak wrapper
if [ -z "$GODOT_CMD" ]; then
  if command -v flatpak >/dev/null 2>&1 ; then
    GODOT_CMD="/usr/bin/flatpak run org.godotengine.Godot"
  fi
fi

echo "Root: $ROOT"
echo "Using Godot command: ${GODOT_CMD:-<none>}"

# 1) Prefer Godot built-in check (Godot 4.x supports --check in newer builds)
if [ -n "$GODOT_CMD" ]; then
  echo "Attempting Godot syntax check via: $GODOT_CMD --check"
  set +e
  eval "$GODOT_CMD --check \"$ROOT/project.godot\""
  rc=$?
  set -e
  if [ $rc -eq 0 ]; then
    echo "Godot --check returned success (0). No syntax errors detected by Godot."
    exit 0
  else
    echo "Godot --check returned non-zero ($rc). Falling back to text scan."
  fi
else
  echo "No godot binary found. Falling back to text scan (quick heuristics)."
fi

# 2) Run Python quick-scan static checks as fallback
PY="$ROOT/scripts/check_gd_quickscan.py"
if [ ! -f "$PY" ]; then
  echo "ERROR: required helper $PY not found."
  exit 2
fi

python3 "$PY" "$ROOT"
exit $?
