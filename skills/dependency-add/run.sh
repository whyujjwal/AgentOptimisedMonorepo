#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

LANG="${1:?Usage: bash skills/dependency-add/run.sh <js|py> <package> [workspace]}"
PACKAGE="${2:?Package name required}"
WORKSPACE="${3:-}"

echo "=== dependency-add: Installing $PACKAGE ==="

case "$LANG" in
  js)
    if [ -n "$WORKSPACE" ]; then
      pnpm add "$PACKAGE" --filter="$WORKSPACE"
    else
      echo "Error: workspace filter required for JS packages (e.g., 'web', '@repo/ui')"
      exit 1
    fi
    ;;
  py)
    cd apps/api && uv add "$PACKAGE"
    ;;
  *)
    echo "Error: LANG must be 'js' or 'py', got '$LANG'"
    exit 1
    ;;
esac

echo "=== dependency-add: Complete ==="
