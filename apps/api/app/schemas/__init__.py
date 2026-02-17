"""Pydantic request/response schemas.

These are the source of truth for the OpenAPI spec and shared-types generation.
"""

from app.schemas.health import HealthResponse

__all__ = ["HealthResponse"]
