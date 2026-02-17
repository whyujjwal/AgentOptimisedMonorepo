"""Supermemory integration for long-term semantic memory.

This service wraps the Supermemory SDK to provide:
- Storing agent thoughts, decisions, and context as memories
- Searching past memories by semantic similarity
- Namespacing memories per agent or user via container_tags

Usage:
    from app.services.memory import MemoryService

    svc = MemoryService()
    svc.add("User prefers dark mode", tags=["user_42"])
    results = svc.search("user preferences", tags=["user_42"])
"""

from __future__ import annotations

from supermemory import Supermemory

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

_client: Supermemory | None = None


def _get_client() -> Supermemory:
    """Lazy-initialize a singleton Supermemory client."""
    global _client
    if _client is not None:
        return _client

    if not settings.SUPERMEMORY_API_KEY:
        raise RuntimeError(
            "SUPERMEMORY_API_KEY is not set. "
            "Add it to your .env file."
        )
    _client = Supermemory(api_key=settings.SUPERMEMORY_API_KEY)
    logger.info("supermemory client initialized")
    return _client


class MemoryService:
    """High-level wrapper around Supermemory for agent memory operations."""

    def __init__(self) -> None:
        self.client = _get_client()

    def add(
        self,
        content: str,
        *,
        tags: list[str] | None = None,
        metadata: dict | None = None,
    ) -> str:
        """Store a memory.

        Args:
            content: The text to remember.
            tags: Container tags for namespacing (e.g., ["agent_backend", "session_abc"]).
            metadata: Arbitrary key-value metadata for filtering.

        Returns:
            Confirmation message.
        """
        kwargs: dict = {"content": content}
        if tags:
            kwargs["container_tags"] = tags
        if metadata:
            kwargs["metadata"] = metadata

        result = self.client.add(**kwargs)
        logger.info("memory stored", content_preview=content[:80], tags=tags)
        return f"Memory stored: {content[:80]}..."

    def search(
        self,
        query: str,
        *,
        tags: list[str] | None = None,
        limit: int = 10,
    ) -> list[dict]:
        """Search memories by semantic similarity.

        Args:
            query: Natural language search query.
            tags: Filter by container tags.
            limit: Max results to return.

        Returns:
            List of matching memory dicts.
        """
        kwargs: dict = {"q": query}
        if tags:
            kwargs["container_tags"] = tags

        response = self.client.search.documents(**kwargs)
        results = []
        for item in (response.results or [])[:limit]:
            results.append({
                "content": getattr(item, "content", str(item)),
                "score": getattr(item, "score", None),
            })

        logger.info("memory search", query=query, results_count=len(results))
        return results

    def list_memories(
        self,
        *,
        tags: list[str] | None = None,
        limit: int = 20,
    ) -> list[dict]:
        """List stored memories.

        Args:
            tags: Filter by container tags.
            limit: Max results.

        Returns:
            List of memory dicts.
        """
        kwargs: dict = {}
        if tags:
            kwargs["container_tags"] = tags
        if limit:
            kwargs["limit"] = limit

        response = self.client.documents.list(**kwargs)
        results = []
        for item in response.results or []:
            results.append({
                "id": getattr(item, "id", None),
                "content": getattr(item, "content", str(item)),
            })

        logger.info("memories listed", tags=tags, count=len(results))
        return results
