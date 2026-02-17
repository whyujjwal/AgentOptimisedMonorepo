"""SQLAlchemy ORM models.

Import all models here so Alembic can discover them for auto-generation.
"""

from app.models.example import Example

__all__ = ["Example"]
