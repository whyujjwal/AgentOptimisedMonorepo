"""Export the OpenAPI schema to a JSON file.

Usage:
    uv run python -m app.scripts.export_openapi

This generates openapi.json at the repo root for shared-types consumption.
"""

import json
from pathlib import Path

from app.main import app


def main() -> None:
    schema = app.openapi()
    output_path = Path(__file__).resolve().parents[4] / "openapi.json"
    output_path.write_text(json.dumps(schema, indent=2))
    print(f"OpenAPI schema written to {output_path}")


if __name__ == "__main__":
    main()
