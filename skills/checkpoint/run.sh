#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

MESSAGE="${1:?Usage: bash skills/checkpoint/run.sh \"checkpoint description\"}"

echo "=== checkpoint: Creating Entire context checkpoint ==="

echo "[1/2] Staging changes..."
git add -A

echo "[2/2] Committing checkpoint: $MESSAGE"
git commit -m "checkpoint: $MESSAGE" || echo "  (nothing to commit)"

echo "=== checkpoint: Complete (Entire hooks auto-captured context) ==="
