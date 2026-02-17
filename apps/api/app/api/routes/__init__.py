from fastapi import APIRouter

from app.api.routes import health, memory

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(memory.router, tags=["memory"])
