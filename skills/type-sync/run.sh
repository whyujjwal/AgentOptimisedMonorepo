#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

echo "=== type-sync: Synchronizing Pydantic → OpenAPI → TypeScript ==="

echo "[1/3] Exporting OpenAPI schema..."
cd apps/api && uv run python -m app.scripts.export_openapi
cd "$REPO_ROOT"

echo "[2/3] Generating TypeScript types..."
cd packages/shared-types && pnpm generate
cd "$REPO_ROOT"

echo "[3/3] Verifying frontend build..."
pnpm build --filter=web

echo "=== type-sync: Complete ==="
