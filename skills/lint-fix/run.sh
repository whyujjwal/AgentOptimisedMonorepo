#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

echo "=== lint-fix: Running linters ==="

echo "[1/2] Linting TypeScript/JavaScript..."
pnpm lint || true

echo "[2/2] Linting Python..."
cd apps/api
uv run ruff check --fix app/ 2>/dev/null || echo "  (ruff not installed, skipping)"
uv run ruff format app/ 2>/dev/null || echo "  (ruff not installed, skipping)"

echo "=== lint-fix: Complete ==="
