"""Local vector database for agent long-term semantic memory.

This service uses ChromaDB to provide:
- Storing agent thoughts, decisions, and context as memories
- Searching past memories by semantic similarity
- Namespacing memories per agent or user via tags
- 100% local, no external API dependencies

Usage:
    from app.services.memory import MemoryService

    svc = MemoryService()
    svc.add("User prefers dark mode", tags=["user_42"])
    results = svc.search("user preferences", tags=["user_42"])

Why ChromaDB?
- Embedding-based semantic search out of the box
- Zero-config persistent storage
- Fast and lightweight
- Perfect for agent reasoning traces and context
"""

from __future__ import annotations

import uuid
from datetime import datetime
from pathlib import Path

import chromadb
from chromadb.config import Settings as ChromaSettings

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

_client: chromadb.ClientAPI | None = None


def _get_client() -> chromadb.ClientAPI:
    """Lazy-initialize a singleton ChromaDB client."""
    global _client
    if _client is not None:
        return _client

    db_path = Path(settings.MEMORY_DB_PATH)
    db_path.mkdir(parents=True, exist_ok=True)

    _client = chromadb.PersistentClient(
        path=str(db_path),
        settings=ChromaSettings(
            anonymized_telemetry=False,
            allow_reset=True,
        ),
    )
    logger.info("chromadb initialized", path=str(db_path))
    return _client


class MemoryService:
    """High-level wrapper around ChromaDB for agent memory operations."""

    def __init__(self) -> None:
        self.client = _get_client()
        self.collection = self.client.get_or_create_collection(
            name="agent_memories",
            metadata={"hnsw:space": "cosine"},
        )

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
            tags: Tags for namespacing (e.g., ["user_42", "agent_backend"]).
            metadata: Arbitrary key-value metadata for filtering.

        Returns:
            Confirmation message with memory ID.
        """
        memory_id = str(uuid.uuid4())
        meta = metadata or {}
        meta["timestamp"] = datetime.utcnow().isoformat()
        if tags:
            meta["tags"] = ",".join(tags)

        self.collection.add(
            ids=[memory_id],
            documents=[content],
            metadatas=[meta],
        )

        logger.info("memory stored", id=memory_id, content_preview=content[:80], tags=tags)
        return f"Memory stored (ID: {memory_id[:8]}): {content[:80]}..."

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
            tags: Filter by tags.
            limit: Max results to return.

        Returns:
            List of matching memory dicts with content, score, metadata.
        """
        where_filter = None
        if tags:
            # ChromaDB where filter: match any of the tags
            where_filter = {"tags": {"$contains": tags[0]}}

        results_obj = self.collection.query(
            query_texts=[query],
            n_results=limit,
            where=where_filter,
        )

        results = []
        if results_obj["ids"] and results_obj["ids"][0]:
            for i, doc_id in enumerate(results_obj["ids"][0]):
                results.append({
                    "id": doc_id,
                    "content": results_obj["documents"][0][i],
                    "score": 1.0 - results_obj["distances"][0][i],  # Convert distance to similarity
                    "metadata": results_obj["metadatas"][0][i],
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
            tags: Filter by tags.
            limit: Max results.

        Returns:
            List of memory dicts.
        """
        where_filter = None
        if tags:
            where_filter = {"tags": {"$contains": tags[0]}}

        result = self.collection.get(
            where=where_filter,
            limit=limit,
        )

        memories = []
        if result["ids"]:
            for i, doc_id in enumerate(result["ids"]):
                memories.append({
                    "id": doc_id,
                    "content": result["documents"][i],
                    "metadata": result["metadatas"][i],
                })

        logger.info("memories listed", tags=tags, count=len(memories))
        return memories

    def delete(self, memory_id: str) -> bool:
        """Delete a memory by ID.

        Args:
            memory_id: The ID of the memory to delete.

        Returns:
            True if deleted, False if not found.
        """
        try:
            self.collection.delete(ids=[memory_id])
            logger.info("memory deleted", id=memory_id)
            return True
        except Exception as e:
            logger.warning("memory delete failed", id=memory_id, error=str(e))
            return False
