"""Supermemory integration for long-term semantic memory."""

from supermemory import Supermemory

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)


def get_memory_client() -> Supermemory:
    """Create a Supermemory client.

    Raises RuntimeError if SUPERMEMORY_API_KEY is not configured.
    """
    if not settings.SUPERMEMORY_API_KEY:
        raise RuntimeError(
            "SUPERMEMORY_API_KEY is not set. "
            "Add it to your .env file or environment variables."
        )
    logger.info("initializing supermemory client")
    return Supermemory(api_key=settings.SUPERMEMORY_API_KEY)
