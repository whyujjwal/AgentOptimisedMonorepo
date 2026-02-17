from pydantic import BaseModel


class MemoryAddRequest(BaseModel):
    content: str
    tags: list[str] | None = None
    metadata: dict | None = None


class MemoryAddResponse(BaseModel):
    message: str


class MemorySearchRequest(BaseModel):
    query: str
    tags: list[str] | None = None
    limit: int = 10


class MemorySearchResult(BaseModel):
    content: str
    score: float | None = None


class MemorySearchResponse(BaseModel):
    results: list[MemorySearchResult]
    count: int
