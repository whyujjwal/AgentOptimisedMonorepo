from fastapi import APIRouter, HTTPException

from app.core.logging import get_logger
from app.schemas.memory import (
    MemoryAddRequest,
    MemoryAddResponse,
    MemorySearchRequest,
    MemorySearchResponse,
    MemorySearchResult,
)
from app.services.memory import MemoryService

logger = get_logger(__name__)
router = APIRouter(prefix="/memory")


def _get_memory_service() -> MemoryService:
    try:
        return MemoryService()
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.post("/add", response_model=MemoryAddResponse)
async def add_memory(req: MemoryAddRequest):
    """Store a new memory in the local vector database."""
    svc = _get_memory_service()
    message = svc.add(req.content, tags=req.tags, metadata=req.metadata)
    return MemoryAddResponse(message=message)


@router.post("/search", response_model=MemorySearchResponse)
async def search_memories(req: MemorySearchRequest):
    """Search memories by semantic similarity."""
    svc = _get_memory_service()
    raw_results = svc.search(req.query, tags=req.tags, limit=req.limit)
    results = [MemorySearchResult(**r) for r in raw_results]
    return MemorySearchResponse(results=results, count=len(results))
