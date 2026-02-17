#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT/apps/api"

echo "=== openapi-gen: Exporting OpenAPI schema ==="
uv run python -m app.scripts.export_openapi
echo "=== openapi-gen: Complete ==="
