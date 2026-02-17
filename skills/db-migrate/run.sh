#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT/apps/api"

MESSAGE="${1:?Usage: bash skills/db-migrate/run.sh \"migration description\"}"

echo "=== db-migrate: Creating and applying migration ==="

echo "[1/2] Generating migration: $MESSAGE"
uv run alembic revision --autogenerate -m "$MESSAGE"

echo "[2/2] Applying migration..."
uv run alembic upgrade head

echo "=== db-migrate: Complete ==="
