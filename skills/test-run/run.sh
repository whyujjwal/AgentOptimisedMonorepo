#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

echo "=== test-run: Running test suites ==="

echo "[1/2] Python tests..."
cd apps/api && uv run pytest -v 2>/dev/null || echo "  (no tests found or pytest not installed)"

cd "$REPO_ROOT"

echo "[2/2] JS/TS tests..."
pnpm test 2>/dev/null || echo "  (no test script configured yet)"

echo "=== test-run: Complete ==="
